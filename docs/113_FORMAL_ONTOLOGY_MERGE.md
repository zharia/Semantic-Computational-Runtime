# Formal Ontology Merge Audit — `formal/` ⊔ `SCRFormal/`

**Date:** 2026-09-10 · **Merge commit:** (this change) · **Result:** one Lean project: `SCRFormal/`

## 1. What existed

Two disconnected Lean projects, same namespace prefix, no shared build:

| | root `formal/` | `SCRFormal/` |
|---|---|---|
| Toolchain | Lean **v4.34.0-rc2** | Lean **v4.19.0** (stable, pinned) |
| Dependencies | Mathlib `master` (~8 GB cache) | Batteries only (Mathlib import dropped: unused) |
| Full build time | minutes (cached: 8 s no-op) | **~1 s** |
| Content | `Basic.lean` (380) + `Canonical.lean` (309): polymorphic `SemanticField` type-record, functional `Transformation` + composition laws, `Constraint`/`Manifestation`, `evolve`/`Satisfies`/`ConstraintPreserving`, `SemanticTime`, `Observation`/`observe`, entity-definition conformance, `TransformResult`/`tryEvolve` + 6 failure-semantics theorems; 12-theorem canonical witness | `SCR.*` relational ontology (State/Entity/Relationship/Equivalence/Field/Invariants/Transformation/Seed) + the entire STC-001/STC-002 corpus: `STC`, `STCLaws`, `STCExamples`, `STCCounterexamples`, `STCGraphCounterexamples`, `STCGraphLaws`, `STCGraphMigration` (~2 900 lines, ~120 theorems incl. 20+20 counterexample programs) |
| Historical role | Milestone 001–005 verification ("lake build SCRFormal # 8882 jobs" — its library was also *named* `SCRFormal`) | Milestone 002 (Semantic Machine) calculus |

## 2. Name conflicts (same `SCR` namespace, incompatible meanings)

| Symbol | root | inner | Kind | Merged resolution |
|---|---|---|---|---|
| `SCR.Value` | `{ content : String }` | sum type (`int/bool/real/text/sequence/unit`) | **shape conflict** | **inner wins** — matches the Mojo kernel & Reference Executor (`value_int`), used by all STC machines; root form dropped |
| `SCR.EntityId` | `{ id : String }` | `{ value : String }` | **shape conflict** | inner wins; ported code adapted (`{ value := "c1" }`) |
| `SCR.Relationship` | `def (E) := E → E → Prop` | `structure {source, target, kind, properties}` | **different kinds** | renamed port: `RelationshipSchema` (typed predicate — the schema-level R of the F-tuple); inner structure unchanged (data-level fact) |
| `SCR.Transformation` | polymorphic `structure {apply : C → S → S}` + 5 laws | descriptive record `{id, operation, target, argument}` | **different kinds** | renamed port: `FunTransformation` / `FunFieldTransformation`; inner record unchanged (STC-001 already classified it as data, not behaviour) |
| `SCR.SemanticField` | record of **types** (the docs `F = (E,R,T,C,S,K,M)`) | data instance `{state, contexts, transformations}` | **different levels** | renamed port: `FieldSchema` (the normative tuple); inner `SemanticField` stays the data form |
| module `SCRFormal` | root library name == inner project dir name | — | **identity collision** | root library deleted; one `SCRFormal` remains (the project) |

## 3. Divergences (same concept, different treatment)

