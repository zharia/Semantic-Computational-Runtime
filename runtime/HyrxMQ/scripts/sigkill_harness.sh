#!/usr/bin/env bash
# sigkill_harness.sh — real SIGKILL durability test for HyrxMQ (M3.2).
#
# For each kill timing (after 10 / 50 / 90 published messages):
#   1. start the broker with HYRXMQ_STORAGE_MODE=file + a temp WAL path;
#   2. publish up to 100 durable messages with a real python3 pika client;
#   3. `kill -9` the broker mid-publish (no graceful shutdown, no sync);
#   4. restart the broker on the SAME WAL path (recovery replay);
#   5. consume and count recovered messages;
#   6. assert recovered_count > 0 (durability proven).
#
# Usage: bash scripts/sigkill_harness.sh
# Exit 0 iff every iteration recovers at least one message.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

BROKER="$ROOT/build/hyrxmq-listen"
MSG_COUNT=100
KILL_AT=(10 50 90)

BROKER_PID=""
PUB_PID=""
TMPROOT=""

cleanup() {
    if [ -n "$BROKER_PID" ]; then kill -9 "$BROKER_PID" 2>/dev/null; fi
    if [ -n "$PUB_PID" ]; then kill -9 "$PUB_PID" 2>/dev/null; fi
    if [ -n "$TMPROOT" ] && [ -d "$TMPROOT" ]; then rm -rf "$TMPROOT"; fi
    wait 2>/dev/null
}
trap cleanup EXIT INT TERM

# ---- build the broker if missing --------------------------------------------
build_broker() {
    if [ -x "$BROKER" ]; then
        echo "sigkill: broker present at $BROKER"
        return 0
    fi
    echo "sigkill: broker missing — building"
    if command -v pixi >/dev/null 2>&1; then
        pixi run hyrxmq-listen
    else
        mkdir -p "$ROOT/build"
        mojo build -I src -I vendor/flare src/hyrxmq/main_listen.mojo -o "$BROKER"
    fi
    [ -x "$BROKER" ] || { echo "sigkill: broker build FAILED" >&2; return 1; }
    return 0
}

# ---- resolve a python3 that can import pika ---------------------------------
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
    echo "sigkill: pika not found — creating venv at $VENV" >&2
    python3 -m venv "$VENV" >/dev/null 2>&1 || return 1
    "$VENV/bin/pip" install -q pika >/dev/null 2>&1 || return 1
    PY="$VENV/bin/python"
    return 0
}

# ---- pick a free TCP port ----------------------------------------------------
free_port() {
    "$PY" - <<'PY'
import socket
s = socket.socket()
s.bind(("127.0.0.1", 0))
print(s.getsockname()[1])
s.close()
PY
}

# ---- wait until a TCP port accepts -------------------------------------------
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

# ---- start the broker (file storage) ----------------------------------------
start_broker() {
    local port="$1" path="$2" log="$3"
    HYRXMQ_HOST=127.0.0.1 HYRXMQ_PORT="$port" \
        HYRXMQ_STORAGE_MODE=file HYRXMQ_STORAGE_PATH="$path" \
        "$BROKER" >"$log" 2>&1 &
    BROKER_PID=$!
    if wait_port 127.0.0.1 "$port"; then
        return 0
    fi
    echo "sigkill: broker did not become ready" >&2
    cat "$log" >&2
    return 1
}

# ---- stop the broker abruptly -----------------------------------------------
sigkill_broker() {
    if [ -n "$BROKER_PID" ]; then
        kill -9 "$BROKER_PID" 2>/dev/null
        wait "$BROKER_PID" 2>/dev/null
        BROKER_PID=""
    fi
}

# ---- publisher: N durable publishes, progress printed per message -----------
write_publisher() {
    cat >"$1" <<'PY'
import sys
import time
import pika

port = int(sys.argv[1])
progress = sys.argv[2]
n = int(sys.argv[3])

conn = pika.BlockingConnection(pika.ConnectionParameters(
    host="127.0.0.1", port=port,
    credentials=pika.PlainCredentials("admin", "password"),
    connection_attempts=1, socket_timeout=5,
))
ch = conn.channel()
ch.queue_declare(queue="sigkill-q", durable=True)

f = open(progress, "w")
for i in range(n):
    ch.basic_publish(
        exchange="", routing_key="sigkill-q", body=("msg-%d" % i).encode(),
        properties=pika.BasicProperties(delivery_mode=2),
    )
    f.write("%d\n" % i)
    f.flush()
    time.sleep(0.003)  # keep the single-threaded broker roughly in step
f.close()
conn.close()
PY
}

