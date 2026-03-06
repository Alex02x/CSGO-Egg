#!/bin/bash

source /utils/logging.sh
source /utils/config.sh
source /scripts/install.sh
source /scripts/sync.sh
source /scripts/cleanup.sh
source /scripts/update.sh
source /scripts/filter.sh
source /scripts/update_helper.sh

# Enhanced error handling
trap 'handle_error ${LINENO} "$BASH_COMMAND"' ERR

cd /home/container
sleep 1

# Run legacy file migration check (only runs on first boot with new structure)
migrate_legacy_files

# Remove obsolete config files from old versions
cleanup_obsolete_configs

# Check for deprecated variables (ADDON_SELECTION)
check_deprecated_variables

# Initialize and load configurations
init_configs
load_configs

# Get internal Docker IP
INTERNAL_IP=$(ip route get 1 | awk '{print $NF;exit}')

# VPK Sync and SteamCMD installation (skip if updates disabled)
if [ ${SRCDS_STOP_UPDATE:-0} -eq 0 ]; then
    # VPK Sync (if configured) - must happen before SteamCMD
    sync_files
    sync_cfg_files

    # Initial setup and sync
    install_steamcmd
    clean_old_logs
else
    log_message "Updates disabled, skipping VPK sync and SteamCMD" "warning"
fi

# Server update process
if [ -n "${SRCDS_APPID}" ] && [ "${SRCDS_STOP_UPDATE:-0}" -eq 0 ]; then
    STEAMCMD=""
    if [ -n "${SRCDS_BETAID}" ]; then
        if [ -n "${SRCDS_BETAPASS}" ]; then
            if [ "${SRCDS_VALIDATE}" -eq 1 ]; then
                log_message "Validation enabled: THIS MAY WIPE CUSTOM CONFIGURATIONS!" "error"
                if [ -n "${SRCDS_LOGIN}" ]; then
                    STEAMCMD="./steamcmd/steamcmd.sh +force_install_dir /home/container +login ${SRCDS_LOGIN} ${SRCDS_LOGIN_PASS} +app_update ${SRCDS_APPID} -beta ${SRCDS_BETAID} -betapassword ${SRCDS_BETAPASS} validate +quit"
                else
                    STEAMCMD="./steamcmd/steamcmd.sh +force_install_dir /home/container +login anonymous +app_update ${SRCDS_APPID} -beta ${SRCDS_BETAID} -betapassword ${SRCDS_BETAPASS} validate +quit"
                fi
            else
                if [ -n "${SRCDS_LOGIN}" ]; then
                    STEAMCMD="./steamcmd/steamcmd.sh +force_install_dir /home/container +login ${SRCDS_LOGIN} ${SRCDS_LOGIN_PASS} +app_update ${SRCDS_APPID} -beta ${SRCDS_BETAID} -betapassword ${SRCDS_BETAPASS} +quit"
                else
                    STEAMCMD="./steamcmd/steamcmd.sh +force_install_dir /home/container +login anonymous +app_update ${SRCDS_APPID} -beta ${SRCDS_BETAID} -betapassword ${SRCDS_BETAPASS} +quit"
                fi
            fi
        else
            if [ "${SRCDS_VALIDATE}" -eq 1 ]; then
                if [ -n "${SRCDS_LOGIN}" ]; then
                    STEAMCMD="./steamcmd/steamcmd.sh +force_install_dir /home/container +login ${SRCDS_LOGIN} ${SRCDS_LOGIN_PASS} +app_update ${SRCDS_APPID} -beta ${SRCDS_BETAID} validate +quit"
                else
                    STEAMCMD="./steamcmd/steamcmd.sh +force_install_dir /home/container +login anonymous +app_update ${SRCDS_APPID} -beta ${SRCDS_BETAID} validate +quit"
                fi
            else
                if [ -n "${SRCDS_LOGIN}" ]; then
                    STEAMCMD="./steamcmd/steamcmd.sh +force_install_dir /home/container +login ${SRCDS_LOGIN} ${SRCDS_LOGIN_PASS} +app_update ${SRCDS_APPID} -beta ${SRCDS_BETAID} +quit"
                else
                    STEAMCMD="./steamcmd/steamcmd.sh +force_install_dir /home/container +login anonymous +app_update ${SRCDS_APPID} -beta ${SRCDS_BETAID} +quit"
                fi
            fi
        fi
    else
        if [ "${SRCDS_VALIDATE}" -eq 1 ]; then
            log_message "Validation enabled: THIS MAY WIPE CUSTOM CONFIGURATIONS!" "error"
            if [ -n "${SRCDS_LOGIN}" ]; then
                STEAMCMD="./steamcmd/steamcmd.sh +force_install_dir /home/container +login ${SRCDS_LOGIN} ${SRCDS_LOGIN_PASS} +app_update ${SRCDS_APPID} validate +quit"
            else
                STEAMCMD="./steamcmd/steamcmd.sh +force_install_dir /home/container +login anonymous +app_update ${SRCDS_APPID} validate +quit"
            fi
        else
            if [ -n "${SRCDS_LOGIN}" ]; then
                STEAMCMD="./steamcmd/steamcmd.sh +force_install_dir /home/container +login ${SRCDS_LOGIN} ${SRCDS_LOGIN_PASS} +app_update ${SRCDS_APPID} +quit"
            else
                STEAMCMD="./steamcmd/steamcmd.sh +force_install_dir /home/container +login anonymous +app_update ${SRCDS_APPID} +quit"
            fi
        fi
    fi

    log_message "SteamCMD command: $(echo "$STEAMCMD" | sed -E 's/(\+login [^ ]+ )[^ ]+/\1****/')" "debug"
    eval ${STEAMCMD}
    STEAM_EXIT_CODE=$?

    if [ $STEAM_EXIT_CODE -eq 8 ]; then
        log_message "SteamCMD connection error (exit code 8)" "error"
        log_message "1. Check network and Steam server status (steamstat.us)" "info"
        log_message "2. Ensure 20-30GB free disk space available (with VPK-Sync 3GB free)" "info"
        log_message "3. Disable proxy/VPN if enabled" "info"
    elif [ $STEAM_EXIT_CODE -ne 0 ]; then
        log_message "SteamCMD failed with exit code $STEAM_EXIT_CODE" "error"
    fi

    # Update steamclient.so files
    cp -f ./steamcmd/linux32/steamclient.so ./.steam/sdk32/steamclient.so
    cp -f ./steamcmd/linux64/steamclient.so ./.steam/sdk64/steamclient.so
