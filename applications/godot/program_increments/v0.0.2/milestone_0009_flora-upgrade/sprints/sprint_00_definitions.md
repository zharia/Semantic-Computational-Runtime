# Sprint 00 — Definitions (Rule 10 Gate)

**Milestone:** [0009 — Flora Upgrade](../spec.md)
**Predecessor sprint:** none (first; hard-gates sprints 01–04)
**Scope:** `lib/` only — **zero `src/mojo`/`applications/godot` implementation changes** (milestone AP-21)
**Language:** normative markdown/YAML/JSON (no code)

---

## 1. Objective

Establish the semantic definitions the implementation consumes: the new **flora domain** (population, flora field, growth, selection) and the missing **control-plane files** for the two authoritative parent definitions (`705_Ecology`, `704_Evolution` — both have complete 101s but no `102`/`103`).

Rule 10: nothing in sprints 01–04 may exist until this sprint's gate is green.

## 2. Deliverables

```text
lib/
├── 705_Ecology/Flora/
│   ├── 101_definition.md            # NEW
│   ├── 102_status.yaml              # NEW
│   └── 103_library.graph.json       # NEW
├── 705_Ecology/
│   ├── 102_status.yaml              # NEW (backfill)
│   └── 103_library.graph.json       # NEW (backfill)
└── 704_Evolution/
    ├── 102_status.yaml              # NEW (backfill)
    └── 103_library.graph.json       # NEW (backfill)
```

**Explicitly untouched:** `503_Simulation/Reproduction`, `601_Agent/Population`, every other `lib/` path, all of `applications/godot/` (milestone §9).

## 3. Normative requirements

| # | Requirement | Source |
|---|---|---|
| R1 | `Flora/101_definition.md` front matter modeled on `lib/401_Morphology/Growth/101_definition.md` (`document`, `document_type`, `schema_version`, `id: SCR-LIB-ECOLOGY-FLORA`, `name`, `version`, `status`, `created`/`updated`, `parent: SCR-LIB-ECOLOGY`, `authority`, `domain`) | milestone §5 Sprint 00; `scr-new-domain` skill |
| R2 | Flora 101 required sections: Summary; Semantic Definition covering (a) **flora population** (membership = instance list; `ECOLOGY-INV-003`), (b) **flora field** — establishment suitability over the terrain-cell domain, a Field specialization per `301_Field` ("meaningful information over a defined domain", not a sampled texture), (c) **growth** conformance to `401_Morphology/Growth` (developmental accretion; wire `scale` is representation, `MORPHOLOGY-INV-016/018`), (d) **selection** conformance to `704_Evolution` (`INV-004` variation, `INV-005` selection, `INV-009` viability, `INV-011` environmental, `INV-018` reproducibility; `INV-006/007` trivial per-instance only — cross-generational lineage explicitly out of scope), (e) **determinism** (pure functions, no mutable RNG stream; `ECOLOGY-INV-010`); Invariants Consumed table; Relationships; Definition Authority footer | milestone §4 rows 1–4, §5 Sprint 00 |
| R3 | Flora 101 Relationships section uses **only controlled vocabulary** (`001_agents/02_graph_relationships.md`): Ecology `CONTAINS` Flora; Flora `REFINES` Field(s); Flora `INTERACTS_WITH` Morphology/Growth, Evolution, Ecology — no invented types | milestone §5 Sprint 00 |
| R4 | `ECOLOGY-INV-013` (evolution distinction) stated as the firewall: trait/selection semantics belong to `704_Evolution`; population/environment to Ecology; the Flora definition must not redefine evolution meaning | milestone §4 row 2 |
| R5 | Flora `102_status.yaml` valid front matter + status values per `scr-domain-validator` conventions; `103_library.graph.json` relationship types valid; `103` remains **derived, not authoritative** | milestone §5 Sprint 00; AGENTS control-plane rules |
| R6 | Backfill `704_Evolution` and `705_Ecology` `102_status.yaml` + `103_library.graph.json` consistent with their existing 101 front matter (status `draft` in 101 → valid status mapping documented); edges reflect the 101's own Domain Relationships (Evolution: Fields/Morphology/Ecology/Simulation interactivity; Ecology: Fields/Population links) — controlled vocabulary only | milestone §1.1, §5 Sprint 00 |
| R7 | Sprint 00 diff contains **no files** outside the three `lib/` paths listed in §2 (AP-21 gate is partially automated: `git diff --name-only` must match the allowed list) | milestone AP-21 |

## 4. Tasks

1. Read `lib/401_Morphology/Growth/101_definition.md` (front-matter model), `lib/705_Ecology/101_definition.md` (§1/§3/§9/§17/§43 + INV-003/004/009/010/012/013), `lib/704_Evolution/101_definition.md` (definition + INV-004/005/006/007/009/011/018), `lib/301_Field/101_definition.md` (field semantics), `001_agents/02_graph_relationships.md` (vocabulary), `.opencode/skills/scr-new-domain/SKILL.md` (required sections/status values).
2. Write `lib/705_Ecology/Flora/{101_definition.md,102_status.yaml,103_library.graph.json}`.
3. Backfill `lib/705_Ecology/{102_status.yaml,103_library.graph.json}` and `lib/704_Evolution/{102_status.yaml,103_library.graph.json}`.
4. Run validation (§5); fix findings; re-run.

## 5. Acceptance criteria (this sprint's gate)

- [ ] `scr-domain-validator` agent over `lib/705_Ecology` (incl. `Flora`) + `lib/704_Evolution`: **0 findings**.
- [ ] Manual checklist: required 101 sections present; YAML status values valid; every `103` edge type ∈ controlled vocabulary; directory naming conventions (PascalCase) correct.
- [ ] `git diff --name-only` for this sprint ⊆ the §2 path list (AP-21 evidence).
- [ ] Milestone §7 box "Definition gate" can be checked.

**Milestone sprints 01–04 do not start until this gate is green.**

## 6. Constraints

- **AP-21** (implementation-before-definition) — this sprint exists for it; no code, no doc-backfill-after-code.
- **Rule 15** — no new subdomain directories under `705_Ecology/Flora/` or `704_Evolution/` beyond the three files each; no speculative child domains.
- `103` graphs are derived: never treat them as authority over the 101s (AGENTS source-of-truth hierarchy).
