# SCR STC-001 — Semantic Transition Calculus Formalization and Falsification

## Mission

You are implementing the next foundational increment of the Semantic Computational Runtime (SCR).

The current SCR architecture is explicitly founded on the principle:

> **Engineer outward from the Semantic Field.**

The repository now contains an established Semantic Field / Semantic Machine Model (SMM) documentation layer, an existing Lean formal ontology, a Mojo semantic kernel, a Reference Executor, MLIR representation/lowering, and differential execution.

Your task is **NOT** to build another runtime subsystem.

Your task is to determine whether the current Semantic Machine Model can be given a coherent formal computational calculus without silently importing assumptions from conventional programming languages, virtual machines, schedulers, processors, databases, message brokers, operating systems, or physical execution architectures.

The specific increment is:

> **STC-001 — Semantic Transition Calculus Formalization**

The primary objective is falsification.

Do not merely make the proposed model compile.

Attempt to demonstrate where it is insufficient, ambiguous, redundant, inconsistent, or incapable of expressing required computation.

Where the model survives, formalize it.

Where it fails, produce a concrete counterexample before changing the semantic ontology.

---

# 1. Absolute architectural principles

These are constraints, not suggestions.

## 1.1 Semantic primacy

The Semantic Field is the foundational engineering principle.

SCR treats computation as transformation of semantic structure within a field.

Do not reason:

```text
runtime component
    ↓
semantic abstraction
```

Reason:

```text
Semantic Field
    ↓
semantic structure
    ↓
semantic transformation
    ↓
semantic transition
    ↓
semantic observation/equivalence
    ↓
possible physical manifestation
```

Physical implementation is a realization of semantics.

It is not the source of semantics.

---

## 1.2 Do not invent abstractions to make the implementation convenient

The following pattern is prohibited:

```text
STC says "Context"
    ↓
create Context type

STC says "Outcome"
    ↓
create Outcome type

STC says "Transition"
    ↓
create Transition type
```

That is backwards.

Instead:

```text
STC concept
    ↓
inspect existing SCR ontology
    ↓
attempt formal expression using existing concepts
    ↓
identify actual insufficiency
    ↓
construct counterexample
    ↓
determine minimum semantic refinement
```

A new semantic primitive is justified only when an existing semantic structure cannot express the required distinction without loss of meaning.

---

## 1.3 Implementation existence is not semantic evidence

Never infer:

> "The runtime needs X, therefore X is a fundamental semantic primitive."

For example, the existence of:

* a scheduler
* a queue
* a thread
* a process
* a CPU
* a worker
* a database
* a storage provider
* a network connection
* a message
* a timestamp
* a memory allocation
* a container
* a Kubernetes pod
* an executor
* a provider
* an MLIR operation

does not establish that the corresponding concept belongs in SMM.

A physical mechanism belongs in the semantic model only if its distinction is semantically observable or is explicitly represented as semantic state/capability/constraint.

---

# 2. Current architectural boundary

The current conceptual architecture is:

```text
Semantic Field
        │
        ▼
Semantic Machine Model (SMM)
        │
        ▼
Semantic Transition Calculus (STC)
        │
        ▼
Reference Executor
        │
        ▼
semantic observations
        │
        ▼
semantic equivalence
        │
        ▼
Executable / representational forms
        │
        ▼
MLIR / Mojo / lowering
        │
        ▼
physical manifestation
```

Eventually:

```text
Semantic Machine
        │
        ▼
Executable Semantic Hypergraph
        │
        ▼
SCR Executable Graph Server (EGS)
        │
        ▼
capability resolution
        │
        ▼
provider manifestation
        │
        ▼
physical execution
```

But **EGS is not this task**.

Do not implement EGS.

Do not implement provider infrastructure.

Do not implement schedulers.

Do not implement distributed execution.

Do not implement storage infrastructure.

Do not implement networking infrastructure.

Do not implement messaging infrastructure.

Do not expand the Mojo runtime merely because STC raises a conceptual question.

First establish the semantic calculus.

---

# 3. Current SMM hypothesis

Treat the following as a hypothesis to be tested, not as unquestionable truth.

The Semantic Machine is an implementation-independent abstract computational system induced by a computational Semantic Field.

It defines:

* semantically observable state
* contexts in which state is interpreted
* lawful transformations
* admissibility constraints
* outcomes permitted by realization
* equivalence relations by which alternative realizations preserve semantic meaning