fi

# Patch steam.inf to use new CSGO AppID (4465480) so updated clients can connect
# SteamCMD installs with appID=730, but the new standalone CSGO uses 4465480
STEAM_INF="/home/container/csgo/steam.inf"
if [ -f "$STEAM_INF" ]; then
    if grep -q "appID=730" "$STEAM_INF"; then
        sed -i 's/appID=730/appID=4465480/' "$STEAM_INF"
        log_message "Patched steam.inf: appID=730 -> 4465480" "info"
    fi
fi

# Handle the addon installations based on the selection
update_addons

# Set up console filter
setup_message_filter

# Build the actual startup command from template
MODIFIED_STARTUP=$(eval echo $(echo ${STARTUP} | sed -e 's/{{/${/g' -e 's/}}/}/g'))

# Add -insecure flag if tokenless server is allowed
if [ "${ALLOW_TOKENLESS:-0}" -eq 1 ] && [ -z "${STEAM_ACC}" ]; then
    MODIFIED_STARTUP="${MODIFIED_STARTUP} -insecure"
    log_message "Running in tokenless mode (-insecure)" "warning"
fi

# Log the command but hide the Steam account token for security
LOGGED_STARTUP=$(echo "${MODIFIED_STARTUP}" | \
    sed -E 's/(\+sv_setsteamaccount\s+[A-Z0-9]{32})/+sv_setsteamaccount ************************/g')
log_message "Starting server: ${LOGGED_STARTUP}" "info"

# GDB mode: launch server under gdbserver for remote debugging
if [ -n "${GDB_DEBUG_PORT}" ]; then
    export GAME_DEBUGGER="gdbserver --no-disable-randomization :${GDB_DEBUG_PORT}"
    log_message "GDB mode: Server will start under gdbserver on port ${GDB_DEBUG_PORT}" "info"
    log_message "Server will wait for debugger connection before starting" "warning"
fi

# Actually start the server and handle its output
START_CMD="script -qfc \"$MODIFIED_STARTUP\" /dev/null 2>&1"

eval "$START_CMD" | while IFS= read -r line; do
    line="${line%[[:space:]]}"
    [[ "$line" =~ Segmentation\ fault.*"${GAMEEXE}" ]] && continue

    # Detect crash via srcds crash pattern
    if [[ "$line" =~ Segmentation\ fault|Aborted.*\(core\ dumped\) ]]; then
        handle_server_output "$line"

        log_message "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "warning"
        log_message "Server crash detected - Common causes and solutions:" "warning"
        log_message "" "warning"
        log_message "1. Plugin Issues:" "info"
        log_message "   • Check if recently installed/updated plugins are compatible" "info"
        log_message "   • Try removing plugins one by one to identify the culprit" "info"
        log_message "" "warning"
        log_message "2. Addon Compatibility:" "info"
        log_message "   • Verify MetaMod/SourceMod versions are up to date" "info"
        log_message "   • Check addon compatibility with current CSGO version" "info"
        log_message "   • Review gameinfo.txt for correct addon load order" "info"
        log_message "" "warning"
        log_message "3. Outdated Gamedata:" "info"
        log_message "   • Check which plugins have outdated gamedata for current CSGO version" "info"
        log_message "   • Check SourceMod plugin compatibility" "info"
        log_message "" "warning"
        log_message "Review logs above for specific error messages and stack traces" "warning"
        log_message "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "warning"
        continue
    fi

    handle_server_output "$line"
done

# Clean up any background processes we started
pkill -P $$ 2>/dev/null || true

log_message "Server stopped" "success"