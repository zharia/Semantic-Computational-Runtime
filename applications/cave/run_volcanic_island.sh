#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# SCR Exotic Volcanic Island Explorer — Launcher
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
APP_DIR="$SCRIPT_DIR"
BIN="$APP_DIR/volcanic_island_app"
LOG="$APP_DIR/island_explorer.log"

OGRE_STORE="/nix/store/93dqfagdxd6aiv80j7vbm221ns1iibaa-ogre-14.5.2"
VDB_STORE="/nix/store/zlqhf6hgddacs71njbws7k9ajfi4kd2x-openvdb-12.1.0"
VDB_INC_STORE="/nix/store/rixg5lywdy2pqbc9xqlmw6x8bywspf4p-openvdb-12.1.0-dev"
JSON_INC_STORE="/nix/store/ikjg3l2vyw9bwccabx1m9dlk8la7n921-nlohmann_json-3.12.0"

print_banner() {
cat << 'EOF'
================================================================================
 SCR Volcanic Island Explorer — OpenVDB + OGRE 14 + Dear ImGui HUD
 Procedural Environment: Multi-scale Spectral Noise + Hierarchical WFC
================================================================================
 Controls:
    WASD / Arrows — Move (camera-relative) |  Mouse — Look (FPS)
    SPACE         — Jump / Swim           |  LSHIFT — Sprint
    [ / ]         — Time of Day (Dawn / Noon / Sunset / Night)
    C             — Cycle Cloud Preset (RDR2 Cumulus / Sunset / Ash Storm / Clear)
    F12 / P       — Take Screenshot       |  M      — Toggle mesh mode
    LMB           — Mine voxel            |  RMB    — Place (hotbar)
    1-9           — Hotbar mats           |  T      — STC reaction
    R             — Regenerate island     |  H      — Head-shake
    ESC           — Quit

 HUD & Overlay:
    Center       — Targeting Reticle / Crosshair
    Bottom-Right — Biome minimap + compass + coordinates
    Bottom-Left  — Material inspector (aim reticle at any surface)
    Top-Left     — FPS overlay
    Top-Centre   — Compass rose
================================================================================
EOF
}

compile_island() {
    echo "[Build] Compiling volcanic island explorer..."
    nix-shell -p ogre openvdb tbb c-blosc SDL2 nlohmann_json pkg-config --run "
        g++ -std=c++17 -O2 \
            -I\"$APP_DIR/include\" \
            \$(pkg-config --cflags OGRE OGRE-Bites OGRE-RTShaderSystem OGRE-Overlay tbb blosc) \
            -I\"$VDB_INC_STORE/include\" \
            -I\"$JSON_INC_STORE/include\" \
            \"$APP_DIR/src/volcanic_island_app.cpp\" \
            \"$PROJECT_ROOT/providers/physics/fluid/adapter/fluid_adapter.cpp\" \
            \$(pkg-config --libs OGRE OGRE-Bites OGRE-RTShaderSystem OGRE-Overlay tbb blosc) \
            -L\"$VDB_STORE/lib\" -lopenvdb \
            -o \"$BIN\" 2>&1
    "
    echo "[Build] OK — $BIN"
}

# ── Main ──────────────────────────────────────────────────────────────────────
cd "$PROJECT_ROOT"
print_banner

# Rebuild if source is newer than binary
if [ ! -f "$BIN" ] || \
   find "$APP_DIR/include" "$APP_DIR/src" -name "*.hpp" -o -name "*.cpp" \
        -newer "$BIN" 2>/dev/null | grep -q .; then
    compile_island
else
    echo "[Build] Binary up to date."
fi

echo "[Launch] Starting SCR Volcanic Island Explorer..."
echo "[Log]    $LOG"
echo ""

# Run with OGRE plugin/resource paths set
export DISPLAY="${DISPLAY:-:0}"
export OGRE_PLUGIN_DIR="$OGRE_STORE/lib/OGRE"
export OGRE_RESOURCE_DIR="$OGRE_STORE/share/OGRE-14.5/Media"

exec nix-shell -p ogre openvdb tbb c-blosc SDL2 nlohmann_json --run \
    "LD_LIBRARY_PATH=\"$VDB_STORE/lib:\$LD_LIBRARY_PATH\" \"$BIN\""
