# Sprint 04 — Docs + Verification

**Milestone:** [0009 — Flora Upgrade](../spec.md)
**Predecessor sprint:** [Sprint 03 (contract/fixture/scene green)](sprint_03_contract-scene.md)
**Scope:** `docs/`, roadmap, evidence capture, full gate suite, AP review
**Language:** markdown + shell gates

---

## 1. Objective

Document the delivered flora model, produce rendered evidence, run the **complete milestone §7 gate set**, and close the AP-1..22 review. This sprint flips milestone `spec.md` `Status: Planned → Complete` only after every §7 box is checked.

## 2. Deliverables

```text
applications/godot/
├── docs/04_simulation_engine.md   # §6.8 flora extension (field/growth/selection params),
│                                  # emission rule, evidence table, honest limitations,
│                                  # AP-1..22 review table (§9-style)
├── docs/06_roadmap.md             # v0.0.2 section + 0009 row (Complete when gates green)
├── build/*.png                    # screenshot evidence (day + growth sub-captures)
└── program_increments/v0.0.2/milestone_0009_flora-upgrade/spec.md   # Status → Complete (last step)
```

## 3. Normative requirements

| # | Requirement | Source |
|---|---|---|
| R1 | `docs/04`: flora field / growth curve / trait-selection domain model traced to Sprint 00 definitions; parameter table rows for every new tunable (growth curves, threshold, `FLORA_EMIT_EPS`, stress weights, trait salts) | milestone §5 Sprint 04, AP-7 |
| R2 | `docs/04` honest limitations: no reproduction / cross-generational inheritance (`INV-006/007` trivial); stress-model choice (crater-distance ∧ wetness) + why plume mask rejected; voxel-flora deviation still open; emission-rule change + schema/ABI unchanged | milestone §1.2, §4 row 3, §9 |
| R3 | Evidence table: growth observable — scale distribution (or mean scale) at two separated ticks from the same run; PNG paths; fixture sha256; gate result rows (commands + PASS/FAIL) | milestone §7 rendered-growth box |
| R4 | AP-1..22 review table item-by-item (normative reference + how each was satisfied + gate that proves it) | milestone §7 review box |
| R5 | Roadmap: v0.0.2 section, 0009 row Complete with link to spec + `docs/04` evidence anchor | docs/06 conventions (0007/0008 rows) |
| R6 | Full §7 milestone gate set executed serially; socket gates with `SCR_SIM_TRANSPORT=socket SCR_SIM_IPC_PACE=manual`; no orphan `scr_sim_server`/godot processes after runs; **never `pkill -f`/`killall`** | session shell-safety policy, 0008 gate discipline |

## 4. Tasks

1. Docs edits (R1–R5).
2. Run full gate set (§5) serially; capture outputs + PNGs; read PNGs (content assertions actually hold — plume/terrain/flora visible, growth evidence plausible).
3. AP-1..22 review table; append to `docs/04`.
4. Flip milestone spec `Status: Complete`; tick all §7 boxes.
5. Report completion + deviations to stakeholder; await commit instruction.

## 5. Gate checklist (milestone §7, full set)

Run from repo root; `M=.venv/bin/mojo`; serial execution (no parallel godot/server runs); check `pgrep -x scr_sim_server | wc -l` == 0 afterwards.

- [ ] Definition gate (Sprint 00) evidence re-confirmed: `scr-domain-validator` 0 findings, Sprint 00 diff ⊆ `lib/` paths.
- [ ] `test_flora_growth.mojo` PASS.
- [ ] `test_flora_evolution.mojo` PASS.
- [ ] `test_flora_placement.mojo` PASS (field oracle).
- [ ] `test_determinism.mojo` PASS (growth+selection in byte-identical sequence).
- [ ] `test_projection_purity.mojo` PASS.
- [ ] `test_envelope.mojo` + `test_golden_fixture.mojo` PASS (fixture regenerated, sha recorded).
- [ ] `abi_smoke.py` + `test_schema_mismatch.sh` PASS (6 accepted; 5/7 refused).
- [ ] `build_godot_provider.sh` + `check_layout.sh` PASS.
- [ ] `godot_load_test.sh` + `godot_playability_test.sh` PASS.
- [ ] `godot_screenshot.sh` PASS with flora + growth-evidence assertions; PNGs read by orchestrator.
- [ ] Transport re-run: in-process smoke + `SCR_SIM_TRANSPORT=socket SCR_SIM_IPC_PACE=manual godot_ipc_smoke.sh` + `test_ipc_determinism.sh` PASS.
- [ ] Full `docs/04` milestone-0002 §8 lineage procedures PASS.
- [ ] All 21 mojo spec-test files PASS (`MOJO_FAILS=0`).
- [ ] AP-1..22 review table complete in `docs/04`.

## 6. Constraints

- **AP-21:** `docs/04` definitions cite Sprint 00 sources — no undocumented semantics.
- **Rule 15:** no scope additions during verification; new findings → honest-gap rows (`docs/04` §9), not silent fixes.
- **Rule 11:** exit boxes require the named command's output, not intent.
