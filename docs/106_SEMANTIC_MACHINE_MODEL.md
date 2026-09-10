# Semantic Machine Model (SMM)

**Document ID:** SCR-DOC-SMM-106  
**Status:** Normative architectural draft  
**Version:** 0.1.0  
**Scope:** SCR architecture  
**Authority:** Project architecture; this document does not replace domain-level `101_definition.md` files.

---

## 1. Purpose

The Semantic Machine Model (SMM) defines the implementation-independent computational machine induced by a computational Semantic Field.

SMM exists to establish a precise boundary between:

1. what a computation means;
2. what semantic transformations are lawful;
3. what outcomes are semantically permitted;
4. what an implementation must preserve; and
5. how those semantics may be physically realized.

The SMM is therefore an **abstract machine specification**, not a runtime component architecture.

The central architectural law is:

\[
\boxed{\text{Machine Semantics} \neq \text{Machine Implementation}}
\]

and:

\[
\boxed{\text{Implementation} \models \text{Machine Semantics}}
\]

---

## 2. Definition

### 2.1 Semantic Machine

> **The Semantic Machine is the implementation-independent abstract computational system induced by a computational Semantic Field. It defines the semantically observable state of the field, the contexts in which that state is interpreted, the lawful transformations applicable to that state, the constraints governing their admissibility, the outcomes permitted by their realization, and the equivalence relations by which alternative realizations are determined to preserve semantic meaning.**

The Semantic Machine does **not** prescribe:

- physical representation;
- processor architecture;
- memory organization;
- instruction encoding;
- scheduling mechanism;
- storage mechanism;
- communication mechanism;
- execution strategy;
- provider;
- deployment environment;
- operating system;
- container;
- device;
- network topology;
- physical resource allocation.

---

## 3. Semantic Machine Model

> **The Semantic Machine Model is the formal specification of the Semantic Machine and its conformance boundary.**

The minimal kernel is:

\[
\boxed{
SMM=\langle\mathcal S,\mathcal C,\mathcal T,\mathcal K,\mathcal O,\equiv\rangle
}
\]

where:

- \(\mathcal S\) — semantic states;
- \(\mathcal C\) — semantic contexts;
- \(\mathcal T\) — semantic transformations;
- \(\mathcal K\) — semantic constraints;
- \(\mathcal O\) — semantic outcomes;
- \(\equiv\) — semantic equivalence.

This tuple is intentionally smaller than the surrounding SCR architecture.

If a concept can be derived from these elements, it must not be promoted to an additional primitive without a demonstrated semantic necessity.

---

## 4. Relationship to the Semantic Field

SCR's Semantic Field remains architecturally prior.

A Semantic Field describes meaningful semantic structure. A **computational** Semantic Field is one for which lawful transformation semantics are defined.

A useful criterion is:

\[
ComputationalField(F)
\iff
F\text{ admits defined transformation semantics}
\]

The SMM is therefore derived from the field:

\[
\boxed{SMM(F)=FormalComputationalSemantics(F)}
\]

The SMM is not:

\[
SMM=F+Runtime
\]

and not:

\[
SMM=RuntimeArchitecture
\]

The runtime is a realization of semantics that are already defined.

---

## 5. Semantic State

A semantic state is the portion of Semantic Field state relevant to computational interpretation at a particular semantic context.

The SMM does not require that semantic state correspond to:

- a memory object;
- a process;
- a database row;
- a file;
- an MLIR SSA value;
- a CPU register;
- a GPU buffer;
- a network message.

An implementation state may contain substantially more information:

\[
IState \supseteq S
\]

where the implementation state contains caches, scheduling metadata, indexes, allocation state, device state, synchronization state, compiled code, and other realization information.

A semantic projection may therefore be defined:

\[
\pi:IState\rightarrow S
\]

Correctness requires preservation of the relevant semantic state:

\[
\pi(IState_{t+1})\equiv S_{t+1}
\]

where equivalence is evaluated under the observation and equivalence rules of the applicable semantic context.

---

## 6. Context

Context determines how semantic state and transformations are interpreted.

Context is not equivalent to:

- a process;
- a thread;
- a runtime object;
- a namespace implementation;
- a CPU execution context;
- a container;
- a Kubernetes context.

