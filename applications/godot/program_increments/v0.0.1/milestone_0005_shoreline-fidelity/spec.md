# Milestone 0005: Shoreline Fidelity — Foam + Crater Material Blending

**Program Increment:** v0.0.1
**Milestone:** 0005 — Shoreline fidelity & crater material blending
**Project:** Godot Simulation (applications/godot)
**Parent System:** Semantic Computational Runtime (SCR)
**Status:** Planned
**Primary Language:** Mojo
**Initial Engine Provider:** Godot 4.7.2
**Binding Architecture:** RenderSnapshot contract + in-process GDExtension (godot-cpp)
**Scene Scope:** Core slice — shoreline foam band, feathered crater/terrain material transitions, quench evaluator (catalog reaction)
**Predecessor:** [milestone_0002_scene-initiation/spec.md](../milestone_0002_scene-initiation/spec.md) (Complete)
**Siblings (optional interactions):** [milestone 0003](../milestone_0003_volcano/spec.md), [milestone 0004](../milestone_0004_atmosphere-weather/spec.md) — independent; §3.6 rebase rule

---

## 1. Scope & Objective

Fix the two documented 0002 display defects at their semantic roots and close
the recorded `SCR-LIB-RENDER-WATER` deviation:

1. **Shoreline foam:** the contract intent is shore foam from
   `y_terrain(x,z)` vs `y_water(x,z,t)`; today the ocean shader approximates
   crest foam only and a white ring artifact sits at the surf line
   (`docs/04_simulation_engine.md` §7 deviation, §8.1 fixes). This milestone
   fulfills the contract properly.
2. **Crater material blending:** crater rim "teeth" (alternating sulfur/basalt
   cells + first-vertex material grouping, `docs/04` §8.1) are fixed
   sim-side in voxel synthesis — smooth, feathered material transitions.
3. **Quench evaluator (sub-slice c):** completes the `lava_water_quench`
   reaction marked documented-partial in [milestone 0003](../milestone_0003_volcano/spec.md).

- **Sim** owns a foam/depth field and boundary material blending (both are
  semantics); **Godot** shades what the contract delivers.
- **Contract:** new section `SHORE_FOAM`, TERRAIN per-vertex material
  representation extended → `SCR_SIM_SCHEMA_VER` bump (§3.5).

This milestone fulfills the 0002 deferred note *"shoreline foam fidelity"*
(`docs/06_roadmap.md` → "Explicit Non-Goals Carried Forward") and the
`SCR-LIB-RENDER-WATER` row of 0002 §4.

### 1.1 Decisions Locked (architectural, confirmed before drafting)

