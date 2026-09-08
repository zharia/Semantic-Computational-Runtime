#!/usr/bin/env bash
# Reproducible real-pika negotiation gate against the HyrxMQ listen binary.
#
# Binds a port OTHER than RabbitMQ's 5672 (default 5699), starts the binary,
# drives a real pika 1.4.4 client through the AMQP handshake + basic flow, and
# ALWAYS tears the broker subprocess down (verified: the port is freed). The
# reference RabbitMQ container is never touched.
#
# Usage: [HYRXMQ_PORT=5699] [PIKA_PY=/tmp/amqp-venv/bin/python] \
#        bash scripts/interop/run_pika_negotiation.sh
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PORT="${HYRXMQ_PORT:-5699}"
BIN="$ROOT/build/hyrxmq-listen"
PY="${PIKA_PY:-/tmp/amqp-venv/bin/python}"

[ -x "$BIN" ] || { echo "missing $BIN — build it first (see header)"; exit 2; }

LOG="$(mktemp)"
BROKER_PID=""

cleanup() {
    if [ -n "$BROKER_PID" ] && kill -0 "$BROKER_PID" 2>/dev/null; then
        kill -TERM "$BROKER_PID" 2>/dev/null || true
        for _ in 1 2 3 4 5; do
            kill -0 "$BROKER_PID" 2>/dev/null || break
            sleep 1
        done
        kill -KILL "$BROKER_PID" 2>/dev/null || true
        wait "$BROKER_PID" 2>/dev/null || true
    fi
    rm -f "$LOG"
}
trap cleanup EXIT INT TERM

# Start the binary DIRECTLY as the background job (NOT `cd && bin &`, which
# would background a subshell and orphan the broker holding the port).
HYRXMQ_HOST=127.0.0.1 HYRXMQ_PORT="$PORT" "$BIN" >"$LOG" 2>&1 &
BROKER_PID=$!
sleep 1

if ! ss -ltnH "sport = :$PORT" 2>/dev/null | grep -q .; then
    echo "broker did not bind :$PORT"; cat "$LOG"; exit 1
fi
echo "broker PID=$BROKER_PID listening on 127.0.0.1:$PORT (RabbitMQ stays on 5672)"

HYRX_PORT="$PORT" timeout 90 "$PY" "$ROOT/scripts/interop/pika_negotiation.py"
rc=$?

# Tear down and PROVE the port is released before printing the broker log.
cleanup
trap - EXIT INT TERM
if ss -ltnH "sport = :$PORT" 2>/dev/null | grep -q .; then
    echo "FATAL: port $PORT still bound after teardown"
    exit 3
fi
echo "teardown ok: broker $BROKER_PID gone, port $PORT released, RabbitMQ :5672 untouched"
exit $rc