It does NOT prescribe:

* physical representation
* processor architecture
* memory organisation
* scheduling
* storage mechanism
* communication mechanism
* execution strategy
* provider
* deployment environment
* implementation detail

The current proposed minimal kernel is:

$$
SMM =
\langle
\mathcal S,
\mathcal C,
\mathcal T,
\mathcal K,
\mathcal O,
\equiv
\rangle
$$

where:

* \(\mathcal S\) = semantic states
* \(\mathcal C\) = semantic contexts
* \(\mathcal T\) = semantic transformations
* \(\mathcal K\) = constraints
* \(\mathcal O\) = outcomes
* \(\equiv\) = semantic equivalence

Do not assume that this tuple is minimal merely because it looks elegant.

Attempt to falsify its minimality.

Also determine whether some members are genuinely primitive or whether some are derived from existing concepts.

---

# 4. Existing formal ontology audit

Before creating or modifying any Lean ontology, inspect the current formal model completely.

At minimum inspect:

```text
SCRFormal/SCR/Basic.lean
SCRFormal/SCR/Equivalence.lean
SCRFormal/SCR/Field.lean
SCRFormal/SCR/Identity.lean
SCRFormal/SCR/Invariants.lean
SCRFormal/SCR/Relationship.lean
SCRFormal/SCR/Seed.lean
SCRFormal/SCR/State.lean
SCRFormal/SCR/Transformation.lean
```

The current repository contains these formal components already. Do not duplicate their concepts without first determining whether they are adequate.

Also inspect:

```text
formal/
lib/
runtime/
seed/
docs/
program_increments/v0.0.1/
```

especially the authoritative semantic specifications.

Inspect the existing:

```text
lib/101_Core/
lib/203_Graph/
lib/301_Field/
lib/303_Topology/
lib/801_Spatial/
lib/902_Interfaces/
lib/903_Lowering/
lib/904_Providers/
lib/905_Transforms/
```

and the current Reference Executor.

The repository already has a broad Core ontology containing concepts such as identity, state, transition, transformation, operation, event, temporal relations, causal relations, constraints, capabilities, contracts, equivalence, observation, resources, and errors.

Therefore:

> **Do not create a second ontology simply because STC uses different terminology.**

Determine whether STC is a calculus over the existing ontology.

---

# 5. Produce the formal crosswalk first

Before substantial implementation, create a formal crosswalk.

At minimum:

| SMM/STC concept | Existing SCR concept                       | Existing Lean representation | Decision          | Reason |
| --------------- | ------------------------------------------ | ---------------------------- | ----------------- | ------ |
| Semantic State  | State                                      | `State.lean`                 | reuse/refine/gap  |        |
| Context         | existing context/field concepts            | inspect                      | reuse/refine/gap  |        |
| Transformation  | Transformation                             | `Transformation.lean`        | reuse/refine/gap  |        |
| Constraint      | existing constraint concepts               | inspect                      | reuse/refine/gap  |        |
| Outcome         | existing error/result/etc.                 | inspect                      | reuse/refine/gap  |        |
| Transition      | State/Transformation                       | inspect                      | derive/refine/gap |        |
| Observation     | Observation concepts                       | inspect                      | reuse/refine/gap  |        |
| Equivalence     | Equivalence                                | `Equivalence.lean`           | reuse/refine/gap  |        |
| Identity        | Identity                                   | `Identity.lean`              | reuse/refine/gap  |        |
| Relationship    | Relationship                               | `Relationship.lean`          | reuse/refine/gap  |        |
| Composition     | existing transformation/operation concepts | inspect                      | derive/refine/gap |        |
| Independence    | existing relationships/capabilities        | inspect                      | derive/refine/gap |        |
| Causality       | existing causal concepts                   | inspect                      | derive/refine/gap |        |
| Temporal order  | existing temporal concepts                 | inspect                      | derive/refine/gap |        |
| Conformance     | existing equivalence/observation concepts  | inspect                      | derive/refine/gap |        |

The crosswalk must explicitly distinguish:

1. existing primitive
2. existing derived concept
3. existing concept requiring refinement
4. genuine semantic gap
5. concept that should NOT exist in the semantic layer

Do not silently classify something as a gap because the name does not already exist.

---

# 6. Formalise STC

Attempt to formalise the following calculus.