| Decision | Choice | Rationale / rejected alternative |
|---|---|---|
| **(a) Foam authority** | **Sim computes a low-resolution foam/depth field into the snapshot** (`SHORE_FOAM` section); adapter uploads it as a texture; ocean shader only shades it — **LOCKED** | Foam from `y_terrain − y_water` *is* sim physics (shore contact, wave phase). Sim already owns both the height field and Gerstner state. **Rejected alternative:** adapter deriving foam from existing TERRAIN + OCEAN sections — the adapter would re-implement terrain sampling + Gerstner phase evaluation at frame rate = a second semantic authority (AP-8 / `Provider ≠ Semantic Authority`), plus it must recompute every frame while TERRAIN is emitted only on regeneration |
| Foam field resolution | **Full terrain grid `grid_n × grid_n` (64×64), `f32` per cell ∈ [0,1]** — locked | Aligns 1:1 with `IslandSubject` height field (no resampling error); 16 384 B/snapshot ≈ 7% of the 228 KB schema-1 fixture — acceptable; uniform `f32` matches existing contract style. Rejected: u8 packing (quantization of a *contract* field for minor savings) and half-res grid (double lookup, no clarity gain) |
| Foam formula | `Δy = y_water(x,z,t) − y_terrain(x,z)`; `Foam_shore = clamp(1 − Δy/d_foam, 0, 1)² · (0.6 + 0.4·sin(6·Δy − 4·t))`, `d_foam = 1.8 m` — verbatim from `lib/A01_Render/Water/101_definition.md` §3 — locked | Normative library formula; parameters in `parameters.mojo` (AP-7). Crest foam display path (0002 Jacobian thresholds) unchanged — dual-zone foam per Water §1 |
| **(b) Material blending** | **Synthesis emits per-vertex blend tuples**; representation change: TERRAIN vertex payload `material_ids: u32×V` → `(material_id u8, blend_id u8, blend_weight u8, pad u8)×V` (stride-neutral 4 B/vertex) — **LOCKED** | Blending is a synthesis semantic (Synthesis is the *sole authoritative mapping* to materials). Per-vertex dominant + neighbor + weight lets the adapter render a feathered band with existing per-dominant-id surfaces. Rejected: adapter-side post-hoc smoothing (would modify material assignment outside the pipeline — violates Synthesis §1); rejected: full material-weight vectors per vertex (overkill; only boundary pairs matter) |
| Blend mixing location | **Adapter resolves blended albedo** = `mix(albedo[dominant], albedo[blend], w)` from catalog entries, vertex-color path (`vertex_color_use_as_albedo`) — locked | Representation conversion only (catalog-derived, deterministic). Rejected: shader lookup table over all 96 materials (custom terrain shader + more surface semantics at the boundary). Recorded limitation: roughness/opacity stay the dominant material's (per-vertex roughness unsupported by `StandardMaterial3D`) |
| Blend constraints | Feather band width `FEATHER_WIDTH_CELLS` + deterministic noise dither from `noise_context`; **blend pairs restricted to the two adjacent biomes' permitted surface materials** — locked | Preserves Synthesis §2 rule: fine detail "MUST NOT override the biome surface material with a material from a different biome" — blending never introduces e.g. sand into `CALDERA_RIM` |
| **(c) Quench** | Reaction evaluator implemented against `material_reactions.json` verbatim (face-sharing lava+water → obsidian/cobblestone + steam); evaluated at synthesis/world-gen adjacency — locked | 0003 declared partial; evaluator needs no new semantics beyond the catalog. Live lava-reaches-sea activation requires eruption/flow semantics — `TBD — future milestone` (recorded honestly in §9) |
| Schema evolution | `SCR_SIM_SCHEMA_VER` **+1 over then-current** (nominal 2/3/4 depending on sibling order — §3.5); fixture regen; adapter + negative test updated — locked | TERRAIN representation change + new section both require it (0002 §7 of `104_contract.md`: additive changes bump; adapters MUST NOT guess) |

### 1.2 Governing Principle

> Never allow implementation convenience to silently redefine computational semantics.

```text
Semantic Meaning → Contract → Representation → Transformation → Lowering → Provider → Runtime → Execution Substrate
```

Foam and material assignment are semantics owned by the sim and its synthesis
pipeline; the adapter converts representation; the shader shades.


### 1.3 Open decisions (confirm before drafting final)

Everything above is locked as recommended default. Items seeking explicit
confirmation before the contract is finalized:

1. **TERRAIN blend tuple layout** — `(u8 material_id, u8 blend_id, u8 blend_weight, u8 pad)` stride-neutral (recommend, §1.1) vs wider u32 blend fields (extra 8·V bytes/chunk) —
   **Open decision — confirm before drafting final**.
2. **SHORE_FOAM emission cadence** — every snapshot (recommend, §3.2; foam tracks wave phase) vs suppressed-until-regeneration (would freeze the surf line — rejected as a semantic defect) —
   **Open decision — confirm before drafting final**.
3. **Crater-rim teeth evidence** — documented manual capture (recommend, §7) vs automated luminance-ripple check (stretch, marked `TBD`) —
   **Open decision — confirm before drafting final**.

---

