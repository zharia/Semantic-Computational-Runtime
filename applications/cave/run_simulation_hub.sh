#!/usr/bin/env bash
# ==============================================================================
# SCR Simulation Hub — Unified Multi-Domain Simulation Runner
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "================================================================================"
echo " Starting SCR Simulation Hub..."
echo " Repository Root: $REPO_ROOT"
echo "================================================================================"

cd "$REPO_ROOT"

nix-shell -p ogre openvdb tbb c-blosc SDL2 bullet nlohmann_json wayland wayland-protocols libxkbcommon foot weston alacritty pkg-config --run '
  set -e
  echo "[Build] Compiling SCR Simulation Framework..."
  g++ -std=c++17 -O2 \
    -I applications/cave/include \
    -I providers/physics/bullet3/adapter \
    -I providers/render/water_ssfr/adapter \
    -I providers/system/gpu/dmabuf/adapter \
    $(pkg-config --cflags OGRE OGRE-Bites OGRE-RTShaderSystem OGRE-Overlay tbb blosc bullet) \
    -I/nix/store/rixg5lywdy2pqbc9xqlmw6x8bywspf4p-openvdb-12.1.0-dev/include \
    -I/nix/store/ikjg3l2vyw9bwccabx1m9dlk8la7n921-nlohmann_json-3.12.0/include \
    applications/cave/src/simulation_main.cpp \
    applications/cave/src/xdg_shell_protocol.c \
    providers/physics/fluid/adapter/fluid_adapter.cpp \
    providers/physics/bullet3/adapter/bullet_adapter.cpp \
    providers/render/water_ssfr/adapter/water_ssfr_adapter.cpp \
    providers/system/gpu/dmabuf/adapter/dmabuf_adapter.c \
    $(pkg-config --libs OGRE OGRE-Bites OGRE-RTShaderSystem OGRE-Overlay tbb blosc bullet) \
    -L/nix/store/zlqhf6hgddacs71njbws7k9ajfi4kd2x-openvdb-12.1.0/lib -lopenvdb \
    -lwayland-server -lxkbcommon \
    -Wl,-rpath,/nix/store/zlqhf6hgddacs71njbws7k9ajfi4kd2x-openvdb-12.1.0/lib \
    -o applications/cave/scr_simulation_hub

  echo "[Launch] Running SCR Simulation Hub..."
  exec ./applications/cave/scr_simulation_hub
'
