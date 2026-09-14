#!/usr/bin/env bash
# disk_failure_harness.sh — filesystem-failure behaviour for HyrxMQ (M3.3).
#
#  1. create a directory and make it read-only (chmod 500);
#  2. start the broker with HYRXMQ_STORAGE_MODE=file pointing the WAL at it;
#  3. attempt to publish (the WAL open/append must fail, EACCES);
#  4. verify the broker did NOT crash (process alive AND still accepting
#     fresh AMQP connections — the serving loop survives the failed write);
#  5. restore permissions and clean up.
#
# Usage: bash scripts/disk_failure_harness.sh
# Exit 0 iff the broker stays alive and serving through the disk failure.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

BROKER="$ROOT/build/hyrxmq-listen"

BROKER_PID=""
TMPROOT=""

cleanup() {
    if [ -n "$BROKER_PID" ]; then kill -9 "$BROKER_PID" 2>/dev/null; fi
    if [ -n "$TMPROOT" ] && [ -d "$TMPROOT" ]; then
        chmod -R u+rwX "$TMPROOT" 2>/dev/null || true
        rm -rf "$TMPROOT"
    fi
    wait 2>/dev/null
}
trap cleanup EXIT INT TERM

build_broker() {
    if [ -x "$BROKER" ]; then
        echo "disk-failure: broker present at $BROKER"
        return 0
    fi
    echo "disk-failure: broker missing — building"
    if command -v pixi >/dev/null 2>&1; then
        pixi run hyrxmq-listen
    else
        mkdir -p "$ROOT/build"
        mojo build -I src -I vendor/flare src/hyrxmq/main_listen.mojo -o "$BROKER"
    fi
    [ -x "$BROKER" ] || { echo "disk-failure: broker build FAILED" >&2; return 1; }
    return 0
}

VENV="${TMPDIR:-/tmp}/hyrxmq-pika-venv"
resolve_python() {
    if [ -n "${PYTHON:-}" ]; then
        PY="$PYTHON"
        return 0
    fi
    if python3 -c 'import pika' >/dev/null 2>&1; then
        PY=python3
        return 0
    fi
    if [ -x "$VENV/bin/python" ] && "$VENV/bin/python" -c 'import pika' >/dev/null 2>&1; then
        PY="$VENV/bin/python"
        return 0
    fi
    echo "disk-failure: pika not found — creating venv at $VENV" >&2
    python3 -m venv "$VENV" >/dev/null 2>&1 || return 1
    "$VENV/bin/pip" install -q pika >/dev/null 2>&1 || return 1
    PY="$VENV/bin/python"
    return 0
}

free_port() {
    "$PY" - <<'PY'
import socket
s = socket.socket()
s.bind(("127.0.0.1", 0))
print(s.getsockname()[1])
s.close()
PY
}

wait_port() {
    local host="$1" port="$2" tries="${3:-100}"
    local i=0
    while [ "$i" -lt "$tries" ]; do
        if python3 - "$host" "$port" <<'PY' >/dev/null 2>&1
import socket, sys
s = socket.socket()
s.settimeout(0.2)
try:
    s.connect((sys.argv[1], int(sys.argv[2])))
except OSError:
    sys.exit(1)
s.close()
PY
        then
            return 0
        fi
        sleep 0.05
        i=$((i + 1))
    done
    return 1
}

# ---- main --------------------------------------------------------------------
if ! build_broker; then
    echo "DISK_FAILURE_HARNESS=FAIL (build)"
    exit 1
fi
if ! resolve_python; then
    echo "DISK_FAILURE_HARNESS=FAIL (no pika)"
    exit 1
fi

TMPROOT="$(mktemp -d "${TMPDIR:-/tmp}/hyrxmq-diskfail.XXXXXX")"
RODIR="$TMPROOT/readonly"
mkdir -p "$RODIR"
chmod 500 "$RODIR"
WAL="$RODIR/wal.log"
LOG="$TMPROOT/broker.log"
PORT="$(free_port)"

HYRXMQ_HOST=127.0.0.1 HYRXMQ_PORT="$PORT" \
    HYRXMQ_STORAGE_MODE=file HYRXMQ_STORAGE_PATH="$WAL" \
    "$BROKER" >"$LOG" 2>&1 &
BROKER_PID=$!

if ! wait_port 127.0.0.1 "$PORT"; then
    echo "disk-failure: broker did not become ready" >&2
    cat "$LOG" >&2
    echo "DISK_FAILURE_HARNESS=FAIL (start)"
    exit 1
fi
echo "disk-failure: broker up on $PORT with read-only WAL dir $RODIR"

# attempt to publish durable messages (the WAL cannot be created/appended)
"$PY" - "$PORT" <<'PY'
import sys
import pika

port = int(sys.argv[1])
raised = False
try:
    conn = pika.BlockingConnection(pika.ConnectionParameters(
        host="127.0.0.1", port=port,
        credentials=pika.PlainCredentials("admin", "password"),
        connection_attempts=1, socket_timeout=5,
    ))
    ch = conn.channel()
    ch.queue_declare(queue="disk-q", durable=True)
    ch.basic_publish(
        exchange="", routing_key="disk-q", body=b"disk-failure",
        properties=pika.BasicProperties(delivery_mode=2),
    )
    conn.close()
except Exception as exc:
    raised = True
    print("disk-failure: publish surfaced:", type(exc).__name__)
print("PUBLISH_RAISED=%s" % raised)
sys.exit(1 if raised else 0)
PY
pub_rc=$?

sleep 0.2

alive="no"
if kill -0 "$BROKER_PID" 2>/dev/null; then alive="yes"; fi
echo "disk-failure: broker process alive=$alive"

# health probe: a BRAND-NEW connection must still negotiate
health="no"
"$PY" - "$PORT" <<'PY'
import sys
import pika

port = int(sys.argv[1])
try:
    conn = pika.BlockingConnection(pika.ConnectionParameters(
        host="127.0.0.1", port=port,
        credentials=pika.PlainCredentials("admin", "password"),
        connection_attempts=1, socket_timeout=5,
    ))
    ch = conn.channel()
    assert ch.is_open and conn.is_open
    conn.close()
    print("HEALTH=ok")
except Exception as exc:
    print("HEALTH=fail:%s" % type(exc).__name__)
    sys.exit(1)
PY
health_rc=$?
if [ "$health_rc" -eq 0 ]; then health="yes"; fi
echo "disk-failure: broker health (fresh connection)=$health"

# restore permissions before cleanup
chmod 700 "$RODIR"
wal_exists="no"
[ -e "$WAL" ] && wal_exists="yes"
echo "disk-failure: WAL created despite read-only dir=$wal_exists"

# stop the broker cleanly (it must still respond to SIGKILL)
kill -9 "$BROKER_PID" 2>/dev/null
wait "$BROKER_PID" 2>/dev/null
BROKER_PID=""

if [ "$alive" = "yes" ] && [ "$health" = "yes" ]; then
    echo "DISK_FAILURE_HARNESS=PASS (publish_rc=$pub_rc raised=$([ "$pub_rc" -ne 0 ] && echo yes || echo no) alive=$alive health=$health)"
    exit 0
else
    echo "DISK_FAILURE_HARNESS=FAIL (alive=$alive health=$health publish_rc=$pub_rc)"
    exit 1
fi