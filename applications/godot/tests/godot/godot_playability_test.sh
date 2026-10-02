#!/usr/bin/env bash
# godot_playability_test.sh — runner for the scripted-input playability gate.
#
# Spec: milestone_0002 §7 exit criterion 3. Runs godot_playability_test.gd in
# headless game mode (no display needed — physics + input map work headless).
#
# Exit: 0 all checks PASS · 1 any check FAIL · 2 harness/engine failure.
#
# MANUAL PROCEDURE (documented fallback if script-driven input is ever blocked
# by an engine quirk): open the scene interactively
#     godot --path applications/godot/godot
# then verify by hand: click to capture mouse, look around (yaw/pitch), WASD
# walk on the beach, Shift sprint covers ground faster, Space jumps ~1.5 u up
# and lands back on terrain (never falls through into the seabed), Esc releases
# the mouse. Record the session result in docs/04_simulation_engine.md §8.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../../.." && pwd)"
PROJ="${REPO_ROOT}/applications/godot/godot"
GODOT_BIN="${GODOT_BIN:-godot}"
LOG="$(mktemp)"
trap 'rm -f "${LOG}"' EXIT

# Socket leg: the F-leg edit checks read the snapshot mirror only 2 physics
# frames after submit_edit. Under the server's default wall 60 Hz clock a
# headless run burns those frames in <16 ms — before the server's next wall
# tick returns the edited snapshot — so the mirror reads stale (F5/F6/F13
# flake). Client-paced mode (SCR_SIM_IPC_PACE=manual, 104_contract.md §2)
# makes every physics frame issue CMD_TICK, i.e. request/response per frame,
# matching the in-process leg the checks were written against. Same default
# as godot_screenshot.sh: only when the caller did not choose a pace
# explicitly (deliberate wall runs pass SCR_SIM_IPC_PACE=wall).
if [[ "${SCR_SIM_TRANSPORT:-}" == "socket" && -z "${SCR_SIM_IPC_PACE+x}" ]]; then
    export SCR_SIM_IPC_PACE=manual
fi

cd "${REPO_ROOT}"
timeout 300 "${GODOT_BIN}" --headless --path "${PROJ}" \
    -s "${SCRIPT_DIR}/godot_playability_test.gd" >"${LOG}" 2>&1
rc=$?

grep -E "^PASS:|^FAIL:|^NOTE:|^INFO:|^PLAYABILITY|^SCREENSHOT|SCRIPT ERROR" "${LOG}"

if [[ ${rc} -ne 0 ]]; then
    echo "godot_playability_test: FAIL (godot exit ${rc})" >&2
    exit 1
fi
if ! grep -q "^PLAYABILITY: PASS" "${LOG}"; then
    echo "godot_playability_test: FAIL (no PASS verdict)" >&2
    exit 1
fi
echo "godot_playability_test: PASS"
exit 0
