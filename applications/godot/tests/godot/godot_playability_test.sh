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
