#!/usr/bin/env bash
# test_ipc_crash_restart.sh — 0008 Sprint 03 supervised restart + cap
# (milestone 0008 §1.1 supervision row, §7 exit criterion "supervised
# restart", 0008 AP-18).
#
# Three legs, all against the SAME contract:
#
#   A  adapter owns the session (0008 §1.1): the Godot adapter spawns
#      build/scr_sim_server itself (default socket + default binary — no env
#      at all but SCR_SIM_TRANSPORT=socket), the test kills -9 the ONE server
#      it owns, and the adapter must respawn it: fresh session, same seed,
#      tick reset backwards, snapshots resume, exactly one server during the
#      run, none afterwards (no orphan = AP-18).
#
#   B  restart cap (0008 §1.1: > 5 restarts / 30 s => fatal, stop stepping):
#      SCR_SIM_SERVER_BIN=tests/ipc/fake_server.py in crash-loop mode, which
#      handshakes and dies every session. The adapter must restart exactly 5
#      times (6 spawns) and then go FATAL — loud, and no further spawns.
#
#   C  harness leg (ipc_harness.py --restart-check): kill + restart with the
#      client-side assertions the Godot log cannot make — envelope tick reset
#      and TERRAIN re-delivery (presence rule: first snapshot after init).
#
# Shell safety (mandatory): never pkill -f / killall. Servers are addressed
# by exact-name counts (pgrep -x) and by PIDs this script itself observed;
# a pre-existing scr_sim_server makes the run refuse to start rather than
# touch somebody else's process.
#
# MUST be run from the repository root (or anywhere — it re-anchors itself).
#
# Usage:  bash applications/godot/tests/ipc/test_ipc_crash_restart.sh
# Exit:   0 = every leg passed, 1 = at least one assertion failed.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${SCRIPT_DIR}/../../../.." && pwd)"   # repo root
cd "${ROOT}"

GODOT_BIN="${GODOT_BIN:-godot}"
PROJ="${ROOT}/applications/godot/godot"
SERVER="${ROOT}/applications/godot/build/scr_sim_server"
FAKE="${SCRIPT_DIR}/fake_server.py"
HARNESS="${SCRIPT_DIR}/ipc_harness.py"
DRIVER="${ROOT}/applications/godot/tests/godot/godot_socket_supervision_test.gd"

TMP="$(mktemp -d /tmp/scr_ipc_crash.XXXXXX)"
GODOT_PID=""
CHILDREN=()

cleanup() {
    # Stop only what this script started, by PID; never pattern-kill.
    if [[ -n "${GODOT_PID}" ]] && kill -0 "${GODOT_PID}" 2>/dev/null; then
        kill -TERM "${GODOT_PID}" 2>/dev/null
        wait "${GODOT_PID}" 2>/dev/null
    fi
    for pid in "${CHILDREN[@]:-}"; do
        if [[ -n "${pid}" ]] && kill -0 "${pid}" 2>/dev/null; then
            kill -TERM "${pid}" 2>/dev/null
            wait "${pid}" 2>/dev/null
        fi
    done
    rm -rf "${TMP}"
}
trap cleanup EXIT

fail=0
note_ok() { echo "PASS: $1"; }
note_bad() { echo "FAIL: $1" >&2; fail=1; }

# Exact-name live count of the SCR sim server (never a pattern kill).
server_count() { pgrep -x scr_sim_server 2>/dev/null | wc -l; }
fake_count()   { pgrep -x fake_server.py 2>/dev/null | wc -l; }

assert_no_orphans() {
    local n
    n="$(server_count)"
    if [[ "${n}" -ne 0 ]]; then
        note_bad "orphans: ${n} scr_sim_server still running (AP-18)"
        # Report the exact PIDs; kill only the ones this run recorded.
        pgrep -a scr_sim_server >&2 || true
    else
        note_ok "no scr_sim_server orphan after the run (AP-18)"
    fi
}

echo "== IPC crash/restart (milestone 0008 Sprint 03) =="

if [[ ! -x "${SERVER}" ]]; then
    echo "building build/scr_sim_server ..."
    bash "${ROOT}/applications/godot/scripts/build_sim_server.sh"
fi
if [[ ! -x "${SERVER}" ]]; then
    echo "FAIL: ${SERVER} missing" >&2
    exit 1
fi
if [[ ! -f "${FAKE}" ]]; then
    echo "FAIL: ${FAKE} missing" >&2
    exit 1
fi
chmod +x "${FAKE}"

