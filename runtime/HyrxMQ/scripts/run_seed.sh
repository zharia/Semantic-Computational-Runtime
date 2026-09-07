#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if ! command -v mojo >/dev/null 2>&1; then
    echo "ERROR: mojo is not available in PATH." >&2
    exit 1
fi

exec mojo src/hyrx/main.mojo