# ---- consumer: count recovered messages, print RECOVERED=<n> ----------------
write_consumer() {
    cat >"$1" <<'PY'
import sys
import pika

port = int(sys.argv[1])
out = sys.argv[2]

conn = pika.BlockingConnection(pika.ConnectionParameters(
    host="127.0.0.1", port=port,
    credentials=pika.PlainCredentials("admin", "password"),
    connection_attempts=1, socket_timeout=6,
))
ch = conn.channel()
count = 0
for method, props, body in ch.consume("sigkill-q", inactivity_timeout=2):
    if method is None:
        break
    ch.basic_ack(method.delivery_tag)
    count += 1
conn.close()
with open(out, "w") as f:
    f.write(str(count))
PY
}

# ---- one iteration: publish, kill mid-stream, restart, recover ---------------
run_iteration() {
    local target="$1"
    local port pub consumer prog count_file recovered
    port="$(free_port)"
    local dir="$TMPROOT/iter-$target"
    mkdir -p "$dir"
    local path="$dir/wal.log"
    pub="$dir/publisher.py"
    consumer="$dir/consumer.py"
    prog="$dir/progress.txt"
    count_file="$dir/count.txt"
    write_publisher "$pub"
    write_consumer "$consumer"
    : >"$prog"

    if ! start_broker "$port" "$path" "$dir/broker-1.log"; then
        return 1
    fi

    "$PY" "$pub" "$port" "$prog" "$MSG_COUNT" >/dev/null 2>&1 &
    PUB_PID=$!

    # wait until ~target messages are out, then SIGKILL mid-publish
    local waited=0
    while [ "$waited" -lt 300 ]; do
        local lines
        lines="$(wc -l <"$prog" 2>/dev/null || echo 0)"
        if [ "$lines" -ge "$target" ]; then break; fi
        if ! kill -0 "$PUB_PID" 2>/dev/null; then break; fi
        sleep 0.01
        waited=$((waited + 1))
    done
    sigkill_broker
    kill -9 "$PUB_PID" 2>/dev/null
    wait "$PUB_PID" 2>/dev/null
    PUB_PID=""

    local published
    published="$(wc -l <"$prog" 2>/dev/null || echo 0)"
    local walsize
    walsize="$(stat -c %s "$path" 2>/dev/null || echo 0)"

    # restart on the SAME WAL path (recovery replay)
    sleep 0.2
    if ! start_broker "$port" "$path" "$dir/broker-2.log"; then
        return 1
    fi

    "$PY" "$consumer" "$port" "$count_file" >/dev/null 2>&1
    recovered="$(cat "$count_file" 2>/dev/null || echo 0)"

    echo "sigkill: target=$target published=$published wal_bytes=$walsize recovered=$recovered"
    RESULTS+=("$target:$recovered")

    sigkill_broker
    [ "$recovered" -gt 0 ]
}

# ---- main --------------------------------------------------------------------
if ! build_broker; then
    echo "SIGKILL_HARNESS=FAIL (build)"
    exit 1
fi
if ! resolve_python; then
    echo "SIGKILL_HARNESS=FAIL (no pika)"
    exit 1
fi

TMPROOT="$(mktemp -d "${TMPDIR:-/tmp}/hyrxmq-sigkill.XXXXXX")"
RESULTS=()
status=0
for target in "${KILL_AT[@]}"; do
    if ! run_iteration "$target"; then
        status=1
    fi
done

summary=""
for r in "${RESULTS[@]}"; do
    summary="$summary $r"
done

if [ "$status" -eq 0 ]; then
    echo "SIGKILL_HARNESS=PASS recovery:$summary"
    exit 0
else
    echo "SIGKILL_HARNESS=FAIL recovery:$summary"
    exit 1
fi