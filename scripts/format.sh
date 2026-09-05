#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$ROOT"

echo "Formatting Rust..."

cargo fmt --all

echo "Checking Rust formatting..."

cargo fmt --all -- --check

echo "Running Clippy..."

cargo clippy \
    --workspace \
    --all-targets \
    --all-features \
    -- \
    -D warnings

echo "Formatting checks complete."
