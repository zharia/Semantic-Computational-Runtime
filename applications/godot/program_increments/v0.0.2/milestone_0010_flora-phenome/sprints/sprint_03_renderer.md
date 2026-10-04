# Sprint 03 — Renderer: L-System Expansion, Bucketed Mesh Cache, LOD, Wind Weights

**Milestone:** [0010 — Flora Phenome](../spec.md)
**Predecessor sprint:** [Sprint 02 (schema-7 contract gate green)](sprint_02_contract.md)
**Scope:** `applications/godot/godot/` scripts + shaders + scene test; consumes Sprint 01 JSON + Sprint 02 wire fields
**Language:** GDScript (Godot 4.7.2)

---

## 1. Objective

Turn the compact generative description into structured geometry: deterministic **turtle L-system expansion** `(grammar, variant_seed, stage, traits) → ArrayMesh`, **bucketed mesh cache** (K variants/species), **distance LOD** with hysteresis, and **wind-weight vertex attributes** feeding sway (still display-only on `TIME`). Expansion runs only on (species, bucket, stage) change — never per frame (AP-26).

## 2. Deliverables

```text
applications/godot/godot/
├── scripts/
│   ├── phenome_expand.gd                # NEW: pure turtle expander → ArrayMesh + wind-weight channel
│   ├── flora_view.gd                    # EXT: bucketed mesh cache, LOD bands + hysteresis,
│   │                                    #   consumes adapter seed/stage (32-B record)
│   └── species_palette.gd               # EXT if needed: species → grammar_id resolution
├── data/phenome_grammars.json           # consumed (Sprint 01; scene-side resolution, catalog precedent)
└── shaders/flora_wing.gdshader          # EXT: sway amplitude × wind-weight vertex channel
applications/godot/tests/godot/
├── godot_phenome_test.gd / .sh          # NEW: expansion ran, cache ≤ 7·K, LOD smoke, no per-frame expand
└── godot_screenshot.gd / .sh            # EXT: structural-content assertions
```

Untouched: `lib/`, `snapshot/`, adapter (Sprint 02 done), `104_contract` prose (evidence → Sprint 04).

## 3. Normative requirements

| # | Requirement | Source |
|---|---|---|
| R1 | `phenome_expand.gd` is a **pure function**: same `(grammar_id, variant_seed, stage, traits)` ⇒ identical geometry (vertex count + positions deterministic); expansion consumes `phenome_grammars.json` only — productions never hardcoded in GDScript (AP-23) | invariants 1/3 |
| R2 | Conformance: discrete derivation produced by the GDScript expander matches Sprint 01 golden symbol strings for sampled `(grammar, seed, stage, traits)` tuples — harness compares symbol strings (integer-exact), **not** float geometry (AP-24) | §1.1, invariant 2 |
| R3 | Mesh cache: `variant_seed` hashed into `K` buckets/species (default `K = 16`); cache ≤ `7·K` ArrayMeshes; re-expand **only** on (species, bucket, stage) change; no per-frame expansion; cache eviction/bounds asserted | invariant 10, AP-26 |
| R4 | LOD: distance bands select iteration-depth reduction (near/full, mid/−1, far/−2, floor ≥ 1); **hysteresis** prevents band flicker; LOD choice is presentation — never read back to sim, never sent (INV-017) | §1.1, invariant 9 |
| R5 | Wind-weight channel: per-vertex flexibility weight baked at expansion (trunk low, fronds high); `flora_wing.gdshader` scales sway by it; sway phase remains `TIME`-driven display-only — bytes unaffected (AP-19) | invariant 9 |
| R6 | Stage-driven structure: same plant's mesh at `stage+1` has iteration depth ≥ stage's (visible accretion); instance transform (position/yaw/scale) semantics unchanged from 0009 | invariant 5, 0006 §7 |
| R7 | Trait modulation visible: tolerant vs intolerant trait vectors for same seed produce different crowns/leaf counts per JSON modulation map (renderer applies traits exactly as declared) | §1.1, invariant 4 |
| R8 | Scene gate runs headless: expansion executed for all 95 seed-1 plants, cache ≤ 7·K, no `ERROR:` lines; screenshot assertions extended (structural silhouette ≠ primitive blobs) | §7 |

## 4. Tasks

1. Read milestone §1.1 (locked decisions incl. mesh strategy/LOD/wind), §3.1 renderer lane, Sprint 00 definitions (grammar semantics), Sprint 01 `phenome_grammars.json` + conformance goldens, Sprint 02 record fields, current `flora_view.gd` + `flora_wing.gdshader`, `tests/godot/godot_load_test.gd/.sh` (scene-test pattern).
2. Implement `phenome_expand.gd` (turtle: symbols, parametric productions, tropism term, wind channel); unit-path determinism.
3. Rework `flora_view.gd`: bucket lookup from `variant_seed`, stage-keyed cache, LOD bands + hysteresis; keep 0009 transform semantics.
4. Extend `flora_wing.gdshader` for wind-weight channel; resolve grammar JSON scene-side (catalog precedent).
5. Write `godot_phenome_test.gd/.sh`; extend screenshot assertions; run gate (§5) — **serial**, never parallel with other godot gates; exact PIDs only.

## 5. Acceptance criteria (this sprint's gate)

- [x] `bash applications/godot/tests/godot/godot_phenome_test.sh` PASS — expansion ran for all rendered plants; mesh cache ≤ `7·K`; no per-frame re-expansion (counter); LOD band switch + hysteresis verified; **conformance: GDScript symbol strings match Sprint 01 goldens** for sampled tuples.
- [x] `bash applications/godot/tests/godot/godot_load_test.sh` PASS (0 `ERROR:` lines) — schema-7 adapter + new scripts load.
- [x] `bash applications/godot/tests/godot/godot_screenshot.sh` PASS; PNG read by orchestrator shows **visible structure** (branches/fronds, mixed stages, not blobs); structural-content assertions green.
- [x] `bash applications/godot/tests/godot/godot_playability_test.sh` PASS (WASD + dig still work).
- [x] Zero stray processes (`pgrep -x godot` / `scr_sim_server` clean) after gates.

## 6. Constraints

- **AP-23:** grammar only from `phenome_grammars.json`; renderer may not invent/tune productions locally — JSON edits are Sprint 01 artifacts (Rule 19 if a rule needs changing).
- **AP-24:** conformance on symbol strings only.
- **AP-26:** expansion on change only; cache bounded; LOD hysteresis; measure frame-time before/after, record.
- **AP-19/12:** wind-weight + sway remain display-only; no sim readback of LOD or sway.
- **Serial gates:** never run two godot/server gates in parallel (ERR_BUSY); never `pkill -f`/`killall` — exact PIDs only.
