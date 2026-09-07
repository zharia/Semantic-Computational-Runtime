#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

python3 tools/check_phase0.py

if command -v mojo >/dev/null 2>&1; then
    echo "== Mojo format check =="
    mojo format src tests examples
else
    echo "Mojo format: NOT PROVEN (mojo unavailable)"
fi

echo "Phase 0 checks complete."
