# Sprint 04 — Documentation, Evidence, Full Verification

**Milestone:** [0010 — Flora Phenome](../spec.md)
**Predecessor sprint:** [Sprint 03 (renderer gate green)](sprint_03_renderer.md)
**Scope:** `docs/`, spec status flip, complete §7 gate run, AP review
**Language:** markdown + full gate suite (serial)

---

## 1. Objective

Document the phenome model traced to Sprint 00 definitions, record measured evidence (structural screenshot, growth/LOD numbers), re-run **every** milestone gate including the 0002-lineage set and both transports, review AP-1..26, and flip the spec to Complete.

## 2. Deliverables

```text
applications/godot/
├── docs/
│   ├── 04_simulation_engine.md        # + §phenome model (traced), grammar summary tables,
│   │                                  #   trait-modulation map, stage table, params,
│   │                                  #   evidence, limitations, AP-1..26 review table
│   └── 06_roadmap.md                  # + 0010 row → Complete
└── program_increments/v0.0.2/milestone_0010_flora-phenome/
    ├── spec.md                        # Status → Complete; §7 boxes checked
    └── sprints/*.md                   # sprint acceptance boxes checked
```

## 3. Normative requirements

| # | Requirement | Source |
|---|---|---|
| R1 | Phenome domain model section in `docs/04`: stage quantization, variant_seed, modulation map (trait → grammar parameter table), bucketed cache, LOD bands, wind channel — each traced to Sprint 00 definition IDs + Sprint 01 JSON keys | milestone §5 Sprint 04, Rule 10 |
| R2 | Parameter table for all new tunables (`STAGE_MAX`, seed salts, modulation constants, `K`, LOD band distances/hysteresis) — mirrors `parameters.mojo` | AP-7 |
| R3 | Evidence recorded: structural screenshot filename + read result, conformance fixture results, expansion/cache/LOD measurements, seed-1 counts (95 plants, stage distribution) | §7 |
| R4 | Honest limitations: no sim-side structure state, no reproduction, conformance axis is discrete-only, LOD/sway display-only, voxel flora open, grammar = parametric L-system only (no MLIR/rewrite contract) | Rule 16, milestone §9 |
| R5 | AP-1..26 item-by-item review table (linked + new): status PASS/where-exercised — 0009 §10 table format | milestone §2, §7 |
| R6 | Sprint acceptance boxes checked in all five sprint files; spec `Status: Complete`; `docs/06` 0010 row Complete | §7 |
| R7 | **Full §7 gate run** (all boxes below) — serial; orchestrator independently re-runs + reads PNGs before accepting | workflow |

## 4. Tasks

1. Read milestone §7 (exit criteria), 0009 `docs/04` §8.10 (format model), 0009 §10 AP table.
2. Write `docs/04` phenome sections (model, tables, params, evidence, limitations, AP review) and `docs/06` row.
3. Run the complete §7 gate set (below); capture outputs, fixture sha256, screenshot PNGs.
4. Flip statuses (spec, sprints, 06); orchestrator independent verification (gate re-runs + PNG read).

## 5. Acceptance criteria (milestone exit — full §7)

- [x] **Definition gate:** `scr-domain-validator` 0 findings (Sprint 00 paths); Sprint 00 diff ⊆ `lib/`.
- [x] **Grammar core:** `test_phenome_grammar.mojo` PASS; conformance goldens ↔ GDScript symbol strings match.
- [x] **Flora + full suites:** all mojo spec-test files PASS (`MOJO_FAILS=0`).
- [x] **Fixture + versions:** `test_golden_fixture` PASS; `abi_smoke.py` asserts 7/2; `test_schema_mismatch.sh` 7✓/6✗/8✗/ABI3✗; `check_layout.sh` PASS.
- [x] **Build:** `build_godot_provider.sh` PASS.
- [x] **Scene gates (serial):** `godot_load_test.sh`, `godot_phenome_test.sh`, `godot_playability_test.sh` PASS.
- [x] **Rendered evidence:** `godot_screenshot.sh` PASS + extended structural assertions; PNGs read (structure visible, mixed stages); LOD far-capture documented.
- [x] **Transports:** in-process smoke + `SCR_SIM_TRANSPORT=socket SCR_SIM_IPC_PACE=manual godot_ipc_smoke.sh` + `test_ipc_determinism.sh` PASS; `test_ipc_version_refusal.sh`, `test_ipc_crash_restart.sh`, `ipc_harness.py --self-test` PASS.
- [x] **Lineage:** milestone 0002 §8 procedures per `docs/04` PASS (incl. `godot_render_stall_test.sh`); night-glow re-verified only if `TIME_OF_DAY` touched (not expected — if touched, follow 0009 §7 procedure: 21.0 → regen → rebuild → `SCR_EXPECT_GLOW=1` → revert 12.0 → regen → rebuild).
- [x] **Zero stray processes** (`pgrep -x godot`, `pgrep -x scr_sim_server` clean).
- [x] **Review pass:** AP-1..26 table in `docs/04`; limitations recorded; working tree diff ⊆ milestone paths.
- [x] **Roadmap/status:** `docs/06` 0010 Complete; spec + sprint boxes checked, `Status: Complete`.

## 6. Constraints

- **Serial gates only** (ERR_BUSY); never `pkill -f`/`killall` — exact PIDs; verify no orphans before claiming done.
- **Rule 16:** fixture/derived artifacts regenerated, never hand-edited; golden derivations regenerated only from JSON+code.
- **Honest evidence:** flaky gates recorded as deviations in `docs/04` §9 (0009 precedent), not hidden.
- Commit only on explicit user instruction (workflow); stage `git add applications/godot` (+ `lib/` if Sprint 00 included in the same commit).
