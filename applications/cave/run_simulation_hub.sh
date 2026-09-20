#!/usr/bin/env bash
# ==============================================================================
# SCR Simulation Hub — Unified Multi-Domain Simulation Runner
# System-only build. Run install_deps.sh first.
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

XDG_PROTOCOL_C="$SCRIPT_DIR/src/xdg_shell_protocol.c"
XDG_PROTOCOL_H="$SCRIPT_DIR/include/xdg_shell_protocol.h"

echo "================================================================================"
echo " Starting SCR Simulation Hub..."
echo " Repository Root: $REPO_ROOT"
echo "================================================================================"

cd "$REPO_ROOT"

# Generate wayland protocol sources if missing
if [ ! -f "$XDG_PROTOCOL_C" ] || [ ! -f "$XDG_PROTOCOL_H" ]; then
    echo "[Build] Generating xdg-shell wayland protocol sources..."
    PROTOCOL_XML="$(pkg-config --variable=pkgdatadir wayland-protocols)/stable/xdg-shell/xdg-shell.xml"
    wayland-scanner public-code "$PROTOCOL_XML" "$XDG_PROTOCOL_C"
    wayland-scanner server-header "$PROTOCOL_XML" "$XDG_PROTOCOL_H"
fi

echo "[Build] Compiling C sources..."
gcc -c -O2 \
    -I applications/cave/include -I lib \
    "$XDG_PROTOCOL_C" -o /tmp/xdg_shell_protocol.o
gcc -c -O2 \
    providers/system/gpu/dmabuf/adapter/dmabuf_adapter.c -o /tmp/dmabuf_adapter.o

echo "[Build] Compiling SCR Simulation Framework..."
g++ -std=c++17 -O2 \
    -I applications/cave/include -I lib -I providers \
    $(pkg-config --cflags OGRE OGRE-Bites OGRE-RTShaderSystem OGRE-Overlay tbb bullet nlohmann_json) \
    -I providers/physics/fluid/adapter \
    -I providers/physics/bullet3/adapter \
    -I providers/render/water_ssfr/adapter \
    -I providers/system/gpu/dmabuf/adapter \
    applications/cave/src/simulation_main.cpp \
    providers/physics/fluid/adapter/fluid_adapter.cpp \
    providers/physics/bullet3/adapter/bullet_adapter.cpp \
    providers/render/water_ssfr/adapter/water_ssfr_adapter.cpp \
    /tmp/xdg_shell_protocol.o \
    /tmp/dmabuf_adapter.o \
    $(pkg-config --libs OGRE OGRE-Bites OGRE-RTShaderSystem OGRE-Overlay tbb bullet nlohmann_json) \
    -lopenvdb -lImath -lblosc \
    -lwayland-server -lxkbcommon \
    -o applications/cave/scr_simulation_hub

echo "[Launch] Running SCR Simulation Hub..."
exec ./applications/cave/scr_simulation_hub
