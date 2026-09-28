#!/usr/bin/env bash
# test_schema_mismatch.sh — negative test (milestone_0002 exit criterion,
# milestone_0003 AP-13): "schema_version mismatch between adapter and sim is
# rejected loudly".
#
# Builds a stub libscr_sim whose scr_sim_schema_version() returns
# SCR_SIM_SCHEMA_VER + 1 (derived from adapter/scr_godot_abi.h, so future
# bumps keep the stub one ahead), then loads it through
# adapter/scr_sim_loader.h — the exact loader the GDExtension adapter uses —
# and asserts refusal (SCR_LOAD_ERR_SCHEMA).
# When the real library (current SCR_SIM_SCHEMA_VER) is present it is loaded
# as a control (must be accepted), proving the refusal is mismatch-specific.
#
# Usage (repo root or anywhere):  bash applications/godot/tests/test_schema_mismatch.sh
# Exit 0 = pass, 1 = fail.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"          # applications/godot/
ADAPTER_DIR="${APP_DIR}/providers/render/graphics/godot/adapter"
REAL_LIB="${APP_DIR}/build/libscr_sim.so"

TMP_DIR="$(mktemp -d)"
cleanup() { rm -rf "${TMP_DIR}"; }
trap cleanup EXIT

STUB_SO="${TMP_DIR}/libscr_sim_schema2.so"
RUNNER="${TMP_DIR}/schema_mismatch_test"

CC="${CC:-cc}"

echo "== schema mismatch negative test =="
echo "[build] stub library (scr_sim_schema_version() -> SCR_SIM_SCHEMA_VER + 1)"
"${CC}" -std=c11 -shared -fPIC -Wall -DSCR_STUB_IMPL \
    -I"${ADAPTER_DIR}" \
    -o "${STUB_SO}" "${SCRIPT_DIR}/schema_mismatch_test.c"

echo "[build] test runner (uses adapter/scr_sim_loader.h verbatim)"
"${CC}" -std=c11 -Wall -DSCR_TEST_MAIN \
    -I"${ADAPTER_DIR}" \
    -o "${RUNNER}" "${SCRIPT_DIR}/schema_mismatch_test.c" -ldl

echo "[run]"
if [[ -f "${REAL_LIB}" ]]; then
    "${RUNNER}" "${STUB_SO}" "${REAL_LIB}"
else
    echo "  note: real library ${REAL_LIB} not built — control check skipped"
    "${RUNNER}" "${STUB_SO}"
fi

echo "PASS — negative test: loader refuses schema mismatch."
