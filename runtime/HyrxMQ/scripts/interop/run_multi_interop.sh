#!/usr/bin/env bash
# Multi-client AMQP interop runner for HyrxMQ (M8.1).
#
# Binds a port OTHER than RabbitMQ's 5672 (default 5698), starts the listen
# binary, and drives two independent real clients:
#   - Node.js  (amqplib, installed into a temp prefix)
#   - Java     (com.rabbitmq:amqp-client, jar cached from Maven Central)
# Each client is bounded by `timeout`; the broker subprocess is ALWAYS torn
# down. Prints a per-client PASS/FAIL table and exits non-zero if any client
# fails.
#
# Usage: [HYRXMQ_PORT=5698] [NODE_INTEROP_DIR=/tmp/node-interop] \
#        [JAVA_INTEROP_CACHE=/tmp/hyrxmq-java-interop] \
#        bash scripts/interop/run_multi_interop.sh
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PORT="${HYRXMQ_PORT:-5698}"
BIN="$ROOT/build/hyrxmq-listen"
INTEROP="$ROOT/scripts/interop"

NODE_TMP="${NODE_INTEROP_DIR:-/tmp/node-interop}"
JAVA_CACHE="${JAVA_INTEROP_CACHE:-${TMPDIR:-/tmp}/hyrxmq-java-interop}"

AMQP_CLIENT_VERSION="5.21.0"
SLF4J_VERSION="1.7.36"
AMQP_JAR="$JAVA_CACHE/amqp-client-${AMQP_CLIENT_VERSION}.jar"
SLF4J_JAR="$JAVA_CACHE/slf4j-api-${SLF4J_VERSION}.jar"

CLIENT_TIMEOUT="${CLIENT_TIMEOUT:-120}"

NODE_RC=1
JAVA_RC=1
BROKER_PID=""
LOG="$(mktemp)"
BROKER_LOG="$(mktemp)"

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
    rm -f "$LOG" "$BROKER_LOG"
}
trap cleanup EXIT INT TERM

[ -x "$BIN" ] || { echo "missing $BIN — build it first"; exit 2; }

port_open() {
    if command -v ss >/dev/null 2>&1; then
        ss -ltnH "sport = :$PORT" 2>/dev/null | grep -q .
    else
        timeout 1 bash -c "echo > /dev/tcp/127.0.0.1/$PORT" 2>/dev/null
    fi
}

if port_open; then
    echo "port $PORT already in use — refusing to start (RabbitMQ stays on 5672)"
    exit 2
fi

# Start the binary DIRECTLY as the background job so BROKER_PID is the broker,
# not a subshell holding the port.
HYRXMQ_HOST=127.0.0.1 HYRXMQ_PORT="$PORT" "$BIN" >"$BROKER_LOG" 2>&1 &
BROKER_PID=$!

bound=0
for _ in $(seq 1 50); do
    if port_open; then bound=1; break; fi
    if ! kill -0 "$BROKER_PID" 2>/dev/null; then
        echo "broker exited before binding :$PORT"; cat "$BROKER_LOG"; exit 1
    fi
    sleep 0.2
done
if [ "$bound" -ne 1 ]; then
    echo "broker did not bind :$PORT within 10s"; cat "$BROKER_LOG"; exit 1
fi
echo "broker PID=$BROKER_PID listening on 127.0.0.1:$PORT (RabbitMQ stays on 5672)"

# ---------------- Node.js / amqplib client ----------------
echo
echo "== node (amqplib) =="
if ! command -v node >/dev/null 2>&1; then
    echo "node not found — skipping"
    NODE_RC=127
else
    mkdir -p "$NODE_TMP"
    cp "$INTEROP/node_package.json" "$NODE_TMP/package.json"
    if [ ! -d "$NODE_TMP/node_modules/amqplib" ]; then
        echo "installing amqplib into $NODE_TMP"
        if ! npm install --prefix "$NODE_TMP" --no-audit --no-fund --silent amqplib; then
            echo "npm install amqplib failed"
            NODE_RC=1
        fi
    fi
    if [ -d "$NODE_TMP/node_modules/amqplib" ]; then
        NODE_PATH="$NODE_TMP/node_modules" \
        HYRX_HOST=127.0.0.1 HYRX_PORT="$PORT" \
            timeout "$CLIENT_TIMEOUT" node "$INTEROP/node_interop.js"
        NODE_RC=$?
    fi
fi

# ---------------- Java / com.rabbitmq:amqp-client ----------------
echo
echo "== java (amqp-client) =="
if ! command -v javac >/dev/null 2>&1; then
    echo "javac not found — skipping"
    JAVA_RC=127
else
    mkdir -p "$JAVA_CACHE"
    download_jar() {
        local url="$1" dest="$2"
        if [ ! -s "$dest" ]; then
            echo "downloading $(basename "$dest")"
            if ! curl -fsSL "$url" -o "$dest"; then
                rm -f "$dest"
                return 1
            fi
        fi
    }
    ok_jars=1
    download_jar "https://repo1.maven.org/maven2/com/rabbitmq/amqp-client/${AMQP_CLIENT_VERSION}/amqp-client-${AMQP_CLIENT_VERSION}.jar" "$AMQP_JAR" || ok_jars=0
    download_jar "https://repo1.maven.org/maven2/org/slf4j/slf4j-api/${SLF4J_VERSION}/slf4j-api-${SLF4J_VERSION}.jar" "$SLF4J_JAR" || ok_jars=0

    if [ "$ok_jars" -ne 1 ]; then
        echo "failed to fetch Java dependencies from Maven Central"
        JAVA_RC=1
    else
        CP="$AMQP_JAR:$SLF4J_JAR"
        JAVA_BUILD="$(mktemp -d)"
        if javac -cp "$CP" -d "$JAVA_BUILD" "$INTEROP/JavaInterop.java"; then
            HYRX_HOST=localhost HYRX_PORT="$PORT" \
                timeout "$CLIENT_TIMEOUT" java -cp "$JAVA_BUILD:$CP" JavaInterop
            JAVA_RC=$?
        else
            echo "javac failed"
            JAVA_RC=1
        fi
        rm -rf "$JAVA_BUILD"
    fi
fi

# ---------------- teardown + report ----------------
cleanup
trap - EXIT INT TERM
if port_open; then
    echo "FATAL: port $PORT still bound after teardown"
    exit 3
fi

echo
echo "============ MULTI-CLIENT INTEROP RESULT ============"
printf '%-8s  %-4s  %s\n' "CLIENT" "RC" "STATE"
if [ "$NODE_RC" -eq 0 ]; then ns=PASS; else ns=FAIL; fi
if [ "$JAVA_RC" -eq 0 ]; then js=PASS; else js=FAIL; fi
printf '%-8s  %-4s  %s\n' "node" "$NODE_RC" "$ns"
printf '%-8s  %-4s  %s\n' "java" "$JAVA_RC" "$js"
echo "===================================================="

if [ "$NODE_RC" -eq 0 ] && [ "$JAVA_RC" -eq 0 ]; then
    echo "MULTI_INTEROP=PASS"
    exit 0
fi
echo "MULTI_INTEROP=FAIL"
exit 1