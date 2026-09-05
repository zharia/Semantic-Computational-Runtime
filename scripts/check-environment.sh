#!/usr/bin/env bash

set -u

PASS=0
FAIL=0

check() {
    local name="$1"
    local command="$2"

    printf "%-24s" "$name"

    if command -v "$command" >/dev/null 2>&1; then
        echo "✓"
        PASS=$((PASS + 1))
    else
        echo "✗"
        FAIL=$((FAIL + 1))
    fi
}

echo
echo "=============================================="
echo " SCR Development Environment"
echo "=============================================="
echo

check "Nix"              nix
check "Git"              git
check "Clang"            clang
check "Clang++"          clang++
check "LLD"              ld.lld
check "CMake"             cmake
check "Ninja"             ninja
check "LLVM"              llvm-config
check "MLIR opt"          mlir-opt
check "MLIR translate"    mlir-translate
check "FileCheck"         FileCheck
check "lit"               lit
check "Rust"              rustc
check "Cargo"             cargo
check "Python"            python3
check "ccache"            ccache
check "ShellCheck"        shellcheck
check "ripgrep"           rg

echo
echo "----------------------------------------------"
echo " Versions"
echo "----------------------------------------------"

nix --version
clang --version | head -1
llvm-config --version 2>/dev/null || true
mlir-opt --version 2>/dev/null | head -1 || true
rustc --version
cargo --version
python3 --version
cmake --version | head -1
ninja --version

echo
echo "----------------------------------------------"
echo " Results"
echo "----------------------------------------------"

echo "PASS: $PASS"
echo "FAIL: $FAIL"

if [ "$FAIL" -eq 0 ]; then
    echo
    echo "Environment READY."
    exit 0
else
    echo
    echo "Environment NOT READY."
    exit 1
fi
