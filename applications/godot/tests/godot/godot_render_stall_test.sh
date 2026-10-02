#!/usr/bin/env bash
# godot_render_stall_test.sh — 0008 §7 exit criterion "Render thread never
# blocks on I/O (structural + measured)" (0008 AP-15).
#
# (a) MEASURED: run the island scene over the socket transport, SIGSTOP the
#     ONE adapter-owned sim server for 2 s, and require that every main-loop
#     and physics iteration stayed under FRAME_DT_CLAMP (0.05 s) — a blocking
#     read on the frame path would show up as a 2 s gap. Also: no ERROR: line
#     (a stall is not an error), and no restart (a paused server is alive, so
#     supervision must NOT treat it as a crash).
#
# (b) STRUCTURAL: strip comments/strings from scr_godot_adapter.cpp and
#     require zero socket syscalls (socket|connect|recv|send|read|write) —
#     they may only live in transport_socket.cpp (worker thread), which is
#     the positive control.
#
# Shell safety (mandatory): never pkill -f / killall. The stall targets the
# exact PID this script observed, and only after verifying it is the single
# scr_sim_server of this run.
#
# MUST be run from the repository root (or anywhere — it re-anchors itself).
#
# Usage:  bash applications/godot/tests/godot/godot_render_stall_test.sh
# Exit:   0 = pass, 1 = fail (details on stderr).

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${SCRIPT_DIR}/../../../.." && pwd)"   # repo root
cd "${ROOT}"

GODOT_BIN="${GODOT_BIN:-godot}"
PROJ="${ROOT}/applications/godot/godot"
ADAPTER_DIR="${ROOT}/applications/godot/providers/render/graphics/godot/adapter"
ADAPTER_SRC="${ADAPTER_DIR}/scr_godot_adapter.cpp"
SOCK_SRC="${ADAPTER_DIR}/transport_socket.cpp"
DRIVER="${SCRIPT_DIR}/godot_render_stall_test.gd"

WINDOW=14        # seconds the driver measures (see the .gd)
STALL_SECS=2     # how long the server is SIGSTOPped
FRAME_DT_CLAMP=0.05

TMP="$(mktemp -d /tmp/scr_stall.XXXXXX)"
GODOT_PID=""
cleanup() {
    if [[ -n "${GODOT_PID}" ]] && kill -0 "${GODOT_PID}" 2>/dev/null; then
        kill -TERM "${GODOT_PID}" 2>/dev/null
        wait "${GODOT_PID}" 2>/dev/null
    fi
    rm -rf "${TMP}"
}
trap cleanup EXIT

fail=0
note_ok() { echo "PASS: $1"; }
note_bad() { echo "FAIL: $1" >&2; fail=1; }

echo "== IPC render-stall test (milestone 0008 §7 / AP-15) =="

# =============================================================================
# (b) structural grep gate — no Godot needed, runs first
# =============================================================================
echo
echo "-- structural gate: socket syscalls must live only in transport_socket.cpp"
python3 - "${ADAPTER_SRC}" "${SOCK_SRC}" <<'PY'
import re
import sys

adapter_src, sock_src = sys.argv[1], sys.argv[2]
SYSCALLS = ["socket", "connect", "recv", "send", "read", "write"]
# A slightly wider set is reported informationally (never gates).
EXTRA = ["bind", "listen", "accept", "poll", "select", "epoll"]


def strip(src: str) -> str:
    """Remove block comments, line comments and string/char literals so the
    scan sees code, not prose (the file header names recv/send on purpose)."""
    src = re.sub(r"/\*.*?\*/", " ", src, flags=re.S)
    src = re.sub(r"//[^\n]*", " ", src)
    src = re.sub(r'"(?:\\.|[^"\\])*"', '""', src)
    src = re.sub(r"'(?:\\.|[^'\\])*'", "''", src)
    return src


def hits(text: str, names) -> dict:
    return {n: len(re.findall(r"\b%s\s*\(" % n, text)) for n in names}


adapter = strip(open(adapter_src, encoding="utf-8").read())
worker = strip(open(sock_src, encoding="utf-8").read())

a = hits(adapter, SYSCALLS)
w = hits(worker, SYSCALLS)
print("  adapter  :", {k: v for k, v in a.items() if v})
print("  worker   :", {k: v for k, v in w.items() if v})
extra = hits(adapter, EXTRA)
print("  adapter (info, wider set):", {k: v for k, v in extra.items() if v})

rc = 0
for name in SYSCALLS:
    if a[name] != 0:
        print(f"  FAIL  scr_godot_adapter.cpp calls {name}() {a[name]}x", file=sys.stderr)
        rc = 1
