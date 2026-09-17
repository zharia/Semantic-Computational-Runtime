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

nix-shell -p ogre openvdb tbb c-blosc SDL2 nlohmann_json pkg-config --run "
  set -e
  echo 'Compiling SCR Simulation Framework...'
  g++ -std=c++17 -O2 \
    -I applications/cave/include \
    \$(pkg-config --cflags OGRE OGRE-Bites OGRE-RTShaderSystem OGRE-Overlay tbb blosc) \
    -I/nix/store/rixg5lywdy2pqbc9xqlmw6x8bywspf4p-openvdb-12.1.0-dev/include \
    -I/nix/store/ikjg3l2vyw9bwccabx1m9dlk8la7n921-nlohmann_json-3.12.0/include \
    applications/cave/src/simulation_main.cpp \
    providers/physics/fluid/adapter/fluid_adapter.cpp \
    \$(pkg-config --libs OGRE OGRE-Bites OGRE-RTShaderSystem OGRE-Overlay tbb blosc) \
    -L/nix/store/zlqhf6hgddacs71njbws7k9ajfi4kd2x-openvdb-12.1.0/lib -lopenvdb \
    -Wl,-rpath,/nix/store/zlqhf6hgddacs71njbws7k9ajfi4kd2x-openvdb-12.1.0/lib \
    -o applications/cave/scr_simulation_hub

  echo 'Launching SCR Simulation Hub...'
  ./applications/cave/scr_simulation_hub
"