## 2. Lessons & Continuing Anti-Pattern Constraints

`AP-1 … AP-10` ([milestone 0002 §2.1](../milestone_0002_scene-initiation/spec.md)),
`AP-11 … AP-14`
([milestone 0003 §2.1](../milestone_0003_volcano/spec.md)), and
`AP-15 … AP-18` ([milestone 0004 §2.1](../milestone_0004_atmosphere-weather/spec.md))
**remain normative** (not restated).

### 2.1 New anti-patterns (this milestone)

| # | Anti-pattern | Evidence / rationale | Required correction |
|---|---|---|---|
| AP-19 | Display approximation presented as contract compliance | 0002 shipped crest-only foam while the library contract says shore foam (`docs/04` §7 "Deviation … recorded, not silent") — deviation was honest, but leaving it makes the ring artifact permanent | Foam now computed from the library formula in sim; `docs/04` §7 deviation note replaced by implemented status + residual crest-display note |
| AP-20 | Material assignment outside the synthesis pipeline | Crater "teeth" were diagnosed as biome-band alternation + first-vertex grouping; a quick fix would repaint materials in the adapter/shader | Blending happens inside `synthesis/` (sole authoritative mapping); conformance test extended so no material exists that synthesis did not assign |
| AP-21 | Representation change without schema bump | TERRAIN vertex payload changes meaning (u32 id → u8 triple) while byte count stays identical — a *silent* semantic reframe, worse than a size change | Explicit `SCR_SIM_SCHEMA_VER` bump + fixture regen + adapter decode update + negative test in the same sprint (0003 AP-13 discipline) |
| AP-22 | Two foam authorities | After adding shore foam, shader crest foam (display thresholds) and sim shore foam could drift into double-counting white | Zones are disjoint by definition: sim field drives the *shore* band (`Δy` near surface), display crest foam stays Jacobian/height-based; documented in `docs/04` §7 with thresholds |

---

## 3. Architecture & Binding Contract

### 3.1 Layer diagram (delta over 0002 §3.1)

```text
┌─────────────────────────────────────────────────────────────────────────┐
│ SCR semantic library (lib/) — meaning, authoritative                    │
│   A01_Render/Water (shore foam formula) · 801_Spatial/Voxel/Synthesis   │
│   (sole material mapping + invariants) · 302_Geometry (mesh =           │
│   representation) · 301_Field (foam field) · A01_Render/Material        │
│   (catalog + material_reactions.json)                                   │
└───────────────────────────────┬─────────────────────────────────────────┘
                                │ contracts consumed by semantic ID
                                ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ Mojo simulation core — src/mojo/                                        │
│   + sim/shore.mojo: foam field F(x,z,t) from height field + Gerstner    │
│   ~ synthesis/: boundary blend (feather band + dither), blend tuples    │
│   + synthesis/ (or sim/): quench evaluator (face-sharing adjacency)     │
│   output: RenderSnapshot (schema N+1: SHORE_FOAM + TERRAIN blend tuple) │
└───────────────────────────────┬─────────────────────────────────────────┘
                                │ C ABI (.so) — unchanged symbol set
                                ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ Provider: providers/render/graphics/godot/adapter/                      │
│   decode SHORE_FOAM → ImageTexture upload; TERRAIN blend tuples →       │
│   per-vertex blended albedo (catalog mix)                               │
└───────────────────────────────┬─────────────────────────────────────────┘
                                ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ Godot application — godot/                                              │
│   island.tscn: ocean shader samples shore-foam texture (shore band      │
│   only); terrain vertex colors = blended albedo (no teeth)              │
└─────────────────────────────────────────────────────────────────────────┘
```

Data-flow rules and fixed-timestep model carry forward unchanged (0002
§3.3–§3.4).

### 3.2 Payload sections after this milestone

