#!/usr/bin/env bash
# run_v2.sh — fair three-broker AMQP benchmark, v2 (compiled Go client).
#
# SAFETY: only ever creates/removes the exact container names and network
# below. Never uses pkill/killall. Never touches any container it did not start
# (e.g. `ecstatic_khayyam`, `tmp-hyrx-probe`). The one background process it
# starts (docker-stats sampler) is killed by its own PID via the EXIT trap.
#
# Usage:
#   ./run_v2.sh                 # full matrix (see matrix below)
#   ./run_v2.sh --quick         # payload 1024, conc 1&16, 3 reps
#   REPS=5 ./run_v2.sh
#   SKIP_BUILD=1 ./run_v2.sh --quick
#   KEEP_CONTAINERS=1 ./run_v2.sh --quick
#
# Env overrides: REPS, TARGET_REP_S, WORKLOADS, PAYLOADS, CONCS, REP_BUDGET_S
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../../.." && pwd)"
LOADGEN=/tmp/loadgen
PY=python3

NET=hyrxmq-bench2
C_HYRX=hyrxmq-bench2-hyrx
C_RABBIT=hyrxmq-bench2-rabbit
C_LAVIN=hyrxmq-bench2-lavin
HOST_IP=127.0.0.1
P_HYRX=5711
P_RABBIT=5712
P_LAVIN=5713
CPUS=4
MEM=2g

TARGET_REP_S="${TARGET_REP_S:-2.0}"
SKIP_BUILD="${SKIP_BUILD:-0}"
KEEP_CONTAINERS="${KEEP_CONTAINERS:-0}"
QUICK=0
for a in "$@"; do [ "$a" = "--quick" ] && QUICK=1; done

if [ "$QUICK" = "1" ]; then
  PAYLOADS="${PAYLOADS:-1024}"
  CONCS="${CONCS:-1 16}"
  REPS="${REPS:-3}"
else
  PAYLOADS="${PAYLOADS:-64 1024 16384 65536 262144}"
  CONCS="${CONCS:-1 4 8 16 32}"
fi
WORKLOADS="${WORKLOADS:-publish pubget confirm latency fanout}"

RESULTS="$HERE/results"
mkdir -p "$RESULTS"
TS="$(date -u +%Y%m%dT%H%M%SZ)"
STARTED="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
NDJSON="$RESULTS/v2_runs_$TS.ndjson"
STATSND="$RESULTS/v2_stats_$TS.ndjson"
RAW="$RESULTS/v2_raw_$TS.json"
CONS="$RESULTS/v2_consolidated_$TS.json"
: > "$NDJSON"
: > "$STATSND"

SAMPLER_PID=""
cleanup() {
  rc=$?
  trap - EXIT INT TERM
  if [ -n "$SAMPLER_PID" ] && kill -0 "$SAMPLER_PID" 2>/dev/null; then
    kill -TERM "$SAMPLER_PID" 2>/dev/null || true
    wait "$SAMPLER_PID" 2>/dev/null || true
  fi
  if [ "$KEEP_CONTAINERS" = "1" ]; then
    echo "KEEP_CONTAINERS=1: leaving $C_HYRX $C_RABBIT $C_LAVIN and $NET up" >&2
    exit $rc
  fi
  echo "cleanup: removing only our containers + network" >&2
  docker rm -f "$C_HYRX" "$C_RABBIT" "$C_LAVIN" >/dev/null 2>&1 || true
  docker network rm "$NET" >/dev/null 2>&1 || true
  exit $rc
}
trap cleanup EXIT INT TERM

# --- build ------------------------------------------------------------------
echo "[$(date -u +%H:%M:%S)] building Go loadgen"
( cd "$HERE/loadgen" && go build -o "$LOADGEN" . ) || { echo "loadgen build FAILED" >&2; exit 1; }

if [ "$SKIP_BUILD" != "1" ]; then
  echo "[$(date -u +%H:%M:%S)] building HyrxMQ image"
  docker build -t hyrxmq:latest "$ROOT" >"$RESULTS/v2_docker_build_$TS.log" 2>&1 \
    || { echo "hyrxmq docker build FAILED (see log)" >&2; exit 1; }
fi

# --- network + containers ---------------------------------------------------
docker network inspect "$NET" >/dev/null 2>&1 || docker network create "$NET" >/dev/null
docker rm -f "$C_HYRX" "$C_RABBIT" "$C_LAVIN" >/dev/null 2>&1 || true

