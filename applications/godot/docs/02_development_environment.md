# 02 — Development Environment

**Purpose:** Pin toolchain versions and document build/test/verification entry conventions for the Godot application workspace.
**Status:** Active
**Owner milestone:** [v0.0.1 / milestone 0001 — Project Initiation](../program_increments/v0.0.1/milestone_0001_project-initiation/spec.md) (updated by milestone 0002 Sprint 03/04)

---

## 1. Pinned Versions

| Tool | Version | Location / invocation |
|------|---------|----------------------|
| Mojo toolchain | **1.0.0** (`Mojo 1.0.0 (ed45d567)`) | Repository root `.venv/bin/mojo` (NOT on default `PATH`; Modular conda-channel toolchain per root `pixi.lock` / `pyproject.toml`) |
| Godot editor/runtime | **4.7.2.stable** — exact build `v4.7.2.stable.arch_linux.ed1daf0bf` | `/usr/bin/godot` (`godot` on `PATH`) |
| godot-cpp | commit **`507ed9d`** (short), API **4.7**, built `target=template_debug` | `applications/godot/.deps/godot-cpp` — **git-ignored**, see §1.1 |
| scons | **4.11.1** (`~/.local/bin/scons`, not on default PATH for all shells) | used by the adapter `SConstruct` |
| g++ / gcc | **g++ (GCC) 16.2.1 20260810** | system toolchain |
| Python | python3 (stdlib only for `tests/check_luminance.py`; `numpy` present but unused) | `python3` |
| Target OS | **Linux** (x86_64), renderer `gl_compatibility` | v0.0.1 workspace target |

Version drift is a deviation: update this document and the milestone spec together.

### 1.1 Reproducing the `.deps/` godot-cpp checkout (git-ignored)

`applications/godot/.deps/` is ignored by `applications/godot/.gitignore`, so a
fresh clone must rebuild it. Verified facts about the current checkout:

- `applications/godot/.deps/godot-cpp` = clone of
  `https://github.com/godotengine/godot-cpp.git`, commit `507ed9d`,
  built with `scons target=template_debug api_version=4.7`
  (build log: `applications/godot/.deps/godot-cpp-build.log`).
- Binding generation source: `api_version=4.7` makes godot-cpp's SConstruct use
  its **vendored** `gdextension/extension_api-4-7.json`
  (`tools/godotcpp.py::_get_api_file`); no manual API dump is required.
- `applications/godot/.deps/extension_api.json` (header: `Godot Engine
  v4.7.2.stable.arch_linux`) and `gdextension_interface.h` are dumps produced by
  `godot --dump-extension-api` from the pinned engine — reference copies kept
  alongside the checkout (not required by the adapter build).

Reproduce from scratch:

```bash
mkdir -p applications/godot/.deps
git clone https://github.com/godotengine/godot-cpp applications/godot/.deps/godot-cpp
git -C applications/godot/.deps/godot-cpp checkout 507ed9d
"$HOME"/.local/bin/scons -C applications/godot/.deps/godot-cpp \
    target=template_debug api_version=4.7
# produces applications/godot/.deps/godot-cpp/bin/libgodot-cpp.linux.template_debug.x86_64.a
# (the only godot-cpp artifact the adapter SConstruct links)
```

> Honest note: the pinned commit, the SConstruct linkage, and the
> `api_version=4-7` vendored-API resolution above are verified from the live
> checkout; the two-line clone+scons recipe was **not re-run end-to-end from a
> clean state in Sprint 04** — if it fails, record the correction here
> (honesty invariant).

## 2. Directory Conventions

Per [spec §2.3](../program_increments/v0.0.1/milestone_0001_project-initiation/spec.md) (+ milestone 0002 layout amendment):

- Mojo sources: `src/mojo/` (sim, synthesis, ocean, materials, snapshot, export)
- Godot project root: `godot/` (`project.godot`, `scenes/`, `scripts/`, `shaders/`, `addons/scr_godot/`)
- Mojo tests: `tests/mojo/`; Godot scene/integration tests: `tests/godot/` (`*.sh` runners + `*.gd` Godot scripts, milestone 0002); binding-level tests at `tests/` (`abi_smoke.py`, `test_schema_mismatch.sh`)
- Helper scripts: `scripts/`
- Provider tree (repo-level, normative): `providers/render/graphics/godot/` (101/102/103/104 + `adapter/`)