| Section | Change | Content |
|---|---|---|
| 1–2, 4–8 | unchanged | PLAYER, TERRAIN_META, OCEAN, SKY (+0004 fields if present), MATERIALS (+0003 sections if present) |
| **3 TERRAIN** | **extended (representation change)** | per-chunk vertex payload: `material_ids u32×V` → records `(material_id u8, blend_id u8, blend_weight u8 (0..255 ⇒ 0..1), pad u8)×V`; all other chunk fields unchanged |
| **9 SHORE_FOAM** (new) | new | `grid_n u32`, `cell_size f32`, `sea_level f32` (3× headers = 12 B) + `grid_n² × f32` foam values ∈ [0,1] (row-major, cell centers, world xz aligned with the terrain grid) — 16 400 B at `grid_n = 64`. Emitted **every snapshot** (foam evolves with wave phase) |

### 3.3 Foam computation (sim)

```text
for each cell (i,j):
  y_t = height_field(i, j)                    # IslandSubject (SCR-LIB-FIELD)
  y_w = gerstner_y(world_x, world_z, t)       # HydrologySubject authority
  Δy   = y_w - y_t
  F    = clamp(1 - Δy / FOAM_DEPTH_M, 0, 1)^2 * (0.6 + 0.4*sin(6.0*Δy - 4.0*t))
```

`FOAM_DEPTH_M = 1.8` (library value). Cells with `Δy >= FOAM_DEPTH_M`
(deep water) ⇒ 0; land cells above max wave reach ⇒ 0. Pure function of world
state — projection reads, never mutates (purity test extended).

### 3.4 Synthesis blending (sim)

- Boundary detection: adjacent columns whose biome surface materials differ.
- Within `FEATHER_WIDTH_CELLS` of a boundary, assign
  `(dominant, blend, weight)` ramp + deterministic noise dither from
  `noise_context` (same seeded noise family as 0002 synthesis).
- Invariants preserved: bedrock/sea-level rules, "no cross-biome surface
  override" (blend pairs ⊂ adjacent biomes' permitted surface sets),
  pipeline purity/write-once.
- Fixes crater rim: `VOLCANIC_SLOPE` (BASALT) ↔ `CALDERA_RIM`
  (ASH/SULFUR/OBSIDIAN) boundary gets a feathered band instead of
  cell-alternating slivers; first-vertex grouping artifact resolved because
  blend weights interpolate across the seam.

### 3.5 Scene binding (adapter/shader)

| Group | Node | Section | Applied as |
|---|---|---|---|
| `scr_ocean` | ocean `ShaderMaterial` | `9 SHORE_FOAM` | adapter uploads grid as `ImageTexture`; shader samples `foam_shore` by world xz; **replaces** the white-ring approximation; crest foam path (0002 display thresholds) unchanged |
| `scr_terrain` | chunk `MeshInstance3D` | `3 TERRAIN` | surfaces still grouped by dominant id; per-vertex blended albedo written as vertex color with `vertex_color_use_as_albedo`; catalog lookup from MATERIALS |

### 3.6 Schema evolution & sibling rebasing (this milestone)

- `SCR_SIM_SCHEMA_VER` **+1 over the then-current value** (nominal **2** if
  0005 executes first, **3** after one sibling, **4** after both). Required by
  *two* changes: new section + TERRAIN payload meaning.
- Golden fixture regenerated (`tests/mojo/gen_golden_fixture.mojo`);
  `test_envelope.mojo`, `abi_smoke.py`, mismatch stub (= `SCR_SIM_SCHEMA_VER
  + 1`, per 0003 §3.5) updated/re-run.
- **Sibling rebasing rule:** 0003 / 0004 / 0005 are **independent siblings**
  under 0002. Whichever executes later MUST rebase on the then-current schema,
  fixture, adapter, and contract — its bump is "+1 over then-current", not a
  fixed number. This sentence appears in all three specs.
- **Optional sibling interactions (if 0003/0004 executed first):** 0003 lava
  cells (`CALDERA_LAKE` → LAVA surface) are excluded from blending (lava never
  feathers into neighbors — quench/obsidian rules govern lava adjacency);
  0004 wetness/wind may tint foam display via existing SKY fields but must not
  change the foam formula.

