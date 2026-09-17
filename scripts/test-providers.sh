#!/usr/bin/env bash
#
# SCR Provider Conformance Test Suite Runner
#
# Builds and executes standalone conformance tests for all 11 SCR providers:
# 1. OpenVDB (spatial/volumetric)
# 2. OGRE 3D (render/graphics)
# 3. Louvre (system/compositor)
# 4. DMA-BUF (system/gpu)
# 5. BLAS (math/linear_algebra)
# 6. CGAL (geometry/computational_geometry)
# 7. H3 (topology/spatial_indexing)
# 8. Chrono (physics/dynamics)
# 9. CUDA (system/accelerator)
# 10. Vulkan (render/graphics)
# 11. RabbitMQ (system/messaging)
# 12. MaterialX (render/material)
# 13. Fluid Dynamics (physics/fluid)
#

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="/tmp/scr_provider_tests"
mkdir -p "$BUILD_DIR"

echo "============================================================"
echo " Running SCR Provider Conformance Test Suites (13 Providers)"
echo "============================================================"
echo

# Auto-detect C and C++ compilers
if [[ -z "${CC:-}" ]]; then
    if command -v clang >/dev/null 2>&1; then
        CC="clang"
    elif command -v gcc >/dev/null 2>&1; then
        CC="gcc"
    else
        echo "Error: Neither clang nor gcc found." >&2
        exit 1
    fi
fi

if [[ -z "${CXX:-}" ]]; then
    if command -v clang++ >/dev/null 2>&1; then
        CXX="clang++"
    elif command -v g++ >/dev/null 2>&1; then
        CXX="g++"
    else
        echo "Error: Neither clang++ nor g++ found." >&2
        exit 1
    fi
fi

echo "Using C compiler:   $CC"
echo "Using C++ compiler: $CXX"
echo

# 1. OpenVDB Conformance Test
echo ">>> [1/12] Compiling and running OpenVDB provider test..."
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
echo ">>> [2/12] Compiling and running OGRE provider test..."
$CXX -std=c++17 -Wall -Wextra \
    "$ROOT/providers/render/graphics/ogre/adapter/ogre_adapter.cpp" \
    "$ROOT/providers/render/graphics/ogre/tests/test_ogre_contract.cpp" \
    -o "$BUILD_DIR/test_ogre"
"$BUILD_DIR/test_ogre"
echo

# 3. Louvre Conformance Test
echo ">>> [3/12] Compiling and running Louvre provider test..."
$CXX -std=c++17 -Wall -Wextra \
    "$ROOT/providers/system/compositor/louvre/adapter/louvre_adapter.cpp" \
    "$ROOT/providers/system/compositor/louvre/tests/test_louvre_contract.cpp" \
    -o "$BUILD_DIR/test_louvre"
"$BUILD_DIR/test_louvre"
echo

# 4. DMA-BUF Conformance Test
echo ">>> [4/12] Compiling and running DMA-BUF provider test..."
$CC -std=c11 -Wall -Wextra \
    "$ROOT/providers/system/gpu/dmabuf/adapter/dmabuf_adapter.c" \
    "$ROOT/providers/system/gpu/dmabuf/tests/test_dmabuf_contract.c" \
    -o "$BUILD_DIR/test_dmabuf"
"$BUILD_DIR/test_dmabuf"
echo

# 5. BLAS Conformance Test
echo ">>> [5/12] Compiling and running BLAS provider test..."
BLAS_LIBS="-lm"
if echo '#include <cblas.h>' | $CC -x c -E - >/dev/null 2>&1; then
    BLAS_LIBS="-lblas -lm"
fi
$CC -std=c11 -Wall -Wextra \
    "$ROOT/providers/math/linear_algebra/blas/adapter/blas_adapter.c" \
    "$ROOT/providers/math/linear_algebra/blas/tests/test_blas_contract.c" \
    $BLAS_LIBS \
    -o "$BUILD_DIR/test_blas"
"$BUILD_DIR/test_blas"
echo

# 6. CGAL Conformance Test
echo ">>> [6/12] Compiling and running CGAL provider test..."
CGAL_LIBS=""
if echo '#include <CGAL/Exact_predicates_inexact_constructions_kernel.h>' | $CXX -x c++ -E - >/dev/null 2>&1; then
    CGAL_LIBS="-lCGAL -lgmp"
fi
$CXX -std=c++17 -Wall -Wextra \
    "$ROOT/providers/geometry/computational_geometry/cgal/adapter/cgal_adapter.cpp" \
    "$ROOT/providers/geometry/computational_geometry/cgal/tests/test_cgal_contract.cpp" \
    $CGAL_LIBS \
    -o "$BUILD_DIR/test_cgal"
"$BUILD_DIR/test_cgal"
echo