| Concept | divergence | merge verdict |
|---|---|---|
| **Two canonical witnesses** | root `Canonical.lean`: functional layer, string values, `CanonicalConstraint := v = v` (self-documented trivial); inner `Examples.Witness`: entity/relationship state, `Value.int`, real bound constraints, validity/identity/composition theorems | **kept both, layered**: root ported as the SCHEMA-layer witness (trivial constraint preserved — changing it silently would violate source-of-truth rules; its own comment states enforcement is elsewhere); inner is the CALCULUS-layer witness; `Migration` already transports it onto the graph carrier. The schema witness is now strictly weaker and *says so* — recorded as a deliberate open refinement candidate (port bound constraint into `FieldSchema`) for STC-002 |
| **Determinism** | root: `canonical_determinism` (observation-level); inner `Invariants.Deterministic` (function-alias form, STC-001 audit called it vacuous); STC `deterministic`/`stepDet` (relational, the real notion) | all retained (builds/tests reference them); audit note: `Invariants.Deterministic` superseded by `STC.deterministic`, kept for history |
| **tryEvolve** | root original over `FieldSchema` + Decidable constraint; inner `Laws.Oracle` mirror (declared as shape-correspondence witness because projects couldn't import each other) | **now unified**: Oracle's justification note is superseded — the real `tryEvolve` lives beside it; the `Bridge` proves functional ⇒ deterministic/total graph, and Oracle proves the executor shape is a `Realization` of a graph machine — both ends attach to the same carrier |
| **Equivalence** | both layers had bare equality | unchanged; STC `Equiv`/`GConsEquiv` remain the authoritative context-indexed relations (CX-EQV rationale stands) |
| **Time** | root had `SemanticTime`/`TimeProgresses`; STC had none (deferred O-3) | schema layer carries the time *signatures*; calculus must still define semantic-vs-physical ordering (STC-002) — divergence recorded, not papered |
| **Conformance layer** | root-only (`EntityDefinition`/`EntityInstance`/`ConformsTo`) | ported into `Conformance.lean` over inner `EntityId`/`Value`; complements `Entity` (definition schema vs state-carrying participant) |

## 4. Commonalities (union confirmed)

- Same namespace root `SCR`, same *purpose* (engineer outward from the Semantic Field).
- Root's polymorphic `Observation`/`observe` theorems and STC's probe-based `probeDistinction` are complementary faces of docs/106 §15 (schema read vs calculus distinguishability) — both kept.
- `Constraint (S := Prop)` (root) is the constraint *domain*; `Consents` (STC) is the judgement — no conflict, both kept.
- The 12 root theorems' content is *subsumed in spirit* by the ~120-theorem calculus but *not in kind*: schema facts (type-tuple well-formedness, composition identity laws) have no STC equivalent; STC facts (taxonomies, separations) have no schema equivalent. **Union, not replacement.**

## 5. Bridge results added by the merge (`SCR/SchemaBridge.lean`)

- `ofFun` : every functional schema `f : C → S → S` is a graph machine with `Out = S`;
- `ofFun_total` / `ofFun_stepDet` / `ofFun_succFun` : it is total, consequence-deterministic, and successor-functional — the functional layer is *exactly* the deterministic-total fragment of the calculus (composition laws inherit via `Laws.gCompose_deterministic`);
- `graph_strictly_more_general` : the converse fails — `emptyM` (no edges; nonempty `S`) is a graph machine no functional schema represents: **the calculus strictly generalizes the retired schema**, so the merge direction (schema → calculus bridge, both preserved) is correct rather than optional.

## 6. Final layout (one cohesive structure)

```text
SCRFormal/            Lean v4.19.0, Batteries, `lake build` ≈ 1 s
├── lakefile.lean     single package: lean_lib SCRFormal (all modules)
├── SCRFormal.lean    barrel: imports everything below
├── SCR/
│   ├── Basic.lean State.lean Relationship.lean Identity.lean
│   ├── Equivalence.lean Field.lean Invariants.lean Transformation.lean
│   ├── Seed.lean                       ← data-level ontology (STC-001 audit base)
│   ├── Schema.lean                     ← PORTED: F-tuple schema, FunTransformation,
│   │                                      evolve/ConstraintPreserving, SemanticTime,
│   │                                      Observation/observe, tryEvolve + 6 theorems
│   ├── Conformance.lean                ← PORTED: EntityDefinition/Instance/ConformsTo
│   ├── Canonical.lean                  ← PORTED: schema-layer golden witness (12 theorems)
│   ├── STC.lean STCLaws.lean STCExamples.lean STCCounterexamples.lean
│   │                                      ← calculus kernel, laws, machines, falsifications
│   ├── STCGraphCounterexamples.lean STCGraphLaws.lean STCGraphMigration.lean
│   │                                      ← graph carrier, lawful equivalence, migration
│   └── SchemaBridge.lean               ← NEW: schema ⇄ calculus reconciliation theorems
```

Layering rule (now also enforced by imports): `Schema*` never imports
`STC*`; `STC*` never imports `Schema*`; `SchemaBridge` is the only
module seeing both. That is the anti-parallel-ontology guard.

## 7. Classification of every merge decision (spec §34 discipline)

- `Value`/`EntityId` winner: **DECISION (kernel/RE alignment; FACT: inner form used by all implementations)**
- Renames (`RelationshipSchema`, `FunTransformation`, `FieldSchema`): **DEFINITION-preserving**
- Canonical trivial constraint kept: **NO-SILENT-REFINEMENT (semantics authoritative); refinement listed OPEN**
- Oracle note supersession: **REFINEMENT (same content, now co-importable)**
- Bridge theorems: **PROVEN**
- Direction schema→calculus: **PROVEN strictly more general**

## 8. Operational changes

- `formal/` and the root Mathlib require deleted (`git rm`); root
  `lakefile.lean` now a stub pointing to `SCRFormal`.
- `scripts/bootstrap-mathlib.sh`, `scripts/integrate_mathlib.sh`:
  deprecated banners (historical tooling; not deleted).
- README: build instructions unified —
  `cd SCRFormal && lake build` is THE formal build.
- Historical milestone records (001–005) left untouched (records,
  not live claims; docs/README authority order preserved).
