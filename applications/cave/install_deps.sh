#!/usr/bin/env bash
# Install system dependencies for SCR Simulation Hub
# Requires: sudo access
set -euo pipefail

echo "=== Installing system dependencies ==="
sudo pacman -S --needed --noconfirm \
    ogre \
    bullet \
    onetbb \
    sdl2 \
    openvdb \
    imath \
    blosc \
    nlohmann-json \
    wayland \
    wayland-protocols \
    libxkbcommon \
    pkgconf \
    gcc

echo "=== Verifying ==="
pkg-config --exists OGRE OGRE-Bites OGRE-RTShaderSystem OGRE-Overlay && echo "OGRE: OK" || echo "OGRE: MISSING"
pkg-config --exists bullet && echo "Bullet: OK" || echo "Bullet: MISSING"
pkg-config --exists tbb && echo "TBB: OK" || echo "TBB: MISSING"
test -f /usr/include/openvdb/OpenVDB.h && echo "OpenVDB: OK" || echo "OpenVDB: MISSING"
pkg-config --exists nlohmann_json && echo "nlohmann_json: OK" || echo "nlohmann_json: MISSING"
echo "=== Done ==="
