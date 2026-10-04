# Milestone 0010: Flora Phenome — L-System Morphology

**Program Increment:** v0.0.2
**Milestone:** 0010 — Flora Phenome (L-system structure, genotype→phenotype, LOD)
**Project:** Godot Simulation (applications/godot)
**Parent System:** Semantic Computational Runtime (SCR)
**Status:** Complete
**Primary Language:** Mojo (sim authority + reference expander) / GDScript (renderer expander)
**Initial Engine Provider:** Godot 4.7.2
**Binding Architecture:** Definition-first (extend `401_Morphology/Procedural` + new `704_Evolution/Phenotype`) + explicit contract change (schema 6 → 7: FLORA record gains `variant_seed` + `stage`; compact generative description only — no geometry on the wire)
**Scene Scope:** Structured plants — per-instance variant morphology, trait-modulated form, stage-driven development, distance LOD, wind-weighted sway
**Predecessor:** [milestone 0009](../milestone_0009_flora-upgrade/spec.md) (Complete) — living flora (field, growth, selection); this milestone upgrades *phenotype*, not ecology

---

## 1. Scope & Objective

Replace the primitive-blob phenotype (one merged cylinder/sphere mesh per species, uniform scale) with a **structured phenome**:

1. **L-system grammar per species** — axiom + parametric production rules + iteration depth driven by developmental stage; renderer expands to structured geometry (trunk, branches, fronds, leaves) via deterministic turtle expansion.
2. **Variant identity** — every plant carries an explicit `variant_seed` on the wire: same seed + stage ⇒ same structure, visually distinct individuals within a species.
3. **Genotype → phenotype** — the 0009 trait vector (ash/drought tolerance) modulates grammar parameters (documented map), so selection pressure produces *visible* differential form — closing `lib/704_Evolution`'s expected `phenotype` subdomain gap.
4. **Developmental stages** — quantized `stage` (from sim age) drives derivation depth: seedling → sapling → mature structure grows *branching complexity*, not just uniform scale.
5. **LOD + wind-weighted sway** — renderer-side distance LOD (iteration-depth reduction, hysteresis) and per-vertex flexibility weights consumed by the sway shader (still display-only on `TIME`).

**Definition-first (Rule 10):** Sprint 00 extends the name-level stub `lib/401_Morphology/Procedural` into a substantive grammar definition, creates `lib/704_Evolution/Phenotype`, and extends the Flora definition — gated before any implementation code (same discipline as 0009).

- **Sim** stays semantic authority: stage, variant seed, trait modulation are sim state; a **reference expander in Mojo** provides cross-implementation conformance vectors (not a per-tick cost).
- **Renderer** executes the grammar: expansion is a pure function `(grammar, seed, stage, traits) → structure` — `MORPHOLOGY-INV-017` provider independence: substituting the expander preserves the morphological contract.
- **Wire** carries the compact generative description only (`Morphology 101 §17 Repetition (line 577)`: "Repeated structure MAY be represented as a compact generative description rather than explicitly materialised instances"). **No geometry ever crosses the wire.**

### 1.1 Decisions Locked (confirmed with stakeholder before drafting)

