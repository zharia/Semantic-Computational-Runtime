#!/usr/bin/env bash
# godot_load_test.sh — headless scene-load gate.
#
# Spec: milestone_0002 §7 exit criterion 1
#   "godot --headless --path applications/godot/godot loads the island scene
#    with no errors."
#
# Runs the MAIN scene (scenes/island.tscn, project.godot run/main_scene) in
# game mode headless for 120 frames (adapter _ready + physics ticks; the
# bounded --quit-after form — NEVER bare `--quit` with -e, see docs/02 for the
# upstream editor teardown SIGABRT quirk).
#
# PASS requires ALL of:
#   1. exit code 0
#   2. stdout/stderr contains "SCR GDExtension adapter registered" (extension
#      actually loaded — sprint-03 gate)
#   3. ZERO lines matching hard-failure patterns:
#        SCRIPT ERROR                 — GDScript runtime/parse failure
#        Failed to load script        — script resource could not load
#        Cannot open file             — missing resource path
#        ERROR:                       — any engine/adapter error, including
#                                       adapter ERR_PRINT contract rejections
#   4. the specific MATERIALS decode error must NOT appear (blocker witness).
#
# ALLOWED (not failed on) — enumerated deliberately:
#   * WARNING: lines (e.g. missing uid on ext_resource, deprecation notes).
#     Warnings do not fail scene load; the exit-criteria wording is "no errors".
#     None were observed to gate-load failures during Sprint 04 bring-up; if a
#     new WARNING appears it is printed for review but does not fail this gate.
#   * The Godot version banner and "SCR: sim loaded (abi …, schema …)" info
#     lines (UtilityFunctions::print = stdout INFO, not ERROR).
#   * Nothing else: the allowlist is EMPTY for `ERROR:` — any ERROR line fails
#     (an adapter ERR_PRINT means a snapshot/scene contract violation, which
#     the honesty invariant forbids passing silently).
#
# Exit: 0 pass, 1 fail (details on stderr).

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../../.." && pwd)"
PROJ="${REPO_ROOT}/applications/godot/godot"
GODOT_BIN="${GODOT_BIN:-godot}"
OUT="$(mktemp)"
trap 'rm -f "${OUT}"' EXIT

cd "${REPO_ROOT}"
timeout 180 "${GODOT_BIN}" --headless --path "${PROJ}" --quit-after 120 \
    >"${OUT}" 2>&1
rc=$?

fail=0

if [[ ${rc} -ne 0 ]]; then
    echo "FAIL: godot exited ${rc}" >&2
    fail=1
fi

if ! grep -q "SCR GDExtension adapter registered" "${OUT}"; then
    echo "FAIL: GDExtension registration line not found" >&2
    fail=1
else
    echo "PASS: GDExtension adapter registered"
fi

# --- hard-failure patterns (see header for the full allowlist rationale) ----
hard="$(grep -nE "SCRIPT ERROR|Failed to load script|Cannot open file|ERROR:" "${OUT}" || true)"
if [[ -n "${hard}" ]]; then
    n_hard="$(printf '%s\n' "${hard}" | wc -l)"
    echo "FAIL: ${n_hard} hard error line(s); distinct messages:" >&2
    printf '%s\n' "${hard}" | sed 's/^[0-9]*://' | sed 's/[[:space:]]*$//' \
        | sort -u | sed 's/^/    /' >&2
    fail=1
else
    echo "PASS: zero SCRIPT ERROR / Failed to load script / Cannot open file / ERROR: lines"
fi

# --- blocker witness (kept as an explicit named check) ----------------------
if grep -q "MATERIALS: section_bytes" "${OUT}"; then
    echo "FAIL: snapshot decode rejected — MATERIALS framing mismatch" >&2
    echo "      (adapter/104_contract expect 12+36*N; sim encoder emits 4+36*N;" >&2
    echo "       see final report BLOCKER — adapter sources out of scope here)" >&2
    fail=1
fi

warnings="$(grep -c "WARNING:" "${OUT}" || true)"
echo "info: ${warnings} WARNING line(s) (allowed, printed for review)"
grep -n "WARNING:" "${OUT}" | sed 's/^[0-9]*:*/    /' | sort -u | head -20

if [[ ${fail} -ne 0 ]]; then
    echo "godot_load_test: FAIL" >&2
    exit 1
fi
echo "godot_load_test: PASS"
exit 0
