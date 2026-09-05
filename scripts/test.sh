#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$ROOT/build"

cd "$ROOT"

echo "=============================================="
echo " SCR Test Suite"
echo "=============================================="
echo

echo "[1/4] Rust tests"

cargo test --workspace

echo
echo "[2/4] C++ tests"

if [ -f "$BUILD_DIR/build.ninja" ]; then
    cmake --build "$BUILD_DIR" --target test --parallel
fi

echo
echo "[3/4] MLIR / lit tests"

if [ -d "$ROOT/test" ]; then
    lit -v "$ROOT/test"
fi

echo
echo "[4/4] Environment sanity"

./scripts/check-environment.sh

echo
echo "=============================================="
echo " ALL SCR TESTS PASSED"
echo "=============================================="
