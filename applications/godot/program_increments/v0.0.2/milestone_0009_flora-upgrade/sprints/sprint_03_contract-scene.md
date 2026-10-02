# Sprint 03 — Contract + Fixture + Adapter + Scene

**Milestone:** [0009 — Flora Upgrade](../spec.md)
**Predecessor sprint:** [Sprint 02 (selection green)](sprint_02_selection.md)
**Scope:** `104_contract.md`, golden fixture, adapter dispatch, `flora_view.gd`
**Language:** markdown / fixture tooling / C++ adapter / GDScript

---

## 1. Objective

Publish the change-driven FLORA emission rule (milestone §3.2), regenerate the golden fixture **content-only**, and make the scene render growth from the wire — while proving layout neutrality (schema 6 / ABI 2 / 24-B records untouched).

## 2. Deliverables

```text
applications/godot/
├── providers/render/graphics/godot/
│   ├── 104_contract.md          # §10 FLORA emission rule rewrite; explicit "schema/ABI unchanged"
│   ├── 102_status.yaml          # capability/status note if 104 changed materially
│   └── 103_provider.graph.json  # only if Flora-domain edge changes (derived — check, don't force)
├── godot/scripts/flora_view.gd  # EXT: per-snapshot wire scale (growth visible); sway untouched
└── tests/
    ├── fixtures/snapshot_seed1_tick1.bin   # REGENERATED (content only)
    └── mojo/gen_golden_fixture.mojo         # RUN (source change only if content hooks needed)
```

Adapter C++: **no layout change expected** — verify `apply_flora` dispatch fires on every change-driven emission (it already applies whenever the section is present); update comments/validation prose only where they state the old emission rule.

## 3. Normative requirements

| # | Requirement | Source |
|---|---|---|
| R1 | `104_contract.md` §10 rewritten to the milestone §3.2 rule in substance: present on (a) first snapshot after init, (b) count change, (c) ≥ `FLORA_EMIT_EPS` relative scale change or species change; position/yaw change also triggers; absence ⇒ adapter retains cached instances | milestone §3.2 |
| R2 | Explicit statements in §10: `SCR_SIM_SCHEMA_VER == 6`, `SCR_SIM_ABI_VERSION == 2`, record `4 + 24·count` **unchanged**; fixture regen is content-only (0008 layout-neutral precedent) | invariant 8 |
| R3 | Other sections (`FAUNA`, `TERRAIN`, …) and adapter validation ranges (`species_id ∈ [1,7]`, `scale > 0`, `count ≤ 4096`) unchanged | milestone §3.2 |
| R4 | Fixture regenerated; `test_golden_fixture` passes against new bytes; sha256 recorded for `docs/04` (Sprint 04) | milestone §5 Sprint 03 |
| R5 | `flora_view.gd` applies wire `scale` per snapshot (growth changes MultiMesh transforms); **no** growth logic, no `TIME`-driven scale — sway shader untouched | AP-19, invariant 10 |
| R6 | Screenshot-gate readiness: no renderer-side growth interpolation that would make captures disagree with wire values | milestone §3.4 |

## 4. Tasks

1. Rewrite `104_contract.md` §10 per R1–R3; grep contract + adapter comments for the old "world_version-gated" FLORA wording and update each occurrence (docs prose bodies land Sprint 04; contract + adapter now).
2. Regen fixture: `./.venv/bin/mojo run -I applications/godot/src/mojo applications/godot/tests/mojo/gen_golden_fixture.mojo`; verify section ids/framing unchanged (content-only).
3. Confirm `test_envelope.mojo` change-driven round-trip green (from Sprint 01).
4. `flora_view.gd`: confirm it re-reads `scale` on every `apply_flora` (not only at MultiMesh build time); extend if fixed-scale.
5. Run this sprint's gate (§5).

## 5. Acceptance criteria (this sprint's gate)

- [ ] `bash applications/godot/tests/test_schema_mismatch.sh` PASS — **6 accepted; 5 and 7 refused** (schema untouched).
- [ ] `python3 applications/godot/tests/abi_smoke.py` PASS — schema-6 + ABI-2 asserts intact.
- [ ] `M run -I applications/godot/src/mojo applications/godot/tests/mojo/test_golden_fixture.mojo` PASS against regenerated fixture; section ids/count match pre-sprint (layout neutrality).
- [ ] `M run -I applications/godot/src/mojo applications/godot/tests/mojo/test_envelope.mojo` PASS (change-driven framing; malformed `section_bytes` rejection retained).
- [ ] `bash applications/godot/scripts/build_godot_provider.sh` PASS; `bash applications/godot/scripts/check_layout.sh` PASS.
- [ ] `bash applications/godot/tests/godot/godot_load_test.sh` PASS (0 `ERROR:` lines).
- [ ] Grep audit: `104_contract.md` + adapter comments contain no stale world_version-emission claim for FLORA.
- [ ] `git diff --stat` for `snapshot/encode.mojo`, `snapshot/decode.mojo`, `scr_godot_abi.h` shows **no layout edits** (R2 evidence).

## 6. Constraints

- **Invariant 8:** any temptation to add a wire field (age, trait, stage) = stop, spec change first (Rule 19).
- **AP-19:** scene renders wire scale only; no GDScript aging.
- **AP-3:** no new colors/vocabularies — species materials unchanged.
