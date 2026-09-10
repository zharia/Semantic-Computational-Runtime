# SMM Terminology and Architectural Decisions

**Document ID:** SCR-DOC-DEC-111  
**Status:** Normative terminology record  
**Version:** 0.1.0

---

## 1. Semantic Machine

Use:

> **Semantic Machine**

for the abstract computational system.

Do not use "Semantic VM" as the canonical SCR term.

"Abstract machine" is the comparative category.

---

## 2. Semantic Machine Model

Use:

> **Semantic Machine Model (SMM)**

for the formal specification of the Semantic Machine.

SMM is not a runtime architecture.

---

## 3. Semantic Transition Calculus

Use:

> **Semantic Transition Calculus (STC)**

for the formal transition semantics underlying SMM.

STC is the next formalization artifact.

---

## 4. Executable Graph Server

Use:

> **SCR Executable Graph Server (EGS)**

for the operational execution environment.

Do not call EGS the Semantic Machine.

---

## 5. Manifestation

Use:

> **Manifestation**

as an architectural process describing physical realization of semantic computation.

Do not use:

- Manifestation Engine;
- Manifestation Server;
- Manifestation Subsystem,

as normative component names unless a later independent requirement justifies one.

---

## 6. Provider

A Provider realizes a semantic capability.

Correct:

\[
Provider\models Capability
\]

Incorrect:

\[
Capability=Provider
\]

---

## 7. Reference Executor

The Reference Executor is a canonical executable realization and semantic oracle.

Correct:

```text
Reference Executor = canonical witness
```

Incorrect:

```text
Reference Executor = Semantic Machine
```

---

## 8. Semantic ISA

The term may be used historically or descriptively, but it is not a top-level SMM primitive.

An ISA is one possible representation of semantic machine operations.

---

## 9. Semantic State

Semantic State is the state relevant to semantic interpretation.

Implementation state may be a superset.

Do not equate semantic state with:

- memory;
- process state;
- VM heap;
- database state;
- MLIR SSA;
- device state.

---

## 10. Execution Context

Avoid treating execution context as a physical runtime object.

Context is a semantic concept.

A runtime may instantiate a physical execution context to realize a semantic Context.

---

## 11. Computational Space

Do not create "Computational Space" as an SMM primitive merely because distributed execution or spatial partitioning requires a physical space.

Use existing Spatial, Topology, Field, Region, and Context semantics.

A new primitive requires a demonstrated semantic gap.

---

## 12. Computational Field

A field becomes computational when lawful transformation semantics are defined over it.

Candidate criterion:

\[
ComputationalField(F)
\iff
F\text{ admits defined transformation semantics}
\]

This must be tested during formalization.

---

## 13. Persistence

Persistence is a semantic requirement/capability and a realization process.

It is not a machine subsystem.

---

## 14. Migration

Migration is a semantic transformation/capability.

It is not a machine subsystem.

---

## 15. Propagation

Propagation is a semantic transformation constrained by topology/context.

It is not a machine subsystem.

---

## 16. Scheduler

Scheduler is a physical realization mechanism.

Semantic ordering must be represented independently.

---

## 17. Processor

Processor is a physical resource/provider manifestation.

It is not an SMM primitive.

---

## 18. Storage

Storage is a realization of persistence.

Storage location does not define semantic identity.

---

## 19. Communication

Communication is a realization of semantic dependency/causality.

The semantic relationship is upstream of the communication mechanism.

---

## 20. Control Plane

Control Plane is exogenous to the executing Semantic Field.

Rendering is endogenous.

The distinction is:

> Rendering manifests the Semantic Field. Control manages the system that manifests the Semantic Field.

---

## 21. MLIR

MLIR is representation/lowering infrastructure.

It does not define SCR semantics.

---

## 22. Mojo

Mojo is the preferred implementation language.

It does not define SCR semantics.

---

## 23. Decision Rule

Whenever terminology becomes ambiguous, prefer the term that preserves the following separation:

```text
SEMANTIC
  What does it mean?

REPRESENTATIONAL
  How is that meaning encoded?

REALIZATION
  How is it physically executed?

OPERATIONAL
  How is the execution environment managed?
```

A concept should not cross these boundaries without explicit semantic justification.