# 7. H3 Conformance Test
echo ">>> [7/12] Compiling and running H3 provider test..."
H3_LIBS="-lm"
if echo '#include <h3/h3api.h>' | $CC -x c -E - >/dev/null 2>&1; then
    H3_LIBS="-lh3 -lm"
fi
$CC -std=c11 -Wall -Wextra \
    "$ROOT/providers/topology/spatial_indexing/h3/adapter/h3_adapter.c" \
    "$ROOT/providers/topology/spatial_indexing/h3/tests/test_h3_contract.c" \
    $H3_LIBS \
    -o "$BUILD_DIR/test_h3"
"$BUILD_DIR/test_h3"
echo

# 8. Chrono Conformance Test
echo ">>> [8/12] Compiling and running Chrono provider test..."
CHRONO_LIBS=""
if echo '#include <chrono/physics/ChSystemNSC.h>' | $CXX -x c++ -E - >/dev/null 2>&1; then
    CHRONO_LIBS="-lChronoEngine"
fi
$CXX -std=c++17 -Wall -Wextra \
    "$ROOT/providers/physics/dynamics/chrono/adapter/chrono_adapter.cpp" \
    "$ROOT/providers/physics/dynamics/chrono/tests/test_chrono_contract.cpp" \
    $CHRONO_LIBS \
    -o "$BUILD_DIR/test_chrono"
"$BUILD_DIR/test_chrono"
echo

# 9. CUDA Conformance Test
echo ">>> [9/12] Compiling and running CUDA provider test..."
CUDA_LIBS=""
if echo '#include <cuda_runtime.h>' | $CC -x c -E - >/dev/null 2>&1; then
    CUDA_LIBS="-lcudart"
fi
$CC -std=c11 -Wall -Wextra \
    "$ROOT/providers/system/accelerator/cuda/adapter/cuda_adapter.c" \
    "$ROOT/providers/system/accelerator/cuda/tests/test_cuda_contract.c" \
    $CUDA_LIBS \
    -o "$BUILD_DIR/test_cuda"
"$BUILD_DIR/test_cuda"
echo

# 10. Vulkan Conformance Test
echo ">>> [10/12] Compiling and running Vulkan provider test..."
VULKAN_LIBS=""
if echo '#include <vulkan/vulkan.h>' | $CC -x c -E - >/dev/null 2>&1; then
    VULKAN_LIBS="-lvulkan"
fi
$CC -std=c11 -Wall -Wextra \
    "$ROOT/providers/render/graphics/vulkan/adapter/vulkan_adapter.c" \
    "$ROOT/providers/render/graphics/vulkan/tests/test_vulkan_contract.c" \
    $VULKAN_LIBS \
    -o "$BUILD_DIR/test_vulkan"
"$BUILD_DIR/test_vulkan"
echo

# 11. RabbitMQ Conformance Test
echo ">>> [11/12] Compiling and running RabbitMQ provider test..."
RABBIT_LIBS=""
if echo '#include <amqp.h>' | $CC -x c -E - >/dev/null 2>&1; then
    RABBIT_LIBS="-lrabbitmq"
fi
$CC -std=c11 -Wall -Wextra \
    "$ROOT/providers/system/messaging/rabbitmq/adapter/rabbitmq_adapter.c" \
    "$ROOT/providers/system/messaging/rabbitmq/tests/test_rabbitmq_contract.c" \
    $RABBIT_LIBS \
    -o "$BUILD_DIR/test_rabbitmq"
"$BUILD_DIR/test_rabbitmq"
echo

# 12. MaterialX Conformance Test
echo ">>> [12/13] Compiling and running MaterialX provider test..."
MATX_LIBS=""
if echo '#include <MaterialXCore/Document.h>' | $CXX -x c++ -E - >/dev/null 2>&1; then
    MATX_LIBS="-lMaterialXCore -lMaterialXFormat"
fi
$CXX -std=c++17 -Wall -Wextra \
    "$ROOT/providers/render/material/materialx/adapter/materialx_adapter.cpp" \
    "$ROOT/providers/render/material/materialx/tests/test_materialx_contract.cpp" \
    $MATX_LIBS \
    -o "$BUILD_DIR/test_materialx"
"$BUILD_DIR/test_materialx"
echo

# 13. Fluid Dynamics & Rheology Conformance Test
echo ">>> [13/13] Compiling and running Fluid Dynamics provider test..."
$CXX -std=c++17 -Wall -Wextra \
    "$ROOT/providers/physics/fluid/adapter/fluid_adapter.cpp" \
    "$ROOT/providers/physics/fluid/tests/test_fluid_contract.cpp" \
    -o "$BUILD_DIR/test_fluid"
"$BUILD_DIR/test_fluid"
echo

echo "============================================================"
echo " ALL 13 PROVIDER CONFORMANCE SUITES PASSED SUCCESSFULLY!"
echo "============================================================"


