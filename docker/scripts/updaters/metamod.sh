#!/bin/bash
# MetaMod Auto-Update Script
# Downloads and installs MetaMod 1.x from AlliedMods for CSGO

source /utils/logging.sh
source /utils/updater_common.sh

update_metamod() {
    local OUTPUT_DIR="./csgo/addons"

    if [ ! -d "$OUTPUT_DIR/metamod" ]; then
        log_message "Installing Metamod..." "info"
    fi

    # Use 1.12 branch (latest for CSGO compatibility)
    local MM_BRANCH="1.12"

    local metamod_version=$(curl -sL "https://mms.alliedmods.net/mmsdrop/${MM_BRANCH}/" | grep -o 'href="mmsource-[^"]*-linux\.tar\.gz' | sed 's/href="//' | tail -1)
    local download_failed=0

    if [ -z "$metamod_version" ]; then
        log_message "Failed to fetch Metamod version from alliedmods.net" "warning"
        download_failed=1
    fi

    if [ "$download_failed" -eq 0 ]; then
        local full_url="https://mms.alliedmods.net/mmsdrop/${MM_BRANCH}/$metamod_version"
        local new_version=$(echo "$metamod_version" | grep -o 'git[0-9]\+')
        local current_version=$(get_current_version "Metamod")

        # Check if update is needed
        if [ -n "$current_version" ]; then
            semver_compare "$new_version" "$current_version"
            case $? in
                0) # Equal
                    log_message "Metamod is up-to-date ($current_version)" "info"
                    return 0
                    ;;
                2) # new < current
                    log_message "Metamod is at a newer version ($current_version) than latest ($new_version). Skipping downgrade." "info"
                    return 0
                    ;;
            esac
        fi

        log_message "Update available for Metamod: $new_version (current: ${current_version:-none})" "info"

        if handle_download_and_extract "$full_url" "$TEMP_DIR/metamod.tar.gz" "$TEMP_DIR/metamod" "tar.gz"; then
            # Remove x64 VDF — CSGO srcds is 32-bit, x64 VDF causes ELFCLASS64 errors
            rm -f "$TEMP_DIR/metamod/addons/metamod_x64.vdf"
            cp -rf "$TEMP_DIR/metamod/addons/." "$OUTPUT_DIR/" && \
            update_version_file "Metamod" "$new_version" && \
            log_message "Metamod updated to $new_version" "success"
            return 0
        fi
    fi

    # Fallback: use bundled tar.gz if download failed and not yet installed
    if [ ! -d "$OUTPUT_DIR/metamod" ] && [ -f "/addons/mmsource-bundled.tar.gz" ]; then
        log_message "Using bundled Metamod as fallback..." "warning"
        mkdir -p "$TEMP_DIR/metamod"
        tar -xzf /addons/mmsource-bundled.tar.gz -C "$TEMP_DIR/metamod" 2>/dev/null
        if [ -d "$TEMP_DIR/metamod/addons" ]; then
            rm -f "$TEMP_DIR/metamod/addons/metamod_x64.vdf"
            cp -rf "$TEMP_DIR/metamod/addons/." "$OUTPUT_DIR/" && \
            update_version_file "Metamod" "bundled" && \
            log_message "Metamod installed from bundled archive" "success"
            return 0
        fi
        log_message "Failed to extract bundled Metamod" "error"
    fi

    return 1
}

# Main function
main() {
    mkdir -p "$TEMP_DIR"
    update_metamod
    return $?
}

# Run if executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
