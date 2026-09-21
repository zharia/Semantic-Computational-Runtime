#!/bin/bash
# SCR Volcanic Island - Build Script
# Builds the O3DE project with SCR integration

set -e

echo "=== SCR Volcanic Island Build ==="
echo ""

# Check O3DE
O3DE_PATH="/opt/O3DE/26.05"
if [ ! -d "$O3DE_PATH" ]; then
    echo "ERROR: O3DE not found at $O3DE_PATH"
    exit 1
fi

echo "O3DE found at: $O3DE_PATH"

# Create build directory
BUILD_DIR="build"
mkdir -p "$BUILD_DIR"

echo ""
echo "=== Configuring CMake ==="
cd "$BUILD_DIR"

cmake .. \
    -G "Ninja Multi-Config" \
    -DCMAKE_C_COMPILER=gcc \
    -DCMAKE_CXX_COMPILER=g++ \
    -DCMAKE_BUILD_TYPE=Release \
    -DLY_3RDPARTY_PATH="$O3DE_PATH/External" \
    -DLY_PROJECT_NAME="SCR_VolcanicIsland" \
    -DLY_PROJECT_ROOT="$(pwd)/.." \
    || { echo "ERROR: CMake configuration failed"; exit 1; }

echo ""
echo "=== Building ==="
cmake --build . --config Release --parallel $(nproc) \
    || { echo "ERROR: Build failed"; exit 1; }

echo ""
echo "=== Build Complete ==="
echo "Run with: ./bin/Linux/profile/Default/SCR_VolcanicIsland.GameLauncher"
