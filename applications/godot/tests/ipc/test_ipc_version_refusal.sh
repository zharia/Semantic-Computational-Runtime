#!/usr/bin/env bash
# test_ipc_version_refusal.sh — version/capability refusal over IPC
# (milestone 0008 §7 exit criterion, 0008 AP-17).
#
# (a) harness → server: HELLO with wrong schema/abi/proto, plus an unknown
#     HELLO flag bit ⇒ server replies ERROR{code} + closes, exits non-zero,
#     and never sends a SNAPSHOT (asserted inside ipc_harness.expect_refusal).
#
# (b) fake_server → adapter client (0008 Sprint 03): the adapter spawns
#     tests/ipc/fake_server.py as its sim server, and the fake server answers
#     with an ERROR frame or with a mismatched HELLO_OK version triple. The
#     adapter MUST refuse loudly at startup — no snapshot, no ticking, and
#     above all NO silent fallback to the in-process transport (the same
#     startup gate as scr_sim_loader.h, AP-17). The scene stays alive but
#     inert for SCR_TEST_WINDOW seconds so the log can be inspected.
#
# MUST be run from the repository root (or anywhere — it re-anchors itself).
#
# Usage:  bash applications/godot/tests/ipc/test_ipc_version_refusal.sh
# Exit:   0 = every refusal behaved loudly, 1 = acceptance/silence detected.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${SCRIPT_DIR}/../../../.." && pwd)"   # repo root
cd "${ROOT}"

GODOT_BIN="${GODOT_BIN:-godot}"
PROJ="${ROOT}/applications/godot/godot"
HARNESS="${SCRIPT_DIR}/ipc_harness.py"
FAKE="${SCRIPT_DIR}/fake_server.py"
DRIVER="${ROOT}/applications/godot/tests/godot/godot_socket_supervision_test.gd"
SERVER="applications/godot/build/scr_sim_server"
LIB="applications/godot/build/libscr_sim.so"

TMP="$(mktemp -d /tmp/scr_ipc_refuse.XXXXXX)"
GODOT_PID=""
cleanup() {
    if [[ -n "${GODOT_PID}" ]] && kill -0 "${GODOT_PID}" 2>/dev/null; then
        kill -TERM "${GODOT_PID}" 2>/dev/null
        wait "${GODOT_PID}" 2>/dev/null
    fi
    rm -rf "${TMP}"
}
trap cleanup EXIT

echo "== IPC version refusal (milestone 0008) =="

if [[ ! -x "${SERVER}" || ! -f "${LIB}" ]]; then
    echo "binaries missing — building via scripts/build_sim_server.sh"
    bash applications/godot/scripts/build_sim_server.sh
fi

rc=0

# =============================================================================
# Direction (a): harness → server
# =============================================================================
echo
echo "-- direction (a): harness -> server"
for case in "--wrong-schema 99" "--wrong-abi 99" "--wrong-proto 99" "--wrong-flags 4"; do
    echo
    echo "-- case: python3 ${HARNESS} ${case}"
    if python3 "${HARNESS}" ${case}; then
        echo "case OK: loud ERROR + close, no SNAPSHOT"
    else
        echo "case FAILED: ${case}" >&2
        rc=1
    fi
done

# =============================================================================
# Direction (b): fake_server → adapter client
# =============================================================================
echo
echo "-- direction (b): fake_server -> adapter client"
chmod +x "${FAKE}"

# adapter_refusal <fake mode> <grep that must appear in the Godot log>
adapter_refusal() {
    local mode="$1" expect="$2"
    local log="${TMP}/b_${mode}.log"
    echo
    echo "-- case: adapter vs fake_server.py --mode ${mode}"
    SCR_FAKE_MODE="${mode}" \
    SCR_SIM_TRANSPORT=socket SCR_TEST_MODE=refusal SCR_TEST_WINDOW=4 \
    SCR_SIM_SERVER_BIN="${FAKE}" SCR_SIM_SOCKET="${TMP}/${mode}.sock" \
        timeout 120 "${GODOT_BIN}" --headless --path "${PROJ}" -s "${DRIVER}" \
        >"${log}" 2>&1
    local grc=$?
    local bad=0

    [[ ${grc} -eq 0 ]] || { echo "  FAIL godot exit ${grc}" >&2; bad=1; }
    grep -qF "${expect}" "${log}" \
        || { echo "  FAIL missing refusal line: ${expect}" >&2; bad=1; }
    grep -q "transport init failed with code" "${log}" \
        || { echo "  FAIL no 'transport init failed' diagnostic" >&2; bad=1; }

    # The three ways a wrong server could sneak through — all forbidden:
    grep -q "SCR: sim loaded" "${log}" \
        && { echo "  FAIL adapter reported a loaded sim" >&2; bad=1; }
    grep -q "transport=SocketTransport handshake OK" "${log}" \
        && { echo "  FAIL handshake reported OK despite refusal" >&2; bad=1; }
    grep -q "SCR: transport=InprocTransport" "${log}" \
        && { echo "  FAIL silent fallback to the in-process transport" >&2; bad=1; }
    grep -q "tick=1 seq=" "${log}" \
        && { echo "  FAIL the refusing server produced a snapshot" >&2; bad=1; }

    if [[ ${bad} -eq 0 ]]; then
        echo "  PASS ${mode}: refused loudly, inert, no snapshot, no fallback"
    else
        echo "  ---- log ----" >&2
        grep -E "SCR:|ERROR:|scr-fake-server" "${log}" | sed 's/^/    /' >&2
        rc=1
    fi
}

adapter_refusal "error-frame" "server refused the handshake: ERROR code=2"
adapter_refusal "bad-abi"     "ABI mismatch: server 3, adapter 2 (refusing to run)"
adapter_refusal "bad-schema"  "schema mismatch: server 8, adapter 7 (refusing to run)"
adapter_refusal "bad-proto"   "proto mismatch: server 2, adapter 1 (refusing to run)"

# The adapter must not leave its (misbehaving) server behind — AP-18.
sleep 1
if pgrep -x fake_server.py >/dev/null 2>&1; then
    echo "FAIL: fake_server.py still running after the refusals" >&2
    pgrep -a fake_server.py >&2 || true
    rc=1
else
    echo "PASS: no fake_server.py orphan after the refusals"
fi

echo
if [[ "${rc}" -eq 0 ]]; then
    echo "PASS — every mismatch was refused loudly in both directions"
    echo "       (harness->server ERROR+close+non-zero exit, "
    echo "        fake_server->adapter init failure + inert scene)."
else
    echo "FAIL — a mismatch was accepted, silent, or produced a SNAPSHOT." >&2
fi
exit "${rc}"