A context may contain semantic conditions, references, temporal interpretation, spatial interpretation, authority, capabilities, environmental assumptions, or other information required by a transformation.

Existing Core `Context` remains the semantic authority for context. SMM should reuse it rather than introduce a parallel context ontology.

---

## 7. Transformation

A semantic transformation is a lawful semantic change applicable to a state under a context.

A transformation is not identified with:

- a function pointer;
- a Mojo function;
- an MLIR operation;
- a CPU instruction;
- a provider call;
- a system call;
- a message;
- a database transaction.

The distinction is:

\[
\boxed{SemanticTransformation\neq PhysicalInstruction}
\]

and:

\[
\boxed{Representation(\tau)\neq Realization(\tau)}
\]

An implementation may realize one semantic transformation using:

- zero CPU instructions in a cached observation;
- one machine instruction;
- many machine instructions;
- a GPU kernel;
- distributed execution;
- interpretation;
- JIT compilation;
- AOT compilation;
- a remote provider;
- a combination of providers.

All are valid if they preserve the required semantics.

---

## 8. Constraints

Constraints determine admissibility.

Let:

\[
Applicable(\tau,S,C)
\]

mean that transformation \(\tau\) is meaningful for state \(S\) in context \(C\).

Let:

\[
Admissible(\tau,S,C,K)
\]

mean that the transformation satisfies the applicable semantic constraints.

Then:

\[
Admissible(\tau,S,C,K)\Rightarrow Applicable(\tau,S,C)
\]

Applicability and admissibility are semantic properties. Physical capability is not.

---

## 9. Semantic Transition

A semantic transition is an instantiated application of a transformation to a semantic state under a context and constraints.

Rather than making transition a new primitive, define it by instantiation:

\[
\delta =
Instantiate(\tau,S,C,K)
\]

provided:

\[
Applicable(\tau,S,C)
\land
Admissible(\tau,S,C,K)
\]

The Semantic Transition Calculus is specified separately in `107_SEMANTIC_TRANSITION_CALCULUS.md`.

---

## 10. Outcomes

A transition does not necessarily produce exactly one result.

Define the semantic outcome relation:

\[
\boxed{
M(\delta)\subseteq\mathcal O
}
\]

This permits:

- deterministic outcomes;
- nondeterministic outcomes;
- stochastic outcomes;
- partial outcomes;
- failure outcomes;
- indeterminate outcomes.

For deterministic transitions:

\[
|M(\delta)|=1
\]

The model must not silently collapse semantic nondeterminism into physical scheduling behaviour.

---

## 11. Failure Taxonomy

SCR must distinguish at least four classes:

### 11.1 Semantic rejection

The requested transformation is not admissible.

Examples:

- invalid input domain;
- violated constraint;
- transformation not applicable in context.

### 11.2 Semantic failure

The transformation is semantically valid, but its outcome is a defined failure outcome.

### 11.3 Realization failure

The semantic transformation is valid, but the selected implementation cannot currently realize it.

Examples:

- unavailable capability;
- incompatible provider;
- resource exhaustion;
- provider constraint violation.

### 11.4 Physical failure

A selected physical realization failed during execution.

These must not be collapsed into one generic "execution error".

---

## 12. Concurrency and Ordering

Semantic ordering is distinct from physical scheduling.

\[
\boxed{
SemanticOrdering\neq PhysicalScheduling
}
\]

Likewise:

\[
\boxed{
SemanticConcurrency\neq PhysicalParallelism
}
\]

Two semantic transitions may be independent:

\[
\delta_1\perp\delta_2
\]

meaning that no semantic dependency or required ordering exists between them.

This does not require simultaneous physical execution.

A sequential implementation may legally realize semantically independent transitions if observations remain equivalent.

Conversely, physically parallel execution does not imply semantic independence.

---

## 13. Atomicity

Atomicity is treated as a property or constraint of a transition, not as a new machine component.

A transition may require that no externally observable intermediate semantic state exist.

Atomicity therefore belongs to the semantic contract of the applicable transformation and observation boundary.

The implementation may realize atomicity through:

- locking;
- transactional memory;
- copy-on-write;
- versioning;
- compare-and-swap;
- message ordering;
- database transactions;
- single-threaded execution;
- other mechanisms.

No mechanism is normative at the SMM level.

---

