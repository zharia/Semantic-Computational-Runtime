# Execution, Manifestation, EGS, Providers, and Conformance

**Document ID:** SCR-DOC-EXEC-108  
**Status:** Normative architectural draft  
**Version:** 0.1.0

---

## 1. Purpose

This document fixes the architectural boundary between SCR semantics and their physical realization.

The most important rule is:

\[
\boxed{
Meaning \rightarrow Representation \rightarrow Realization
}
\]

not:

\[
PhysicalImplementation\rightarrow Meaning
\]

---

## 2. Layer Model

```text
SEMANTIC AUTHORITY
────────────────────────────────────
Semantic Field
      │
      ▼
Semantic Machine Model
      │
      ▼
Semantic Transition Calculus
      │
      ▼
Executable Semantic Hypergraph
      │
      ▼
Semantic Observation / Equivalence

REALIZATION
────────────────────────────────────
Reference Executor
Other conforming implementations
      │
      ▼
EGS
      │
      ▼
Capability resolution
      │
      ▼
Providers
      │
      ▼
Physical resources
      │
      ▼
Manifestation
```

The boundary between the two is architectural, not necessarily a separate process boundary.

---

## 3. EGS

EGS is:

> **SCR Executable Graph Server (EGS): The operational execution environment that hosts executable semantic hypergraphs, establishes execution contexts, resolves semantic capabilities, and provides the physical mechanisms through which graph execution occurs.**

EGS is therefore an execution environment.

EGS MUST NOT:

- define semantic meaning;
- redefine Core state;
- replace the Semantic Machine;
- become the semantic authority;
- force provider identity into executable graphs.

EGS MAY:

- select providers;
- allocate resources;
- establish physical execution contexts;
- schedule physical work;
- manage execution;
- report realization failures;
- expose telemetry;
- materialize semantic observations.

---

## 4. Providers

Providers are realization mechanisms.

\[
Provider\models Capability
\]

A provider MAY be:

- CPU;
- GPU;
- accelerator;
- numerical backend;
- physics backend;
- storage implementation;
- messaging implementation;
- rendering implementation;
- spatial implementation;
- distributed implementation.

The semantic contract is upstream.

Provider identity is not part of the meaning of a transformation unless the field explicitly models provider identity as semantic data.

---

## 5. Capability Resolution

A semantic graph may require:

\[
Requires(\delta,c)
\]

EGS or a compiler may determine:

\[
Provides(P,c)
\]

and then select:

\[
Select(c)\rightarrow P
\]

This selection is not itself a semantic transformation.