No ad-hoc top-level source dumps (layout invariant).

## 3. Build / Run Entry Conventions

### 3.1 Full provider build (sim `.so` + GDExtension + project prime)

```bash
bash applications/godot/scripts/build_godot_provider.sh
```

Builds (in order, from repo root):

1. **Sim shared library** — exact command from `tests/mojo/README.md`:
   `cd applications/godot/src/mojo && $MOJO build export/abi.mojo -I src/mojo --emit shared-lib -o ../../build/libscr_sim.so`
2. **GDExtension adapter** — `scons -C applications/godot/providers/render/graphics/godot/adapter`
   → `godot/addons/scr_godot/bin/libscr_godot.so` (godot-cpp, `target=template_debug`, api 4.7).
3. **Project prime** — first-run editor scan writes `godot/.godot/extension_list.cfg`
   (game-mode runs discover GDExtensions through this file).

The script prints pinned versions (godot-cpp commit, scons, godot, mojo, g++),
symbol counts, and `OK — provider built.` on success.

### 3.2 Godot open / headless validation

```bash
# Headless load gate (CI-friendly, bounded frames — use this):
godot --headless --path applications/godot/godot --quit-after 120

# Interactive game run (main scene = scenes/island.tscn):
godot --path applications/godot/godot
```

**Engine quirk (upstream):** `godot -e --quit` SIGABRTs when a native class is
registered (GDExtension teardown race). Use `--quit-after N` instead of bare
`--quit`, and never combine bare `--quit` with `-e`. `scripts/build_godot_provider.sh`
uses `timeout … -e --quit-after 300` for the prime step for the same reason.

**Old note (0001):** the declared main scene is no longer the empty
`main.tscn` scaffold — milestone 0002 sets `run/main_scene="res://scenes/island.tscn"`.
`main.tscn`/`main.gd` remain as the 0001 artifact, not the main scene.

### 3.3 Layout check

```bash
bash applications/godot/scripts/check_layout.sh
```

Verifies required directories/files (0001 §2.3 + 0002 provider-tree amendment),
AP-1 gate (no engine types in `src/mojo/`), AP-4 gate (no `/home/` absolute
paths in `src/`, `godot/`, `providers/` sources); prints `PASS` when green.

### 3.4 Tests

```bash
# Mojo spec tests (36 tests across 7 files — see tests/mojo/README.md):
M=.venv/bin/mojo
$M run -I applications/godot/src/mojo applications/godot/tests/mojo/test_determinism.mojo
# … (full list in tests/mojo/README.md)

# C ABI smoke (dlopens libscr_sim.so like the adapter):
python3 applications/godot/tests/abi_smoke.py

# Schema-mismatch negative test (adapter loader must refuse non-1 schema):
bash applications/godot/tests/test_schema_mismatch.sh

# Headless scene-load gate (main scene, 120 frames, zero ERROR lines):
bash applications/godot/tests/godot/godot_load_test.sh

# Playability (scripted input, headless):
bash applications/godot/tests/godot/godot_playability_test.sh

# Screenshot + luminance (RENDERED mode — needs $DISPLAY or xvfb-run;
# prints a documented manual procedure when no display is available):
bash applications/godot/tests/godot/godot_screenshot.sh
```

Godot integration test harness/conventions: see `tests/godot/README.md`.

## 4. Hygiene

- Build outputs and caches git-ignored via [`../.gitignore`](../.gitignore) (`.godot/`, `.mojo/`, `.deps/`, `__pycache__`, editor state).
- Derived artifacts never committed (derived-artifact invariant): `build/libscr_sim.so`, `godot/addons/scr_godot/bin/*.so`, `build/*.png`, scons `.os` objects.

## References

- [Documentation index](README.md)
- [spec §2.4–2.6](../program_increments/v0.0.1/milestone_0001_project-initiation/spec.md)
- [tests/mojo/README.md](../tests/mojo/README.md)
- [AGENTS.md](../../AGENTS.md)
