#!/bin/bash
source /utils/logging.sh
source /utils/updater_common.sh

# Directories
GAME_DIRECTORY="./csgo"
OUTPUT_DIR="./csgo/addons"
TEMP_DIR="./temps"

# Source modular updaters
source /scripts/updaters/metamod.sh
source /scripts/updaters/sourcemod.sh

# Backwards compatibility: Map old ADDON_SELECTION to new boolean variables
migrate_addon_selection() {
    if [ -n "${ADDON_SELECTION}" ]; then
        case "${ADDON_SELECTION}" in
            "Metamod Only")
                INSTALL_METAMOD=1
                ;;
            "Metamod + SourceMod")
                INSTALL_METAMOD=1
                INSTALL_SOURCEMOD=1
                ;;
        esac
    fi
}

# Main addon update function based on boolean variables
update_addons() {
    # Cleanup if enabled
    if [ "${CLEANUP_ENABLED:-0}" -eq 1 ]; then
        cleanup
    fi

    mkdir -p "$TEMP_DIR"

    # Backwards compatibility migration
    migrate_addon_selection

    # Dependency check: SourceMod requires MetaMod
    if [ "${INSTALL_SOURCEMOD:-0}" -eq 1 ] && [ "${INSTALL_METAMOD:-0}" -ne 1 ]; then
        log_message "SourceMod requires MetaMod:Source, auto-enabling..." "warning"
        INSTALL_METAMOD=1
    fi

    # MetaMod:Source
    if [ "${INSTALL_METAMOD:-0}" -eq 1 ]; then
        if type update_metamod &>/dev/null; then
            update_metamod
        else
            log_message "update_metamod function not available" "error"
        fi

        # Configure metamod in gameinfo.txt
        add_to_gameinfo "csgo/addons/metamod"
    fi

    # SourceMod
    if [ "${INSTALL_SOURCEMOD:-0}" -eq 1 ]; then
        if type update_sourcemod &>/dev/null; then
            update_sourcemod
        else
            log_message "update_sourcemod function not available" "error"
        fi
    fi

    # Ensure MetaMod is always first addon after LowViolence (if present)
    ensure_metamod_first

    # Clean up
    rm -rf "$TEMP_DIR"
}