| Decision | Choice | Rationale |
|---|---|---|
| Wire strategy | **Explicit: schema 6 → 7.** FLORA record `24 → 32 B`: existing fields + `u32 variant_seed` + `u8 stage` + `u8 pad[3]`. ABI stays **2**. Fixture regenerated. Adapter version gate proves itself again (7 accepted; 6 refused) | Sim is semantic authority — seed/stage are sim state, carried explicitly (SCR explicitness). Layout-neutral derivation (hash from anchor) rejected: re-derives sim semantics renderer-side |
| Expansion locus | **Renderer-side expansion + sim conformance.** L-string derivation runs in GDScript as a pure function; Mojo reference expander ships conformance vectors asserted in spec tests. Sim does **not** expand per tick | Zero per-tick geometry cost; INV-017 provider independence; conformance keeps the two honest |
| Conformance axis | Assert sim↔renderer agreement on the **discrete symbol derivation** (integer/rational production steps), **not** float geometry. Geometry determinism asserted per implementation | Cross-language float equality is a trap; the grammar's meaning lives in the derivation, not float bits |
| Genotype→phenotype | **Traits modulate grammar parameters** — documented map (e.g. ash tolerance → trunk diameter / crown density; drought tolerance → leaf count / droop angle); reserved traits 2–3 unused but reserved | Closes `704_Evolution`'s expected `phenotype` subdomain; makes 0009 selection visually legible |
| Grammar scope | **Full:** parametric L-systems for **all 7 species** + tropism term (phototropism/precession) + **distance LOD** + **wind-weight vertex attributes** | Stakeholder decision |
| Grammar data source | **Single-source JSON** (`godot/data/phenome_grammars.json`, `materials_catalog.json` precedent): axiom, productions, per-stage iteration table, tropism params, trait-modulation map. Mojo reference expander + GDScript expander both consume it; conformance test asserts both parse identically | AP-3 discipline: one vocabulary, no parallel grammar copies. Adapter/scene ship the file; sim reads it in tests |
| Stage model | `stage = f(age)` quantized per species maturity curve, global cap `STAGE_MAX = 15` (`u8`). Monotone non-decreasing (like age). Drives iteration depth; `scale(age)` continues to drive instance transform (0009 unchanged) | Structure complexity and physical size stay separate, explicit axes |
| Mesh strategy | Variant **bucketing**: `variant_seed` hashed into `K` buckets per species (default `K = 16`) → ≤ 7·16 = 112 cached `ArrayMesh`es, one `MultiMeshInstance3D` per bucket; bucket mesh re-expanded only on (species, bucket, stage) change | Caps memory/expansion cost at `FLORA_N_MAX = 4096`; avoids 4096 individual nodes |
| LOD | Distance bands select iteration depth reduction (e.g. far = −1, very-far = −2 steps, floor ≥ 1); **hysteresis** prevents band flicker. LOD is presentation: chosen at render, never sent, never affects sim (INV-017) | No wire cost; no semantics |
| Wind-weight attrs | Generated meshes carry a per-vertex flexibility weight (extra vertex color / UV channel); `flora_wing.gdshader` scales `TIME` sway by it (trunk rigid, fronds flexible). **Still display-only** — sway phase never enters bytes (0009 AP-19 stands) | Richer *how*, same *what*: TIME animation stays out of semantics |
| Rejected: sim-side structure state | Internode lists as sim state (collision/footprint future) — **out of scope** | Wire cost (KB/plant/stage-change), Rule 15; successor when a consumer exists |
| Rejected: geometry on wire | Mesh/vertex streaming per plant | AP-25; compact description only |

### 1.2 Open decision — confirm before Sprint 03 final

- **Bucket count `K` and LOD bands:** defaults proposed `K = 16`, 3 distance bands (near/full, mid/−1, far/−2). Tune against measured expansion cost + screenshot popping during Sprint 03; record final values in `parameters`/scene constants (Rule 19).

### 1.3 Governing Principle

> Never allow implementation convenience to silently redefine computational semantics.

```text
Semantic Meaning → Contract → Representation → Transformation → Lowering → Provider → Runtime → Execution Substrate
```

Phenome meaning lives in `lib/401_Morphology/Procedural` (grammar), `lib/704_Evolution/Phenotype` (trait→form), and `lib/705_Ecology/Flora` (conformance) — defined **before** code. The FLORA record carries the generative description (seed + stage); meshes are representations. If a production rule, tropism term, or trait-modulation constant exists only in renderer code, it is wrong (AP-23).

---

## 2. Lessons & Anti-pattern Constraints (Normative)

### 2.1 Continuing normative constraints — linked, not re-tabled

