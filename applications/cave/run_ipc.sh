#!/usr/bin/env bash
# ==============================================================================
# SCR IPC Launcher — Two-Process Simulation/Rendering
# Starts simulation server and render client as separate processes.
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

SOCK_PATH="${SCR_SIM_SOCK:-/tmp/scr_ipc.sock}"
SIM_PID=""
RENDER_PID=""

cleanup() {
    echo "[Launcher] Shutting down..."
    [ -n "$RENDER_PID" ] && kill -TERM "$RENDER_PID" 2>/dev/null || true
    [ -n "$SIM_PID" ] && kill -TERM "$SIM_PID" 2>/dev/null || true
    wait "$RENDER_PID" 2>/dev/null || true
    wait "$SIM_PID" 2>/dev/null || true
    rm -f "$SOCK_PATH"
    echo "[Launcher] Done."
}
trap cleanup EXIT INT TERM

echo "========================================================================="
echo " SCR IPC — Two-Process Mode"
echo " Socket: $SOCK_PATH"
echo "========================================================================="

# Start simulation server (headless or graphical)
MODE="${1:-headless}"
shift 2>/dev/null || true

if [ "$MODE" = "headless" ]; then
    echo "[Launcher] Starting headless IPC server..."
    "$REPO_ROOT/applications/cave/scr_sim_ipc_server" "$SOCK_PATH" "$@" &
    SIM_PID=$!
else
    echo "[Launcher] Starting graphical simulation..."
    "$REPO_ROOT/applications/cave/scr_simulation_hub" &
    SIM_PID=$!
fi

# Wait for socket to appear
echo "[Launcher] Waiting for simulation socket..."
for i in $(seq 1 50); do
    [ -S "$SOCK_PATH" ] && break
    sleep 0.1
done

if [ ! -S "$SOCK_PATH" ]; then
    echo "[Launcher] ERROR: Simulation socket not found at $SOCK_PATH"
    exit 1
fi

echo "[Launcher] Simulation ready (PID $SIM_PID)"

# Start render client
echo "[Launcher] Starting render client..."
"$REPO_ROOT/applications/cave/scr_render_client" "$SOCK_PATH" &
RENDER_PID=$!
echo "[Launcher] Render client started (PID $RENDER_PID)"

echo ""
echo "[Launcher] Both processes running. Press Ctrl+C to stop."
echo ""

wait
