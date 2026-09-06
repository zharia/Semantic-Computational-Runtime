#!/usr/bin/env bash
# check-ir-terminology-report.sh
# Convenience wrapper — runs check-ir-terminology.sh and outputs full report.
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
"$SCRIPT_DIR/check-ir-terminology.sh"
