# Sprint 02 — Selection + Variation (Mojo)

**Milestone:** [0009 — Flora Upgrade](../spec.md)
**Predecessor sprint:** [Sprint 01 (field + growth green)](sprint_01_field-growth.md)
**Scope:** `applications/godot/src/mojo/` sim core + new mojo test
**Language:** Mojo

---

## 1. Objective

Add the `704_Evolution` vertical slice: per-instance **trait variation**, environment-driven **selection** at establishment and survival, **differential persistence** — no reproduction, no generational inheritance (milestone §1.1, §9).

**Open decision to confirm before coding (milestone §1.2, Rule 19):** exact stress formula. Recommendation: `stress = f(crater_distance, local_wetness)` — both pure sim state (0003 volcano subject, 0004 weather wetness). No sim-side plume mask exists (plume advection is shader-`TIME` only) — do not invent one.

## 2. Deliverables

```text
applications/godot/src/mojo/
├── sim/flora.mojo        # EXT: trait vector, establishment selection, survival/death selection
├── sim/world.mojo        # EXT: survival pass in tick phase (stress recompute per tick or amortized — document)
└── sim/parameters.mojo   # + trait salts, stress-term weights, tolerance thresholds
applications/godot/tests/mojo/
└── test_flora_evolution.mojo    # NEW
```

## 3. Normative requirements

| # | Requirement | Source |
|---|---|---|
| R1 | Trait vector: fixed-size ≤ 4 × f32 (ash tolerance, drought tolerance; 2 salts reserved), from **pure hash** `(seed, cell, trait_salt)`; constant over instance life (trivial inheritance) | milestone §5 Sprint 02, AP-20 |
| R2 | Establishment selection: candidate fails if `local_stress > tolerance(trait)`; stress is a pure function of existing world state — **no invented inputs** (milestone §1.1 stress row) | invariant 3 |
| R3 | Survival selection: plant dies when current local stress exceeds tolerance; deterministic given state; dead removed same tick (never violates cap) | invariant 3/5 |
| R4 | `ECOLOGY-INV-013` firewall: this sprint implements variation/selection only; nothing here may add adaptation/learning/optimization semantics (`704` explicitly ≠ those) | milestone §4 row 2 |
| R5 | Honest limitation recorded in code header + `docs/04` (Sprint 04): `EVOLUTION-INV-006/007` (inheritance/lineage) satisfied trivially per instance; cross-generational = successor | milestone §4 row 3, §9 |
| R6 | Determinism: stress, trait, decision all pure — run-twice identical death sets | invariant 3 |
| R7 | Band/cap invariants from Sprint 01 still hold after deaths (§5) | invariants 4/5 |

## 4. Tasks

1. Confirm §1.2 stress-formula decision (stakeholder) before implementation.
2. Read `lib/704_Evolution/101_definition.md` (INV-004/005/009/011/018 + definition), Sprint 00's `lib/705_Ecology/Flora/101_definition.md`, Sprint 01 code.
3. Implement traits + establishment filter in `sim/flora.mojo`; survival pass in `sim/world.mojo` tick phase; params in `parameters.mojo`.
4. Write `test_flora_evolution.mojo`; re-run Sprint 01 gate + full mojo suite.

## 5. Acceptance criteria (this sprint's gate)

- [ ] `M run -I applications/godot/src/mojo applications/godot/tests/mojo/test_flora_evolution.mojo` PASS —
  (a) trait distribution over seed-1 population matches hash distribution (statistical sanity, fixed thresholds);
  (b) high-stress band (crater-adjacent / dry cells) establishment rate significantly lower than comparable low-stress band;
  (c) synthetic wetness drop kills a **deterministic superset** of plants (same set across runs);
  (d) run-twice identical population sequences;
  (e) `count ≤ FLORA_N_MAX` held after every death wave.
- [ ] `test_flora_growth.mojo` + `test_flora_placement.mojo` still PASS (selection integrated, no regressions).
- [ ] Full 21-file mojo suite PASS.
- [ ] Stress formula documented (code header + params table) and matches the confirmed §1.2 decision.

## 6. Constraints

- **AP-20:** no RNG streams — traits/stress/decisions are pure hashes/functions.
- **AP-13/22:** caps hold through death waves; deaths are not warnings (asserts).
- **Rule 19:** if selection semantics need a definition the Sprint 00 Flora 101 does not carry → stop, extend definition first (never silently redefine).
- No wire/contract/scene changes (Sprint 03 owns those).
