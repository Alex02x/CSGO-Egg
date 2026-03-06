#!/bin/bash
# Common utility functions for all updater scripts

# Configuration
VERSION_FILE="${EGG_DIR:-/home/container/egg}/versions.txt"
TEMP_DIR="./temps"

# Get GitHub release info (supports prerelease via PRERELEASE env var)
# Outputs JSON: {version, asset_url, asset_name, is_prerelease}
get_github_release() {
    local repo="$1"
    local asset_pattern="${2:-.*}"
    local url="https://api.github.com/repos/$repo/releases"

    # Select endpoint based on prerelease setting (log to stderr to not pollute output)
    if [ "${PRERELEASE:-0}" = "1" ]; then
        log_message "Checking releases (prereleases enabled) for $repo" "debug" >&2
    else
        url="$url/latest"
        log_message "Checking latest stable release for $repo" "debug" >&2
    fi

    curl -s "$url" 2>/dev/null | jq --arg p "$asset_pattern" '
        (if type == "array" then .[0] else . end) //empty |
        {
            version: .tag_name,
            is_prerelease: .prerelease,
            asset_url: (first(.assets[] | select(.name | test($p)) | .browser_download_url) // ""),
            asset_name: (first(.assets[] | select(.name | test($p)) | .name) // "")
        }
    ' 2>/dev/null
}

# Compare two semantic versions (semver)
# Returns:
#   0: if v1 == v2
#   1: if v1 > v2
#   2: if v1 < v2
semver_compare() {
    local v1=$(echo "$1" | sed 's/v//')
    local v2=$(echo "$2" | sed 's/v//')

    # Handle equality first for performance
    if [ "$v1" = "$v2" ]; then
        return 0
    fi

    # Use sort -V to find the "largest" version
    local highest=$(printf "%s\n%s" "$v1" "$v2" | sort -V | tail -n1)

    if [ "$v1" = "$highest" ]; then
        return 1 # v1 > v2
    else
        return 2 # v1 < v2
    fi
}

# Get current version from version file
get_current_version() {
    local addon="$1"
    if [ -f "$VERSION_FILE" ]; then
        grep "^$addon=" "$VERSION_FILE" | cut -d'=' -f2
    else
        echo ""
    fi
}

# Update version file
update_version_file() {
    local addon="$1"
    local new_version="$2"

    # Create directory if it doesn't exist
    mkdir -p "$(dirname "$VERSION_FILE")"

    if [ -f "$VERSION_FILE" ] && grep -q "^$addon=" "$VERSION_FILE"; then
        sed -i.bak "s/^$addon=.*/$addon=$new_version/" "$VERSION_FILE" && rm -f "$VERSION_FILE.bak"
    else
        echo "$addon=$new_version" >> "$VERSION_FILE"
    fi
}

# Centralized download and extract function
handle_download_and_extract() {
    local url="$1"
    local output_file="$2"
    local extract_dir="$3"
    local file_type="$4"  # "zip" or "tar.gz"

    log_message "Downloading from: $url" "debug"

    # Download with timeout and retry
    local max_retries=3
    local retry=0
    while [ $retry -lt $max_retries ]; do
        if curl -fsSL -m 300 -o "$output_file" "$url"; then
            break
        fi
        ((retry++))
        log_message "Download failed (attempt $retry/$max_retries)" "warning"
        sleep 5
    done

    if [ $retry -eq $max_retries ]; then
        log_message "Failed to download after $max_retries attempts" "error"
        return 1
    fi

    if [ ! -s "$output_file" ]; then
        log_message "Downloaded file is empty" "error"
        return 1
    fi

    mkdir -p "$extract_dir"

    case $file_type in
        "zip")
            unzip -qq -o "$output_file" -d "$extract_dir" || {
                log_message "Failed to extract zip file" "error"
                return 1
            }
            ;;
        "tar.gz")
            tar -xzf "$output_file" -C "$extract_dir" || {
                log_message "Failed to extract tar.gz file" "error"
                return 1
            }
            ;;
    esac

    return 0
}

