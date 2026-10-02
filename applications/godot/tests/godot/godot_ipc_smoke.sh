#!/usr/bin/env bash
# godot_ipc_smoke.sh — 0008 §2.2 AP-18: the main scene over the SOCKET
# transport (Sprint 02).
#
# Starts build/scr_sim_server (wall pace, seed 1) on a private UDS, then
# runs the main scene headless with:
#   SCR_SIM_TRANSPORT=socket
#   SCR_SIM_SOCKET=<private path>
# The adapter connects, handshakes (proto/abi/schema), streams snapshots
# from the SERVER's fixed 60 Hz clock, and sends BYE on teardown.
#
# PASS requires ALL of:
#   1. godot exit code 0
#   2. "SCR GDExtension adapter registered"
#   3. "SCR: sim loaded (abi …, schema …)"          (same line as in-process)
#   4. "SCR: transport=SocketTransport handshake OK" (selection + handshake)
#   5. ZERO hard-error lines (SCRIPT ERROR / Failed to load script /
#      Cannot open file / ERROR:) — the socket path must be as clean as the
#      in-process default (godot_load_test.sh remains the default gate)
#   6. server exit 0 (saw BYE and shut down cleanly)
#
# Deviations from godot_load_test.sh header are ONLY the env selection and
# the two added positive greps (3) and (4).
#
# Exit: 0 pass, 1 fail (details on stderr).

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../../.." && pwd)"
PROJ="${REPO_ROOT}/applications/godot/godot"
GODOT_BIN="${GODOT_BIN:-godot}"
SERVER="${REPO_ROOT}/applications/godot/build/scr_sim_server"

TMP="$(mktemp -d /tmp/scr_ipc_smoke.XXXXXX)"
SOCK="${TMP}/sim.sock"
OUT="${TMP}/godot.log"
SOUT="${TMP}/server.log"
SERVER_PID=""
cleanup() {
    if [[ -n "${SERVER_PID}" ]] && kill -0 "${SERVER_PID}" 2>/dev/null; then
        kill -TERM "${SERVER_PID}" 2>/dev/null
        wait "${SERVER_PID}" 2>/dev/null
    fi
    rm -rf "${TMP}"
}
trap cleanup EXIT

cd "${REPO_ROOT}"

if [[ ! -x "${SERVER}" ]]; then
    echo "FAIL: ${SERVER} missing — run scripts/build_sim_server.sh" >&2
    exit 1
fi

# Server: cwd = repo root so runtime_init finds materials_catalog.json.
# Stale socket can't exist (fresh mktemp dir).
"${SERVER}" --socket "${SOCK}" --seed 1 --pace wall >"${SOUT}" 2>&1 &
SERVER_PID=$!

# Wait for the server to bind (it binds before blocking on accept).
for _ in $(seq 1 100); do
    [[ -S "${SOCK}" ]] && break
    if ! kill -0 "${SERVER_PID}" 2>/dev/null; then
        echo "FAIL: server exited before binding" >&2
        cat "${SOUT}" >&2
        exit 1
    fi
    sleep 0.05
done
if [[ ! -S "${SOCK}" ]]; then
    echo "FAIL: server socket never appeared" >&2
    cat "${SOUT}" >&2
    exit 1
fi

SCR_SIM_TRANSPORT=socket SCR_SIM_SOCKET="${SOCK}" \
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

if ! grep -q "SCR: sim loaded (abi " "${OUT}"; then
    echo "FAIL: SCR: sim loaded line not found" >&2
    fail=1
else
    echo "PASS: SCR: sim loaded line present"
fi

if ! grep -q "SCR: transport=SocketTransport handshake OK" "${OUT}"; then
    echo "FAIL: socket transport handshake line not found" >&2
    fail=1
else
    echo "PASS: transport=SocketTransport handshake OK"
fi

# Same hard-error allowlist as godot_load_test.sh (empty for ERROR:).
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

# --- server side ------------------------------------------------------------
wait "${SERVER_PID}"
src=$?
SERVER_PID=""
if [[ ${src} -ne 0 ]]; then
    echo "FAIL: server exited ${src} (expected 0 after BYE)" >&2
    cat "${SOUT}" >&2
    fail=1
else
    echo "PASS: server exited 0 (BYE received)"
fi

if [[ ${fail} -ne 0 ]]; then
    echo "godot_ipc_smoke: FAIL" >&2
    exit 1
fi
echo "godot_ipc_smoke: PASS"
exit 0
