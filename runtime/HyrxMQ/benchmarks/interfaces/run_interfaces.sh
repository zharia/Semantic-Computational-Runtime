#!/usr/bin/env bash
# run_interfaces.sh — orchestrate the HyrxMQ TCP-vs-WebSocket interface benchmark.
#
# Builds the broker + the Go load generator, starts a TCP-only broker and a
# WSS-only broker (each in its own process), health-gates each with a real
# handshake+publish+get, then runs the SAME Go binary and matrix against both.
#
# SAFETY: this script kills only the exact PIDs it launched (tracked from $!).
# It never uses pkill/killall. Idle orphan brokers on other ports are untouched.
#
# Usage:
#   benchmarks/interfaces/run_interfaces.sh [--quick] [--no-build]
#     --quick     small matrix (payloads 64,16384; concurrency 1; 3 reps)
#     --no-build  reuse existing build/hyrxmq-listen and build/hyrxmq-ws-bench
#
# NOTE (2026-09): the shipped broker CANNOT serve the WSS tier in this build
# (see REPORT.md / WSS findings). The script records that as a blocked
# transport instead of faking a comparison.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

INTERFACES="$ROOT/benchmarks/interfaces"
OUT="$INTERFACES/out"
mkdir -p "$OUT"

QUICK=0
NO_BUILD=0
for a in "$@"; do
  case "$a" in
    --quick) QUICK=1 ;;
    --no-build) NO_BUILD=1 ;;
    *) echo "unknown arg: $a" >&2; exit 2 ;;
  esac
done

TCP_PORT="${TCP_PORT:-15701}"
WS_PORT="${WS_PORT:-15702}"
FRAME_MAX="${FRAME_MAX:-1048576}"
HOST=127.0.0.1
BROKER="$ROOT/build/hyrxmq-listen"
WS_BROKER="$ROOT/build/hyrxmq-ws-bench"
BIN="$OUT/ifbench"
STAMP="$(date +%Y%m%d-%H%M%S)"
RAW="$OUT/raw_$STAMP.jsonl"
BLOCKED="$OUT/blocked_$STAMP.json"
RESOURCES="$OUT/resources_$STAMP.json"
CONSOLIDATED="$OUT/consolidated_$STAMP.json"
: > "$RAW"

TCP_PID=""
WS_PID=""
cleanup() {
  # Kill ONLY our own broker PIDs. Never pkill/killall.
  for p in "$TCP_PID" "$WS_PID"; do
    if [ -n "$p" ] && kill -0 "$p" 2>/dev/null; then
      kill -TERM "$p" 2>/dev/null
      for _ in $(seq 1 20); do kill -0 "$p" 2>/dev/null || break; sleep 0.1; done
      kill -0 "$p" 2>/dev/null && kill -9 "$p" 2>/dev/null
      wait "$p" 2>/dev/null
    fi
  done
}
trap cleanup EXIT INT TERM

log() { printf '[run_interfaces] %s\n' "$*" >&2; }

start_broker() {
  # $1=env-prefix-string  $2=logfile ; echoes PID
  local envprefix="$1" logfile="$2"
  # shellcheck disable=SC2086
  env $envprefix "$BROKER" >"$logfile" 2>&1 &
  echo $!
}

# ---- builds ---------------------------------------------------------------
if [ "$NO_BUILD" -eq 0 ]; then
  log "building broker (pixi run hyrxmq-listen)"
  [ -f "$ROOT/build/libflare_tls.so" ] || cp "$ROOT/vendor/libflare_tls.so" "$ROOT/build/" 2>/dev/null
  if ! (cd "$ROOT" && timeout 1800 pixi run hyrxmq-listen >/tmp/hyrxmq_build.log 2>&1); then
    log "broker build failed; see /tmp/hyrxmq_build.log"
    tail -5 /tmp/hyrxmq_build.log >&2 || true
    [ -x "$BROKER" ] || { log "no broker binary"; exit 1; }
  fi
  log "building ws benchmark launcher"
  (cd "$ROOT" && timeout 1800 pixi run bash -c 'cp vendor/libflare_tls.so build/ 2>/dev/null; mojo build -I src -I vendor/flare benchmarks/interfaces/ws_broker.mojo -o build/hyrxmq-ws-bench' >/tmp/hyrxmq_ws_build.log 2>&1) \
    || log "ws launcher build failed; see /tmp/hyrxmq_ws_build.log"