# Centralized version checking using semver
check_version() {
    local addon="$1"
    local current="${2:-none}"
    local new="$3"

    if [ "$current" = "none" ] || [ -z "$current" ]; then
        log_message "Update available for $addon: $new (current: none)" "info"
        return 0 # New install
    fi

    semver_compare "$new" "$current"
    case $? in
        0) # Equal
            log_message "$addon is up-to-date ($current)" "debug"
            return 1
            ;;
        1) # new > current
            log_message "Update available for $addon: $new (current: $current)" "info"
            return 0
            ;;
        2) # new < current
            log_message "$addon is at a newer version ($current) than latest ($new). Skipping downgrade." "info"
            return 1
            ;;
    esac
}

# Add addon path to gameinfo.txt if not already present
# For CSGO (Source 1), MetaMod uses GameBin entry in SearchPaths
# Usage: add_to_gameinfo "csgo/addons/metamod"
add_to_gameinfo() {
    local addon_path="$1"
    local GAMEINFO_FILE="/home/container/csgo/gameinfo.txt"

    if [ ! -f "$GAMEINFO_FILE" ]; then
        log_message "gameinfo.txt not found at $GAMEINFO_FILE" "error"
        return 1
    fi

    # For MetaMod in CSGO, we need a GameBin entry
    local search_entry
    if [[ "$addon_path" == *"metamod"* ]]; then
        search_entry="GameBin				|gameinfo_path|addons/metamod/bin"
    else
        search_entry="Game				${addon_path}"
    fi

    # Check if path already exists
    if grep -qF "$search_entry" "$GAMEINFO_FILE"; then
        log_message "${addon_path} already in gameinfo.txt" "debug"
        return 0
    fi

    log_message "Adding ${addon_path} to gameinfo.txt..." "info"

    # Create backup
    cp "$GAMEINFO_FILE" "$GAMEINFO_FILE.bak" 2>/dev/null || {
        log_message "Failed to backup gameinfo.txt" "error"
        return 1
    }

    # For CSGO gameinfo.txt, insert after the SearchPaths opening brace
    # MetaMod needs GameBin entry, insert after first Game line in SearchPaths
    if [[ "$addon_path" == *"metamod"* ]]; then
        # Insert GameBin line for MetaMod after the SearchPaths section's first Game entry
        sed "/^[[:space:]]*Game[[:space:]]*|gameinfo_path|\.$/a\\
			GameBin				|gameinfo_path|addons/metamod/bin" "$GAMEINFO_FILE.bak" > "$GAMEINFO_FILE"
    else
        sed "/Game_LowViolence/a\\
			Game				${addon_path}" "$GAMEINFO_FILE.bak" > "$GAMEINFO_FILE"
    fi

    if [ $? -ne 0 ]; then
        log_message "sed command failed, restoring backup" "error"
        mv "$GAMEINFO_FILE.bak" "$GAMEINFO_FILE"
        return 1
    fi

    # Verify it was actually added
    if grep -qF "$search_entry" "$GAMEINFO_FILE"; then
        log_message "Added ${addon_path} to gameinfo.txt" "info"
        rm -f "$GAMEINFO_FILE.bak"
        return 0
    else
        log_message "WARNING: ${addon_path} not found after sed insertion, restoring backup" "error"
        mv "$GAMEINFO_FILE.bak" "$GAMEINFO_FILE"
        return 1
    fi
}

# Ensure MetaMod is always first addon after the initial Game entry
# This is critical because MetaMod must load before other addons
ensure_metamod_first() {
    local GAMEINFO_FILE="/home/container/csgo/gameinfo.txt"

    # Check if metamod GameBin entry exists in file
    if ! grep -q "GameBin.*addons/metamod" "$GAMEINFO_FILE" 2>/dev/null; then
        return 0  # No metamod, nothing to reorder
    fi

    # For CSGO, MetaMod uses GameBin entry which is naturally processed first
    # Just verify it exists - no complex reordering needed for Source 1
    log_message "MetaMod GameBin entry present in gameinfo.txt" "debug"
    return 0
}

# Tokenless mode for CSGO is handled via -insecure launch flag in entrypoint.sh
# No gameinfo.txt patching needed (unlike CS2's RequireLoginForDedicatedServers)
patch_tokenless_setting() {
    return 0
}
