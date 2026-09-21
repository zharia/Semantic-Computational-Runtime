#!/bin/bash
# SCR Volcanic Island - Launch Script
# Usage: ./run_project.sh [editor|game]
set -e

PROJ="$(cd "$(dirname "$0")" && pwd)"
MODE="${1:-editor}"

echo "=== SCR Volcanic Island ==="
echo "Project: $PROJ"
echo "Mode: $MODE"

# Kill any existing O3DE processes for this project
pkill -f "AssetProcessor.*o3de_volcanic_island" 2>/dev/null || true
pkill -f "Editor.*o3de_volcanic_island" 2>/dev/null || true
sleep 1

case "$MODE" in
    editor)
        echo "Launching O3DE Editor (includes built-in Asset Processor)..."
        QT_QPA_PLATFORM=xcb /opt/O3DE/26.05/bin/Linux/profile/Default/Editor \
            --project-path "$PROJ"
        ;;
    game)
        # Run APBatch in background, wait for it, then launch game
        echo "Starting Asset Processor..."
        /opt/O3DE/26.05/bin/Linux/profile/Default/AssetProcessorBatch \
            --project-path "$PROJ" &
        AP_PID=$!

        echo "Waiting for Asset Processor..."
        for i in $(seq 1 120); do
            if ss -tln 2>/dev/null | grep -q ":45644 "; then
                echo "Asset Processor ready"
                break
            fi
            if ! kill -0 $AP_PID 2>/dev/null; then
                echo "Asset Processor exited (all assets cached)"
                break
            fi
            sleep 1
        done

        echo "Launching Game Launcher..."
        "$PROJ/build/bin/profile/SCR_VolcanicIsland.GameLauncher" &
        GAME_PID=$!

        # Keep AP alive while game runs
        wait $GAME_PID 2>/dev/null || true
        kill $AP_PID 2>/dev/null || true
        wait $AP_PID 2>/dev/null || true
        ;;
    *)
        echo "Usage: $0 [editor|game]"
        exit 1
        ;;
esac

echo "Done."