- [Milestone 0002 §2.1 AP-1 … AP-10](../../v0.0.1/milestone_0002_scene-initiation/spec.md).
- [Milestone 0006 §2.2 AP-11 … AP-14](../../v0.0.1/milestone_0006_ecology/spec.md) (presentation-owned ecology, display animation leaks, unbounded growth, parallel vocabulary).
- Milestone 0007 AP-11 … AP-14; [milestone 0008 §2.2 AP-15 … AP-18](../../v0.0.1/milestone_0008_ipc-transport/spec.md).
- [Milestone 0009 §2.2 AP-19 … AP-22](../milestone_0009_flora-upgrade/spec.md) (presentation-owned growth/evolution, RNG streams, implementation-before-definition, unbounded FLORA emission) — AP-19/20 bite hard here: expansion and sway discipline.

Their gates are re-run as this milestone's final gate set (§7).

### 2.2 New milestone-specific anti-patterns (this milestone only)

| # | Anti-pattern | Required correction |
|---|---|---|
| AP-23 | **Renderer-invented grammar** — productions/tropism/trait maps tuned directly in GDScript, spec backfilled later, or two divergent grammar copies (sim vs renderer) | Grammar single-sourced in `phenome_grammars.json`; sim reference expander + renderer consume it; conformance test asserts identical discrete derivations; Sprint 00 definitions precede any expansion code (Rule 10) |
| AP-24 | **Float-geometry conformance** — asserting sim↔renderer equality on vertex coordinates/turtle floats across languages | Conformance vectors = discrete symbol strings / production-step counts (integer-exact); float geometry determinism asserted **per implementation** only; documented in spec tests |
| AP-25 | **Geometry or structure lists on the wire** — internodes, vertices, L-strings streamed per tick | FLORA carries `variant_seed` + `stage` only (32 B record); §7 greps encode path for any struct-growth beyond the record; `Morphology §17 Repetition` compact-description rule cited in `104_contract` |
| AP-26 | **Expansion/thrash cost** — re-expanding meshes every frame, unbounded mesh cache, LOD flicker | Expansion only on (species, bucket, stage) change; mesh cache ≤ `7·K`; LOD hysteresis; stage quantization bounds re-expansion rate; gate: frame-time stall check + cache-size assert |

---

## 3. Architecture & Binding Contract

### 3.1 Layer diagram (delta over milestone 0009 §3.1)

```text
┌─────────────────────────────────────────────────────────────────────────┐
│ SCR semantic library (lib/) — meaning, authoritative                    │
│   401_Morphology/Procedural (EXTENDED: axiom/production/derivation,     │
│        tropism, termination, determinism — closes parent §70 open Q11/12)│
│   704_Evolution/Phenotype (NEW: genotype→phenotype mapping semantics)   │
│   705_Ecology/Flora (EXTENDED: phenome conformance section)             │
│   401_Morphology §18/§25/§17 (branching, rule-based growth,             │
│        compact generative description — parent authority)               │
└───────────────────────────────┬─────────────────────────────────────────┘
                                ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ Mojo simulation core — src/mojo/ (semantic authority)                   │
│   + sim/phenome.mojo : stage = f(age), variant_seed hash, trait→param   │
│                        modulation map (pure)                            │
│   + phenome/expand.mojo : REFERENCE expander (conformance vectors only) │
│   + data/phenome_grammars.json : single-source grammar (parsed in tests)│
│   output: RenderSnapshot — FLORA record now 32 B (seed + stage)         │
└───────────────────────────────┬─────────────────────────────────────────┘
                                │ C ABI — schema 7, ABI 2 unchanged
                                ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ Provider adapter — C++ : decode/validate new fields (stage ≤ 15),       │
│   pass-through; grammar file resolved scene-side (catalog precedent)    │
│   NO expansion, NO grammar decisions                                    │
└───────────────────────────────┬─────────────────────────────────────────┘
                                ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ Godot scene                                                             │
│   + godot/scripts/phenome_expand.gd : turtle L-system expansion        │
│       pure fn (grammar, seed, stage, traits) → ArrayMesh                │
│   flora_view.gd : bucketed mesh cache (K/species), LOD bands +          │
│       hysteresis, wind-weight vertex channel                            │
│   flora_wing.gdshader : sway × wind-weight (display-only on TIME)       │
└─────────────────────────────────────────────────────────────────────────┘
```