---

## 4. Semantic Library Consumption

Every path below was verified to exist.

| Domain / ID | Concept consumed | Consumption mode |
|---|---|---|
| `SCR-LIB-RENDER-WATER` (`lib/A01_Render/Water`) | Dual-zone foam: crest whitecaps (Jacobian/elevation) + **shoreline edge foam** from `Δy = y_water(x,z,t) − y_terrain(x,z)`, `Foam_shore = clamp(1 − Δy/d_foam,0,1)²·(0.6+0.4·sin(6Δy − 4t))`, `d_foam = 1.8 m`; palette `FOAM_WHITECAP (0.941,0.980,1.000)` | Implement verbatim in sim (§3.3); shader shades field. 0002's recorded deviation (`docs/04` §7) now **implemented** — crest-only remainder noted honestly |
| `SCR-LIB-SPATIAL-VOXEL-SYNTHESIS` (`lib/801_Spatial/Voxel/Synthesis`) | Pure pipeline `(x,z,biome,feature,height,noise_context) → MaterialColumn`; biome→material table; invariants (purity, bedrock, water fill, write-once); rule: fine detail MUST NOT override biome surface with another biome's material | Extend pipeline with boundary blend tuples (§3.4) *inside* the pipeline; conformance test extended (existing `test_synthesis_conformance.mojo` + new blend cases) |
| `SCR-LIB-GEOMETRY` (`lib/302_Geometry`) | Geometry ≠ Mesh; spatial structure meaning independent of representation; mesh/surface semantics | Vertex blend tuples + arrays are **representation**; semantics = synthesis field + frames (0002 §4 discipline) |
| `SCR-LIB-FIELD` (`lib/301_Field`) | Values + relationships over a domain; sampling/interpolation semantics | Foam field `F(x,z,t)` is a field over the terrain grid — sampled, not ad-hoc |
| `SCR-LIB-RENDER-MATERIAL` (`lib/A01_Render/Material`) | `materials_catalog.json` (albedo/roughness/emissive/opacity); `material_reactions.json` → `reaction.lava_water_quench` (primary `fluid.lava`, adjacent `fluid.water`, `face_sharing_6_neighborhood`; source → `rock.obsidian`, non-source → `rock.cobblestone`, byproduct `fluid.steam`, `energy_released_j` 15000/8000; `mass_conservation`, `enthalpy_dissipation`) | Blend albedo from catalog only (AP-3). Quench evaluator implements the reaction verbatim (§1.1 (c)); steam byproduct & energy accounting: **not manifested this milestone** (no steam particles) — recorded deviation, `TBD — future milestone` |
| `lib/801_Spatial` frames | world-frame positions | Foam grid declared in world frame; adapter texture mapping is representation |

**Known spec-only gaps:** `301_Field`, `302_Geometry` definitions are draft
status with no Mojo code — consumed as contract semantics (field/mesh
distinction), implemented in Mojo per definition.

---

## 5. Deliverables & Sprint Breakdown