fi
[ -x "$BROKER" ] || { log "missing $BROKER"; exit 1; }

log "building Go load generator"
( cd "$INTERFACES/go" && go mod tidy >/dev/null 2>&1 && go build -o "$BIN" . ) || { log "go build failed"; exit 1; }

# ---- matrix ---------------------------------------------------------------
if [ "$QUICK" -eq 1 ]; then
  WORKLOADS="publish pubget confirm latency"
  PAYLOADS="64 16384"
  CONCURRENCIES="1"
  REPS=3
  DURATION=1.0
  COUNT=2000
else
  WORKLOADS="publish pubget confirm latency"
  PAYLOADS="64 1024 16384 65536 262144"
  CONCURRENCIES="1 4 16"
  REPS=5
  DURATION=2.0
  COUNT=20000
fi

# ---- resource sampling ----------------------------------------------------
sample_proc() {
  local pid="$1"
  [ -r "/proc/$pid/stat" ] || { echo "0 0"; return; }
  awk '{print $14" "$15}' "/proc/$pid/stat"
}
rss_proc() {
  local pid="$1"
  [ -r "/proc/$pid/status" ] || { echo "0"; return; }
  awk '/VmRSS/{print $2}' "/proc/$pid/status"
}

run_cell() {
  # $1=transport $2=workload $3=payload $4=concurrency $5=rep
  local transport="$1" workload="$2" payload="$3" conc="$4" rep="$5"
  local url="$HOST:$TCP_PORT"
  [ "$transport" = ws ] && url="$HOST:$WS_PORT"
  local workflag="-workload $workload -payload $payload -concurrency $conc"
  [ "$workload" = publish ] && workflag="$workflag -duration $DURATION" || workflag="$workflag -count $COUNT"
  local line
  # shellcheck disable=SC2086
  line="$(timeout 60 "$BIN" -transport "$transport" -url "$url" $workflag 2>>"$OUT/stderr_$STAMP.log")"
  if [ -z "$line" ]; then
    printf '%s\t%s\t%s\n' "$rep" "$transport" "{\"transport\":\"$transport\",\"workload\":\"$workload\",\"payload\":$payload,\"concurrency\":$conc,\"error\":\"no output\"}" >> "$RAW"
    return
  fi
  printf '%s\t%s\t%s\n' "$rep" "$transport" "$line" >> "$RAW"
}

# ---- TCP broker -----------------------------------------------------------
log "starting TCP broker on $HOST:$TCP_PORT"
TCP_PID="$(start_broker "HYRXMQ_PORT=$TCP_PORT HYRXMQ_HOST=$HOST HYRXMQ_FRAME_MAX=$FRAME_MAX" "$OUT/tcp_broker_$STAMP.log")"
sleep 1.0
if kill -0 "$TCP_PID" 2>/dev/null; then
  TCP_ST_OK=1
  if timeout 20 "$BIN" -transport tcp -url "$HOST:$TCP_PORT" -probe -payload 64 >"$OUT/probe_tcp_$STAMP.txt" 2>&1; then
    TCP_PROBE=PASS
  else
    TCP_PROBE=FAIL
  fi
else
  TCP_ST_OK=0; TCP_PROBE=FAIL
fi
log "TCP broker probe: $TCP_PROBE"
cat "$OUT/probe_tcp_$STAMP.txt" >&2 2>/dev/null || true

TCP_CPU0="$(sample_proc "$TCP_PID")"
TCP_RSS0="$(rss_proc "$TCP_PID")"