## 14. Causality and Temporal Semantics

Temporal and causal ordering are semantic relations.

Physical timestamps, wall-clock time, CPU cycles, event-loop ticks, network latency, and scheduler order are implementation mechanisms unless explicitly elevated into the Semantic Field's meaning.

The SMM must distinguish:

- semantic time;
- duration;
- deadline;
- temporal precedence;
- causal precedence;
- physical execution time.

A faster realization and a slower realization may be semantically equivalent when physical timing is not semantically observable.

Where timing is itself part of the field semantics, timing becomes part of the observation/equivalence contract.

---

## 15. Observation

Observation defines what semantic behaviour is exposed to an observer.

A physical implementation may differ internally while remaining correct if:

\[
Obs(I_1)\equiv Obs(I_2)
\]

for the observations required by the semantic contract.

Observation is therefore the principal boundary for determining implementation equivalence.

Internal differences do not constitute semantic differences unless they are observable under the applicable contract.

---

## 16. Semantic Equivalence

Semantic equivalence establishes whether two states, transitions, outcomes, or realizations preserve the same required meaning.

Equivalence is contextual:

\[
x\equiv_C y
\]

rather than necessarily universal bitwise identity.

This permits:

- representation equivalence;
- state equivalence;
- observational equivalence;
- transition equivalence;
- implementation equivalence.

The existing SCR semantic equivalence machinery should be extended from its current representation-preservation role toward this broader conformance boundary.

---

## 17. Reference Executor

The Reference Executor is a canonical executable realization of the semantic model.

It is not:

- the Semantic Machine;
- the SMM;
- the only legal implementation;
- the physical runtime architecture.

Let:

\[
RE(\delta)=O_R
\]

and another implementation produce:

\[
I(\delta)=O_I
\]

Correctness requires:

\[
O_I\equiv_{sem}O_R
\]

subject to the same semantic contract.

The Reference Executor is therefore an executable oracle/witness for semantics.

---

## 18. Executable Semantic Hypergraph

An executable semantic hypergraph is a semantic representation of executable structure.

It is not the Semantic Machine itself.

It may be compared conceptually to:

- RISC-V instruction representation;
- JVM bytecode;
- CIL;
- other executable representations.

However, SCR is not required to become instruction-sequential.

The executable hypergraph may express:

- entities;
- transformations;
- dependencies;
- constraints;
- relationships;
- observations;
- execution requirements.

Its requirements must remain semantic.

### Provider firewall

\[
\boxed{
ExecutableHypergraph
\not\rightarrow
PhysicalProvider
}
\]

An executable hypergraph may express a required capability, but it must not directly select a provider.

---

## 19. Providers

A provider realizes a declared semantic capability.

\[
Provider\models Capability
\]

not:

\[
Capability=Provider
\]

Provider selection belongs to realization infrastructure such as compilation and/or EGS.

Replacing a provider with another provider satisfying the same semantic contract must not require modification of the semantic hypergraph.

---

## 20. EGS

The canonical operational component is:

> **SCR Executable Graph Server (EGS): The operational execution environment that hosts executable semantic hypergraphs, establishes execution contexts, resolves semantic capabilities, and provides the physical mechanisms through which graph execution occurs.**

EGS is not the Semantic Machine.

The distinction is:

\[
\boxed{
EGS=ExecutionEnvironment(SMM)
}
\]

EGS performs realization work. It must not redefine semantic meaning.

---

## 21. Manifestation

"Manifestation" is an architectural process, not a subsystem name.

\[
\boxed{
PhysicalExecution=Manifestation(SemanticTransition)
}
\]

The governing firewall is:

\[
\boxed{
Manifestation\not\rightarrow Meaning
}
\]

Physical realization can change while semantic meaning remains invariant.

---

## 22. Resources, Processors, Schedulers, Storage, Communication

These are realization concepts.

### Processor

A physical resource/provider through which semantic transformations may be realized.

### Scheduler

A physical mechanism that realizes semantic ordering, concurrency, and resource allocation.

### Storage

A physical mechanism through which persistence or state recovery may be realized.

### Communication

A physical mechanism through which semantic dependency, causality, or data movement may be realized.

None is a required SMM primitive.

---

## 23. Persistence, Migration, Replication

These are semantic transformations/capabilities, not machine subsystems.

