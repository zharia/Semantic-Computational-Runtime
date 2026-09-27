#!/usr/bin/env bash
# build_godot_provider.sh — build the SCR Godot render provider:
#   (a) Mojo simulation shared library  applications/godot/build/libscr_sim.so
#   (b) GDExtension adapter              applications/godot/godot/addons/scr_godot/bin/libscr_godot.so
#
# MUST be run from the repository root (or anywhere — it re-anchors itself).
# Paths are computed from this script's location; no absolute paths (AP-4).
#
# Usage:  bash applications/godot/scripts/build_godot_provider.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"   # repo root
cd "${ROOT}"

MOJO="${ROOT}/.venv/bin/mojo"
SCONS="${HOME}/.local/bin/scons"
GODOT_BIN="/usr/bin/godot"
ADAPTER_DIR="applications/godot/providers/render/graphics/godot/adapter"
SIM_OUT="applications/godot/build/libscr_sim.so"
EXT_OUT="applications/godot/godot/addons/scr_godot/bin/libscr_godot.so"

echo "== SCR Godot provider build — toolchain pinning =="

# godot-cpp commit (dependency pin for docs/02_development_environment.md)
if git -C "applications/godot/.deps/godot-cpp" rev-parse --git-dir >/dev/null 2>&1; then
    GODOT_CPP_COMMIT="$(git -C "applications/godot/.deps/godot-cpp" rev-parse --short HEAD)"
else
    GODOT_CPP_COMMIT="unknown (not a git checkout)"
fi
echo "godot-cpp : commit ${GODOT_CPP_COMMIT} (prebuilt static lib, api 4.7, target template_debug)"
echo "scons     : $("${SCONS}" --version 2>/dev/null | sed -n 2p | sed 's/^\s*//')"
echo "godot     : $("${GODOT_BIN}" --version 2>/dev/null | head -1)"
echo "mojo      : $("${MOJO}" --version 2>/dev/null | head -1)"
echo "g++       : $(g++ --version | head -1)"

echo
echo "== [1/3] simulation shared library (Mojo C ABI) =="
# Exact command from tests/mojo/README.md (abi build entry: export/abi.mojo).
mkdir -p "applications/godot/build"
(
    cd "applications/godot/src/mojo"
    "${MOJO}" build export/abi.mojo -I src/mojo --emit shared-lib \
        -o ../../build/libscr_sim.so
)
ls -l "${SIM_OUT}"

echo
echo "== [2/3] GDExtension adapter (godot-cpp, scons) =="
mkdir -p "$(dirname "${EXT_OUT}")"
"${SCONS}" -C "${ADAPTER_DIR}"
ls -l "${EXT_OUT}"

echo
echo "== [3/3] Godot project prime (.godot/extension_list.cfg) =="
# Game-mode runs discover GDExtensions via .godot/extension_list.cfg, which the
# editor writes during its first scan. Without this step a fresh checkout runs
# the project with the extension silently unloaded. NOTE: `godot -e --quit` and
# `godot --import` abort (engine teardown race when a native class is
# registered); a bounded idle quit (-e --quit-after N) is the safe form.
EXT_LIST="applications/godot/godot/.godot/extension_list.cfg"
if [[ -f "${EXT_LIST}" ]]; then
    echo "already primed: ${EXT_LIST}"
elif [[ -x "${GODOT_BIN}" ]]; then
    echo "priming editor scan (bounded quit)..."
    if timeout 180 "${GODOT_BIN}" --headless --path applications/godot/godot \
         -e --quit-after 300 >/dev/null 2>&1; then
        [[ -f "${EXT_LIST}" ]] && echo "primed: ${EXT_LIST}" \
            || { echo "WARNING: ${EXT_LIST} still missing — extension will not load in game runs" >&2; }
    else
        echo "WARNING: editor prime run failed (exit $?) — extension may not load in game runs" >&2
    fi
else
    echo "WARNING: ${GODOT_BIN} not found — run the editor once manually to prime ${EXT_LIST}" >&2
fi

echo
echo "== summary =="
echo "sim library   : ${SIM_OUT}"
echo "gdextension   : ${EXT_OUT}"
if command -v nm >/dev/null 2>&1; then
    echo "entry symbol  : $(nm -D "${EXT_OUT}" | grep -c ' gdextension_init$') match(es) for gdextension_init"
    echo "sim symbols   : $(nm -D "${SIM_OUT}" | grep -c ' T scr_sim_') exported scr_sim_* functions"
fi
if [[ -f "${EXT_LIST}" ]]; then
    echo "extension list: ${EXT_LIST} (game runs will load the extension)"
else
    echo "extension list: MISSING (game runs will NOT load the extension)"
fi
echo "OK — provider built."