The proposed structure is:

$$
STC =
\langle
S,C,T,K,O,\equiv
\rangle
$$

but this is a working hypothesis.

The formalisation must determine whether this structure is actually coherent.

---

# 7. Applicability

Formalise whether a transformation may be applied to a state under a context.

Conceptually:

$$
Applicable(\tau,S,C)
$$

Questions to answer:

1. Is applicability a primitive relation?
2. Can it be derived from transformation preconditions?
3. Is context part of state?
4. Is context an interpretation environment?
5. Can two contexts interpret the same state differently?
6. Can applicability change without state changing?
7. Can applicability itself be observed?
8. Is applicability equivalent to constraint satisfaction?

Do not answer these philosophically.

Construct formal examples and counterexamples.

---

# 8. Admissibility

Formalise:

$$
Admissible(\tau,S,C,K)
$$

with the intended invariant:

$$
Admissible(\tau,S,C,K)
\Rightarrow
Applicable(\tau,S,C)
$$

But challenge this assumption.

Determine whether:

* applicability
* admissibility
* preconditions
* constraints
* capability requirements

are genuinely distinct.

Construct examples where the distinctions matter.

For example:

```text
Transformation exists.
Transformation is structurally applicable.
Required semantic constraint is violated.
```

Then determine what the semantic calculus should say.

Do not introduce separate concepts merely because the English terminology suggests them.

---

# 9. Transition instantiation

Investigate:

$$
\delta =
Instantiate(\tau,S,C,K)
$$

The important question is whether a transition is:

1. a primitive semantic object,
2. a relation,
3. a derived object,
4. a transformation application,
5. a state delta,
6. or some combination of these.

Existing SCR already has state, transformation, transition, delta, operation and related concepts.

Determine whether STC can reuse those concepts.

Do not introduce a second `STCTransition` merely because the name is convenient.

---

# 10. Outcome semantics

This is expected to be one of the most important areas of investigation.

We need to distinguish at least:

```text
semantic rejection
semantic failure
realization failure
physical failure
```

Do not collapse these.

Investigate whether outcomes should be represented as:

$$
M(\delta)\subseteq\mathcal O
$$

rather than:

$$
M:\delta\rightarrow\mathcal O
$$

The relational/set-valued model is deliberately preferred as a hypothesis because it permits:

* deterministic outcomes
* nondeterministic outcomes
* stochastic outcomes
* partial outcomes
* failure outcomes
* multiple permitted realizations

Test this formally.

At minimum test:

### Deterministic

$$
|M(\delta)|=1
$$

### Nondeterministic

$$
|M(\delta)|>1
$$

### Failure

Determine whether failure is:

* an outcome,
* a state,
* an error,
* an observation,
* or a separate semantic relation.

### Partiality

Determine how a transformation that may produce no valid outcome should be represented.

### Stochasticity

Determine whether probability belongs in the core semantic model or in a refinement/capability.

Do not build a large probabilistic algebra unless formal counterexamples require it.

---

# 11. Semantic failure taxonomy

Explicitly investigate this distinction:

```text
Semantic rejection
    The transformation is not permitted.

Semantic failure
    The semantic operation is permitted but its specified semantic execution
    produces a failure outcome.

Realization failure
    A valid semantic transition cannot currently be realised by a provider.

Physical failure
    The physical mechanism fails while attempting realization.
```

These must not be conflated.

For example:

```text
Division by zero under a semantic rule
```

may be semantic failure.

Whereas:

```text
GPU unavailable
```

may be realization failure.

Whereas:

```text
process crashed
```

may be physical failure.

But do not assume those classifications are correct merely because they are intuitive.

Formalise the distinctions and identify where they become observable.

---

# 12. Observation

Formalise semantic observation.

Conceptually:

$$
Obs_C(O)
$$

Investigate:

* Is observation a projection?
* Is observation context-dependent?
* Can two distinct outcomes be observationally equivalent?
* Can two different representations produce the same observation?
* Can an unobservable physical distinction exist?
* Is observation itself semantic state?
* Is observation primitive or derived?

The central principle is:

> Semantic equivalence is defined over semantically observable behaviour, not representation identity.

---

# 13. Equivalence

Reuse the existing equivalence formalisation wherever possible.

Investigate the desired conformance structure:

$$
I\models SMM
$$

iff:

$$
Obs(I(\delta))
\equiv
Obs(SMM(\delta))
$$