Persistence may be expressed as:

\[
Restore(S_t)\rightarrow S'
\]

with:

\[
S'\equiv S_t
\]

Migration may be expressed as:

\[
(S,C_1)\rightarrow(S',C_2)
\]

where:

\[
S'\equiv_{required}S
\]

Replication requires an explicit equivalence and divergence model; it must not be assumed to mean bitwise duplication.

---

## 24. ISA

"Semantic ISA" is demoted from machine ontology.

An ISA is one possible representation of a machine's semantic transformations:

\[
SemanticISA\subseteq Representation(SM)
\]

It is not:

\[
SM=SemanticISA
\]

SCR may use graph-native executable representations without requiring a linear instruction stream.

---

## 25. Implementation Independence

An implementation is correct when it realizes the semantic contract, not when it reproduces an implementation strategy.

The implementation may introduce arbitrary internal state:

\[
IState=S\cup H
\]

where \(H\) is hidden realization state.

Correctness is evaluated by projection and observation:

\[
\pi(IState)\equiv S
\]

and:

\[
Obs(I)\equiv Obs(SMM)
\]

---

## 26. Architectural Firewall

The following dependency direction is normative:

```text
Semantic Field
      │
      ▼
Semantic Machine Model
      │
      ▼
Semantic Machine
      │
      ▼
Semantic Transformation
      │
      ▼
Semantic Outcome
      │
      ▼
Semantic Equivalence
      │
      ├───────────────┐
      ▼               ▼
Reference         Other
Executor          Implementations
      │               │
      └───────┬───────┘
              ▼
             EGS
              │
              ▼
          Capabilities
              │
              ▼
           Providers
              │
              ▼
     Physical Resources
              │
              ▼
        Manifestation
```

The reverse semantic dependency is forbidden.

A provider, runtime component, representation, processor, or physical resource MUST NOT become the source of semantic meaning.

---

## 27. What SMM Is Not

SMM is not:

- an operating system;
- a process model;
- a scheduler;
- a memory manager;
- a storage system;
- a message broker;
- a graph database;
- an MLIR dialect;
- a programming language;
- a provider registry;
- EGS;
- the Reference Executor;
- a collection of Mojo classes;
- a replacement for the Semantic Field.

---

## 28. Design Invariants

1. Meaning precedes representation.
2. Semantic state is distinct from implementation state.
3. Semantic transformation is distinct from physical instruction.
4. Semantic ordering is distinct from physical scheduling.
5. Semantic concurrency is distinct from physical parallelism.
6. Semantic validity is distinct from physical realizability.
7. Semantic outcome is distinct from physical success.
8. Providers realize capabilities; they do not define them.
9. EGS realizes execution; it does not define semantics.
10. MLIR represents and lowers; it does not define SCR semantics.
11. Mojo implements; it does not define SCR semantics.
12. Reference Executor witnesses semantics; it does not monopolize realization.
13. Persistence, migration, replication, propagation, and scheduling are derived concerns.
14. Executable hypergraphs express semantic requirements, not physical provider choices.
15. Manifestation cannot alter meaning.
16. Any proposed new primitive must be justified by a semantic counterexample showing that the existing kernel cannot express the required behaviour.

---

## 29. Relationship to Existing SCR Library

SMM must reuse existing authoritative definitions where possible:

- `101_Core` for identity, state, transformation, constraint, context, observation, provenance, equivalence, etc.;
- `301_Field` for field semantics;
- `203_Graph` for semantic hypergraph structure;
- `303_Topology` and `801_Spatial` for spatial/topological semantics;
- `902_Interfaces` for declared capabilities/interfaces;
- `904_Providers` for realization;
- `905_Transforms` for semantic/representation transformations;
- `903_Lowering` for representation and lowering.

SMM is therefore an architectural formalization layer over existing semantic definitions, not a parallel ontology.

---

## 30. Open Formal Questions

The following must be resolved by the Semantic Transition Calculus rather than by adding speculative subsystems:

1. exact boundary between Core `State` and SMM semantic state;
2. exact use of Core `Context`;
3. outcome algebra;
4. temporal semantics;
5. concurrency and conflict;
6. composition;
7. atomicity;
8. observation boundary;
9. identity preservation;
10. computational-field criterion.

These questions are the next formalization work.