Replacing \(P\) with \(P'\) is permitted where:

\[
P\models c
\land
P'\models c
\]

and both preserve the required semantic contract.

---

## 6. Manifestation

Manifestation is the process by which a semantic transition becomes physical execution.

\[
PhysicalExecution=Manifestation(\delta)
\]

The selected implementation may include:

- compilation;
- interpretation;
- kernel dispatch;
- distributed execution;
- storage access;
- message exchange;
- hardware execution;
- cached results.

The semantic transition remains authoritative.

---

## 7. Executable Hypergraph

The executable hypergraph is a representation of executable semantic structure.

It may specify:

- semantic dependencies;
- transformations;
- constraints;
- required capabilities;
- contexts;
- observations;
- provenance.

It MUST NOT encode:

- provider names as semantic requirements;
- CPU core IDs;
- GPU device IDs;
- process IDs;
- memory addresses;
- container IDs;
- network endpoints,

unless those are explicitly part of the modeled semantic field.

---

## 8. Reference Executor

The Reference Executor provides a canonical witness.

It should be intentionally conservative and transparent.

Its purpose is to answer:

> What does the semantic specification mean for this input?

It is not required to be fast.

A production implementation may use entirely different physical mechanisms while remaining conformant.

---

## 9. Conformance

Conformance is semantic, not implementation-structural.

An implementation conforms when its required observations are equivalent to the SMM-defined observations.

Conceptually:

\[
I\models SMM
\]

if:

\[
\forall \delta,\quad
Obs(I(\delta))
\equiv
Obs(SMM(\delta))
\]

for the required domain and context.

The actual Lean definition must distinguish:

- total conformance;
- partial conformance;
- capability-limited conformance;
- deterministic conformance;
- stochastic conformance.

---

## 10. Implementation State

An implementation may maintain hidden state:

\[
IState=S\cup H
\]

where \(H\) contains implementation-only information.

Examples:

- caches;
- indexes;
- compiled kernels;
- allocation state;
- scheduling queues;
- device state;
- synchronization state;
- transport state;
- storage metadata.

Hidden state is permitted provided it does not violate semantic observations.

---

## 11. Optimization

Optimization is valid when it preserves required semantics.

A transformation:

\[
T_1\rightarrow T_2
\]

is valid when:

\[
Obs(T_1)\equiv Obs(T_2)
\]

under the applicable contract.

This is the fundamental reason SCR can permit:

- fusion;
- tiling;
- vectorization;
- parallelization;
- caching;
- memoization;
- specialization;
- approximation,

where their semantic contracts permit them.

---

## 12. Physical Failure

A provider may fail even though the semantic transition is valid.

This is a realization failure.

The system must not silently reinterpret:

```text
provider unavailable
```

as:

```text
semantic transformation invalid
```

The distinction is required for recovery, retry, fallback, and diagnosis.

---

## 13. Fallback

A fallback provider may be selected when the semantic requirement remains unchanged.

\[
P_1\models C
\]

and:

\[
P_2\models C
\]

allow:

\[
P_1\rightsquigarrow P_2
\]

without changing the semantic graph.

Fallback selection is therefore a realization concern.

---

## 14. Persistence and Migration

Persistence is a realization of semantic state durability.

Migration is a realization of a semantic state transformation across contexts.

Storage location is not semantic identity.

Processor location is not semantic identity.

A state can move across:

- memory;
- storage;
- processor;
- host;
- cluster;
- provider;

without changing semantic identity if the semantic identity contract is preserved.

---

## 15. Communication

Communication realizes semantic dependencies where the physical execution is distributed.

A message broker, socket, shared memory region, RPC system, or direct function call may all realize the same semantic dependency.

Communication mechanism therefore does not define the dependency's meaning.

---

## 16. Scheduler

A scheduler realizes semantic execution constraints physically.

It is not the source of semantic ordering.

The scheduler may choose a physical order consistent with semantic constraints.

It may not violate a required semantic dependency merely because another physical schedule is faster.

---

## 17. Processor

A processor is a realization resource.

The semantic machine does not care whether the realization occurs on:

- CPU;
- GPU;
- FPGA;
- accelerator;
- remote service;
- interpreter.

Unless the field explicitly models the hardware distinction semantically, these are interchangeable realization dimensions.

---

## 18. Architectural Invariant

The following implication must hold:

\[
Provider_1\equiv_{cap}Provider_2
\Rightarrow
SemanticGraph_{required}\ unchanged
\]

Likewise:

\[
Representation_1\equiv_{sem}Representation_2
\Rightarrow
Meaning\ unchanged
\]

and:

\[
ExecutionStrategy_1\equiv_{obs}ExecutionStrategy_2
\Rightarrow
SemanticOutcome\ unchanged
\]

---

## 19. Control Plane

The Control Plane is exogenous to the executing Semantic Field.

\[
\boxed{
Rendering\ manifests\ the\ Semantic\ Field
}
\]

\[
\boxed{
Control\ manages\ the\ system\ that\ manifests\ the\ Semantic\ Field
}
\]

Control-plane mechanisms may reuse semantic machinery, but they do not become dependencies of the controlled field unless explicitly modeled.

This preserves the distinction between:

- endogenous field semantics;
- exogenous operational control.

---

## 20. HyrxMQ / AMQP Boundary

Messaging may be used as an execution/control realization.

It must not be inserted into SMM merely because SCR may use messaging operationally.

The semantic model defines causal/dependency relationships.

AMQP, HyrxMQ, or another broker realizes those relationships where required by deployment.

---

## 21. MLIR Boundary

MLIR is a representation and lowering substrate.

The SMM does not depend on a custom `scr.*` dialect.

Existing SCR policy remains:

- standard MLIR dialects;
- metadata/attributes where appropriate;
- no semantic authority transferred to MLIR.

---

## 22. Mojo Boundary

Mojo is the preferred implementation language.

It implements semantic contracts.

It does not define them.

Mojo structures must therefore be derived from the semantic model rather than becoming the source of new semantic primitives.

---

## 23. Final Firewall

The following dependency is permitted:

```text
Meaning
  ↓
Semantic Transformation
  ↓
Representation
  ↓
Implementation
  ↓
Provider
  ↓
Physical Execution
```

The following is forbidden:

```text
Physical Execution
  ↓
Provider
  ↓
Implementation
  ↓
Representation
  ↓
Meaning
```

Physical observations may trigger semantic error handling only where the semantic contract explicitly defines those observations.
