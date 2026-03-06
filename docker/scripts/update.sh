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

# Install nolobbyreservation SourceMod plugin
# Required for CSGO AppID 4465480 — without it clients get "Client dropped by server"
install_nolobbyreservation() {
    local plugin_dir="./csgo/addons/sourcemod/plugins"
    local gamedata_dir="./csgo/addons/sourcemod/gamedata"
    local plugin_file="$plugin_dir/nolobbyreservation.smx"

    # Skip if already installed
    if [ -f "$plugin_file" ]; then
        log_message "nolobbyreservation plugin already installed" "debug"
        return 0
    fi

    mkdir -p "$plugin_dir" "$gamedata_dir" 2>/dev/null

    # Download nolobbyreservation.smx from known source
    local smx_url="https://raw.githubusercontent.com/eldoradoel/NoLobbyReservation/master/csgo/addons/sourcemod/plugins/nolobbyreservation.smx"
    local gamedata_url="https://raw.githubusercontent.com/eldoradoel/NoLobbyReservation/master/csgo/addons/sourcemod/gamedata/nolobbyreservation.games.txt"

    if curl -sSL --connect-timeout 15 --max-time 60 -o "$plugin_file" "$smx_url" 2>/dev/null; then
        log_message "Installed nolobbyreservation.smx plugin" "success"
    else
        log_message "Failed to download nolobbyreservation.smx — clients may not be able to connect" "warning"
        rm -f "$plugin_file" 2>/dev/null
        return 1
    fi

    local gamedata_file="$gamedata_dir/nolobbyreservation.games.txt"
    if [ ! -f "$gamedata_file" ]; then
        if curl -sSL --connect-timeout 15 --max-time 60 -o "$gamedata_file" "$gamedata_url" 2>/dev/null; then
            log_message "Installed nolobbyreservation gamedata" "debug"
        else
            log_message "Failed to download nolobbyreservation gamedata" "warning"
        fi
    fi

    return 0
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

        # Install nolobbyreservation plugin (required for new CSGO AppID 4465480)
        # Without this plugin, clients cannot connect to the server
        install_nolobbyreservation
    fi

    # Ensure MetaMod is always first addon after LowViolence (if present)
    ensure_metamod_first

    # Clean up
    rm -rf "$TEMP_DIR"
}