if rc == 0:
    print("  PASS  zero socket syscalls in scr_godot_adapter.cpp")
# Positive control: the worker file must actually contain the syscall usage
# the gate is looking for, otherwise the gate would pass on a dead regex.
for name in ("socket", "connect", "recv", "send"):
    if w[name] == 0:
        print(f"  FAIL  positive control: transport_socket.cpp has no {name}()", file=sys.stderr)
        rc = 1
if rc == 0:
    print("  PASS  positive control: transport_socket.cpp holds socket/connect/recv/send")
sys.exit(rc)
PY
if [[ $? -ne 0 ]]; then
    note_bad "structural grep gate"
else
    note_ok "structural grep gate (0008 AP-15)"
fi

# =============================================================================
# (a) measured stall test
# =============================================================================
echo
echo "-- measured gate: SIGSTOP the sim server for ${STALL_SECS} s"
if pgrep -x scr_sim_server >/dev/null 2>&1; then
    echo "FAIL: a scr_sim_server is already running; refusing to run this test" >&2
    echo "      (list it first: pgrep -a scr_sim_server)" >&2
    exit 1
fi

LOG="${TMP}/stall.log"
SCR_SIM_TRANSPORT=socket SCR_TEST_WINDOW="${WINDOW}" \
    timeout 180 "${GODOT_BIN}" --headless --path "${PROJ}" -s "${DRIVER}" \
    >"${LOG}" 2>&1 &
GODOT_PID=$!

# Wait for the adapter-owned server, give the driver time to finish warming
# up (60 physics frames) and open its measurement window, then stall it.
PID=""
for _ in $(seq 1 480); do
    if ! kill -0 "${GODOT_PID}" 2>/dev/null; then
        break
    fi
    mapfile -t pids < <(pgrep -x scr_sim_server 2>/dev/null)
    if [[ "${#pids[@]}" -eq 1 ]]; then
        age="$(ps -o etimes= -p "${pids[0]}" 2>/dev/null | tr -d ' ')"
        if [[ -n "${age}" && "${age}" -ge 6 ]]; then
            PID="${pids[0]}"
            break
        fi
    elif [[ "${#pids[@]}" -gt 1 ]]; then
        note_bad "${#pids[@]} scr_sim_server at once (single-session invariant)"
        break
    fi
    sleep 0.25
done

if [[ -n "${PID}" ]]; then
    echo "   SIGSTOP pid ${PID} (${STALL_SECS} s) ..."
    kill -STOP "${PID}" 2>/dev/null
    sleep "${STALL_SECS}"
    # Still the same PID? Verify ownership before signalling it again.
    if kill -0 "${PID}" 2>/dev/null && grep -q scr_sim_server "/proc/${PID}/comm" 2>/dev/null; then
        kill -CONT "${PID}" 2>/dev/null
        echo "   SIGCONT pid ${PID}"
    else
        note_bad "server pid ${PID} vanished during the stall"
    fi
else
    note_bad "no single sim server to stall (see ${LOG})"
fi

wait "${GODOT_PID}"
GRC=$?
GODOT_PID=""
[[ ${GRC} -eq 0 ]] && note_ok "godot exit 0" || note_bad "godot exit ${GRC}"

grep -E "SCR-TEST:|max (physics|process) frame gap" "${LOG}" | sed 's/^/   | /'

grep -q "SCR-TEST: STALL PASS" "${LOG}" \
    && note_ok "frame gaps stayed under FRAME_DT_CLAMP during the stall" \
    || note_bad "no STALL PASS verdict (frame gaps exceeded the clamp?)"

hard="$(grep -nE "SCRIPT ERROR|Failed to load script|Cannot open file|ERROR:" "${LOG}" || true)"
if [[ -z "${hard}" ]]; then
    note_ok "zero hard-error lines while the server was stalled"
else
    note_bad "hard error line(s) during the stall:"
    printf '%s\n' "${hard}" | sed 's/^[0-9]*://' | sed 's/^/    /' >&2
fi

if grep -qE "session restart|connection to the sim server closed" "${LOG}"; then
    note_bad "a stalled (not dead) server was treated as a crash"
else
    note_ok "paused server was NOT treated as a crash (no restart, no loss)"
fi

sleep 1
n="$(pgrep -x scr_sim_server 2>/dev/null | wc -l)"
[[ "${n}" -eq 0 ]] && note_ok "no scr_sim_server orphan" || note_bad "${n} server orphan(s)"

echo
if [[ "${fail}" -eq 0 ]]; then
    echo "godot_render_stall_test: PASS"
    exit 0
fi
echo "godot_render_stall_test: FAIL" >&2
exit 1