```text
applications/godot/
├── src/mojo/
│   ├── sim/shore.mojo                      # NEW — foam field from height field + Gerstner (library formula)
│   ├── sim/world.mojo                      # EXTEND — own foam field, commit to projection
│   ├── sim/parameters.mojo                 # EXTEND — FOAM_DEPTH_M, FEATHER_WIDTH_CELLS, dither amp; SCHEMA_VERSION +1
│   ├── sim/subjects.mojo                   # EXTEND — quench evaluator hook (or synthesis/quench.mojo)
│   ├── synthesis/                          # EXTEND — boundary detection, feather band, blend tuples, quench adjacency pass
│   ├── snapshot/types.mojo                 # EXTEND — SHORE_FOAM struct; TERRAIN vertex blend tuple
│   ├── snapshot/encode.mojo                # EXTEND — encode SHORE_FOAM; TERRAIN u8 tuple; schema N+1
│   └── snapshot/decode.mojo                # EXTEND — reject schema ≠ N+1 loudly
├── godot/
│   ├── scenes/island.tscn                  # EXTEND — ocean texture slot, terrain vertex-color flag
│   ├── scripts/                            # unchanged (AP-8)
│   └── shaders/ocean.gdshader              # EXTEND — sample shore-foam texture; shore band replaces ring artifact
├── tests/mojo/
│   ├── test_shoreline_foam.mojo            # NEW — formula conformance, ranges, purity, grid alignment
│   ├── test_material_blending.mojo         # NEW — feather band, biome-pair constraint, no cross-biome override, dither determinism
│   ├── test_quench.mojo                    # NEW — reaction evaluator vs catalog (source/non-source, adjacency, no-adjacency no-op)
│   ├── test_synthesis_conformance.mojo     # EXTEND — blend cases inside invariants
│   ├── test_determinism.mojo               # EXTEND — SHORE_FOAM + blend bytes in byte-identity
│   ├── test_envelope.mojo                  # EXTEND — section 9 framing, TERRAIN stride
│   └── gen_golden_fixture.mojo             # RUN — regenerate fixture
├── tests/
│   ├── abi_smoke.py                        # EXTEND — SHORE_FOAM decode + TERRAIN stride checks
│   ├── schema_mismatch_test.c              # verified (stub = SCR_SIM_SCHEMA_VER + 1)
│   ├── fixtures/snapshot_seed1_tick1.bin   # REGENERATED
│   └── godot/
│       ├── godot_aerial_diagnostic.gd      # EXTEND — shoreline + crater-rim captures
│       ├── check_shoreline_foam.py         # NEW — luminance/position check: foam only in shore band
│       └── godot_screenshot.sh|.gd         # EXTEND — documented capture commands
├── docs/04_simulation_engine.md            # EXTEND — foam/blending/quench sections; §7 deviation resolved
├── docs/06_roadmap.md                      # EXTEND — 0005 status
└── program_increments/v0.0.1/milestone_0005_shoreline-fidelity/spec.md   # this file

providers/render/graphics/godot/
├── 104_contract.md                         # EXTEND — schema N+1, SHORE_FOAM, TERRAIN tuple
├── 102_status.yaml / 103_provider.graph.json  # EXTEND
└── adapter/scr_godot_adapter.cpp, scr_godot_abi.h  # EXTEND — schema N+1, texture upload, vertex colors
```

### Sprint 01 — Sim foam field + synthesis blending + tests

- `sim/shore.mojo` (library formula), blend tuples in `synthesis/`, quench
  evaluator; parameters.
- Tests: `test_shoreline_foam.mojo`, `test_material_blending.mojo`,
  `test_quench.mojo`; extended `test_synthesis_conformance.mojo`;
  existing 7 spec-test files green.

### Sprint 02 — Snapshot & contract (schema N+1)

- `SHORE_FOAM` section; TERRAIN per-vertex blend tuple; envelope bump;
  `104_contract.md` §4 updated (field tables + framing).
- Fixture regenerated; `test_envelope.mojo` + `abi_smoke.py` extended;
  projection purity re-verified.

### Sprint 03 — Adapter & scene

- Adapter: texture upload for `SHORE_FOAM`; TERRAIN decode of blend tuples →
  per-vertex blended albedo (catalog mix) + `vertex_color_use_as_albedo`.
- `ocean.gdshader`: shore band from texture; remove ring artifact; keep the
  0002 display wave spectrum and crest thresholds untouched.
- Headless load + screenshot + aerial gates.

### Sprint 04 — Docs & verification

- `docs/04` (§7 deviation resolved, new params, scene↔state rows), `docs/06`,
  `104_contract.md`; full gate run (§7); anti-pattern review (0002/0003/0004
  tables + this §2.1).