# --- pre-flight: do not touch a server this run did not start --------------
if [[ "$(server_count)" -ne 0 ]]; then
    echo "FAIL: a scr_sim_server is already running; refusing to run this test" >&2
    echo "      (list it first: pgrep -a scr_sim_server)" >&2
    exit 1
fi

# =============================================================================
# Phase A — the adapter owns the session: kill -9, respawn, tick reset, no orphans
# =============================================================================
echo
echo "-- phase A: adapter-supervised kill + respawn (default socket + binary)"
ALOG="${TMP}/a.log"
SCR_SIM_TRANSPORT=socket SCR_TEST_MODE=restart \
    timeout 180 "${GODOT_BIN}" --headless --path "${PROJ}" -s "${DRIVER}" \
    >"${ALOG}" 2>&1 &
GODOT_PID=$!

# Wait for the adapter-spawned server to exist AND to have been up for a few
# seconds (handshake + a few ticks), then kill the exact PID we observed.
PID_A=""
for _ in $(seq 1 240); do
    if ! kill -0 "${GODOT_PID}" 2>/dev/null; then
        break
    fi
    mapfile -t pids < <(pgrep -x scr_sim_server 2>/dev/null)
    if [[ "${#pids[@]}" -eq 1 ]]; then
        age="$(ps -o etimes= -p "${pids[0]}" 2>/dev/null | tr -d ' ')"
        if [[ -n "${age}" && "${age}" -ge 3 ]]; then
            PID_A="${pids[0]}"
            break
        fi
    elif [[ "${#pids[@]}" -gt 1 ]]; then
        note_bad "phase A: ${#pids[@]} scr_sim_server at once (single-session invariant)"
        break
    fi
    sleep 0.25
done

PID_B=""
if [[ -n "${PID_A}" ]]; then
    echo "   killing server pid ${PID_A} (SIGKILL)"
    kill -9 "${PID_A}" 2>/dev/null
    # The adapter must respawn: same count, different PID.
    for _ in $(seq 1 240); do
        mapfile -t pids < <(pgrep -x scr_sim_server 2>/dev/null)
        if [[ "${#pids[@]}" -eq 1 && "${pids[0]}" != "${PID_A}" ]]; then
            PID_B="${pids[0]}"
            break
        fi
        if ! kill -0 "${GODOT_PID}" 2>/dev/null; then
            break
        fi
        sleep 0.25
    done
    if [[ -n "${PID_B}" ]]; then
        note_ok "adapter respawned the server: pid ${PID_A} -> pid ${PID_B}"
    else
        note_bad "phase A: no respawn after SIGKILL of pid ${PID_A}"
    fi
else
    note_bad "phase A: adapter never spawned a server (see ${ALOG})"
fi

wait "${GODOT_PID}"
ARC=$?
GODOT_PID=""
if [[ ${ARC} -eq 0 ]]; then
    note_ok "phase A godot exit 0"
else
    note_bad "phase A godot exit ${ARC}"
fi

grep -E "SCR-TEST:|SCR: socket transport:|session restart|tick reset|snapshots resumed" "${ALOG}" | sed 's/^/   | /'

grep -q "SCR-TEST: SUPERVISION PASS" "${ALOG}" \
    && note_ok "driver: tick reset + snapshots resumed (end-to-end via HUD)" \
    || note_bad "driver: no SUPERVISION PASS in the log"
grep -q "SCR: socket transport: session restart #1" "${ALOG}" \
    && note_ok "adapter logged session restart #1 (fresh session, tick reset)" \
    || note_bad "adapter did not log session restart #1"
grep -q "snapshots resumed after restart #1" "${ALOG}" \
    && note_ok "adapter logged snapshots resumed after restart #1" \
    || note_bad "adapter did not log snapshots resumed"
grep -q "SCR: socket transport: spawned sim server pid" "${ALOG}" \
    && note_ok "adapter logged its spawned server pid" \
    || note_bad "adapter did not log a spawned server pid"

# Fresh session, same seed: the server banner must appear once per session.
n_start="$(grep -c "\[scr-sim-server\] start seed=1 " "${ALOG}" || true)"
[[ "${n_start}" -ge 2 ]] \
    && note_ok "server started ${n_start}x with seed 1 (fresh session, same seed)" \
    || note_bad "server 'start seed=1' appeared ${n_start}x, expected >= 2"

