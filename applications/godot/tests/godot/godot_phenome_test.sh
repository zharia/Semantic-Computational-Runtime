#!/usr/bin/env bash
# godot_phenome_test.sh — runner for the sprint 03 phenome renderer gate.
#
# Spec: milestone_0010 sprints/sprint_03_renderer.md (R1-R8). Runs
# godot_phenome_test.gd headless: AP-24 goldens conformance (84 rows),
# stage monotonicity, trait modulation, LOD floor + hysteresis, then the
# live island scene (95 seed-1 plants, mesh cache, band refill, stability).
#
# Exit: 0 all checks PASS · 1 any check FAIL · 2 harness/engine failure.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../../.." && pwd)"
PROJ="${REPO_ROOT}/applications/godot/godot"
GODOT_BIN="${GODOT_BIN:-godot}"
LOG="$(mktemp)"
trap 'rm -f "${LOG}"' EXIT

cd "${REPO_ROOT}"
timeout 300 "${GODOT_BIN}" --headless --path "${PROJ}" \
    -s "${SCRIPT_DIR}/godot_phenome_test.gd" >"${LOG}" 2>&1
rc=$?

grep -E "^PASS:|^FAIL:|^PHENOME:|^NOTE:|SCRIPT ERROR" "${LOG}"

if [[ ${rc} -ne 0 ]]; then
    echo "godot_phenome_test: FAIL (godot exit ${rc})" >&2
    exit 1
fi
if grep -qE "^ERROR:" "${LOG}"; then
    echo "godot_phenome_test: FAIL (ERROR: lines in log)" >&2
    grep -E "^ERROR:" "${LOG}" | head -20 >&2
    exit 1
fi
if ! grep -q "^PHENOME: PASS" "${LOG}"; then
    echo "godot_phenome_test: FAIL (no PASS verdict)" >&2
    exit 1
fi
echo "godot_phenome_test: PASS"
exit 0
