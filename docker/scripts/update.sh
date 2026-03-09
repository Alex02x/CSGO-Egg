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
    local gamedata_file="$gamedata_dir/nolobbyreservation.games.txt"

    # Skip if already installed
    if [ -f "$plugin_file" ] && [ -f "$gamedata_file" ]; then
        log_message "nolobbyreservation plugin already installed" "debug"
        return 0
    fi

    mkdir -p "$plugin_dir" "$gamedata_dir" 2>/dev/null

    # Copy from bundled files in Docker image
    if [ -f "/plugins/nolobbyreservation/nolobbyreservation.smx" ]; then
        cp -f /plugins/nolobbyreservation/nolobbyreservation.smx "$plugin_file"
        cp -f /plugins/nolobbyreservation/nolobbyreservation.games.txt "$gamedata_file"
        log_message "Installed nolobbyreservation plugin (bundled)" "success"
    else
        log_message "nolobbyreservation plugin files not found in image" "warning"
        return 1
    fi

    return 0
}

# Install bundled CSGO steam fix extension files for SourceMod.
install_csgo_steamfix() {
    local ext_dir="./csgo/addons/sourcemod/extensions"
    local ext_file="$ext_dir/csgo_steamfix.ext.so"
    local autoload_file="$ext_dir/csgo_steamfix.autoload"

    # Skip when already installed.
    if [ -f "$ext_file" ] && [ -f "$autoload_file" ]; then
        log_message "csgo_steamfix already installed" "debug"
        return 0
    fi

    mkdir -p "$ext_dir" 2>/dev/null

    if [ -f "/fixes/steamfix/csgo_steamfix.ext.so" ] && [ -f "/fixes/steamfix/csgo_steamfix.autoload" ]; then
        cp -f /fixes/steamfix/csgo_steamfix.ext.so "$ext_file"
        cp -f /fixes/steamfix/csgo_steamfix.autoload "$autoload_file"
        log_message "Installed csgo_steamfix extension files" "success"
    else
        log_message "csgo_steamfix files not found in image" "warning"
        return 1
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

        # CSGO loads MetaMod via VDF files (metamod.vdf), no gameinfo.txt patching needed
        # Remove x64 VDF if present (32-bit srcds can't load it, causes ELFCLASS64 error)
        rm -f "./csgo/addons/metamod_x64.vdf"
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

        # Install bundled steam fix extension files for SourceMod servers.
        install_csgo_steamfix
    elif [ -d "./csgo/addons/sourcemod/extensions" ]; then
        # If SourceMod already exists from previous setup, ensure fix files are present.
        install_csgo_steamfix
    fi

    # CSGO uses VDF-based MetaMod loading, no gameinfo.txt reordering needed

    # Clean up
    rm -rf "$TEMP_DIR"
}