LAVIN_HASH="$($PY - <<'PY'
import base64, hashlib
salt = b'\x9a\x1b\x2c\x3d'
print(base64.b64encode(salt + hashlib.sha256(salt + b'password').digest()).decode())
PY
)"

echo "[$(date -u +%H:%M:%S)] starting brokers cpus=$CPUS mem=$MEM net=$NET"
docker run -d --name "$C_HYRX" --network "$NET" --cpus "$CPUS" --memory "$MEM" \
  --no-healthcheck -p "$HOST_IP:$P_HYRX:5673" \
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

# --- health gate: identical tiny loadgen op on all three --------------------
health() {
  local label=$1 port=$2 container=$3
  local i
  for i in $(seq 1 60); do
    if timeout 12 "$LOADGEN" --url "amqp://admin:password@127.0.0.1:$port/" \
        --broker "$label" --workload pubget --count 2 --payload 8 \
        --concurrency 1 >/dev/null 2>&1; then
      echo "  $label healthy on 127.0.0.1:$port"
      return 0
    fi
    sleep 2
  done
  echo "HEALTH GATE FAILED for $label" >&2
  docker logs --tail 40 "$container" >&2 2>&1 || true
  return 1
}
health HyrxMQ "$P_HYRX" "$C_HYRX" || exit 1
health RabbitMQ "$P_RABBIT" "$C_RABBIT" || exit 1
health LavinMQ "$P_LAVIN" "$C_LAVIN" || exit 1

# --- background docker-stats sampler (killed by exact PID) -------------------
sample_stats() {
  while true; do
    local ts
    ts="$(date +%s.%N)"
    docker stats --no-stream --format '{{.Name}}|{{.CPUPerc}}|{{.MemUsage}}' \
      "$C_HYRX" "$C_RABBIT" "$C_LAVIN" 2>/dev/null \
      | while IFS= read -r line; do printf '%s|%s\n' "$ts" "$line" >>"$STATSND"; done
    sleep 1
  done
}
sample_stats &
SAMPLER_PID=$!
echo "[$(date -u +%H:%M:%S)] stats sampler pid=$SAMPLER_PID"

url_for() {
  case "$1" in
    hyrxmq) echo "amqp://admin:password@127.0.0.1:$P_HYRX/" ;;
    rabbitmq) echo "amqp://admin:password@127.0.0.1:$P_RABBIT/" ;;
    lavinmq) echo "amqp://admin:password@127.0.0.1:$P_LAVIN/" ;;
  esac
}

# --- calibration (per broker/workload/payload/concurrency) -------------------
declare -A CAL
PROBE_COUNT() {
  case "$1" in
    pubget) echo 1000 ;;
    confirm) echo 300 ;;
    fanout) echo 200 ;;
    latency) echo 200 ;;
    *) echo 500 ;;
  esac
}
MIN_COUNT() {
  case "$1" in
    pubget) echo 500 ;;
    confirm) echo 200 ;;
    fanout) echo 200 ;;
    latency) echo 300 ;;
    *) echo 200 ;;
  esac
}
MAX_COUNT() {
  case "$1" in
    pubget|confirm) echo 200000 ;;
    fanout) echo 1000 ;;
    latency) echo 20000 ;;
    *) echo 100000 ;;
  esac
}

calibrate() {
  local broker=$1 wl=$2 payload=$3 conc=$4
  local key="$broker:$wl:$payload:$conc"
  if [ -n "${CAL[$key]:-}" ]; then echo "${CAL[$key]}"; return 0; fi
  local pc minc maxc memcap rate count out
  pc="$(PROBE_COUNT "$wl")"
  minc="$(MIN_COUNT "$wl")"
  maxc="$(MAX_COUNT "$wl")"
  memcap=$((268435456 / payload))
  [ "$memcap" -lt 1 ] && memcap=1
  [ "$maxc" -gt "$memcap" ] && maxc="$memcap"
  [ "$minc" -gt "$maxc" ] && minc="$maxc"
  out="$(timeout 30 "$LOADGEN" --url "$(url_for "$broker")" --broker "$broker" \
        --workload "$wl" --payload "$payload" --concurrency "$conc" --count "$pc" 2>/dev/null)"
  rate="$(printf '%s' "$out" | $PY -c 'import sys,json
try: print(json.load(sys.stdin).get("msgs_per_sec") or 0)
except Exception: print(0)' 2>/dev/null)"
  count="$($PY -c "r=float('$rate' or 0); c=int(r*$TARGET_REP_S); print(max($minc,min($maxc,c)))")"
  CAL[$key]="$count"
  echo "$count"
}