# Tick reset observed on the SERVER side too (each session begins at tick 1).
n_t1="$(grep -c "tick=1 seq=" "${ALOG}" || true)"
[[ "${n_t1}" -ge 2 ]] \
    && note_ok "tick=1 emitted ${n_t1}x (a session restarted)" \
    || note_bad "tick=1 emitted ${n_t1}x, expected >= 2"

# The only hard errors allowed are the two loud supervision notices.
unexpected="$(
    grep -E "SCRIPT ERROR|Failed to load script|Cannot open file|ERROR:" "${ALOG}" \
        | grep -vE "connection to the sim server closed" || true
)"
if [[ -z "${unexpected}" ]]; then
    note_ok "every ERROR line is a supervised-restart notice (nothing else broke)"
else
    note_bad "unexpected hard error line(s):"
    printf '%s\n' "${unexpected}" | sed 's/^/    /' >&2
fi

sleep 1
assert_no_orphans

# =============================================================================
# Phase B — restart cap: > 5 restarts / 30 s => fatal, stop stepping
# =============================================================================
echo
echo "-- phase B: fake_server.py crash-loop -> restart cap -> FATAL"
SPAWNS="${TMP}/spawns.log"
BLOG="${TMP}/b.log"
SCR_FAKE_SPAWN_LOG="${SPAWNS}" \
SCR_SIM_TRANSPORT=socket SCR_TEST_MODE=cap \
SCR_SIM_SERVER_BIN="${FAKE}" SCR_SIM_SOCKET="${TMP}/b.sock" \
    timeout 180 "${GODOT_BIN}" --headless --path "${PROJ}" -s "${DRIVER}" \
    >"${BLOG}" 2>&1 &
GODOT_PID=$!
wait "${GODOT_PID}"
BRC=$?
GODOT_PID=""
if [[ ${BRC} -eq 0 ]]; then
    note_ok "phase B godot exit 0"
else
    note_bad "phase B godot exit ${BRC}"
fi

grep -E "SCR: socket transport:|SCR-TEST:" "${BLOG}" | sed 's/^/   | /'

n_spawn=0
if [[ -f "${SPAWNS}" ]]; then
    n_spawn="$(wc -l <"${SPAWNS}" | tr -d ' ')"
fi
[[ "${n_spawn}" -eq 6 ]] \
    && note_ok "server spawned exactly 6x (initial + 5 restarts)" \
    || note_bad "server spawned ${n_spawn}x, expected 6"

grep -q "SCR: socket transport: session restart #5" "${BLOG}" \
    && note_ok "5 restarts reported before the cap" \
    || note_bad "restart #5 not reported"

# ASCII-only patterns: the notice text carries em dashes (UTF-8) and this
# script must not depend on the caller's locale.
grep -q "FATAL" "${BLOG}" && grep -q "restart cap reached: 5 restarts within 30 s" "${BLOG}" \
    && note_ok "FATAL notice: restart cap reached (0008 §1.1)" \
    || note_bad "no FATAL restart-cap notice in the log"

grep -q "SCR-TEST: cap window elapsed" "${BLOG}" \
    && note_ok "scene kept running after the fatal stop (window elapsed)" \
    || note_bad "driver window never elapsed"

# No spawn must happen after the fatal stop.
sleep 2
n_spawn_after=0
if [[ -f "${SPAWNS}" ]]; then
    n_spawn_after="$(wc -l <"${SPAWNS}" | tr -d ' ')"
fi
[[ "${n_spawn_after}" -eq "${n_spawn}" ]] \
    && note_ok "no spawn after FATAL (stepping stopped for good)" \
    || note_bad "spawns kept coming after FATAL (${n_spawn} -> ${n_spawn_after})"

nf="$(fake_count)"
if [[ "${nf}" -eq 0 ]]; then
    note_ok "no fake_server.py process left (AP-18)"
else
    note_bad "${nf} fake_server.py process(es) left behind"
    pgrep -a fake_server.py >&2 || true
fi

# =============================================================================
# Phase C — harness leg: envelope tick reset + TERRAIN re-delivery
# =============================================================================
echo
echo "-- phase C: ipc_harness --restart-check (client-side envelope assertions)"
if python3 "${HARNESS}" --restart-check; then
    note_ok "harness restart leg passed (EOF, tick reset, TERRAIN re-delivery)"
else
    note_bad "harness restart leg failed"
fi

echo
if [[ "${fail}" -eq 0 ]]; then
    echo "test_ipc_crash_restart: PASS"
    exit 0
fi
echo "test_ipc_crash_restart: FAIL" >&2
exit 1
