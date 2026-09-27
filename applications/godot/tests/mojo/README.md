# tests/mojo — Mojo Spec Tests

**Purpose:** Executable specification tests for the simulation core under `src/mojo/` (milestone_0002 Sprints 01+02).
**Framework:** `std.testing` — each file defines `def test_*() raises:` functions, registered by hand in `main()` via
`TestSuite.discover_tests[(...)]().run()`. A failing `assert` exits non-zero.
**Status:** Active (v0.0.1 / milestone 0002).

## Running (from repo root)

```sh
M=.venv/bin/mojo
$M run -I applications/godot/src/mojo applications/godot/tests/mojo/test_determinism.mojo
$M run -I applications/godot/src/mojo applications/godot/tests/mojo/test_projection_purity.mojo
$M run -I applications/godot/src/mojo applications/godot/tests/mojo/test_envelope.mojo
$M run -I applications/godot/src/mojo applications/godot/tests/mojo/test_synthesis_conformance.mojo
$M run -I applications/godot/src/mojo applications/godot/tests/mojo/test_gerstner.mojo
$M run -I applications/godot/src/mojo applications/godot/tests/mojo/test_catalog.mojo
$M run -I applications/godot/src/mojo applications/godot/tests/mojo/test_golden_fixture.mojo
```

ABI smoke (builds the shared library first, then dlopens it like the adapter):

```sh
(cd applications/godot/src/mojo && $OLDPWD/.venv/bin/mojo build export/abi.mojo \
    -I src/mojo --emit shared-lib -o ../../build/libscr_sim.so)
python3 applications/godot/tests/abi_smoke.py
```

## Files

| File | Covers |
|------|--------|
| `test_determinism.mojo` | §6.8: same seed+inputs ⇒ byte-identical snapshot sequence; fixed-timestep accumulator; seed sensitivity |
| `test_projection_purity.mojo` | §6.3: world fingerprint unchanged across projection |
| `test_envelope.mojo` | 104_contract §4: envelope/framing/section payloads; loud failure on malformed input |
| `test_synthesis_conformance.mojo` | Voxel Synthesis: biome→material table, bedrock/sea-level/feature invariants, field sampling, spawn band |
| `test_gerstner.mojo` | SCR-LIB-MATH-GERSTNER: dispersion, steepness bound, Jacobian/foam ranges, determinism |
| `test_catalog.mojo` | AP-3/§6.5: every shading parameter derivable from `materials_catalog.json` (repo-relative) |
| `test_golden_fixture.mojo` | Byte-exact golden snapshot (`../fixtures/snapshot_seed1_tick1.bin`) |
| `gen_golden_fixture.mojo` | Tool (not a test): regenerates the fixture after intentional changes |
| `../abi_smoke.py` | 7 C ABI symbols, `scr_input_batch` 20-byte layout, SCR_ERR_* paths, FFI snapshot == fixture |

## Golden fixture

`fixtures/snapshot_seed1_tick1.bin` = seed 1 → one `dt = 1/60` step with scripted input
`move=(0.5, 1.0), look=(0.25, −0.1), jump=1, sprint=0` → snapshot with all six sections.
Input constants are duplicated (and must stay identical) in `gen_golden_fixture.mojo`,
`test_golden_fixture.mojo`, and `abi_smoke.py`. Regenerate only on intentional changes:

```sh
$M run -I applications/godot/src/mojo applications/godot/tests/mojo/gen_golden_fixture.mojo
```
