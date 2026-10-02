#!/usr/bin/env bash
# godot_screenshot.sh — runner for the automated screenshot + luminance gate.
#
# Spec: milestone_0002 §7 exit criterion 2.
#   1. Display probe: needs a real display/GPU (rendered game mode).
#      If neither $DISPLAY nor xvfb-run is available, prints the documented
#      MANUAL capture procedure (exit-criteria fallback) and exits 2.
#   2. Runs godot_screenshot.gd (content assertions + tick-wait to a fully
#      developed plume + spawn/crater captures + in-script luminance check) in
#      RENDERED game mode (never --headless).
#      Env: TICK_MIN (default 1900), FRAMES (settle frames, default 60),
#      SCR_EXPECT_GLOW=1 adds the night-glow assertion (docs/04 §8).
#   3. Re-checks the PNG with check_luminance.py (independent decoder).
#   4. (milestone_0005 §7) Aerial capture with fog OFF via
#      godot_aerial_diagnostic.gd, then check_shoreline_foam.py asserts the
#      bright water pixels sit within ±FOAM_BAND_M of the y_terrain = sea_level
#      contour ("foam only at the shoreline").
#
# Exit: 0 PASS · 1 content/scene or foam-gate assertion failed · 2 capture/display failure
#       (manual fallback printed) · 3 blank image.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../../.." && pwd)"
PROJ="${REPO_ROOT}/applications/godot/godot"
PNG="${REPO_ROOT}/applications/godot/build/island.png"
PNG2="${REPO_ROOT}/applications/godot/build/island_crater.png"
PNG3="${REPO_ROOT}/applications/godot/build/island_sun.png"
PNG4="${REPO_ROOT}/applications/godot/build/island_rain.png"
# 0006 §7 ecology sub-captures (daytime only — see godot_screenshot.gd phase D)
PNG5="${REPO_ROOT}/applications/godot/build/island_flora.png"
PNG6="${REPO_ROOT}/applications/godot/build/island_fauna.png"
RAIN_TICK="${RAIN_TICK:-4200}"   # seed-1 precipitation window 1801..8100
GODOT_BIN="${GODOT_BIN:-godot}"
FRAMES="${FRAMES:-60}"   # settle frames after the tick-wait (see .gd header)
TICK_MIN="${TICK_MIN:-1900}"
EXTRA_ARGS=()
if [[ -n "${SCR_EXPECT_GLOW:-}" ]]; then EXTRA_ARGS+=("--expect-glow"); fi

# Socket legs of this gate are WALL-TIME sensitive: the plume particle
# lifetime (6 s) and the cloud display advance on wall time while sim ticks
# advance on Godot physics frames. With the server's default wall pace the
# sim reaches the capture tick ~2x faster than the in-process leg, so the
# plume column has not developed and the sun sub-capture lands at a
# different cloud phase (0008 §1.1 client-paced socket mode — the adapter
# issues CMD_TICK 1 per physics frame, making socket tick timing equal the
# in-process leg's). Set SCR_SIM_IPC_PACE=manual for the socket leg unless
# the caller already chose a pace explicitly (deliberate wall runs pass
# SCR_SIM_IPC_PACE=wall).
if [[ "${SCR_SIM_TRANSPORT:-}" == "socket" && -z "${SCR_SIM_IPC_PACE+x}" ]]; then
    export SCR_SIM_IPC_PACE=manual
fi

manual_fallback() {
    cat >&2 <<'EOF'
MANUAL CAPTURE PROCEDURE (documented fallback, spec §7 exit criterion 2):
  1. On a machine with a display and GPU: from the repo root run
        godot --path applications/godot/godot
  2. Wait ~5 s for the island to render (terrain + ocean + sky + sun,
     HUD "tick ..." line updating at the top left).
  3. Capture the window (e.g. Screenshot key / window manager capture) and
     save it as applications/godot/build/island.png.
  4. Verify non-blank:
        python3 applications/godot/tests/godot/check_luminance.py \
            applications/godot/build/island.png
  5. Record the mean/stddev output in the milestone verification record
     (docs/04_simulation_engine.md §8).
EOF
}

if [[ -z "${DISPLAY:-}" && -z "${WAYLAND_DISPLAY:-}" ]]; then
    if ! command -v xvfb-run >/dev/null 2>&1; then
        echo "no display (DISPLAY/WAYLAND_DISPLAY unset, xvfb-run absent)" >&2
        manual_fallback
        exit 2
    fi
    WRAP=(xvfb-run -a)
else
    WRAP=()
fi

mkdir -p "$(dirname "${PNG}")"
cd "${REPO_ROOT}"
LOG="$(mktemp)"
trap 'rm -f "${LOG}" "${LOG}.aerial"' EXIT

