#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$ROOT"

echo "=============================================="
echo " Semantic Computational Runtime"
echo " Development Environment Bootstrap"
echo "=============================================="
echo

if ! command -v nix >/dev/null 2>&1; then
    echo "ERROR: Nix is not installed."
    echo
    echo "Install Nix using your preferred supported Nix installation method."
    exit 1
fi

echo "[1/5] Checking Nix..."

nix --version

echo
echo "[2/5] Checking Flakes..."

if ! nix flake metadata . >/dev/null 2>&1; then
    echo "ERROR: Nix flakes are unavailable."
    echo
    echo "Enable the nix-command and flakes experimental features."
    exit 1
fi

echo "PASS: flakes available"

echo
echo "[3/5] Updating flake inputs..."

nix flake lock

echo
echo "[4/5] Validating development shell..."

nix develop --command bash -c '
    echo "Nix development shell is operational."
'

echo
echo "[5/5] Running environment validation..."

nix develop --command \
    "$PWD/scripts/check-environment.sh"

echo
echo "=============================================="
echo " SCR development environment READY"
echo "=============================================="
echo
echo "Enter the environment with:"
echo
echo "    nix develop"
echo