### 3.2 Contract change — schema 6 → 7 (normative draft for `104_contract.md` §4.3 §10)

**Section `10 — FLORA`, record `24 → 32` bytes** (additive fields appended; existing offsets unchanged):

| Off | Type | Field |
|---|---|---|
| 0 | f32×3 | `position` (unchanged) |
| 12 | f32 | `yaw` (unchanged) |
| 16 | f32 | `scale` (unchanged — 0009 growth) |
| 20 | u32 | `species_id` (unchanged) |
| 24 | u32 | `variant_seed` **NEW** — sim-pure hash; identity of the generative description |
| 28 | u8 | `stage` **NEW** — developmental stage `0..STAGE_MAX (= 15)`, monotone non-decreasing in age |
| 29 | u8×3 | `pad` **NEW** = 0 |

Section bytes = `4 + 32·count` (max 131,076 B at `FLORA_N_MAX`). `SCR_SIM_SCHEMA_VER` **6 → 7**; `SCR_SIM_ABI_VERSION` stays **2** (no ABI symbol change — snapshot schema only). FAUNA/TERRAIN/… byte-identical semantics. Adapter validation additions: `stage ≤ 15`, `pad == 0`, `section_bytes == 4 + 32·count`; ranges `species_id ∈ [1,7]`, `scale > 0`, `count ≤ 4096` unchanged. Emission rule (0009 change-driven) gains triggers: `variant_seed` or `stage` change vs last emission.

### 3.3 Data flow rules (inherited, unchanged)

Down: sim tick → project (pure) → encode → adapter decode → node update. Up: input/edit only. One state channel. Transports (in-process + socket `SCR_SIM_IPC_PACE=manual`) carry the new bytes unchanged — 0008 gates re-run.

### 3.4 Timestep, development, display animation

60 Hz fixed. `stage` advances in the tick phase with age (quantized; monotone). Expansion runs **renderer-side, only when (species, bucket, stage) changes** — never per frame, never in sim (AP-26). Sway/wind stays shader-`TIME` display-only; wind-weight is a vertex *channel*, not state (AP-19). Instance transform (position/yaw/scale) unchanged from 0009.

---

## 4. Semantic Library Consumption

| Domain / ID | Concept consumed (verified on disk) | Consumption mode |
|---|---|---|
| `SCR-LIB-MORPHOLOGY-PROCEDURAL` (`lib/401_Morphology/Procedural` — **stub today; EXTENDED in Sprint 00**) | "Grammar-based, fractally recursive, and parametric procedural generation of structures" — extended to: alphabet/axiom, production rules, derivation step, iteration depth, termination, determinism, parametric tropism | **Spec-first:** Sprint 00 authors the substantive 101; sprints 01/03 implement exactly it; definition is the conformance-review oracle |
| `SCR-LIB-EVOLUTION-PHENOTYPE` (`lib/704_Evolution/Phenotype` — **NEW in Sprint 00**) | Genotype (trait vector) → phenotype (form parameters) mapping; distinction from selection; `EVOLUTION-INV-004` variation manifests in form; `INV-011` environmental inputs explicit; 704 101's own tree lists `phenotype` as expected subdomain | **Spec-first:** defines the trait-modulation map semantics sprints 01–03 implement; firewall: phenotype maps form, it does not redefine selection (704) or growth (Morphology/Growth) |
| `SCR-LIB-ECOLOGY-FLORA` (`lib/705_Ecology/Flora` — 0009 Sprint 00) | §1.3 growth conformance; new phenome-conformance section (Sprint 00 edit) | Extended: structure complexity is developmental (stage), consistent with age/`ECOLOGY-INV-010` temporal explicitness |
| `SCR-LIB-MORPHOLOGY` parent (`lib/401_Morphology/101`) | §18 Branching (`:583`), §25 Growth "rule-based growth" (`:756`), §17 Repetition compact generative description (line 577), §70 open questions 11/12 (`:2027`) | Authoritative context; Sprint 00 closes the Procedural child without editing the parent (parent open-questions row noted as addressed-by-child in docs) |
| `SCR-LIB-GRAPH-HYPERGRAPH` (`lib/203_Graph/Hypergraph`) | §16 `input pattern → Transformation → output pattern` (nearest production concept), §29 "must be capable of representing the future SCR morphology model" | Background only — **not implemented**; no graph-rewriting contract consumed (MAY-bullets insufficient) |
| `SCR-LIB-SPATIAL-VOXEL-SYNTHESIS` §3 + `A01_Render/Material` | Species vocabulary; material catalog | Unchanged (0006/0009) |

