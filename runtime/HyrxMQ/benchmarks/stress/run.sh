#!/usr/bin/env bash
# AMQP stress/soak benchmark driver.
#
# Usage:
#   ./benchmarks/stress/run.sh                  # both brokers, all defaults
#   ./benchmarks/stress/run.sh --broker hyrx    # HyrxMQ only
#   ./benchmarks/stress/run.sh --soak 3600      # 1-hour soak test
#   ./benchmarks/stress/run.sh --quick          # 10s workloads, small sizes
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
VENV="/tmp/stress-venv"

# ensure venv
if [ ! -d "$VENV" ]; then
    echo "creating venv at $VENV ..."
    python3 -m venv "$VENV"
    "$VENV/bin/pip" install --quiet pika
fi

PYTHON="$VENV/bin/python"

# quick mode: short duration, small sizes
EXTRA_ARGS=()
if [ "${1:-}" = "--quick" ]; then
    EXTRA_ARGS+=(--duration 10 --sizes 64,1024,4096 --skip-scenarios)
    shift
fi

# pass through all args
EXTRA_ARGS+=("$@")

echo "=== AMQP Stress Benchmark ==="
echo "root: $ROOT_DIR"
echo "python: $PYTHON"
echo "args: ${EXTRA_ARGS[*]:-}"
echo

cd "$ROOT_DIR"
"$PYTHON" "$SCRIPT_DIR/harness.py" "${EXTRA_ARGS[@]}"

echo
echo "=== Analysis ==="
"$PYTHON" "$SCRIPT_DIR/analyze.py" --compare "$SCRIPT_DIR/results/"*.json 2>/dev/null || true
