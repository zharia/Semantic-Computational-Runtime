#!/usr/bin/env bash
# Fair three-broker AMQP benchmark driver: HyrxMQ vs RabbitMQ vs LavinMQ.
#
# SAFETY: this script only ever creates/removes the exact container names and
# network below. It never uses pkill/killall and never touches any container it
# did not start (e.g. the pre-existing `ecstatic_khayyam`).
#
# Usage:
#   ./run_three_broker.sh                 # full suite
#   ./run_three_broker.sh --quick         # smoke pass (1KB, conc 1&16, 3 reps)
#   KEEP_CONTAINERS=1 ./run_three_broker.sh --quick   # leave brokers up
#
# Any extra args are forwarded to harness.py.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PY=/tmp/amqp-venv/bin/python

NET=hyrxmq-bench
C_HYRX=hyrxmq-bench-hyrx
C_RABBIT=hyrxmq-bench-rabbit
C_LAVIN=hyrxmq-bench-lavin
HOST_IP=127.0.0.1
P_HYRX=5711
P_RABBIT=5712
P_LAVIN=5713
CPUS=4
MEM=2g

if [ ! -x "$PY" ]; then
  echo "creating pika venv at /tmp/amqp-venv"
  python3 -m venv /tmp/amqp-venv
  "$PY" -m pip install -q pika
fi

KEEP_CONTAINERS="${KEEP_CONTAINERS:-0}"

cleanup() {
  rc=$?
  if [ "$KEEP_CONTAINERS" = "1" ]; then
    echo "KEEP_CONTAINERS=1: leaving $C_HYRX $C_RABBIT $C_LAVIN and $NET up" >&2
    return $rc
  fi
  echo "cleanup: removing only our containers + network" >&2
  docker rm -f "$C_HYRX" "$C_RABBIT" "$C_LAVIN" >/dev/null 2>&1 || true
  docker network rm "$NET" >/dev/null 2>&1 || true
  return $rc
}
trap cleanup EXIT INT TERM

# --- same-network, same-proxy-hop setup --------------------------------------
if ! docker network inspect "$NET" >/dev/null 2>&1; then
  docker network create "$NET" >/dev/null
fi

# LavinMQ stores a SHA256 password HASH (RabbitMQ scheme) in
# LAVINMQ_DEFAULT_PASSWORD, not a plaintext password.
LAVIN_HASH="$(python3 - <<'PY'
import base64, hashlib
salt = b'\x9a\x1b\x2c\x3d'
digest = hashlib.sha256(salt + b'password').digest()
print(base64.b64encode(salt + digest).decode())
PY
)"

docker rm -f "$C_HYRX" "$C_RABBIT" "$C_LAVIN" >/dev/null 2>&1 || true

echo "starting brokers: cpus=$CPUS mem=$MEM network=$NET"
# HyrxMQ: override the image CMD (hyrxmq-web) with the dedicated broker
# executable. The web binary's embedded AMQP listener does not complete a
# client handshake in this build, but /app/build/hyrxmq-listen (same image)
# does. --no-healthcheck suppresses the web-port HEALTHCHECK (port 8080 is not
# served by the listener binary and is irrelevant to the AMQP measurement).
docker run -d --name "$C_HYRX" --network "$NET" --cpus "$CPUS" --memory "$MEM" \
  --no-healthcheck \
  -p "$HOST_IP:$P_HYRX:5673" \
  -e HYRXMQ_HOST=0.0.0.0 -e HYRXMQ_PORT=5673 -e HYRXMQ_USERS=admin/password \
  hyrxmq:latest /app/build/hyrxmq-listen >/dev/null

docker run -d --name "$C_RABBIT" --network "$NET" --cpus "$CPUS" --memory "$MEM" \
  -p "$HOST_IP:$P_RABBIT:5672" \
  -e RABBITMQ_DEFAULT_USER=admin -e RABBITMQ_DEFAULT_PASS=password \
  rabbitmq:4-management >/dev/null

docker run -d --name "$C_LAVIN" --network "$NET" --cpus "$CPUS" --memory "$MEM" \
  -p "$HOST_IP:$P_LAVIN:5672" \
  -e LAVINMQ_DEFAULT_USER=admin -e LAVINMQ_DEFAULT_PASSWORD="$LAVIN_HASH" \
  cloudamqp/lavinmq:latest >/dev/null

# --- health gate: SAME pika connect + channel open on all three -------------
health() {
  local label=$1 port=$2 container=$3
  if ! "$PY" - "$port" <<'PY'
import sys, time, pika
port = int(sys.argv[1])
deadline = time.time() + 120
last = None
while time.time() < deadline:
    try:
        params = pika.ConnectionParameters(
            host='127.0.0.1', port=port, virtual_host='/',
            credentials=pika.PlainCredentials('admin', 'password'),
            heartbeat=0, frame_max=131072, connection_attempts=1,
            socket_timeout=5, stack_timeout=8)
        conn = pika.BlockingConnection(params)
        conn.channel()
        conn.close()
        sys.exit(0)
    except Exception as exc:
        last = repr(exc)
        time.sleep(1)
print('last error:', last)
sys.exit(1)
PY
  then
    echo "HEALTH GATE FAILED for $label" >&2
    docker logs --tail 40 "$container" >&2 2>&1 || true
    exit 1
  fi
  echo "  $label healthy on 127.0.0.1:$port"
}

health HyrxMQ   "$P_HYRX"   "$C_HYRX"
health RabbitMQ "$P_RABBIT" "$C_RABBIT"
health LavinMQ  "$P_LAVIN"  "$C_LAVIN"

# --- run the benchmark -------------------------------------------------------
echo "running harness $*"
set +e
"$PY" "$HERE/harness.py" --out-dir "$HERE/results" "$@"
rc=$?
set -e
echo "harness exit=$rc; results in $HERE/results"
exit $rc