---

## 6. Formal Invariants

Carried from [0002 §6](../milestone_0002_scene-initiation/spec.md),
[milestone 0003 §6](../milestone_0003_volcano/spec.md),
[milestone 0004 §6](../milestone_0004_atmosphere-weather/spec.md) — unchanged
and normative.

1. **Scope amendment:** 0002 invariant 10 is lifted *only* for foam, blending,
   and quench-evaluator features defined here (weather/lava/plume = siblings;
   vegetation/fauna/multi-biome/IPC remain out).
2. **Single-material-authority invariant:** every material assignment —
   including blended boundary weights — originates in the synthesis pipeline;
   adapter/shader only convert representation (AP-20).
3. **Foam authority invariant:** shore foam is computed sim-side from the
   library formula; the shader never re-derives terrain-vs-water depth
   (AP-19). Crest foam remains display-only and disjoint (AP-22).
4. **Blend-pair invariant:** blend pairs ⊆ adjacent biomes' permitted surface
   materials (Synthesis §2 cross-biome rule preserved).
5. **Schema invariant:** TERRAIN payload meaning change and new section both
   bump `SCR_SIM_SCHEMA_VER` + fixture + adapter + negative test together
   (AP-21).
6. **Reaction fidelity invariant:** quench outcomes come verbatim from
   `material_reactions.json`; anything not implemented (steam volume, energy
   release manifestation) is recorded as deviation, never implied (AP-14).

---

## 7. Exit Criteria

Commands run from repo root. (Milestone-specified visual criteria included.)

- [ ] **Spec tests green:** `.venv/bin/mojo run -I applications/godot/src/mojo applications/godot/tests/mojo/test_shoreline_foam.mojo`, `…/test_material_blending.mojo`, `…/test_quench.mojo` PASS; existing 7 spec-test files still PASS.
- [ ] **Foam formula conformance:** `test_shoreline_foam.mojo` evaluates the library formula at committed `(Δy, t)` sample points and asserts exact agreement; `F ∈ [0,1]`; `F = 0` for `Δy ≥ 1.8 m`; field unchanged across projection (purity).
- [ ] **Blending conformance:** `test_material_blending.mojo` asserts feather band width within `FEATHER_WIDTH_CELLS ± 1` at a synthetic BASALT↔SULFUR boundary, no cross-biome material appears in any column (Synthesis §2), dither identical across two runs with same seed.
- [ ] **Quench conformance:** `test_quench.mojo` asserts source-lava + adjacent-water → `rock.obsidian`, non-source → `rock.cobblestone`, no-adjacency → unchanged, byproduct `fluid.steam` recorded (values from `material_reactions.json`); current seed-1 island triggers **zero** quenches (no lava↔water adjacency) — asserted and documented.
- [ ] **Schema bump:** `scr_sim_schema_version() == N+1` via `python3 applications/godot/tests/abi_smoke.py` PASS (SHORE_FOAM decode + TERRAIN stride checks); fixture regenerated; `test_golden_fixture.mojo` PASS.
- [ ] **Negative test:** `bash applications/godot/tests/test_schema_mismatch.sh` PASS.
- [ ] **Determinism/purity/catalog:** `test_determinism.mojo`, `test_projection_purity.mojo`, `test_catalog.mojo` PASS (blend albedos derivable from `materials_catalog.json`).
- [ ] **Layout gates:** `bash applications/godot/scripts/check_layout.sh` PASS (AP-1, AP-4).
- [ ] **Headless load:** `bash applications/godot/tests/godot/godot_load_test.sh` PASS (0 `ERROR:` lines).
- [ ] **Foam only at shoreline (automated):** `bash applications/godot/tests/godot/godot_screenshot.sh` extended to run `godot_aerial_diagnostic.gd` (overhead capture), then `python3 applications/godot/tests/godot/check_shoreline_foam.py build/aerial.png` asserts: bright foam-luminance pixels lie within a band of ±`FOAM_BAND_M` (default 6 u) of the `y_terrain = sea_level` contour (contour computed from the committed seed-1 height field in the script), and pixel count outside the band ≤ 2% of in-band count — **foam only at the shoreline**. Fallback: documented manual capture + inspection procedure in the script header (0002 pattern).
- [ ] **Crater rim without teeth (documented visual):** procedure in `docs/04` §8 — run `godot_aerial_diagnostic.gd` crater-rim view (`build/crater_rim.png`), confirm no alternating sulfur/basalt sliver pattern at glancing angle; capture + one-line PASS/FAIL recorded in `docs/04` §8 verification table. (Automated luminance-ripple check across the rim band is a stretch goal recorded as `TBD` if manual suffices per task allowance.)
- [ ] **Ocean spectrum intact:** existing ocean gates unchanged — display-wave spectrum params in `docs/04` §6.4 untouched; `test_gerstner.mojo` PASS.
- [ ] **Playability unaffected:** `bash applications/godot/tests/godot/godot_playability_test.sh` PASS.
- [ ] **Docs:** `04` (§7 deviation resolved → implemented; params; scene rows), `06`, `104_contract.md` updated.
- [ ] **Anti-pattern review:** 0002 AP-1..10, 0003 AP-11..14, 0004 AP-15..18, this AP-19..22 checked item-by-item, evidence in `docs/04` §8.