**Not consumed:** `203_Graph` rewriting (aspirational only), `905_Transforms` §12 Rewrite (general, not morphological), MLIR dialects (non-goal), `503_Simulation/Reproduction` (stub untouched).

---

## 5. Deliverables & Sprint Breakdown

```text
lib/                                             # Sprint 00 — definitions BEFORE code
├── 401_Morphology/Procedural/101_definition.md  # EXTENDED: grammar semantics (axiom, productions,
│                                                #   derivation, tropism, termination, determinism)
├── 704_Evolution/Phenotype/
│   ├── 101_definition.md                        # NEW: genotype→phenotype mapping
│   ├── 102_status.yaml                          # NEW
│   └── 103_library.graph.json                   # NEW (controlled vocabulary)
├── 705_Ecology/Flora/101_definition.md          # EXTENDED: phenome conformance §1.6
├── 704_Evolution/102_status.yaml                # EXTENDED: subdomain list + status
└── 705_Ecology/Flora/102_status.yaml            # EXTENDED: status touch

applications/godot/
├── godot/data/phenome_grammars.json             # NEW: single-source 7 species grammars
├── src/mojo/
│   ├── sim/phenome.mojo                         # NEW: stage quantization, variant_seed, trait map (pure)
│   ├── phenome/expand.mojo                      # NEW: reference expander (conformance vectors)
│   ├── sim/world.mojo                           # EXT: stage advance in tick phase
│   ├── sim/runtime.mojo                         # EXT: emission triggers (seed/stage change)
│   ├── sim/parameters.mojo                      # + STAGE_MAX, seed salts, modulation params
│   ├── snapshot/types.mojo, encode.mojo         # EXT: 32-B record (schema 7)
│   └── snapshot/decode.mojo                     # EXT: round-trip + validation
├── providers/render/graphics/godot/
│   ├── 104_contract.md                          # §4.3 §10 record 32 B, schema 7, validation, §17
│   ├── 102_status.yaml                          # capability note
│   └── adapter/scr_godot_abi.h, scr_godot_adapter.cpp  # schema 7, decode + validation
├── godot/scripts/
│   ├── phenome_expand.gd                        # NEW: turtle L-system expander (pure)
│   ├── flora_view.gd                            # EXT: bucketed cache, LOD, wind channel
│   └── ../shaders/flora_wing.gdshader           # EXT: wind-weighted sway (display-only)
├── tests/mojo/
│   ├── test_phenome_grammar.mojo                # NEW: stage/seed/modulation + conformance vectors
│   ├── test_flora_growth/evolution/placement    # EXT: seed/stage fields
│   ├── test_envelope.mojo                       # EXT: 32-B framing, malformed rejection
│   ├── test_determinism.mojo, test_projection_purity.mojo  # EXT
│   └── gen_golden_fixture.mojo                  # RUN: schema-7 fixture
├── tests/godot/
│   ├── godot_phenome_test.gd / .sh              # NEW: expansion ran, bucket count, LOD smoke
│   └── godot_screenshot.gd / .sh                # EXT: structural-content assertions + evidence
├── tests/fixtures/snapshot_seed1_tick1.bin      # REGENERATED (schema 7)
├── docs/04_simulation_engine.md                 # + phenome model, grammar tables, params, evidence, AP review
├── docs/06_roadmap.md                           # + 0010 row
└── program_increments/v0.0.2/milestone_0010_flora-phenome/spec.md   # this file
```

