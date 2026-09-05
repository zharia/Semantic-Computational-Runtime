#!/usr/bin/env bash

export SCR_ROOT="/home/zharia/Projects/experiments/artificial_life/universal_specifications/semantic_computational_runtime"

export SCR_LLVM_VERSION="22.1.8"
export SCR_LLVM_ROOT="/home/zharia/.local/opt/scr/llvm-22.1.8"

export LLVM_ROOT="${SCR_LLVM_ROOT}"
export MLIR_ROOT="${SCR_LLVM_ROOT}"

export MLIR_DIR="${SCR_LLVM_ROOT}/lib/cmake/mlir"
export LLVM_DIR="${SCR_LLVM_ROOT}/lib/cmake/llvm"

export PATH="${SCR_LLVM_ROOT}/bin:${PATH}"

export CC="${CC:-clang}"
export CXX="${CXX:-clang++}"
export LD="${LD:-ld.lld}"

export CMAKE_GENERATOR="${CMAKE_GENERATOR:-Ninja}"