# ---- WSS broker (documented command; expected to be refused) --------------
log "starting WSS broker on $HOST:$WS_PORT (HYRXMQ_WSS_TLS_MODE=none)"
WS_PID="$(start_broker "HYRXMQ_WSS_LISTEN=$WS_PORT HYRXMQ_WSS_TLS_MODE=none HYRXMQ_HOST=$HOST HYRXMQ_FRAME_MAX=$FRAME_MAX" "$OUT/wss_broker_$STAMP.log")"
sleep 1.5
WS_PROBE=FAIL
WS_BLOCK_REASON=""
if kill -0 "$WS_PID" 2>/dev/null; then
  if timeout 20 "$BIN" -transport ws -url "$HOST:$WS_PORT" -probe -payload 64 >"$OUT/probe_ws_$STAMP.txt" 2>&1; then
    WS_PROBE=PASS
  else
    WS_BLOCK_REASON="WSS broker process started but the AMQP handshake over ws:// did not complete"
  fi
else
  WS_BLOCK_REASON="WSSAMQPListener refuses to start: HYRXMQ_WSS_TLS_MODE=none (no cert source); and with a cert its serve_forever raises because event_driven_serving()=True reads the raw fd"
  wait "$WS_PID" 2>/dev/null
fi
log "WSS broker probe: $WS_PROBE"

# Optional: benchmark-only plaintext ws launcher (proves the carrier deadlock)
WS_BENCH_PROBE=untested
if [ -x "$WS_BROKER" ] && { [ -z "$WS_PID" ] || ! kill -0 "$WS_PID" 2>/dev/null; }; then
  log "starting benchmark-only plaintext ws launcher on $HOST:$WS_PORT"
  HYRXMQ_WSS_LISTEN="$WS_PORT" HYRXMQ_HOST="$HOST" HYRXMQ_FRAME_MAX="$FRAME_MAX" "$WS_BROKER" >"$OUT/ws_bench_$STAMP.log" 2>&1 &
  WS_PID=$!
  sleep 1.0
  if kill -0 "$WS_PID" 2>/dev/null; then
    if timeout 8 "$BIN" -transport ws -url "$HOST:$WS_PORT" -probe -payload 64 >"$OUT/probe_ws_bench_$STAMP.txt" 2>&1; then
      WS_BENCH_PROBE=PASS
    else
      WS_BENCH_PROBE=DEADLOCK
    fi
  else
    WS_BENCH_PROBE=CRASHED
  fi
  log "ws launcher probe: $WS_BENCH_PROBE"
fi

WS_CPU0="$(sample_proc "$WS_PID")"
WS_RSS0="$(rss_proc "$WS_PID")"