### Sprint 00 — Definitions (Rule 10 gate; no `applications/` or `src/mojo` changes)

- **Extend `lib/401_Morphology/Procedural/101_definition.md`** from 57-line stub to substantive definition: alphabet/symbols (modules with parameters), axiom, production rules (context-free parametric), derivation step semantics, iteration depth, termination bounds, determinism, tropism as parametric term, conformance to parent `MORPHOLOGY-INV-001/002/016/017/018`; explicitly addresses parent §70 open questions 11 (Procedural morphology) and 12 (Morphological grammars).
- **New `lib/704_Evolution/Phenotype/`** (101 + 102 + 103): genotype (trait vector) → phenotype (form parameters) mapping; distinction from selection and from growth; `EVOLUTION-INV-004/011/018` conformance; relationships (`704 CONTAINS Phenotype`, `Phenotype INTERACTS_WITH Morphology/Procedural`, `Phenotype INTERACTS_WITH Flora`).
- **Extend `lib/705_Ecology/Flora/101_definition.md`** with §1.6 Phenome Conformance (structure complexity = developmental stage; generative description = representation; seed/stage are instance identity state) + relationship row + invariants row.
- Update `102_status.yaml` files (subdomain lists, `last_updated`); `103` for Phenotype with **controlled vocabulary only**.
- **Gate:** `scr-domain-validator` zero findings on the three touched domains; `git diff` ⊆ listed `lib/` paths (AP-21); stubs `503_Simulation/Reproduction`, `203_Graph/*` untouched.

### Sprint 01 — Sim phenome core + reference expander (Mojo)

- `sim/phenome.mojo`: `stage_for_age(species, age)` quantized, monotone, `0..STAGE_MAX`; `variant_seed(cell, seed, salt)` pure hash; trait→grammar-parameter modulation map (reads `phenome_grammars.json`-declared modulation spec — parse in tests; runtime map compiled to `parameters.mojo` constants with a conformance test asserting constants == JSON).
- `phenome/expand.mojo`: reference turtle expander producing the **discrete derivation** (symbol string with parameters) for `(grammar, seed, stage, traits)` — used only by tests to emit conformance vectors (goldens checked into `tests/fixtures/phenome/`).
- World tick: stage advance (with age); emission dirty on stage/seed change (extends 0009 rule).
- Tests `test_phenome_grammar.mojo`: stage quantization (monotone, bounds, per-species maturity), seed determinism/variance, modulation effects (tolerant trait ⇒ declared parameter shift, exact value vs JSON map), reference-expansion determinism + golden vectors, stage-monotone structure growth (iteration depth non-decreasing).

### Sprint 02 — Contract (schema 7) + fixture + adapter

- `104_contract.md`: record table (§3.2), schema 7, validation additions, emission triggers, §17 Repetition citation; `scr_godot_abi.h` `SCR_SIM_SCHEMA_VER 7`; adapter decode/validation/comments.
- Encode/decode 32-B record; `test_envelope` framing + malformed `pad`/`stage` rejection; fixture regen (schema 7, ~131 KB-class FLORA section); `test_golden_fixture`; `abi_smoke` updated to assert 7/2; `test_schema_mismatch` (7 accepted; 6 and 8 refused; ABI 2/3 as before).
- `test_flora_growth/evolution/placement`, `test_determinism`, `test_projection_purity` extended for seed/stage.

### Sprint 03 — Renderer (expansion + LOD + wind)

- `godot/data/phenome_grammars.json` finalized (7 grammars: axiom, productions, stage→depth table, tropism, modulation map).
- `phenome_expand.gd`: pure turtle expansion → `ArrayMesh` (trunk/branch cylinders, leaf/frond quads), wind-weight vertex channel, deterministic per `(grammar, seed, stage, traits)`.
- `flora_view.gd`: bucketed mesh cache (`K`/species), re-expand on (species, bucket, stage) change only, LOD bands + hysteresis; adapter resolves grammar file (catalog precedent).
- `flora_wing.gdshader`: sway amplitude × wind-weight channel (TIME still display-only).
- Scene gate `godot_phenome_test.gd/.sh`: expansion executed, cache ≤ `7·K`, no per-frame re-expansion, LOD bands switch with hysteresis.

