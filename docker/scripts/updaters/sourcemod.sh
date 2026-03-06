#!/bin/bash
# SourceMod Auto-Update Script
# Downloads and installs SourceMod from AlliedMods for CSGO

source /utils/logging.sh
source /utils/updater_common.sh

update_sourcemod() {
    local OUTPUT_DIR="./csgo/addons"

    if [ ! -d "$OUTPUT_DIR/sourcemod" ]; then
        log_message "Installing SourceMod..." "info"
    fi

    # Use 1.12 branch (required for CSGO compatibility)
    local SM_BRANCH="1.12"
    if [ "${PRERELEASE:-0}" != "1" ]; then
        log_message "Using SourceMod $SM_BRANCH branch" "debug"
    fi

    local sm_version=$(curl -sL "https://sm.alliedmods.net/smdrop/${SM_BRANCH}/" | grep -o 'href="sourcemod-[^"]*-linux\.tar\.gz' | sed 's/href="//' | tail -1)
    local download_failed=0

    if [ -z "$sm_version" ]; then
        log_message "Failed to fetch SourceMod version from alliedmods.net" "warning"
        download_failed=1
    fi

    if [ "$download_failed" -eq 0 ]; then
        local full_url="https://sm.alliedmods.net/smdrop/${SM_BRANCH}/$sm_version"
        local new_version=$(echo "$sm_version" | grep -o 'git[0-9]\+')
        local current_version=$(get_current_version "SourceMod")

        # Check if update is needed
        if [ -n "$current_version" ]; then
            semver_compare "$new_version" "$current_version"
            case $? in
                0) # Equal
                    log_message "SourceMod is up-to-date ($current_version)" "info"
                    return 0
                    ;;
                2) # new < current
                    log_message "SourceMod is at a newer version ($current_version) than latest ($new_version). Skipping downgrade." "info"
                    return 0
                    ;;
            esac
        fi

        log_message "Update available for SourceMod: $new_version (current: ${current_version:-none})" "info"

        if handle_download_and_extract "$full_url" "$TEMP_DIR/sourcemod.tar.gz" "$TEMP_DIR/sourcemod" "tar.gz"; then
            cp -rf "$TEMP_DIR/sourcemod/addons/." "$OUTPUT_DIR/" && \
            # Also copy cfg files if present (SourceMod ships default configs)
            if [ -d "$TEMP_DIR/sourcemod/cfg" ]; then
                cp -rf "$TEMP_DIR/sourcemod/cfg/." "./csgo/cfg/"
            fi
            update_version_file "SourceMod" "$new_version" && \
            log_message "SourceMod updated to $new_version" "success"
            return 0
        fi
    fi

    # Fallback: use bundled tar.gz if download failed and not yet installed
    if [ -d "$OUTPUT_DIR/sourcemod" ]; then
        log_message "SourceMod already installed, skipping fallback" "debug"
    elif [ ! -f "/addons/sourcemod-bundled.tar.gz" ]; then
        log_message "Bundled SourceMod archive not found in image" "error"
    fi
    if [ ! -d "$OUTPUT_DIR/sourcemod" ] && [ -f "/addons/sourcemod-bundled.tar.gz" ]; then
        log_message "Using bundled SourceMod as fallback..." "warning"
        mkdir -p "$TEMP_DIR/sourcemod"
        tar -xzf /addons/sourcemod-bundled.tar.gz -C "$TEMP_DIR/sourcemod" 2>/dev/null
        if [ -d "$TEMP_DIR/sourcemod/addons" ]; then
            cp -rf "$TEMP_DIR/sourcemod/addons/." "$OUTPUT_DIR/" && \
            if [ -d "$TEMP_DIR/sourcemod/cfg" ]; then
                cp -rf "$TEMP_DIR/sourcemod/cfg/." "./csgo/cfg/"
            fi
            update_version_file "SourceMod" "bundled" && \
            log_message "SourceMod installed from bundled archive" "success"
            return 0
        fi
        log_message "Failed to extract bundled SourceMod" "error"
    fi

    return 1
}

# Main function
main() {
    mkdir -p "$TEMP_DIR"
    update_sourcemod
    return $?
}

# Run if executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
