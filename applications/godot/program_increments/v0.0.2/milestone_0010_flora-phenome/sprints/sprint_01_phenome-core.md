# Sprint 01 — Phenome Core: Stage, Seed, Modulation, Reference Expander (Mojo)

**Milestone:** [0010 — Flora Phenome](../spec.md)
**Predecessor sprint:** [Sprint 00 (definitions gate green)](sprint_00_definitions.md)
**Scope:** `applications/godot/src/mojo/` sim core + `godot/data/phenome_grammars.json` + new/extended mojo tests
**Language:** Mojo (Mojo 1.0.0, `.venv/bin/mojo`); JSON data single-source

---

## 1. Objective

Add the sim-side phenome state and meaning: **developmental stage** (quantized from age), **variant_seed** (explicit generative identity), **trait→grammar-parameter modulation** (genotype→phenotype map), and a **reference expander** that emits discrete conformance vectors for the renderer to match. Wire record stays 24 B this sprint (contract change is Sprint 02); expansion never runs per tick.

## 2. Deliverables

```text
applications/godot/
├── godot/data/phenome_grammars.json             # NEW: single-source 7-species grammars
│                                                 #   (axiom, productions, stage→depth, tropism, modulation map)
├── src/mojo/
│   ├── sim/phenome.mojo                         # NEW: stage_for_age, variant_seed, trait→param map (pure)
│   ├── phenome/expand.mojo                      # NEW: reference turtle expander (discrete derivation only)
│   ├── sim/world.mojo                           # EXT: stage advance in tick phase
│   ├── sim/runtime.mojo                         # EXT: emission dirty on stage/seed change
│   ├── sim/parameters.mojo                      # + STAGE_MAX, seed salts, modulation constants (AP-7)
│   └── sim/flora.mojo                           # EXT: instances gain sim-side stage + variant_seed
└── tests/mojo/
    ├── test_phenome_grammar.mojo                # NEW
    ├── test_flora_growth.mojo                   # EXT: stage monotone with age
    ├── test_flora_evolution.mojo                # EXT: modulation visible in expanded params
    ├── test_determinism.mojo                    # EXT: stage/seed in byte-identical sequence
    └── test_projection_purity.mojo              # EXT: phenome fingerprint outside projection
tests/fixtures/phenome/                          # NEW: golden discrete derivations (checked in)
```

Untouched this sprint: `lib/`, `104_contract.md` prose (Sprint 02), adapter, scene, fixture `snapshot_seed1_tick1.bin`.

## 3. Normative requirements

| # | Requirement | Source |
|---|---|---|
| R1 | `stage_for_age(species, age)` pure, quantized per-species maturity curve, monotone non-decreasing, `0 ≤ stage ≤ STAGE_MAX (= 15)`; curves in `parameters.mojo` (AP-7) derived from and conformance-tested against `phenome_grammars.json` stage tables | milestone §1.1 stage model, invariant 5 |
| R2 | `variant_seed = hash(seed, cell, salt)` pure, order-independent, distinct across plants; no mutable RNG stream anywhere (AP-20) | invariant 2, AP-20 |
| R3 | Trait→grammar-parameter modulation is a **pure, documented map**: tolerant trait ⇒ declared parameter shift (e.g. ash tolerance → crown density; drought tolerance → leaf count/droop), values **exact vs the JSON map** (constants in `parameters.mojo` are mirrors — conformance test asserts mirror == JSON) | milestone §1.1, §6 invariant 4, AP-3/AP-23 |
| R4 | Stage/seed/traits computed **once per fixed tick in the tick phase** (`world.mojo`); projection read-only (fingerprint extended) | invariant 5, 0009 R4 |
| R5 | Reference expander produces the **discrete derivation** (symbol string + integer/rational params) for `(grammar, seed, stage, traits)` — deterministic, run-twice identical; **never called in the sim tick path**, only tests; goldens in `tests/fixtures/phenome/` | §1.1 conformance axis, AP-24 |
| R6 | Expansion depth follows the stage table (non-decreasing in stage); structure accretes — no regression without death | invariant 5 |
| R7 | Emission dirty extended: stage or variant_seed change (vs last emission) joins 0009's ε-scale/count triggers; first snapshot after init always emits | §3.2, 0009 R7 |
| R8 | `count ≤ FLORA_N_MAX`, `0 < scale` unchanged; wire record **still 24 B** this sprint — stage/seed exist sim-side only until Sprint 02 (layout neutrality: if a test wants them on the wire, that is Sprint 02's spec change) | invariant 6 pre-state, 0009 R6 |

## 4. Tasks

1. Read milestone §1.1 (decisions table), §3.1, §6; Sprint 00 definitions (`Procedural/101`, `Phenotype/101`, Flora §1.6); `sim/flora.mojo`, `sim/world.mojo`, `sim/runtime.mojo`, `tests/mojo/test_flora_evolution.mojo`.
2. Author `phenome_grammars.json` for all 7 species (grammar content concretized from Sprint 00 definitions; modulation map declared here first — single source).
3. Implement `sim/phenome.mojo` + `phenome/expand.mojo`; wire stage/seed into `FloraInstance`, tick advance, emission dirty; parameters per AP-7.
4. Write `test_phenome_grammar.mojo`; extend growth/evolution/determinism/purity tests; generate golden derivation fixtures.
5. Run this sprint's gate (§5); re-run full mojo suite for regressions.

## 5. Acceptance criteria (this sprint's gate)

- [x] `M run -I applications/godot/src/mojo applications/godot/tests/mojo/test_phenome_grammar.mojo` PASS — (a) stage monotone, bounded, per-species curve; (b) variant_seed deterministic + distinct; (c) modulation value-exact vs JSON map; (d) reference expansion deterministic, goldens match, depth non-decreasing in stage; (e) traits variation ⇒ different derivation for same seed.
- [x] `test_flora_growth`, `test_flora_evolution`, `test_determinism`, `test_projection_purity` PASS (extensions included).
- [x] All pre-existing mojo suites still PASS (no regressions); `check_layout.sh` PASS.
- [x] `rg -n "rand\(|random" applications/godot/src/mojo/{sim/phenome.mojo,phenome/expand.mojo}` → no mutable-stream hits (AP-20).
- [x] `git diff --stat` shows **no** `snapshot/encode.mojo`/`decode.mojo`/fixture changes (record still 24 B — R8 evidence).

## 6. Constraints

- **AP-23:** grammar lives in JSON + Sprint 00 definitions; no productions invented in Mojo/GDScript — JSON is the single vocabulary (AP-3).
- **AP-24:** conformance fixtures are discrete symbol strings, never float geometry.
- **AP-7:** every tunable in `parameters.mojo`; mirrors of JSON conformance-tested.
- **Invariant 8:** layout-neutral this sprint — stage/seed do not cross the wire until Sprint 02 (Rule 19 if pressure to ship early).
