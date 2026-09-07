#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "== Hyrx Phase 0 bootstrap =="
echo "Repository: $ROOT"

if command -v mojo >/dev/null 2>&1; then
    echo "Mojo: $(command -v mojo)"
    mojo --version || true
else
    echo "Mojo: NOT PROVEN (not installed or not in PATH)"
    echo "Install/activate the project-approved Mojo environment before build validation."
fi

python3 tools/check_phase0.py
echo "Bootstrap structure checks complete."
