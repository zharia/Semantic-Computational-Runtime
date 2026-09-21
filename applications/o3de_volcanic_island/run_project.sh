#!/bin/bash
# SCR Volcanic Island - Launch Script
# Usage: ./run_project.sh [editor|game|null]
#   editor - O3DE Editor with built-in AP (needs GPU memory)
#   game   - GameLauncher + AP (needs GPU memory)
#   null   - GameLauncher with Null RHI (no GPU, headless simulation)
set -e

PROJ="$(cd "$(dirname "$0")" && pwd)"
MODE="${1:-game}"

echo "=== SCR Volcanic Island ==="
echo "Project: $PROJ"
echo "Mode: $MODE"

# Kill any existing O3DE processes for this project
pkill -x AssetProcessor 2>/dev/null || true
pkill -x SCR_VolcanicIsland.GameLauncher 2>/dev/null || true
sleep 1

case "$MODE" in
    editor)
        echo "Launching O3DE Editor (includes built-in AP)..."
        QT_QPA_PLATFORM=xcb /opt/O3DE/26.05/bin/Linux/profile/Default/Editor \
            --project-path "$PROJ"
        ;;
    game)
        # Run non-batch AP in background (stays alive while game runs)
        echo "Starting Asset Processor..."
        QT_QPA_PLATFORM=xcb /opt/O3DE/26.05/bin/Linux/profile/Default/AssetProcessor \
            --project-path "$PROJ" --no-redirect &>/dev/null &
        AP_PID=$!
        for i in $(seq 1 60); do
            if ss -tln 2>/dev/null | grep -q ":45643 "; then
                echo "Asset Processor ready on port 45643"
                break
            fi
            if ! kill -0 $AP_PID 2>/dev/null; then
                echo "Asset Processor exited"
                break
            fi
            sleep 1
        done
        echo "Launching Game Launcher..."
        "$PROJ/build/bin/profile/SCR_VolcanicIsland.GameLauncher" &
        GAME_PID=$!
        wait $GAME_PID 2>/dev/null || true
        kill $AP_PID 2>/dev/null || true
        wait $AP_PID 2>/dev/null || true
        ;;
    null)
        # Null RHI - no GPU rendering, simulation only
        echo "Starting Asset Processor..."
        QT_QPA_PLATFORM=xcb /opt/O3DE/26.05/bin/Linux/profile/Default/AssetProcessor \
            --project-path "$PROJ" --no-redirect &>/dev/null &
        AP_PID=$!
        for i in $(seq 1 60); do
            if ss -tln 2>/dev/null | grep -q ":45643 "; then
                echo "Asset Processor ready on port 45643"
                break
            fi
            if ! kill -0 $AP_PID 2>/dev/null; then
                echo "Asset Processor exited"
                break
            fi
            sleep 1
        done
        echo "Launching Game Launcher (Null RHI - no GPU)..."
        "$PROJ/build/bin/profile/SCR_VolcanicIsland.GameLauncher" --rhi=Null &
        GAME_PID=$!
        wait $GAME_PID 2>/dev/null || true
        kill $AP_PID 2>/dev/null || true
        wait $AP_PID 2>/dev/null || true
        ;;
    *)
        echo "Usage: $0 [editor|game|null]"
        exit 1
        ;;
esac

echo "Done."
