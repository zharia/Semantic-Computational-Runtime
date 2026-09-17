#!/usr/bin/env bash
# SCR Voxel Cave Explorer Desktop Launcher with Automatic Logging
# Launches the OpenVDB-accelerated OGRE 3D Procedural Cave Simulation

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
LOG_FILE="${SCRIPT_DIR}/cave_explorer.log"

cd "${WORKSPACE_ROOT}"

# Rotate log file if > 5MB
if [ -f "${LOG_FILE}" ] && [ $(stat -c%s "${LOG_FILE}" 2>/dev/null || echo 0) -gt 5242880 ]; then
    mv "${LOG_FILE}" "${LOG_FILE}.old"
fi

{
    echo "================================================================================"
    echo " SCR Voxel Cave Explorer Session Start"
    echo " Timestamp   : $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
    echo " Workspace   : ${WORKSPACE_ROOT}"
    echo " Log File    : ${LOG_FILE}"
    echo " Display     : ${DISPLAY:-:0}"
    echo " Wayland     : ${WAYLAND_DISPLAY:-none}"
    echo " Session Type: ${XDG_SESSION_TYPE:-unknown}"
    echo " Video Driver: x11 (via XWayland bridge for OGRE GLX/EGL compatibility)"
    echo "================================================================================"
} | tee -a "${LOG_FILE}"

# Execute application with combined stdout/stderr logging via tee
nix-shell -p ogre openvdb tbb c-blosc SDL2 nlohmann_json pkg-config --run "
    export LD_LIBRARY_PATH=\"/nix/store/zlqhf6hgddacs71njbws7k9ajfi4kd2x-openvdb-12.1.0/lib:\$LD_LIBRARY_PATH\"
    export SDL_VIDEODRIVER=x11
    export DISPLAY=\"${DISPLAY:-:0}\"
    ./applications/cave/voxel_cave_app
" 2>&1 | tee -a "${LOG_FILE}"

EXIT_CODE="${PIPESTATUS[0]}"

{
    echo ""
    echo "================================================================================"
    if [ "${EXIT_CODE}" -eq 0 ]; then
        echo " Session completed normally (Exit Code: 0)."
    else
        echo " [ERROR] Application terminated with exit code ${EXIT_CODE}."
        echo " Full diagnostic log captured at: ${LOG_FILE}"
    fi
    echo " Timestamp: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
    echo "================================================================================"
} | tee -a "${LOG_FILE}"

exit "${EXIT_CODE}"
