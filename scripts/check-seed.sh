#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 "$ROOT/scripts/check-seed.py"
"$ROOT/scripts/check-formal-seed.sh"
