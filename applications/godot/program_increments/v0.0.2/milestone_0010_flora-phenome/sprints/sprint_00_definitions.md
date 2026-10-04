# Sprint 00 — Definitions (Rule 10 Gate)

**Milestone:** [0010 — Flora Phenome](../spec.md)
**Predecessor sprint:** none (first; hard-gates sprints 01–04)
**Scope:** `lib/` only — **zero `applications/godot` implementation changes** (milestone AP-21)
**Language:** normative markdown/YAML/JSON (no code)

---

## 1. Objective

Establish the semantic definitions the implementation consumes: substantive **grammar semantics** (extend the name-level stub `401_Morphology/Procedural`), the new **`704_Evolution/Phenotype`** subdomain (genotype→phenotype mapping — `704`'s own tree expects it, closes parent §70 open questions 11/12), and the Flora definition's **phenome conformance** section.

Rule 10: nothing in sprints 01–04 may exist until this sprint's gate is green.

## 2. Deliverables

```text
lib/
├── 401_Morphology/Procedural/101_definition.md  # EXTENDED: stub → grammar semantics
├── 704_Evolution/Phenotype/
│   ├── 101_definition.md                        # NEW
│   ├── 102_status.yaml                          # NEW
│   └── 103_library.graph.json                   # NEW
├── 704_Evolution/102_status.yaml                # EXT: subdomain list + status touch
└── 705_Ecology/Flora/101_definition.md          # EXT: §1.6 Phenome Conformance + relationship/invariant rows
```

**Explicitly untouched:** `503_Simulation/Reproduction`, `203_Graph/*`, `401_Morphology/101` (parent — cited, not edited), every other `lib/` path, all of `applications/godot/` (milestone §9).

## 3. Normative requirements

| # | Requirement | Source |
|---|---|---|
| R1 | `Procedural/101` keeps its front matter/id (`SCR-LIB-MORPHOLOGY-PROCEDURAL`) but the body becomes substantive: alphabet (modules with parameters), axiom, parametric production rules, derivation-step semantics, iteration depth, termination bounds, determinism, tropism as parametric term; conformance to parent `MORPHOLOGY-INV-001/002/016/017/018`; explicitly addresses parent §70 open questions 11 (Procedural morphology) and 12 (Morphological grammars) | milestone §5 Sprint 00, §4 row 1 |
| R2 | `Phenotype/101_definition.md` required sections per `scr-new-domain` skill; front matter `id: SCR-LIB-EVOLUTION-PHENOTYPE`, `parent: SCR-LIB-EVOLUTION`; covers genotype (trait vector) → phenotype (form parameters) mapping, distinction from **selection** (704) and **growth** (Morphology/Growth), conformance to `EVOLUTION-INV-004/011/018`; Invariants Consumed table; Relationships; Definition Authority footer | milestone §4 row 2, §1.1 |
| R3 | Phenotype Relationships use **only controlled vocabulary** (`001_agents/02_graph_relationships.md`): Evolution `CONTAINS` Phenotype; Phenotype `INTERACTS_WITH` Morphology/Procedural; Phenotype `INTERACTS_WITH` Flora — no invented types | milestone §5 Sprint 00 |
| R4 | Firewall statements: phenotype maps **form only** — it must not redefine selection (704 `ECOLOGY-INV-013` firewall from 0009 stands), growth accretion (`401_Morphology/Growth`), or ecology membership (Flora) | milestone §6 invariant 4, 0009 R4 |
| R5 | Flora 101 gains §1.6 **Phenome Conformance**: structure complexity is developmental (stage), consistent with age (`ECOLOGY-INV-010` temporal explicitness); the wire carries a **compact generative description** (`variant_seed` + `stage`) per parent §17 Repetition (line 577) — geometry never crosses; plus one Relationships row (`Flora INTERACTS_WITH Morphology/Procedural`) and one invariant row (stage monotone) appended to existing tables — existing sections preserved verbatim otherwise | milestone §5 Sprint 00, §6 invariants 5/6 |
| R6 | `704_Evolution/102_status.yaml`: `Phenotype` added to subdomain list, `last_updated` touched; status values remain valid per validator conventions; `103` graphs stay **derived, not authoritative** | milestone §5 Sprint 00; AGENTS control-plane rules |
| R7 | Sprint 00 diff contains **no files** outside the §2 path list (AP-21: `git diff --name-only` must match the allowed list) | milestone AP-21 |

## 4. Tasks

1. Read `lib/401_Morphology/Procedural/101_definition.md` (stub), `lib/401_Morphology/101_definition.md` (§18/§25/§17/§70 authority), `lib/401_Morphology/Growth/101_definition.md` (front-matter + conformance model), `lib/704_Evolution/101_definition.md` (tree expects `phenotype`; INV-004/011/018), `lib/705_Ecology/Flora/101_definition.md` (0009 base), `001_agents/02_graph_relationships.md`, `.opencode/skills/scr-new-domain/SKILL.md`.
2. Rewrite `Procedural/101_definition.md` body (keep id/front matter; substantive grammar semantics per R1).
3. Write `lib/704_Evolution/Phenotype/{101_definition.md,102_status.yaml,103_library.graph.json}`.
4. Edit `lib/705_Ecology/Flora/101_definition.md` §1.6 + tables; touch `704_Evolution/102_status.yaml`.
5. Run validation (§5); fix findings; re-run.

## 5. Acceptance criteria (this sprint's gate)

- [x] `scr-domain-validator` agent over `lib/401_Morphology/Procedural`, `lib/704_Evolution` (incl. `Phenotype`), `lib/705_Ecology/Flora`: **0 findings**.
- [x] Manual checklist: required 101 sections present in Phenotype; Procedural 101 no longer stub (grammar terms present: axiom, production, derivation, termination, determinism); Flora §1.6 present with §17 Repetition citation; every `103` edge type ∈ controlled vocabulary.
- [x] `git diff --name-only` for this sprint ⊆ the §2 path list (AP-21 evidence).
- [x] Milestone §7 box "Definition gate" can be checked.

**Milestone sprints 01–04 do not start until this gate is green.**

## 6. Constraints

- **AP-21** (implementation-before-definition) — this sprint exists for it; no grammar constants invented in code first.
- **Rule 15** — no speculative child domains beyond the three `Phenotype` files; no edits to parent `401_Morphology/101`.
- `103` graphs are derived: never authority over the 101s (AGENTS source-of-truth hierarchy).
