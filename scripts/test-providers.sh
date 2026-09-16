#!/usr/bin/env bash
#
# SCR Provider Conformance Test Suite Runner
#
# Builds and executes standalone conformance tests for the core providers:
# - OpenVDB (spatial/volumetric)
# - OGRE 3D (render/graphics)
# - Louvre (system/compositor)
# - DMA-BUF (system/gpu)
#

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="/tmp/scr_provider_tests"
mkdir -p "$BUILD_DIR"

echo "============================================================"
echo " Running SCR Provider Conformance Test Suites"
echo "============================================================"
echo

CC="${CC:-clang}"
CXX="${CXX:-clang++}"

# 1. OpenVDB Conformance Test
echo ">>> [1/4] Compiling and running OpenVDB provider test..."
VDB_LIBS=""
if echo '#include <openvdb/openvdb.h>' | $CXX -x c++ -E - >/dev/null 2>&1; then
    VDB_LIBS="-lopenvdb -ltbb"
fi
$CXX -std=c++17 -Wall -Wextra \
    "$ROOT/providers/spatial/volumetric/openvdb/adapter/openvdb_adapter.cpp" \
    "$ROOT/providers/spatial/volumetric/openvdb/tests/test_openvdb_contract.cpp" \
    $VDB_LIBS \
    -o "$BUILD_DIR/test_openvdb"
"$BUILD_DIR/test_openvdb"
echo

# 2. OGRE Conformance Test
echo ">>> [2/4] Compiling and running OGRE provider test..."
$CXX -std=c++17 -Wall -Wextra \
    "$ROOT/providers/render/graphics/ogre/adapter/ogre_adapter.cpp" \
    "$ROOT/providers/render/graphics/ogre/tests/test_ogre_contract.cpp" \
    -o "$BUILD_DIR/test_ogre"
"$BUILD_DIR/test_ogre"
echo

# 3. Louvre Conformance Test
echo ">>> [3/4] Compiling and running Louvre provider test..."
$CXX -std=c++17 -Wall -Wextra \
    "$ROOT/providers/system/compositor/louvre/adapter/louvre_adapter.cpp" \
    "$ROOT/providers/system/compositor/louvre/tests/test_louvre_contract.cpp" \
    -o "$BUILD_DIR/test_louvre"
"$BUILD_DIR/test_louvre"
echo

# 4. DMA-BUF Conformance Test
echo ">>> [4/4] Compiling and running DMA-BUF provider test..."
$CC -std=c11 -Wall -Wextra \
    "$ROOT/providers/system/gpu/dmabuf/adapter/dmabuf_adapter.c" \
    "$ROOT/providers/system/gpu/dmabuf/tests/test_dmabuf_contract.c" \
    -o "$BUILD_DIR/test_dmabuf"
"$BUILD_DIR/test_dmabuf"
echo

echo "============================================================"
echo " ALL 4 PROVIDER CONFORMANCE SUITES PASSED SUCCESSFULLY!"
echo "============================================================"