---

## 8. Dependencies

- **Predecessor:** [milestone 0002](../milestone_0002_scene-initiation/spec.md) (Complete) — height field, Gerstner, synthesis, adapter, gates.
- **Siblings (optional, §3.6):** [milestone 0003](../milestone_0003_volcano/spec.md), [milestone 0004](../milestone_0004_atmosphere-weather/spec.md) — independent; rebase rule applies.
- **Semantic contracts:** `lib/A01_Render/Water`, `lib/801_Spatial/Voxel/Synthesis`, `lib/302_Geometry`, `lib/301_Field`, `lib/A01_Render/Material`, `lib/801_Spatial`.
- **Normative reference:** `providers/render/graphics/godot/104_contract.md`.
- **External toolchain:** unchanged (Mojo 1.0.0, Godot 4.7.2, godot-cpp).

---

## 9. Out of Scope

- Dynamic lava flows reaching the sea (live quench activation) — requires
  eruption/flow semantics; `TBD — future milestone` (evaluator itself ships
  here, §1.1 (c)).
- Steam volume/heat effects from quench (`energy_released_j` manifestation) —
  `TBD — future milestone` (recorded deviation).
- Multi-material weight vectors / full triplanar terrain shader — rejected in
  §1.1; revisit only with a normative need.
- Wet-sand darkening, tidal variation, beach erosion — no contract exists;
  Rule 9: not invented here.
- Weather (0004), lava/plume (0003), vegetation/fauna, editing, IPC, MLIR
  work — unchanged out-of-scope.

---

## 10. Successor Milestones

| Intent | Triggering contracts | Fulfilled by |
|---|---|---|
| Volcano: lava + plume (crater visuals this milestone blends around) | `A01_Render/Volcano`, `lava_water_quench` | [milestone 0003](../milestone_0003_volcano/spec.md) (sibling) |
| Atmosphere & weather (wetness/wind display inputs) | `202_Math/Atmosphere`, `A01_Render/Sky`, `503_Simulation/Environment/Weather` | [milestone 0004](../milestone_0004_atmosphere-weather/spec.md) (sibling) |
| Lava flow → sea quench activation + steam | `A01_Render/Volcano`, `material_reactions.json` | `TBD — future milestone` |
| Ash-fall deposition interacting with foam/water | `A01_Render/Volcano` dispersion | `TBD — future milestone` |
| Editing/hotbar on blended terrain | `501_Physics` bodies, material hotbar semantics | `TBD — future milestone` |
