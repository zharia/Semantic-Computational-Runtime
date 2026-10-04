#!/usr/bin/env bash
# test_schema_mismatch.sh — negative test (milestone_0002 exit criterion,
# milestone_0003 AP-13, milestone_0007 invariant 9): "ABI/schema_version
# mismatch between adapter and sim is rejected loudly".
#
# Builds THREE stub libscr_sim libraries:
#   - stub A: scr_sim_schema_version() returns SCR_SIM_SCHEMA_VER + 1
#     (derived from adapter/scr_godot_abi.h, so future bumps keep the stub
#     one ahead),
#   - stub C (-DSCR_STUB_SCHEMA_OLD): scr_sim_schema_version() returns
#     SCR_SIM_SCHEMA_VER - 1 — the stale schema-6 library must be refused
#     after the 6 -> 7 bump (104_contract §3/§7),
#   - stub B (-DSCR_STUB_ABI): scr_sim_abi_version() returns
#     SCR_SIM_ABI_VERSION + 1 while the schema is correct (ABI 1->2
#     refusal, milestone_0007),
# then loads all three through adapter/scr_sim_loader.h — the exact loader the
# GDExtension adapter uses — and asserts refusal (SCR_LOAD_ERR_SCHEMA /
# SCR_LOAD_ERR_ABI). When the real library (current schema) is present it
# is loaded as a control (must be accepted), proving the refusal is
# mismatch-specific.
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
STUB_OLD_SO="${TMP_DIR}/libscr_sim_schema_old.so"
ABI_STUB_SO="${TMP_DIR}/libscr_sim_abi.so"
RUNNER="${TMP_DIR}/schema_mismatch_test"

CC="${CC:-cc}"

echo "== schema/ABI mismatch negative test =="
echo "[build] stub library A (scr_sim_schema_version() -> SCR_SIM_SCHEMA_VER + 1)"
"${CC}" -std=c11 -shared -fPIC -Wall -DSCR_STUB_IMPL \
    -I"${ADAPTER_DIR}" \
    -o "${STUB_SO}" "${SCRIPT_DIR}/schema_mismatch_test.c"

echo "[build] stub library C (scr_sim_schema_version() -> SCR_SIM_SCHEMA_VER - 1)"
"${CC}" -std=c11 -shared -fPIC -Wall -DSCR_STUB_IMPL -DSCR_STUB_SCHEMA_OLD \
    -I"${ADAPTER_DIR}" \
    -o "${STUB_OLD_SO}" "${SCRIPT_DIR}/schema_mismatch_test.c"

echo "[build] stub library B (scr_sim_abi_version() -> SCR_SIM_ABI_VERSION + 1)"
"${CC}" -std=c11 -shared -fPIC -Wall -DSCR_STUB_IMPL -DSCR_STUB_ABI \
    -I"${ADAPTER_DIR}" \
    -o "${ABI_STUB_SO}" "${SCRIPT_DIR}/schema_mismatch_test.c"

echo "[build] test runner (uses adapter/scr_sim_loader.h verbatim)"
"${CC}" -std=c11 -Wall -DSCR_TEST_MAIN \
    -I"${ADAPTER_DIR}" \
    -o "${RUNNER}" "${SCRIPT_DIR}/schema_mismatch_test.c" -ldl

echo "[run]"
if [[ -f "${REAL_LIB}" ]]; then
    "${RUNNER}" "${STUB_SO}" "${STUB_OLD_SO}" "${ABI_STUB_SO}" "${REAL_LIB}"
else
    echo "  note: real library ${REAL_LIB} not built — control check skipped"
    "${RUNNER}" "${STUB_SO}" "${STUB_OLD_SO}" "${ABI_STUB_SO}"
fi

echo "PASS — negative test: loader refuses schema and ABI mismatch."
