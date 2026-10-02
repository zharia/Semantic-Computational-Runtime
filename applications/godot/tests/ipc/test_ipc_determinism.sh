#!/usr/bin/env bash
# test_ipc_determinism.sh — 0008 §3.4 / AP-16 byte-identity gate (Sprint 02).
#
# Runs the SAME deterministic input script through both transport legs for
# N fixed ticks and byte-compares the concatenated snapshots:
#
#   leg A: in-process  (ipc_harness.py --in-process, drives libscr_sim.so)
#   leg B: socket      (ipc_harness.py --spawn, drives build/scr_sim_server
#                       over UDS with SCRT framing, manual pace)
#
# Framing must be transparent: identical payload bytes in, identical bytes
# out. Any difference fails the gate (prints the first differing offset).
#
# Usage: tests/ipc/test_ipc_determinism.sh [TICKS]   (default 600)
set -u

cd "$(dirname "$0")/../.." || exit 1
APP="$PWD"
TICKS="${1:-600}"
TMP="$(mktemp -d /tmp/scr_det.XXXXXX)"
SOCK="$TMP/sim.sock"
INPROC="$TMP/inproc.bin"
SOCKBIN="$TMP/socket.bin"
LOG="$TMP/server.log"
trap 'rm -rf "$TMP"' EXIT

HARNESS="python3 tests/ipc/ipc_harness.py"

echo "== [1/2] in-process leg: $TICKS ticks =="
if ! $HARNESS --in-process --ticks "$TICKS" --seed 1 --out "$INPROC" \
    >"$TMP/inproc.log" 2>&1; then
    echo "FAIL: in-process leg"
    cat "$TMP/inproc.log"
    exit 1
fi

echo "== [2/2] socket leg: $TICKS ticks over UDS =="
if ! $HARNESS --spawn --socket "$SOCK" --ticks "$TICKS" --seed 1 \
    --out "$SOCKBIN" >"$TMP/socket.log" 2>&1; then
    echo "FAIL: socket leg"
    cat "$TMP/socket.log"
    exit 1
fi

A_SIZE=$(stat -c %s "$INPROC")
B_SIZE=$(stat -c %s "$SOCKBIN")

if [ "$A_SIZE" -eq 0 ] || [ "$B_SIZE" -eq 0 ]; then
    echo "FAIL: empty output (inproc=$A_SIZE socket=$B_SIZE bytes)"
    exit 1
fi

if ! cmp -s "$INPROC" "$SOCKBIN"; then
    OFF=$(cmp "$INPROC" "$SOCKBIN" 2>/dev/null | sed -n 's/.*differ: *byte \([0-9]*\),.*/\1/p')
    echo "FAIL: snapshots differ at byte offset ${OFF:-?} (inproc=$A_SIZE, socket=$B_SIZE)"
    exit 1
fi

echo "PASS: socket leg == in-process leg ($TICKS ticks, $A_SIZE bytes, byte-identical)"
exit 0