record() {
  local wl=$1 payload=$2 conc=$3 rep=$4 order=$5 broker=$6 rc=$7 t0=$8 out=$9
  local res="null"
  if [ "$rc" -eq 0 ] && [ -n "$out" ]; then res="$out"; fi
  printf '{"workload":"%s","payload":%s,"concurrency":%s,"rep":%s,"order":%s,"broker":"%s","rc":%s,"t_start":%s,"result":%s}\n' \
    "$wl" "$payload" "$conc" "$rep" "$order" "$broker" "$rc" "$t0" "$res" >>"$NDJSON"
}

run_one() {
  local wl=$1 payload=$2 conc=$3 rep=$4 order=$5 broker=$6
  local url out rc count t0 t1 args
  url="$(url_for "$broker")"
  if [ "$wl" = "publish" ]; then
    args=(--workload publish --duration "$TARGET_REP_S" --count 1000000)
  else
    count="$(calibrate "$broker" "$wl" "$payload" "$conc")"
    args=(--workload "$wl" --count "$count")
  fi
  t0="$(date +%s.%N)"
  out="$(timeout 60 "$LOADGEN" --url "$url" --broker "$broker" "${args[@]}" \
        --payload "$payload" --concurrency "$conc" --declares 4 2>/dev/null)"
  rc=$?
  t1="$(date +%s.%N)"
  record "$wl" "$payload" "$conc" "$rep" "$order" "$broker" "$rc" "$t0" "$out"
  local rate
  rate="$(printf '%s' "$out" | $PY -c 'import sys,json
try: print(json.load(sys.stdin).get("msgs_per_sec"))
except Exception: print(None)' 2>/dev/null)"
  printf '  [%s] %-9s %-7s p=%-7s c=%-2s rep=%s order=%s -> %s msg/s (rc=%s)\n' \
    "$(date -u +%H:%M:%S)" "$broker" "$wl" "$payload" "$conc" "$rep" "$order" "$rate" "$rc"
}

BROKERS=(hyrxmq rabbitmq lavinmq)

echo "[$(date -u +%H:%M:%S)] matrix start: reps=$REPS payloads=[$PAYLOADS] concs=[$CONCS] workloads=[$WORKLOADS] target=${TARGET_REP_S}s"
for wl in $WORKLOADS; do
  case "$wl" in
    latency) pl="$PAYLOADS"; cl="1" ;;
    fanout)  pl="1024"; cl="$CONCS" ;;
    *)       pl="$PAYLOADS"; cl="$CONCS" ;;
  esac
  for payload in $pl; do
    for conc in $cl; do
      echo "=== CELL $wl payload=$payload conc=$conc ==="
      rep=0
      while [ "$rep" -lt "$REPS" ]; do
        rot=$(( rep % ${#BROKERS[@]} ))
        idx=0
        while [ "$idx" -lt "${#BROKERS[@]}" ]; do
          broker="${BROKERS[$(( (idx + rot) % ${#BROKERS[@]} ))]}"
          run_one "$wl" "$payload" "$conc" "$rep" "$idx" "$broker"
          idx=$(( idx + 1 ))
        done
        rep=$(( rep + 1 ))
      done
    done
  done
done

FINISHED="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "[$(date -u +%H:%M:%S)] matrix done; collecting"

$PY "$HERE/collect_v2.py" \
  --runs "$NDJSON" --stats "$STATSND" --raw "$RAW" --consolidated "$CONS" \
  --reps "$REPS" --target "$TARGET_REP_S" --started "$STARTED" \
  --finished "$FINISHED" --mode "$([ "$QUICK" = 1 ] && echo quick || echo full)" \
  --containers "$C_HYRX" "$C_RABBIT" "$C_LAVIN" \
  --payloads "$PAYLOADS" --concs "$CONCS" --workloads "$WORKLOADS"

echo "[$(date -u +%H:%M:%S)] WROTE $RAW"
echo "[$(date -u +%H:%M:%S)] WROTE $CONS"