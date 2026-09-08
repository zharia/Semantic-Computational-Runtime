#!/usr/bin/env bash
# Fair RabbitMQ-vs-HyrxMQ AMQP benchmark — one-shot driver.
#
# NOT part of scripts/test_all.sh: this is a long-running empirical workload,
# kept out of the correctness suite (pixi task: bench-fair).
#
# What it does, in order:
#   0. preflight  — reference RabbitMQ must already be live (this script never
#                   starts, stops, restarts or reconfigures it), stale
#                   hyrx-bench containers/images are cleaned, and the pika
#                   AF_UNIX patch is self-tested.
#   1. build      — build/hyrxmq-listen (the listen-mode binary).
#   2. measure    — benchmarks/perf/harness.py, one process, one connection per
#                   broker at a time, sequential: 4 cells x payloads + latency
#                   + floors  ->  benchmarks/perf/results.json. The
#                   hyrx-tcp-docker cell builds + starts the throwaway
#                   hyrx-bench container on the same bridge as node-rabbitmq
#                   (benchmarks/perf/docker_hyrx.py) and stops it at the end of
#                   its cell; step 5 catches anything left by a crash.
#   3. judge      — benchmarks/perf/index.py: transport matrix + the single
#                   Performance Rating R.
#   4. gate       — benchmarks/perf/compare.py against baseline.json (if one
#                   exists); non-zero exit means regression.
#   5. cleanup    — every hyrx-bench container/image removed, /tmp sockets
#                   removed, and a leftover report (including that the reference
#                   broker has no bench queues/exchanges left on it).
#
# Tunables (env): BENCH_PY, BENCH_OUT, BENCH_CELLS, BENCH_PAYLOADS,
#                BENCH_MAX_CELL_SECONDS, BENCH_ARGS (e.g. "--quick").
set -uo pipefail

cd "$(dirname "$0")/../.."
ROOT=$PWD
PY=${BENCH_PY:-/tmp/amqp-venv/bin/python}
OUT=${BENCH_OUT:-benchmarks/perf/results.json}
CELLS=${BENCH_CELLS:-rabbit-tcp,hyrx-tcp-docker,hyrx-tcp-native,hyrx-uds}
PAYLOADS=${BENCH_PAYLOADS:-64,256,1024,4096,16384}
MAXCELL=${BENCH_MAX_CELL_SECONDS:-90}
BASELINE=${BENCH_BASELINE:-benchmarks/perf/baseline.json}

say() { printf '\n=== %s ===\n' "$*"; }
die() { printf 'FATAL: %s\n' "$*" >&2; exit 2; }

[ -x "$PY" ] || die "python with pika not found at $PY (see requirements-note.txt)"
"$PY" -c 'import pika' 2>/dev/null || die "$PY cannot import pika"

cleanup() {
  say "5. cleanup / leftovers"
  "$PY" benchmarks/perf/docker_hyrx.py down || true
  rm -f /tmp/hyrx-bench-*.sock /tmp/hyrx-probe-*.sock \
        /tmp/hyrx-bench-*.log /tmp/hyrx-uds-preflight.log || true
  "$PY" benchmarks/perf/docker_hyrx.py status || true
  "$PY" - <<'EOF' || true
import base64, json, urllib.request
def get(p):
    r = urllib.request.Request('http://127.0.0.1:15672' + p)
    r.add_header('Authorization', 'Basic ' + base64.b64encode(b'admin:password').decode())
    return json.load(urllib.request.urlopen(r, timeout=5))
qs = [q['name'] for q in get('/api/queues')]
xs = [e['name'] for e in get('/api/exchanges') if e['name'].startswith('bench')]
print('rabbit queues left by bench:', [q for q in qs if q.startswith('bench')] or 'none')
print('rabbit exchanges left by bench:', xs or 'none')
print('rabbit total queues now:', len(qs))
EOF
  docker inspect node-rabbitmq --format 'node-rabbitmq state: {{.State.Status}} startedAt={{.State.StartedAt}}' || true
}
trap cleanup EXIT

say "0. preflight"
docker inspect node-rabbitmq --format 'node-rabbitmq state: {{.State.Status}} startedAt={{.State.StartedAt}}' \
  || die "reference container node-rabbitmq is not present"
"$PY" - <<'EOF' || die "cannot reach reference RabbitMQ on 127.0.0.1:5672"
import socket, sys
try:
    socket.create_connection(('127.0.0.1', 5672), timeout=3).close()
except OSError as exc:
    print(exc); sys.exit(1)
EOF
# start clean even if a previous run was killed -9
"$PY" benchmarks/perf/docker_hyrx.py down >/dev/null 2>&1 || true

say "0b. pika AF_UNIX patch self-test"
UDS_PROBE=/tmp/hyrx-probe-$$.sock
rm -f "$UDS_PROBE"
HYRXMQ_UDS_PATH="$UDS_PROBE" ./build/hyrxmq-listen > /tmp/hyrx-uds-preflight.log 2>&1 &
PROBE_PID=$!
for _ in $(seq 1 40); do [ -S "$UDS_PROBE" ] && break; sleep 0.1; done
if [ -S "$UDS_PROBE" ]; then
  timeout 30 "$PY" benchmarks/perf/pika_uds.py "$UDS_PROBE" \
    && echo "PIKA_UDS: works" || echo "PIKA_UDS: BLOCKED (see line above; the UDS cell will be reported NOT MEASURED)"
else
  echo "PIKA_UDS: BLOCKED (broker did not create $UDS_PROBE; see /tmp/hyrx-uds-preflight.log)"
fi
kill $PROBE_PID 2>/dev/null; wait $PROBE_PID 2>/dev/null
rm -f "$UDS_PROBE"

say "1. build hyrxmq-listen"
pixi run mojo build -I src -I vendor/flare src/hyrxmq/main_listen.mojo \
  -o build/hyrxmq-listen || die "mojo build failed"

say "2..4. measure + rate + gate"
"$PY" benchmarks/perf/harness.py --cells "$CELLS" --payloads "$PAYLOADS" \
  --max-cell-seconds "$MAXCELL" --out "$OUT" ${BENCH_ARGS:-}
RC=$?
[ $RC -eq 0 ] || die "harness exited $RC"

"$PY" benchmarks/perf/index.py "$OUT"
INDEX_RC=$?
if [ $INDEX_RC -eq 3 ]; then
  echo "NOTE: the Performance Rating could not be computed (fair pair blocked)."
  echo "      Run the fallback below and see the report for why."
fi

if [ -f "$BASELINE" ]; then
  "$PY" benchmarks/perf/compare.py --baseline "$BASELINE" --now "$OUT" \
    --json-out benchmarks/perf/regression_report.json
  GATE=$?
  echo "regression gate exit=$GATE (0=PASS 1=REGRESSION 2=INCONCLUSIVE)"
else
  echo "no baseline at $BASELINE — gate skipped; capture one with:"
  echo "  $PY benchmarks/perf/compare.py --update-baseline --now $OUT"
  GATE=2
fi

say "done"
echo "results: $OUT"
exit $GATE
