# SMM Library Crosswalk

**Document ID:** SCR-DOC-XW-109  
**Status:** Normative architectural guidance  
**Version:** 0.1.0

---

## 1. Purpose

This document prevents SMM from duplicating concepts already defined in the SCR semantic library.

The governing rule is:

> **Reuse existing semantic authority before introducing a new semantic primitive.**

---

## 2. Core

`lib/101_Core/101_definition.md` already contains the majority of the semantic vocabulary required by SMM.

Relevant existing concepts include:

- identity;
- type;
- value;
- entity;
- relationship;
- role;
- hypergraph;
- region;
- reference;
- representation;
- pattern;
- transformation;
- operation;
- state;
- transition;
- delta;
- event;
- stream;
- temporal;
- causal;
- provenance;
- constraints;
- capabilities;
- contracts;
- equivalence;
- query;
- observation;
- resource;
- error.

### Consequence

SMM MUST NOT redefine these concepts independently.

Instead:

```text
Core semantic definitions
          ↓
Semantic Machine interpretation
          ↓
STC relations
```

---

## 3. Field

`lib/301_Field/101_definition.md` defines Field as a semantic computational structure over a domain.

SMM depends on Field but does not replace it.

The SMM question is:

> Given a computational field, what makes its transformations into an implementation-independent abstract machine?

---

## 4. Graph

`lib/203_Graph/101_definition.md` defines graph specializations over the Core semantic hypergraph.

Executable semantic hypergraphs belong here semantically.

SMM should not create a new graph ontology merely to represent execution.

The distinction is:

```text
Semantic Hypergraph
       │
       ├── data/structural meaning
       │
       └── executable semantic structure
```

The latter requires execution semantics but does not require a new graph primitive.

---

## 5. Topology

`lib/303_Topology/101_definition.md` defines connectivity, continuity, neighbourhood, incidence, boundaries, and related invariants.

STC may use topological relationships to determine semantic dependency or propagation.

SMM must not duplicate topology.

---

## 6. Spatial

`lib/801_Spatial/101_definition.md` already provides:

- spatial domains;
- positions;
- spatial relationships;
- reference systems;
- metrics;
- topology/connectivity;
- neighbourhood/locality;
- queries;
- transformations;
- provenance;
- hierarchical and distributed spatial structures.

SMM must not introduce a new "Computational Space" primitive unless a semantic counterexample demonstrates that Spatial/Core cannot express the requirement.

---

## 7. Interfaces

`lib/902_Interfaces` already contains interfaces such as:

- Dynamical;
- Spatial;
- Differentiable;
- Distributable;
- Observable;
- Persistable;
- Renderable;
- Stateful;
- Streamable;
- Optimizable;
- Learnable.

SMM must not turn these interfaces into machine components.

They express semantic capabilities/properties that may participate in applicability and realization.

---

## 8. Providers

`lib/904_Providers` already defines provider semantics.

The new SMM model confirms that Providers belong on the realization side.

The canonical relationship is:

\[
Provider\models Capability
\]

not:

\[
Capability=Provider
\]

No provider belongs in the SMM kernel.

---

## 9. Transforms

`lib/905_Transforms` is the correct home for transformation specializations such as:

- specialization;
- partition;
- merge/split;
- propagation;
- migration;
- replication;
- materialization;
- dematerialization;
- lowering.

These are not SMM machine components.

STC supplies the abstract transition semantics within which such transformations can be interpreted.

---

## 10. Lowering

`lib/903_Lowering` remains responsible for:

```text
semantic representation
      ↓
generic representation
      ↓
target representation
      ↓
physical execution
```

SMM does not become an MLIR dialect.

---

## 11. Rendering

Rendering remains endogenous to the Semantic Field.

It is an observation/manifestation domain.

It is not a machine subsystem.

---

## 12. Control

Control is operational and exogenous.

The control plane may operate on EGS or other realization infrastructure without becoming part of the Semantic Machine.

---

## 13. Concepts Explicitly NOT to Add