Do not assume implementation equality.

Test:

### Representation substitution

Different representations preserve semantics.

### Provider substitution

Different providers implementing the same capability preserve semantics.

### Execution-strategy substitution

Sequential and parallel realisations may preserve the same semantic result.

### Lowering substitution

Different MLIR/lowering paths may preserve the same semantic observation.

### Reference Executor

Reference Executor agreement should be treated as evidence of conformance to the semantic contract, not as the source of the contract.

---

# 14. Composition

Investigate whether transitions compose naturally.

Given:

$$
\delta_1:S\leadsto S'
$$

and:

$$
\delta_2:S'\leadsto S''
$$

test whether:

$$
\delta_2\circ\delta_1:S\leadsto S''
$$

can be derived without introducing an execution-graph ontology.

Test at least:

1. sequential composition
2. conditional composition
3. independent composition
4. conflicting composition
5. composition with failure
6. composition with nondeterministic outcomes
7. composition across semantic contexts

Determine which composition laws are valid and which require explicit conditions.

---

# 15. Semantic independence and concurrency

This is critical.

Define and test a concept analogous to:

$$
\delta_1\perp_C\delta_2
$$

where the meaning is semantic independence, not physical parallelism.

For example:

```text
δ1 modifies X
δ2 modifies Y
```

may be semantically independent.

Whereas:

```text
δ1 modifies X
δ2 observes X
```

may not be independent.

Test:

```text
sequential execution
```

against:

```text
parallel execution
```

and determine whether both may produce equivalent semantic observations.

The key invariant is:

> Semantic concurrency is not physical parallelism.

Do not introduce:

* threads
* worker pools
* schedulers
* queues
* CPU affinity
* process identifiers

into SMM/STC merely to formalise concurrency.

---

# 16. Temporal semantics

Investigate whether temporal relationships can remain semantic relations.

At minimum consider:

```text
before
after
during
overlaps
precedes
depends-on
```

Determine which are actually semantic and which belong to physical execution.

The distinction must remain explicit:

```text
semantic ordering
≠
scheduler ordering
```

A scheduler may realise a semantic order, but scheduler behaviour is not automatically part of semantic meaning.

---

# 17. Causal semantics

Investigate:

```text
causes
depends-on
enables
prevents
conflicts-with
```

Determine whether causal relationships can be represented as semantic relations over states, transformations, transitions, or observations.

Do not introduce an event-processing architecture to solve this.

---

# 18. Persistence, migration, propagation and replication

Investigate these as semantic transformations/capabilities.

Do not prematurely define them as machine subsystems.

Examples:

```text
persistence
migration
propagation
replication
materialisation
dematerialisation
copy
partition
merge
split
```

The existing `905_Transforms` area is particularly relevant.

Determine whether these can be modelled as transformations with semantic effects.

For example:

$$
Persist:S\rightarrow S'
$$

need not imply:

```text
write to filesystem
write to database
serialize object
flush buffer
```

Those are physical manifestations.

Likewise:

```text
migration
```

must not automatically mean:

```text
move process from machine A to machine B
```

unless the semantic identity of the computation explicitly includes such a distinction.

---

# 19. Representation versus ontology

Maintain this distinction throughout the implementation.

The following are representations or implementation mechanisms unless formally demonstrated otherwise:

```text
struct
class
object
pointer
memory address
buffer
tensor
SSA value
MLIR operation
LLVM instruction
machine instruction
process
thread
queue
socket
database row
file
container
Kubernetes pod
CPU
GPU
network
message
```

Do not promote any of these into SMM merely because the current implementation uses them.

Conversely, do not prohibit a physical mechanism from being semantically modelled when a domain explicitly makes it observable.

The correct principle is:

> A physical distinction becomes semantic only when it is part of the semantic contract or affects semantically observable behaviour.

---

# 20. Reference Executor relationship

The repository already contains a Reference Executor and reports successful differential execution.

Do not discard this work.

Instead, establish its correct architectural position:

```text
Semantic specification
        ↓
STC
        ↓
Reference Executor
        ↓
semantic observations
        ↓
equivalence
```

The Reference Executor is:

> a canonical executable witness/oracle for the semantic model.

It is not:

* the definition of semantics
* the Semantic Machine itself
* the EGS
* the physical runtime architecture

Use the Reference Executor wherever practical to construct executable witnesses for STC properties.