### Sprint 04 — Docs + verification

- `docs/04`: phenome domain model (traced to Sprint 00 definitions), grammar summary tables, trait-modulation map, stage table, params, evidence (structural screenshot + growth/LOD numbers), honest limitations (no sim-side structure, no reproduction, conformance axis), AP-1..26 review table; `docs/06` 0010 row; spec Status flip.
- Full §7 gate run (serial, both transports, PNGs read).

---

## 6. Formal Invariants

1. **Definition-authority invariant:** Sprint 00 gate green before any code; every grammar/modulation/stage behavior traceable to `401_Morphology/Procedural`, `704_Evolution/Phenotype`, `705_Ecology/Flora`, or this spec (Rule 10, AP-23).
2. **Grammar determinism invariant:** `(grammar_id, variant_seed, stage, traits)` ⇒ identical discrete derivation, run-twice, both implementations (conformance axis = discrete symbols, AP-24).
3. **Single-source grammar invariant:** exactly one grammar artifact (`phenome_grammars.json`); sim constants and renderer tables are derived/mirrored and conformance-tested against it (AP-3/AP-23).
4. **Genotype→phenotype invariant:** trait modulation is a pure, documented map asserted value-exact in tests; selection (704) and growth (Morphology/Growth) meanings unchanged (INV-013 firewall from 0009 stands).
5. **Development invariant:** `stage` monotone non-decreasing in `age`, bounded `0..STAGE_MAX`; iteration depth non-decreasing in stage (structure accretes, never regresses without death/regrowth).
6. **Compact-description invariant:** wire carries `variant_seed` + `stage` only — no geometry, no symbol strings, no internodes (AP-25); record exactly 32 B, `pad == 0`.
7. **Contract version invariant:** schema bump by exactly +1 (6 → 7), ABI stays 2, fixture regenerated, adapter refuses schema ≠ 7 (negative test), all other sections byte-identical semantics.
8. **Projection purity invariant:** stage/seed computation in tick phase; projection read-only (0009 §6.7 extended fingerprint includes stage/seed).
9. **Display separation invariant:** LOD choice and sway phase never enter bytes; wind-weight is a mesh channel, not sim state (AP-19).
10. **Cost invariant (AP-26):** mesh cache ≤ `7·K`; expansion only on (species, bucket, stage) change; LOD has hysteresis; no per-frame expansion (scene test asserts).
11. **Scope invariant:** no sim-side structure state, no reproduction, no sim-wind semantics, no MLIR grammar dialect, no voxel flora — successors (§9).

---

## 7. Exit Criteria

All commands from repo root; `M=.venv/bin/mojo`.