Do not create top-level semantic domains merely for:

- Processor;
- Scheduler;
- Memory;
- Storage;
- Executor;
- Runtime;
- Namespace;
- Migration Engine;
- Manifestation Engine;
- Communication Engine.

These are either existing semantic concepts or realization mechanisms.

---

## 14. Candidate New Semantic Concepts

The following may eventually justify definitions if formalization exposes a genuine semantic gap:

1. Outcome algebra;
2. semantic execution context refinement;
3. transition independence/conflict;
4. observation equivalence;
5. computational-field criterion.

Even these should first be tested as extensions to existing Core definitions.

---

## 15. Crosswalk Table

| SMM concern | Existing SCR authority | Action |
|---|---|---|
| Semantic state | Core State | Reuse / refine only if required |
| Context | Core Context | Reuse |
| Transformation | Core Transformation | Reuse |
| Constraint | Core Constraint | Reuse |
| Hypergraph | Core + Graph | Reuse |
| Field | Field | Reuse |
| Spatial semantics | Spatial | Reuse |
| Topological semantics | Topology | Reuse |
| Capability | Interfaces / Providers | Reuse |
| Provider | Providers | Realization only |
| Representation | Core / Lowering | Reuse |
| Transformation of representations | Transforms / Lowering | Reuse |
| Observation | Core Observation | Reuse |
| Equivalence | Core Equivalence | Reuse |
| Outcome | Core Error/Operation plus STC gap | Formalize carefully |
| Transition | Core Transition + STC | Reuse/refine |
| Execution environment | EGS architecture | Operational realization |
| Reference Executor | Existing runtime | Canonical witness |
| MLIR | Lowering | Representation |
| Mojo | Implementation | Implementation |
| Processor | Provider/resource | Realization |
| Scheduler | Realization | Do not add to SMM |
| Storage | Provider/capability | Do not add to SMM |
| Communication | Provider/capability | Do not add to SMM |

---

## 16. Required Existing-Definition Review

Before implementing STC, inspect the exact current definitions of:

- Core `State`;
- Core `Transition`;
- Core `Context`;
- Core `Transformation`;
- Core `Operation`;
- Core `Observation`;
- Core `Equivalence`;
- Core `Error`;
- Interfaces;
- Providers;
- Transforms.

If a concept is already present, the SMM implementation MUST reference or refine it rather than duplicate it.

---

## 17. Architectural Test

For every proposed new SMM type, ask:

1. Is it semantically observable?
2. Does it have meaning independent of implementation?
3. Is it required by the transformation calculus?
4. Can an existing Core concept express it?
5. Can it be derived?
6. Does adding it create a duplicate ontology?
7. Does removing it make a valid semantic case inexpressible?

Only a demonstrated "yes" to the final question is sufficient evidence for a new primitive.

---

## 13. Provisional status after the graph-relational refinement

Per `docs/112` (STC-001.5): the STC-001 additions mapped in §2
(`ResultState`, `Footprint`, `Overlap`, `causallyDependent`) are
PROVISIONAL. `ResultState`/`OutcomeOf` are candidates for demotion to
projections of a single typed edge relation; `causallyDependent :=
¬independent` is REJECTED pending the order-sensitivity candidate.
`Applicable`/`Consents` are reused unchanged and are NOT provisional
(irreducible by CX-GRAPH-007). The reuse rules of §1–§12 are
unaffected: no decision in this crosswalk reifies an implementation
concept; the refinements remain relation-level over existing
ontology, and none has been promoted to permanent kernel status
without surviving the primitive-elimination test of §12.

Update (gate closure, `docs/112` part II): the demotion of
`OutcomeOf`/`ResultState` is now evidence-backed — the canonical
golden path re-derives over the graph carrier
(`STCGraphMigration.wm_golden_composition`); `causallyDependent`
loses its definition to the enablement/conflict decision
(`STCGraphLaws.E`); Delta maps to consequence-payload per
`101_Core` §23 (`D.delta_gt_span`). STC-002 proceeds under those
terms.
