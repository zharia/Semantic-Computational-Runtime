# Sprint 02 — Contract: Schema 7 FLORA Record + Fixture + Adapter

**Milestone:** [0010 — Flora Phenome](../spec.md)
**Predecessor sprint:** [Sprint 01 (phenome core gate green)](sprint_01_phenome-core.md)
**Scope:** `snapshot/` encode/decode, `104_contract.md`, adapter C++, golden fixture, contract tests
**Language:** Mojo + C++ adapter; contract prose normative

---

## 1. Objective

Ship the locked wire decision: **schema 6 → 7**, FLORA record `24 → 32 B` (`+u32 variant_seed`, `u8 stage`, `u8 pad[3] = 0`), ABI stays **2**. Additive record extension, existing offsets unchanged, all other sections byte-identical semantics. Adapter version gate proves itself again: 7 accepted, 6 and 8 refused. **No geometry, no symbol strings on the wire** (AP-25).

## 2. Deliverables

```text
applications/godot/
├── providers/render/graphics/godot/
│   ├── 104_contract.md                          # EXT: §4.3 §10 record 32 B, schema 7, validation,
│   │                                            #   emission triggers, §17 Repetition citation
│   ├── 102_status.yaml                          # EXT: capability note
│   ├── adapter/scr_godot_abi.h                  # EXT: SCR_SIM_SCHEMA_VER 6→7, field structs/comments
│   └── adapter/scr_godot_adapter.cpp            # EXT: decode/validate stage/pad/seed, section-size check
├── src/mojo/snapshot/
│   ├── types.mojo                               # EXT: FLORA struct +8 B fields (24→32)
│   ├── encode.mojo                              # EXT: write seed/stage/pad, section bytes 4+32·count
│   └── decode.mojo                              # EXT: read + validate (stage≤15, pad==0, count≤4096)
└── tests/
    ├── fixtures/snapshot_seed1_tick1.bin        # REGENERATED (schema 7)
    ├── mojo/
    │   ├── gen_golden_fixture.mojo              # RUN (no code change expected)
    │   ├── test_golden_fixture.mojo             # EXT: schema 7 expectations
    │   ├── test_envelope.mojo                   # EXT: 32-B framing, malformed pad/stage rejection
    │   ├── test_flora_growth/evolution/placement.mojo  # EXT: seed/stage fields asserted
    │   └── test_determinism.mojo, test_projection_purity.mojo  # EXT: seed/stage in fingerprint
    ├── godot/abi_smoke.py                       # EXT: assert schema 7 / ABI 2
    └── ipc/test_schema_mismatch.sh              # EXT: 7 accepted; 6 and 8 refused
```

Untouched: `lib/`, scene scripts (Sprint 03), `phenome_expand.gd`.

## 3. Normative requirements

| # | Requirement | Source |
|---|---|---|
| R1 | FLORA record layout exact per milestone §3.2: offsets 0–23 unchanged (`position/yaw/scale/species_id`), `+24 u32 variant_seed`, `+28 u8 stage`, `+29 u8[3] pad = 0`; record 32 B; section bytes `4 + 32·count` (max 131,076 B at 4096) | milestone §3.2 |
| R2 | `SCR_SIM_SCHEMA_VER` bumped by **exactly +1** (6 → 7); `SCR_SIM_ABI_VERSION` stays **2**; fixture regenerated; FAUNA/TERRAIN/… semantics unchanged | invariant 7 |
| R3 | Adapter validation additions: `stage ≤ STAGE_MAX (15)`, `pad == 0`, `section_bytes == 4 + 32·count`; existing checks (`species_id ∈ [1,7]`, `scale > 0`, `count ≤ 4096`) retained | milestone §3.2 |
| R4 | Emission rule: 0009 triggers (count, species, ε-scale) **plus** stage change and variant_seed change vs last emission; first snapshot after init always emits | milestone §3.2, 0009 R7 |
| R5 | Round-trip: encode∘decode identity for FLORA records; malformed `pad ≠ 0` and `stage > 15` rejected at decode with error (frameing test) | invariant 7 |
| R6 | Contract prose: `104_contract.md` §4.3 §10 documents all new fields with types/offsets; schema history line gains 7; §10 cites `Morphology §17 Repetition` (compact generative description — geometry never crosses) and states emission trigger list | milestone §3.2, invariant 6 |
| R7 | `test_schema_mismatch`: schema 7 accepted; **6 and 8 refused** (version-mismatch error path); ABI 2 accepted, 3 refused (unchanged) | invariant 7 |
| R8 | Golden fixture byte-exact: regen after encode change, sha256 recorded, `test_golden_fixture` PASS; other sections byte-identical vs schema-6 fixture modulo the FLORA section + schema word | invariant 7 |

## 4. Tasks

1. Read milestone §3.2 (record table), §6 invariants 6/7, Sprint 01 outputs (`FloraInstance` stage/seed), `104_contract.md` §4.3/§10/§7, `snapshot/{types,encode,decode}.mojo`, adapter decode path, `test_envelope.mojo`, `abi_smoke.py`, `test_schema_mismatch.sh`.
2. Extend `types/encode/decode` (32-B record, validation); bump schema macro in `scr_godot_abi.h`; adapter decode + comments.
3. Update `104_contract.md` (record table, validation, triggers, §17 Repetition citation) + `102_status.yaml` capability note.
4. Regenerate fixture; update `test_golden_fixture`, `test_envelope`, flora tests, determinism/purity fingerprints, `abi_smoke`, `test_schema_mismatch`.
5. Run this sprint's gate (§5); re-run full mojo suite + gate suite for regressions.

## 5. Acceptance criteria (this sprint's gate)

- [x] `M run -I applications/godot/src/mojo applications/godot/tests/mojo/test_envelope.mojo` PASS — 32-B framing, round-trip identity, `pad ≠ 0` / `stage > 15` rejected.
- [x] `M run -I applications/godot/src/mojo applications/godot/tests/mojo/test_golden_fixture.mojo` PASS; fixture sha256 recorded (regen note in sprint evidence).
- [x] `python3 applications/godot/tests/godot/abi_smoke.py` PASS asserting **schema 7 / ABI 2**.
- [x] `bash applications/godot/tests/ipc/test_schema_mismatch.sh` PASS — 7 accepted, **6 and 8 refused**, ABI 3 refused.
- [x] `bash applications/godot/scripts/build_godot_provider.sh` PASS (adapter decodes 32-B records); `check_layout.sh` PASS.
- [x] All mojo suites PASS (no regressions); `test_flora_*` assert seed/stage fields.
- [x] AP-25 spot check: `rg -n "struct|mesh|vertex|lstring" applications/godot/src/mojo/snapshot/encode.mojo` → no structure growth beyond the 32-B record fields.

## 6. Constraints

- **Invariant 8 (layout neutrality):** schema bump by exactly +1; existing field offsets immutable; stop (Rule 19) if any change to position/yaw/scale/species_id offsets is proposed.
- **AP-25:** compact generative description only — `variant_seed` + `stage` are the entire wire delta.
- **AP-22** continues: emission stays change-driven; do not emit on every tick.
- **Fixture discipline:** one regen per encode change; never hand-edit `.bin`.