- [x] **Definition gate (Sprint 00 — blocking):** `scr-domain-validator` zero findings on `401_Morphology/Procedural`, `704_Evolution/Phenotype` (+ `103`), `705_Ecology/Flora`; Sprint 00 diff ⊆ `lib/` paths; controlled vocabulary in the new `103`.
- [x] **Grammar core (automated):** `M run … test_phenome_grammar.mojo` — stage quantization, seed determinism/variance, modulation value-exact vs JSON, reference-expansion golden vectors, stage-monotone depth.
- [x] **Conformance (automated):** sim↔renderer derivation agreement — golden symbol strings from `tests/fixtures/phenome/` match the GDScript expander output for the same `(grammar, seed, stage, traits)` (harness script runs Godot headless or pre-exports vectors; discrete axis only).
- [x] **Existing flora suites (automated):** `test_flora_growth`, `test_flora_evolution`, `test_flora_placement`, `test_determinism`, `test_projection_purity`, `test_envelope` extended for 32-B records — all PASS.
- [x] **Full suite (automated):** all mojo spec-test files PASS (`MOJO_FAILS=0`).
- [x] **Fixture + versions (automated):** `gen_golden_fixture` re-run; `test_golden_fixture` PASS; `abi_smoke.py` asserts schema **7**/ABI **2**; `test_schema_mismatch.sh` — 7 accepted, **6 and 8 refused**; `check_layout.sh` PASS.
- [x] **Build (automated):** `build_godot_provider.sh` PASS (adapter decodes 32-B records).
- [x] **Scene gates (automated):** `godot_load_test.sh` (0 `ERROR:` lines); new `godot_phenome_test.sh` PASS (expansion ran, cache ≤ 7·K, LOD hysteresis, no per-frame re-expansion); `godot_playability_test.sh` PASS.
- [x] **Rendered evidence (automated screenshot + PNG read):** `godot_screenshot.sh` PASS with extended flora content assertions (count > 0; **structural content**: species meshes differ from primitive blobs — e.g. visible branch/frond silhouette); PNG read by orchestrator; LOD far-capture documented.
- [x] **Transport gates re-run:** in-process smoke + `SCR_SIM_TRANSPORT=socket SCR_SIM_IPC_PACE=manual godot_ipc_smoke.sh` + `test_ipc_determinism.sh` PASS (schema-7 bytes identical across transports).
- [x] **Full lineage gate set:** milestone 0002 §8 procedures in `docs/04` re-run PASS.
- [x] **Review pass:** AP-1..26 item-by-item table in `docs/04`; Sprint 00 checklist + honest limitations recorded.
- [x] **Roadmap:** `docs/06` 0010 row Complete; spec `Status: Complete`.

---

## 8. Dependencies

- **Predecessor:** [milestone 0009](../milestone_0009_flora-upgrade/spec.md) (Complete) — stage/age/trait foundations.
- **Semantic contracts:** `lib/401_Morphology/Procedural` (extended), `lib/704_Evolution/Phenotype` (new), `lib/705_Ecology/Flora` (extended), `lib/401_Morphology` parent, `lib/A01_Render/Material`.
- **Contract surface:** [`104_contract.md`](../../../providers/render/graphics/godot/104_contract.md) (§4.3 §10 + schema §7), [`docs/04_simulation_engine.md`](../../../docs/04_simulation_engine.md), [`docs/06_roadmap.md`](../../../docs/06_roadmap.md).
- **Prior art (concepts only):** `applications/cave/include/procedural_vegetation.hpp` (EZ-Tree recursion, phototropism, phyllotaxis) — Ogre/C++, not wired to Godot; portable ideas, no code reuse.
- **Toolchain:** unchanged (Mojo 1.0.0, Godot 4.7.2, godot-cpp).

---

## 9. Out of Scope

- **Sim-side structure state** (internode lists as world state; collision/footprint of plants) — successor when a consumer exists.
- **Reproduction / inheritance of grammar parameters across generations** — `503_Simulation/Reproduction` stub untouched (0009 §9 carries).
- **Sim wind semantics** (wind field as sim state driving sway phase) — 0009 §9 successor stays; this milestone only enriches display-side displacement.
- **MLIR grammar/rewrite dialect** — repo non-goal (docs/06 carried non-goals).
- Voxel/lattice flora (Synthesis §3) — still open (0009 §9).
- New species beyond the 7 (vocabulary = Synthesis §3, unchanged).

---

## 10. Successor Milestones

| Intent | Triggering contracts |
|---|---|
| Sim-side structure consumers (plant collision, footprint, falling debris interacts with canopy) | Structure-as-state decision, `501_Physics`, Hypergraph §29 morphology model |
| Generational inheritance of phenotype (offspring inherit seed/trait grammar params) | `704_Evolution INV-006/007`, `503_Simulation/Reproduction` |
| Sim-wind-driven sway as semantics (phase in bytes) | `705_Ecology` §17, `501_Physics/Field`, 0009 §9 wind successor |
| Graph-rewriting/production grammar contract (if L-system outgrown) | `203_Graph` §18–20 promotion from MAY to contract, `Hypergraph §16` |
| Voxel/lattice flora | `801_Spatial/Voxel/Synthesis` §3 |

Exact sequencing and exit criteria of successors: `TBD — future milestone` (Rule 10).