But do not use existing Reference Executor behaviour as proof that the underlying ontology is correct.

The semantic specification remains authoritative.

---

# 21. Lean implementation strategy

Use Lean 4 and the existing `SCRFormal` project.

First understand:

```text
SCRFormal.lean
lakefile.toml / lakefile.lean
lean-toolchain
SCRFormal/SCR/*.lean
```

Do not replace the existing formal model.

Do not rewrite the formal model merely to make STC easier.

Prefer:

```text
existing ontology
       ↓
STC relations/definitions
       ↓
STC laws
       ↓
STC counterexamples/tests
```

rather than:

```text
new STC ontology
       ↓
duplicate existing ontology
```

Use the smallest definitions capable of expressing the semantics.

Where a concept can be a relation or predicate rather than a new structure, prefer the relation/predicate.

Where a concept can be derived, derive it.

Where a type is necessary, prove why.

---

# 22. Required formal artefacts

Create a coherent STC formalisation within the existing formal architecture.

Do not assume exact filenames in advance if the repository's current structure suggests a better location, but preserve architectural naming consistency.

Potentially appropriate artefacts include:

```text
SCRFormal/SCR/STC.lean
SCRFormal/SCR/STCLaws.lean
SCRFormal/SCR/STCExamples.lean
SCRFormal/SCR/STCCounterexamples.lean
```

However:

> These are suggestions, not instructions to create files mechanically.

If the existing ontology provides a better location, use it.

Do not create files merely to satisfy this list.

---

# 23. Required proofs/invariants

At minimum attempt to establish formal statements for:

### Applicability/admissibility

$$
Admissible(\tau,S,C,K)
\Rightarrow
Applicable(\tau,S,C)
$$

if this implication survives analysis.

### Transition validity

A valid transition must preserve whatever state invariants are semantically required.

### Observation

Observation must be defined independently of physical representation.

### Equivalence

Equivalent realizations must produce equivalent semantic observations.

### Composition

Where composition is permitted, the composed transition must preserve the relevant semantic invariants.

### Independence

Where transitions are semantically independent, permissible ordering should not change the semantic observation, subject to formally identified assumptions.

### Representation independence

Changing representation without changing semantics must preserve semantic observation.

### Provider independence

Replacing a provider with another conforming provider must preserve semantic meaning.

Do not manufacture proofs by weakening definitions until the theorem becomes trivial.

A theorem is useful only if its assumptions correspond to genuine semantic conditions.

---

# 24. Counterexample programme

This is one of the most important deliverables.

For every proposed primitive, construct at least one attempt to show it is unnecessary.

For every proposed omission, construct at least one attempt to show why it may be necessary.

Explicitly investigate counterexamples for:

1. state without context
2. context without state change
3. transformation without transition
4. transition without explicit outcome
5. outcome without execution
6. deterministic versus nondeterministic transition
7. semantic failure versus realization failure
8. semantic order versus scheduler order
9. semantic concurrency versus physical parallelism
10. provider substitution
11. representation substitution
12. observation equivalence
13. persistence
14. migration
15. replication
16. causal dependency
17. temporal dependency
18. partial execution
19. failed execution
20. external capability dependence

The purpose is not to generate arbitrary edge cases.

The purpose is to discover whether the ontology has missing distinctions.

---

# 25. Existing library integration

Before modifying Core, inspect how STC relates to the existing library.

Particularly investigate:

## `101_Core`

Existing Core already contains concepts related to:

* identity
* type
* value
* entity
* attribute
* relationship
* role
* hypergraph
* region
* reference
* representation
* pattern
* transformation
* operation
* state
* transition
* delta
* event
* stream
* temporal semantics
* causal semantics
* provenance
* constraints
* capabilities
* contracts
* equivalence
* queries
* observations
* resources
* errors

Determine whether STC is a calculus **over this vocabulary**.

## `203_Graph`

Determine whether executable graph semantics can later be expressed through existing hypergraph/graph structures without making graph representation part of STC itself.

## `301_Field`

Determine whether the Semantic Field already supplies sufficient structure for state/context/domain semantics.

## `303_Topology`

Determine whether semantic connectivity and independence can be expressed through existing topology.

## `801_Spatial`

Determine whether spatial/region semantics are already sufficient for context/locality without introducing runtime-location semantics.

## `902_Interfaces`

