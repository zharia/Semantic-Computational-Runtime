#!/usr/bin/env bash
# build_sim_server.sh — standalone IPC simulation server (milestone 0008).
#
#   applications/godot/build/scr_sim_server   ← mojo build server/main.mojo
#   applications/godot/build/libscr_sim.so    ← built if missing (harness FFI leg)
#
# MUST be run from the repository root (or anywhere — it re-anchors itself).
# Paths are computed from this script's location; no absolute paths (AP-4).
#
# Usage:  bash applications/godot/scripts/build_sim_server.sh
# Gate:   python3 applications/godot/tests/ipc/ipc_harness.py --self-test

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"   # repo root
cd "${ROOT}"

MOJO="${ROOT}/.venv/bin/mojo"
APP="applications/godot"
OUT_DIR="${APP}/build"
SERVER_OUT="${OUT_DIR}/scr_sim_server"
LIB_OUT="${OUT_DIR}/libscr_sim.so"

echo "== SCR IPC server build (milestone 0008) =="
echo "mojo    : $("${MOJO}" --version 2>/dev/null | head -1)"

mkdir -p "${OUT_DIR}"

# Server binary. `-I .` is resolved from src/mojo (module root for
# server/session, transport/framing, sim/*, snapshot/*).
echo
echo "== [1/2] simulation server =="
(
    cd "${APP}/src/mojo"
    "${MOJO}" build server/main.mojo -I . -o "../../build/scr_sim_server"
)
ls -l "${SERVER_OUT}"

# Shared library for the harness in-process leg (same entry as
# build_godot_provider.sh / tests/mojo/README.md). Built only when absent so
# the provider build stays the owner of its own rebuilds.
echo
echo "== [2/2] simulation shared library (Mojo C ABI) =="
if [[ -f "${LIB_OUT}" ]]; then
    echo "present: ${LIB_OUT} (skip — delete it to force a rebuild)"
else
    (
        cd "${APP}/src/mojo"
        "${MOJO}" build export/abi.mojo -I src/mojo --emit shared-lib \
            -o ../../build/libscr_sim.so
    )
    ls -l "${LIB_OUT}"
fi

echo
echo "== summary =="
echo "server : ${SERVER_OUT}"
echo "library: ${LIB_OUT}"
echo "next   : python3 ${APP}/tests/ipc/ipc_harness.py --self-test"
