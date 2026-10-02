# tests/mojo — Mojo Spec Tests

**Purpose:** Executable specification tests for the simulation core under `src/mojo/` (milestone_0002 Sprints 01+02, extended through milestone 0007).
**Framework:** `std.testing` — each file defines `def test_*() raises:` functions, registered by hand in `main()` via
`TestSuite.discover_tests[(...)]().run()`. Checks use a raise-based `_check` helper (`assert` is a no-op on this toolchain).
**Status:** Active (v0.0.1 / milestones 0002–0008; snapshot schema 6, C ABI 2).

## Running (from repo root)

```sh
M=.venv/bin/mojo
$M run -I applications/godot/src/mojo applications/godot/tests/mojo/test_determinism.mojo
$M run -I applications/godot/src/mojo applications/godot/tests/mojo/test_projection_purity.mojo
$M run -I applications/godot/src/mojo applications/godot/tests/mojo/test_envelope.mojo
$M run -I applications/godot/src/mojo applications/godot/tests/mojo/test_synthesis_conformance.mojo
$M run -I applications/godot/src/mojo applications/godot/tests/mojo/test_edit_ops.mojo
$M run -I applications/godot/src/mojo applications/godot/tests/mojo/test_hotbar.mojo
$M run -I applications/godot/src/mojo applications/godot/tests/mojo/test_raycast.mojo
$M run -I applications/godot/src/mojo applications/godot/tests/mojo/test_props.mojo
$M run -I applications/godot/src/mojo applications/godot/tests/mojo/test_framing.mojo
```

IPC transport (milestone 0008 — server binary + frame harness):

```sh
bash applications/godot/scripts/build_sim_server.sh
python3 applications/godot/tests/ipc/ipc_harness.py --self-test
bash applications/godot/tests/ipc/test_ipc_version_refusal.sh
```

ABI smoke + TERRAIN resend (build the shared library first, then dlopen it like the adapter):

```sh
(cd applications/godot/src/mojo && $OLDPWD/.venv/bin/mojo build export/abi.mojo \
    -I src/mojo --emit shared-lib -o ../../build/libscr_sim.so)
python3 applications/godot/tests/abi_smoke.py
python3 applications/godot/tests/test_terrain_resend.py
bash applications/godot/tests/test_schema_mismatch.sh
nm -D applications/godot/build/libscr_sim.so | grep -c " T scr_"   # expect 8
```

## Files

| File | Covers |
|------|--------|
| `test_determinism.mojo` | §6.8: same seed+inputs ⇒ byte-identical snapshot sequence; scripted edit batches byte-identical; fixed-timestep accumulator; seed sensitivity |
| `test_projection_purity.mojo` | §6.3: world fingerprint unchanged across projection; sensitivity for volcano/foam/ecology/hotbar/edit-queue/props |
| `test_envelope.mojo` | 104_contract §4 (schema 6): envelope/framing/section payloads 1–14; loud failure on malformed input |
| `test_synthesis_conformance.mojo` | Voxel Synthesis: biome→material table, bedrock/sea-level/feature invariants, spawn band; 0007 AP-11 dig/place column recompute invariants |
| `test_edit_ops.mojo` | 0007 §3.2: dig/place apply, miss consumed without mutation, bedrock guard, FIFO bound + atomic batch reject, world_version bump |
| `test_hotbar.mojo` | 0007 §1.1: slot table resolves against the catalog, no bedrock placeable, select valid/invalid slots |
| `test_raycast.mojo` | Sim-owned heightfield raycast: hits, ranges, cell conventions, refine |
| `test_props.mojo` | 0007 §3.5: deterministic prop spawn anchors, gravity/ground clamp, euler zero |
| `test_gerstner.mojo` | SCR-LIB-MATH-GERSTNER: dispersion, steepness bound, Jacobian/foam ranges, determinism |
| `test_catalog.mojo` | AP-3/§6.5: every shading parameter derivable from `materials_catalog.json` (repo-relative) |
| `test_framing.mojo` | 0008 §3.2: SCRT frame codec round-trips (all 9 types), AP-16 payload-blind copy, loud malformed refusal, HELLO verdict matrix (proto/abi/schema/flags) |
| `test_golden_fixture.mojo` | Byte-exact golden snapshot (`../fixtures/snapshot_seed1_tick1.bin`), sections 1–14 |
| `gen_golden_fixture.mojo` | Tool (not a test): regenerates the fixture after intentional changes |
| `test_atmosphere.mojo`, `test_weather.mojo`, `test_quench.mojo`, `test_flora_placement.mojo`, `test_flock.mojo`, `test_shoreline_foam.mojo`, `test_material_blending.mojo` | Domain suites (0003–0006) |
| `../abi_smoke.py` | 8 C ABI symbols, `scr_input_batch` 20 B, `scr_edit_batch` 4 B, SCR_ERR_* paths (incl. −5), FFI snapshot == fixture, section 12/13/14 framing |
| `../test_terrain_resend.py` | TERRAIN presence rule: applied edit resends TERRAIN exactly once; miss does not |
| `../test_schema_mismatch.sh` | Loader refuses SCR_SIM_SCHEMA_VER + 1 (stub lie), accepts the real library |
| `../ipc/ipc_harness.py` | 0008 AP-15..18: pure-Python frame client (handshake, INPUT/CMD_TICK, snapshot capture) + in-process FFI leg; `--self-test` = handshake + 1 tick + AP-16 byte-identity + refusals |
| `../ipc/test_ipc_version_refusal.sh` | 0008 §7: mismatched HELLO (proto/abi/schema/unknown flags) ⇒ ERROR + close + non-zero exit, never a SNAPSHOT |
| `../../scripts/build_sim_server.sh` | 0008 entry: `mojo build server/main.mojo` → `build/scr_sim_server` (+ `libscr_sim.so` when absent) |

## Golden fixture

`fixtures/snapshot_seed1_tick1.bin` = seed 1 → one `dt = 1/60` step with scripted input
`move=(0.5, 1.0), look=(0.25, −0.1), jump=1, sprint=0` → snapshot with all fourteen sections (schema 6).
Input constants are duplicated (and must stay identical) in `gen_golden_fixture.mojo`,
`test_golden_fixture.mojo`, and `abi_smoke.py`. Regenerate only on intentional changes:

```sh
$M run -I applications/godot/src/mojo applications/godot/tests/mojo/gen_golden_fixture.mojo
```