Inspect existing interfaces such as:

```text
Observable
Stateful
Stateless
Deterministic
Stochastic
Parallelizable
Persistable
Distributable
Composable
Dynamical
Streamable
```

Do not create duplicate STC interfaces.

Determine whether these are semantic capabilities, properties, or implementation contracts.

## `903_Lowering`

Ensure the formal STC remains upstream of MLIR lowering.

## `904_Providers`

Maintain the principle:

```text
semantic definition
    ↓
interface
    ↓
capability
    ↓
provider
    ↓
implementation
    ↓
execution substrate
```

Provider selection is not part of SMM semantics.

## `905_Transforms`

Use the existing transformation taxonomy when investigating:

* propagation
* migration
* copy
* replication
* partition
* merge
* split
* materialisation
* dematerialisation
* lowering

---

# 26. Do not prematurely implement EGS

The SCR Executable Graph Server is a later architectural layer.

Its eventual role is approximately:

> The operational execution environment that hosts executable semantic hypergraphs, establishes execution contexts, resolves semantic capabilities, and provides physical mechanisms through which graph execution occurs.

But STC must be defined before EGS.

Do NOT implement:

```text
EGS
scheduler
worker system
provider registry
distributed executor
network executor
storage executor
execution queue
graph server
```

during STC-001.

If your formalisation appears to require one of these, stop and determine whether you have accidentally allowed implementation concerns into the semantic model.

---

# 27. Executable Semantic Hypergraph boundary

The eventual executable semantic hypergraph should express requirements in semantic terms.

It must NOT directly identify:

* physical providers
* machines
* processes
* CPUs
* GPUs
* storage systems
* network endpoints
* Kubernetes objects
* implementation classes

Provider selection and manifestation occur later.

The invariant to preserve is:

> Replacing a physical provider with another provider satisfying the same semantic capability MUST NOT require modification of the semantic hypergraph.

STC-001 should establish the semantic foundations required for this invariant but should not implement the executable graph server.

---

# 28. Control plane boundary

Do not accidentally incorporate the SCR control plane into SMM.

The control plane is exogenous/meta-systemic.

It manages the system that manifests a Semantic Field.

Rendering, where semantically part of the field, is endogenous.

Therefore:

```text
Control plane
    ≠
Semantic Machine
```

and:

```text
control-plane scheduling
    ≠
semantic ordering
```

Do not introduce AMQP/HyrxMQ or networking architecture into STC-001.

---

# 29. Mojo boundary

Mojo remains the preferred implementation language for SCR implementation.

But this increment is primarily formal.

Do not add Mojo types merely because Lean now contains an STC concept.

The correct order is:

```text
semantic definition
    ↓
formalisation
    ↓
laws/invariants
    ↓
executable witness
    ↓
Mojo implementation if justified
```

not:

```text
Mojo type
    ↓
retrofit semantics
```

If a Mojo change is genuinely required to demonstrate an STC property, make the smallest possible change and explain why.

---

# 30. MLIR boundary

MLIR is a representation/lowering substrate.

It is not the semantic authority.

Do not define STC semantics in terms of:

* SSA
* MLIR regions
* MLIR operations
* memrefs
* tensors
* LLVM
* machine instructions

The desired relationship remains:

```text
Semantic meaning
      ↓
semantic representation
      ↓
MLIR
      ↓
lowering
      ↓
physical execution
```

STC must remain meaningful even if the implementation representation changes.

---

# 31. Testing strategy

Run the complete existing formal test/build suite before modification.

Record the baseline.

Then implement STC incrementally.

After every meaningful change:

```bash
lake build SCRFormal
```

Run the existing relevant tests.

Do not allow unrelated regressions.

If the existing repository uses additional prescribed validation commands, discover them from:

```text
AGENTS.md
README.md
program_increments/
docs/
```

and use them.

The final implementation must leave all previously passing validation intact unless a failure is directly caused by an explicitly justified semantic correction.

---

# 32. No fake proofs

Do not weaken definitions to force theorem proving.

Do not introduce vacuous propositions.

Do not prove:

```text
P → P
```

and present that as evidence of semantic correctness.

Do not encode the conclusion into the definition.

Do not hide implementation assumptions inside opaque predicates.

When a theorem is difficult, investigate whether the semantic model is underspecified.

Formal difficulty is evidence worth analysing.

---

# 33. No semantic laundering