# ---- run the matrix -------------------------------------------------------
if [ "$TCP_PROBE" = PASS ]; then
  log "running TCP matrix"
  cells=()
  for w in $WORKLOADS; do for p in $PAYLOADS; do for c in $CONCURRENCIES; do cells+=("$w|$p|$c"); done; done; done
  for rep in $(seq 1 "$REPS"); do
    n=${#cells[@]}
    off=$(( (rep - 1) % n ))
    for k in $(seq 0 $((n - 1))); do
      idx=$(( (k + off) % n ))
      IFS='|' read -r w p c <<< "${cells[$idx]}"
      run_cell tcp "$w" "$p" "$c" "$rep"
    done
  done
fi

WS_CELLS_RUN=0
if [ "$WS_PROBE" = PASS ]; then
  log "running WS matrix"
  WS_CELLS_RUN=1
  cells=()
  for w in $WORKLOADS; do for p in $PAYLOADS; do for c in $CONCURRENCIES; do cells+=("$w|$p|$c"); done; done; done
  for rep in $(seq 1 "$REPS"); do
    n=${#cells[@]}
    off=$(( (rep - 1) % n ))
    for k in $(seq 0 $((n - 1))); do
      idx=$(( (k + off) % n ))
      IFS='|' read -r w p c <<< "${cells[$idx]}"
      run_cell ws "$w" "$p" "$c" "$rep"
    done
  done
fi

# ---- resource snapshots ---------------------------------------------------
end_resources() {
  local pid="$1" cpu0="$2" rss0="$3"
  if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
    local cpu1 rss1
    cpu1="$(sample_proc "$pid")"; rss1="$(rss_proc "$pid")"
    echo "$cpu0 $cpu1 $rss0 $rss1"
  else
    echo "$cpu0 $cpu0 $rss0 $rss0"
  fi
}
TCP_RES="$(end_resources "$TCP_PID" "$TCP_CPU0" "$TCP_RSS0")"
WS_RES="$(end_resources "$WS_PID" "$WS_CPU0" "$WS_RSS0")"

cat > "$BLOCKED" <<EOF
[
EOF
if [ "$WS_PROBE" != PASS ]; then
  cat >> "$BLOCKED" <<EOF
  {"transport":"ws","blocked":true,"reason":"${WS_BLOCK_REASON//\"/\'}","bench_launcher_probe":"$WS_BENCH_PROBE"}
EOF
else
  cat >> "$BLOCKED" <<EOF
EOF
fi
cat >> "$BLOCKED" <<EOF
]
EOF

cat > "$RESOURCES" <<EOF
{
  "tcp": {"raw":"$TCP_RES","note":"<cpu0_ticks cpu1_ticks rss0_kb rss1_kb>"},
  "ws":  {"raw":"$WS_RES","note":"<cpu0_ticks cpu1_ticks rss0_kb rss1_kb>"}
}
EOF

# ---- consolidate ----------------------------------------------------------
python3 - "$RAW" "$BLOCKED" "$RESOURCES" "$CONSOLIDATED" "$STAMP" "$QUICK" <<'PY'
import json, sys, statistics
raw, blocked_f, res_f, out_f, stamp, quick = sys.argv[1:7]
cells = {}
with open(raw) as f:
    for line in f:
        line = line.rstrip("\n")
        if not line:
            continue
        rep, transport, js = line.split("\t", 2)
        try:
            obj = json.loads(js)
        except Exception:
            continue
        key = (transport, obj.get("workload"), obj.get("payload"), obj.get("concurrency"))
        cells.setdefault(key, []).append(obj)

def med(vals):
    vals = [v for v in vals if v is not None]
    return round(statistics.median(vals), 3) if vals else None

out = {"stamp": stamp, "quick": bool(int(quick)), "cells": [], "blocked": [], "resources": {}}
for (transport, workload, payload, conc), runs in sorted(cells.items(), key=lambda kv: (str(kv[0]))):
    ok = [r for r in runs if "error" not in r]
    cell = {
        "transport": transport, "workload": workload, "payload": payload,
        "concurrency": conc, "reps": len(runs), "errors": sum(1 for r in runs if "error" in r),
        "msgs_per_sec": med([r.get("msgs_per_sec") for r in ok]),
        "p50_us": med([r.get("p50_us") for r in ok]),
        "p95_us": med([r.get("p95_us") for r in ok]),
        "p99_us": med([r.get("p99_us") for r in ok]),
        "p999_us": med([r.get("p999_us") for r in ok]),
        "wall_s": med([r.get("wall_s") for r in ok]),
        "count": med([r.get("count") for r in ok]),
        "raw_msgs_per_sec": [r.get("msgs_per_sec") for r in runs],
    }
    out["cells"].append(cell)
try:
    out["blocked"] = json.load(open(blocked_f))
except Exception:
    out["blocked"] = []
try:
    out["resources"] = json.load(open(res_f))
except Exception:
    out["resources"] = {}
json.dump(out, open(out_f, "w"), indent=2)
print(out_f)
PY

log "consolidated: $CONSOLIDATED"

# ---- report ---------------------------------------------------------------
python3 "$INTERFACES/make_report.py" "$CONSOLIDATED" "$INTERFACES/REPORT.md" >>"$OUT/report_$STAMP.log" 2>&1 \
  && log "wrote $INTERFACES/REPORT.md" \
  || log "report generation failed; see $OUT/report_$STAMP.log"

log "done"