timeout 300 "${WRAP[@]}" "${GODOT_BIN}" --path "${PROJ}" \
    -s "${REPO_ROOT}/applications/godot/tests/godot/godot_screenshot.gd" \
    -- "--frames=${FRAMES}" "--tick-min=${TICK_MIN}" "--png=${PNG}" \
    "--png2=${PNG2}" "--png3=${PNG3}" "--png4=${PNG4}" \
    "--png5=${PNG5}" "--png6=${PNG6}" \
    "--rain-tick=${RAIN_TICK}" "${EXTRA_ARGS[@]}" >"${LOG}" 2>&1
rc=$?

grep -E "SCREENSHOT:|SCRIPT ERROR|ERROR: SCR" "${LOG}" | sort -u | head -60

# Independent decode + luminance check runs whenever a PNG exists (rc 0/1),
# so the luminance evidence is recorded even when content assertions fail.
if [[ ${rc} -eq 0 || ${rc} -eq 1 ]]; then
    # Night run (SCR_EXPECT_GLOW): the sky is derived from the SKY palette and
    # is legitimately dark (docs/04 §8.4) — use the "not a black frame" floor.
    NIGHT_ARGS=()
    if [[ -n "${SCR_EXPECT_GLOW:-}" ]]; then NIGHT_ARGS=(--min-mean 3.0 --min-stddev 1.5); fi
    python3 "${SCRIPT_DIR}/check_luminance.py" "${PNG}" "${NIGHT_ARGS[@]}" || exit $?
fi
# Rain-window evidence (0004 §7): independently decoded whenever it exists.
if [[ ${rc} -eq 0 || ${rc} -eq 1 && -f "${PNG4}" ]]; then
    python3 "${SCRIPT_DIR}/check_luminance.py" "${PNG4}" || exit $?
fi
# Ecology evidence (0006 §7): flora/fauna sub-captures exist only after a
# daytime run (phase D is skipped with SCR_EXPECT_GLOW — a stale pair from a
# previous day run must not be re-asserted during the night gate).
if [[ -z "${SCR_EXPECT_GLOW:-}" && ( ${rc} -eq 0 || ${rc} -eq 1 ) ]]; then
    if [[ -f "${PNG5}" ]]; then
        python3 "${SCRIPT_DIR}/check_luminance.py" "${PNG5}" || exit $?
    fi
    if [[ -f "${PNG6}" ]]; then
        python3 "${SCRIPT_DIR}/check_luminance.py" "${PNG6}" || exit $?
    fi
fi

case ${rc} in
    0) ;;
    1) echo "screenshot: scene/content assertion failed (see above)" >&2; exit 1 ;;
    2) echo "screenshot: capture failed" >&2; manual_fallback; exit 2 ;;
    3) echo "screenshot: blank frame (in-script luminance check failed)" >&2; exit 3 ;;
    *) echo "screenshot: godot exited ${rc}" >&2; tail -20 "${LOG}" >&2; exit 2 ;;
esac

# 0005 §7 "foam only at the shoreline": overhead capture (fog OFF — the gate
# measures bright pixels, and fog would wash the whole frame bright; this is
# a deliberate display-verification condition, not a gameplay value), then
# the independent contour-distance check against the committed seed-1 height
# field. Fallback: manual capture procedure in check_shoreline_foam.py /
# godot_aerial_diagnostic.gd headers (0002 pattern).
AERIAL="${REPO_ROOT}/applications/godot/build/aerial.png"
timeout 300 "${WRAP[@]}" "${GODOT_BIN}" --path "${PROJ}" \
    -s "${REPO_ROOT}/applications/godot/tests/godot/godot_aerial_diagnostic.gd" \
    -- "--png=${AERIAL}" "--frames=60" "--fog=0" >"${LOG}.aerial" 2>&1
arc=$?
grep -E "AERIAL:|SCRIPT ERROR|ERROR: SCR" "${LOG}.aerial" | sort -u | head -30
if [[ ${arc} -ne 0 ]]; then
    echo "screenshot: aerial capture failed (rc ${arc})" >&2
    tail -20 "${LOG}.aerial" >&2
    exit 2
fi
# Foam detection is a luma >= 0.60 test over water: a night frame (21.0 h)
# legitimately contains no bright water pixels, so the gate is a daytime-only
# assertion (0004 precedent: plume colour check skipped at night). The night
# gate still runs the aerial capture itself (non-zero exit still fails).
if [[ -n "${SCR_EXPECT_GLOW:-}" ]]; then
    echo "SHORE FOAM: SKIPPED (night frame — luma-based foam gate is daytime-only, enforced by the day run)"
else
    python3 "${SCRIPT_DIR}/check_shoreline_foam.py" "${AERIAL}" || exit $?
fi

echo "godot_screenshot: PASS (${PNG})"
exit 0