Do not rename implementation concepts to make them appear semantic.

Examples of prohibited laundering:

```text
scheduler → Semantic Scheduler
thread → Semantic Agent
queue → Semantic Stream
database → Semantic State Store
process → Semantic Execution Context
container → Semantic Region
message → Semantic Event
CPU → Semantic Resource
```

A semantic term must have a semantic definition independent of the physical implementation.

---

# 34. Distinguish four categories in all analysis

For every important statement, explicitly classify it as one of:

```text
FACT
INFERENCE
DEFINITION
CONJECTURE
```

Where useful also distinguish:

```text
DERIVED
PRIMITIVE
REPRESENTATIONAL
IMPLEMENTATIONAL
```

Do not blur these categories.

Especially distinguish:

```text
"SCR currently implements X"
```

from:

```text
"SCR semantically requires X"
```

These are not equivalent propositions.

---

# 35. Formalisation versus ontology modification

Use this decision procedure whenever you believe the model is missing something:

```text
1. Identify the missing distinction.
2. Produce a concrete semantic scenario.
3. Show why existing ontology cannot represent it.
4. Attempt to derive it from existing concepts.
5. Attempt to encode it as a relation/predicate.
6. Attempt to encode it as a refinement of an existing type.
7. Only if all fail, propose a new primitive.
8. State the invariant that requires the new primitive.
9. Provide at least one counterexample demonstrating why omission is unsound.
10. Update the authoritative semantic documentation only after the formal argument is established.
```

This is mandatory.

---

# 36. Documentation updates

Do not rewrite the documentation wholesale.

Update documentation only where the formal investigation establishes something substantive.

Potential outputs include:

```text
STC formal specification
STC formal crosswalk
formal gap analysis
semantic decisions
counterexample catalogue
invariant catalogue
conformance notes
```

Any semantic correction must propagate consistently through the documentation hierarchy.

Respect the existing documentation rule:

> Lower-level documentation MUST NOT silently redefine higher-level semantics.

If the formal model reveals a contradiction in the current documentation, document the contradiction explicitly and correct the authoritative level first.

---

# 37. Semantic Field consistency check

The current public README presents the Semantic Field as:

$$
\mathcal F=(E,R,T,C,S,K,M)
$$

with \(M\) currently described as physical manifestations.

Do not silently change this merely because STC suggests a different formulation.

However, explicitly test whether this tuple remains architecturally consistent with the newer SMM distinction:

$$
SMM(F)=Formal\ Computational\ Semantics(F)
$$

and:

$$
SMM\neq F+Runtime
$$

If formalisation demonstrates that the current Field tuple conflates semantic structure with manifestation, record that as a semantic/documentation issue.

Do not arbitrarily fix it without analysis.

---

# 38. Required deliverables

When STC-001 is complete, deliver all of the following.

## A. Formal implementation

Working Lean implementation of the minimum STC necessary to express the validated semantic calculus.

## B. Formal crosswalk

A mapping between:

```text
SMM
STC
existing SCR ontology
Lean representation
```

with explicit decisions.

## C. Gap analysis

Every genuine semantic gap discovered.

For each:

```text
gap
why existing ontology is insufficient
counterexample
candidate solutions
selected solution
reason
```

## D. Counterexample report

Document failed assumptions and attempted falsifications.

This is a first-class deliverable.

## E. Formal laws/invariants

List and prove whatever laws survive the analysis.

Clearly identify:

```text
proven
assumed
conjectured
unprovable without additional assumptions
```

## F. Existing implementation compatibility

Demonstrate how the current Reference Executor relates to the formal STC.

Where possible, construct executable witnesses.

## G. Regression status

Provide exact validation results for:

```text
Lean
existing tests
Reference Executor
relevant Mojo tests
relevant differential execution
```

## H. Semantic changes

If the formalisation requires changes to authoritative semantic documentation or existing Lean definitions, provide a precise change log explaining why.

---

# 39. Required final report structure

At completion, produce a report with exactly this conceptual structure:

```text
# STC-001 Completion Report

## 1. Executive Result
Did STC survive formalisation?
What was falsified?
What remains uncertain?

## 2. Baseline
Existing formal model and tests before changes.

## 3. SMM → STC Crosswalk
Full mapping.

## 4. Existing Ontology Reuse
What was reused and why.

## 5. Genuine Semantic Gaps
Only actual gaps.

## 6. Counterexamples
Cases that forced changes or rejected assumptions.

## 7. STC Formal Model
Definitions and relationships.

## 8. Proven Laws
Formal theorems and invariants.

## 9. Unresolved Questions
Anything not yet justified.

## 10. Reference Executor
How executable evidence relates to STC.

## 11. Representation Independence
Evidence regarding Mojo/MLIR/provider substitution.

## 12. Concurrency / Temporal / Causal Semantics
Formal results.

## 13. Failure and Outcome Semantics
Formal results.

## 14. Documentation Changes
Exact files changed and why.

## 15. Validation
Exact commands and results.

## 16. Architectural Consequences
What STC establishes for future EGS/graph/provider work.

## 17. Recommended Next Increment
Only after the evidence is presented.
```

---

# 40. Definition of success

STC-001 is successful if it achieves one of the following outcomes:

### Outcome A — Model survives

The existing semantic architecture can express STC with minimal additions.

Then formalise it and prove its fundamental laws.

### Outcome B — Model requires refinement

Formalisation exposes genuine missing distinctions.

Then identify them through counterexamples and introduce the minimum necessary semantic refinements.

### Outcome C — Model is partially unsound

Formalisation reveals that an existing architectural assumption is incorrect.

Then stop and report the contradiction rather than building on it.

**All three outcomes are valid.**

A successful falsification is more valuable than an artificial green build.

---

# 41. What NOT to do

Do not:

* build EGS
* build an execution scheduler
* build distributed execution
* build provider infrastructure
* build storage infrastructure
* build communication infrastructure
* introduce AMQP
* introduce HyrxMQ
* introduce Kubernetes concepts
* add CPUs/GPUs as semantic primitives
* create a semantic VM implementation
* create an STC-specific parallel runtime
* create duplicate state/transition/transformation types
* create a second graph ontology
* create a second equivalence system
* create types merely because an English term appears in SMM
* redesign the Mojo kernel
* redesign MLIR lowering
* rewrite the Reference Executor
* replace existing Lean foundations
* weaken definitions to make proofs trivial
* treat implementation behaviour as semantic truth
* treat the Reference Executor as the semantic specification
* treat MLIR as semantic authority
* assume deterministic execution
* assume physical ordering is semantic ordering
* assume semantic concurrency means physical parallelism
* assume persistence means filesystem/database storage
* assume migration means process movement
* assume propagation means networking
* assume replication means distributed storage

---

# 42. Governing development loop

The entire increment must follow:

$$
\boxed{
Specification
\rightarrow
Formalisation
\rightarrow
Counterexample
\rightarrow
Semantic\ refinement
\rightarrow
Proof
\rightarrow
Executable\ witness
}
$$

Not:

$$
Specification
\rightarrow
Guess\ abstractions
\rightarrow
Implement
\rightarrow
Make\ tests\ green
$$

The latter is explicitly prohibited for this increment.

---

# 43. Architectural trajectory after STC-001

Do not implement these now.

The intended sequence after this work is:

```text
CURRENT
Semantic Machine Model documentation
        ↓
STC-001
Formal Semantic Transition Calculus
        ↓
counterexample/falsification
        ↓
minimal semantic refinement
        ↓
STC-002
Formal laws + invariants
        ↓
Reference Executor semantic conformance
        ↓
Executable semantic hypergraph
        ↓
EGS
        ↓
capability resolution
        ↓
provider manifestation
        ↓
physical execution
```

Only proceed to the next layer when the current layer has a defensible semantic contract.

---

# 44. Final instruction

Do not optimise for the appearance of progress.

Optimise for semantic truth.

If the current model is wrong, demonstrate why.

If it is incomplete, demonstrate the missing distinction.

If it is sufficient, prove that it is sufficient.

If an existing SCR abstraction already expresses a proposed STC concept, **reuse it**.

If a new abstraction is genuinely necessary, justify it with a counterexample and an invariant.

The central question for this entire increment is:

$$
\boxed{
Can\ SCR\ define\ computation\ independently\ of\ its\ physical\ manifestation?
}
$$

And the operational question is:

$$
\boxed{
Can\ the\ Semantic\ Machine\ be\ formalised\ as\ lawful\ semantic\ transitions\ without\ importing\ a\ conventional\ runtime\ ontology?
}
$$

Do not assume the answer.

**Find out.**
