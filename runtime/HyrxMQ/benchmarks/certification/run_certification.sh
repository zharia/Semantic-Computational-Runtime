#!/usr/bin/env bash
# HyrxMQ (M9) performance-certification driver.
#
# Builds the broker if needed, starts one plaintext broker, runs certify.py
# (thresholded performance certification) and soak.py (leak/latency-drift
# soak), then stops the broker. Cleanup runs on every exit path (trap).
#
# Usage:
#   bash benchmarks/certification/run_certification.sh --quick
#   bash benchmarks/certification/run_certification.sh
#   SOAK_DURATION=3600 bash benchmarks/certification/run_certification.sh
#
# Env: CERT_PY (python with pika), HYRXMQ_BIN, HYRXMQ_HOST, HYRXMQ_PORT.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BIN="${HYRXMQ_BIN:-$ROOT/build/hyrxmq-listen}"
HOST="${HYRXMQ_HOST:-127.0.0.1}"
VENV="${CERT_VENV:-/tmp/hyrxmq-cert-venv}"

QUICK=0
PASSTHRU=()
for arg in "$@"; do
    if [ "$arg" = "--quick" ]; then
        QUICK=1
    else
        PASSTHRU+=("$arg")
    fi
done

say() { printf '\n=== %s ===\n' "$*"; }
die() { printf 'FATAL: %s\n' "$*" >&2; exit 2; }

# --- 1. build/broker preflight -------------------------------------------
say "1. broker binary"
if [ ! -x "$BIN" ]; then
    echo "binary not built ($BIN); building with pixi …"
    if command -v pixi >/dev/null 2>&1; then
        ( cd "$ROOT" && pixi run mojo build -I src -I vendor/flare \
              src/hyrxmq/main_listen.mojo -o build/hyrxmq-listen ) \
            || echo "WARN: mojo build failed"
    fi
fi
if [ ! -x "$BIN" ]; then
    echo "FATAL: broker binary not available at $BIN" >&2
    echo "  build it with: pixi run mojo build -I src -I vendor/flare src/hyrxmq/main_listen.mojo -o build/hyrxmq-listen" >&2
    exit 3
fi
echo "using $BIN"

# --- 2. python + pika -----------------------------------------------------
say "2. python client"
PY=""
if [ -n "${CERT_PY:-}" ] && [ -x "${CERT_PY}" ]; then
    PY="$CERT_PY"
elif python3 -c 'import pika' >/dev/null 2>&1; then
    PY="$(command -v python3)"
elif [ -x "$VENV/bin/python" ] && "$VENV/bin/python" -c 'import pika' >/dev/null 2>&1; then
    PY="$VENV/bin/python"
else
    if command -v python3 >/dev/null 2>&1; then
        echo "pika not found; creating venv at $VENV …"
        python3 -m venv "$VENV" >/dev/null 2>&1 || true
        if [ -x "$VENV/bin/pip" ]; then
            "$VENV/bin/pip" install --quiet 'pika==1.4.4' >/dev/null 2>&1 || true
        fi
        if [ -x "$VENV/bin/python" ] && "$VENV/bin/python" -c 'import pika' >/dev/null 2>&1; then
            PY="$VENV/bin/python"
        fi
    fi
fi
if [ -z "$PY" ]; then
    PY="$(command -v python3 || true)"
    echo "WARN: pika unavailable; certify/soak will use the raw-socket fallback"
fi
[ -n "$PY" ] || die "no python3 found"
echo "using $PY"
"$PY" -c 'import pika; print("pika", pika.__version__)' 2>/dev/null || true

# --- 3. start broker ------------------------------------------------------
say "3. start broker"
PORT="${HYRXMQ_PORT:-}"
if [ -z "$PORT" ]; then
    PORT="$("$PY" -c 'import socket;s=socket.socket();s.bind(("127.0.0.1",0));print(s.getsockname()[1]);s.close()')"
fi
LOG="$SCRIPT_DIR/results/broker-$PORT.log"
mkdir -p "$SCRIPT_DIR/results"
HYRXMQ_HOST="$HOST" HYRXMQ_PORT="$PORT" "$BIN" >"$LOG" 2>&1 &
BROKER_PID=$!

cleanup() {
    if kill -0 "$BROKER_PID" 2>/dev/null; then
        kill "$BROKER_PID" 2>/dev/null || true
        wait "$BROKER_PID" 2>/dev/null || true
    fi
}
trap cleanup EXIT INT TERM

READY=0
for _ in $(seq 1 100); do
    if ! kill -0 "$BROKER_PID" 2>/dev/null; then
        echo "broker exited early; log:"; sed -n '1,40p' "$LOG"; exit 3
    fi
    if "$PY" -c "import socket,sys;s=socket.socket();s.settimeout(0.3);sys.exit(0 if (s.connect_ex(('$HOST',$PORT))==0) else 1)" 2>/dev/null; then
        READY=1
        break
    fi
    sleep 0.1
done
if [ "$READY" -ne 1 ]; then
    echo "FATAL: broker did not bind $HOST:$PORT"; sed -n '1,40p' "$LOG"; exit 3
fi
echo "broker pid=$BROKER_PID port=$PORT"

# --- 4. certify + soak ----------------------------------------------------
CERT_ARGS=(--host "$HOST" --port "$PORT" --broker-pid "$BROKER_PID")
SOAK_ARGS=(--host "$HOST" --port "$PORT" --broker-pid "$BROKER_PID")
if [ "$QUICK" -eq 1 ]; then
    CERT_ARGS+=(--quick)
    SOAK_ARGS+=(--quick)
fi
if [ "${#PASSTHRU[@]}" -gt 0 ]; then
    CERT_ARGS+=("${PASSTHRU[@]}")
    SOAK_ARGS+=("${PASSTHRU[@]}")
fi
if [ -n "${SOAK_DURATION:-}" ]; then
    SOAK_ARGS+=(--duration "$SOAK_DURATION")
fi

say "4a. certify.py"
"$PY" "$SCRIPT_DIR/certify.py" "${CERT_ARGS[@]}"
CERT_RC=$?
echo "certify exit=$CERT_RC"

say "4b. soak.py"
"$PY" "$SCRIPT_DIR/soak.py" "${SOAK_ARGS[@]}"
SOAK_RC=$?
echo "soak exit=$SOAK_RC"

say "5. summary"
echo "certify exit=$CERT_RC  soak exit=$SOAK_RC"
echo "broker log: $LOG"
if [ "$CERT_RC" -ne 0 ] || [ "$SOAK_RC" -ne 0 ]; then
    exit 1
fi
exit 0
