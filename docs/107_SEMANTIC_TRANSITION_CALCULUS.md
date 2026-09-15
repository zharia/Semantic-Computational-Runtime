# Semantic Transition Calculus (STC)

**Document ID:** SCR-DOC-STC-107
**Status:** Normative architectural specification
**Version:** 0.2.0
**Purpose:** Formal semantic calculus for the Semantic Machine Model.

---

## 1. Purpose

The Semantic Transition Calculus (STC) defines the formal semantics of change within the Semantic Machine Model (SMM).

STC specifies how semantic structures may change, under what conditions a transformation is applicable and admissible, what semantic consequences may result, how transitions compose, how semantic dependence and independence are represented, and how observations and equivalence determine conformance.

STC is a **semantic calculus**, not a runtime architecture.

It does not define:

* processors;
* threads;
* schedulers;
* storage engines;
* message brokers;
* providers;
* devices;
* operating systems;
* physical memory;
* physical network topology;
* EGS implementation structure.

Those mechanisms may realize STC semantics, but they do not define them.

The central architectural principle is:

> **The Semantic Machine defines what computation means. STC defines how semantic computation changes. Realizations determine how those changes are physically manifested.**

---

# 2. Relationship to the Semantic Machine Model

The Semantic Machine Model establishes the semantic machine independently of any particular implementation.

STC is the transition calculus consumed by that model.

The relationship is:

```text
Semantic Field
      │
      ▼
Semantic Machine Model
      │
      ├── State
      ├── Context
      ├── Transformation
      ├── Constraints
      │
      ▼
Semantic Transition Calculus
      │
      ├── applicability
      ├── consent/admissibility
      ├── semantic edges
      ├── consequences
      ├── composition
      ├── independence/conflict
      ├── causality
      ├── observation
      └── equivalence
      │
      ▼
Executable Semantic Hypergraph
      │
      ▼
EGS / Reference Executor / Other Realizations
      │
      ▼
Providers
      │
      ▼
Physical Resources
```

STC therefore defines semantic relations between structures rather than physical execution sequences.

---

# 3. Adopted STC Kernel

The original STC-001 hypothesis was:

$$
STC=\langle S,C,T,K,O,\equiv\rangle
$$

where:

* \(S\) = semantic states;
* \(C\) = semantic contexts;
* \(T\) = transformations;
* \(K\) = constraints;
* \(O\) = outcomes;
* \(\equiv\) = semantic equivalence.

This tuple was useful as a falsification scaffold but is **not the adopted STC kernel**.

STC-002 demonstrated that outcome and successor state need not be independent transition carriers. They are projections of a richer typed semantic consequence.

The adopted transition carrier is instead a **typed, labelled relational edge**.

Conceptually:

$$
\boxed{
edge(\tau,K,S,C,o)
}
$$

where:

* \(\tau\) is the transformation;
* \(K\) is the constraint environment;
* \(S\) is the input semantic state;
* \(C\) is the semantic context;
* \(o\) is a typed semantic consequence.

The consequence domain is transformation-specific:

$$
Out : T \rightarrow Type
$$

and the semantic transition relation is:

$$
edge :
\forall \tau,K,S,C,\;
Out(\tau)\rightarrow Prop
$$

Thus the kernel is a **graph-relational machine**, not an outcome function.

---

# 4. Why the Graph-Relational Carrier Is Necessary

A semantic transition cannot in general be represented adequately by:

```text
State → Outcome
```

or:

```text
State → State
```

or:

```text
Input × Output
```

without transformation identity and consequence typing.

Machine-checked counterexamples established:

1. identical emitted values may produce different successor states;
2. equivalent outcomes may produce distinguishable successor states;
3. distinguishable outcomes may produce equivalent successor states;
4. different transformations may have identical endpoints;
5. nondeterministic transformations may produce multiple successors;
6. failure may produce a meaningful successor;
7. admissible transitions may have no resulting consequence;
8. edge identity and provenance may remain observable even where endpoints are identical.

Therefore:

$$
R_\tau \subseteq I_\tau \times O_\tau
$$

is closer to the correct abstraction than a functional transition.

However, an unlabelled relation is insufficient.

The transformation label and consequence type are semantically relevant.

Therefore the adopted abstraction is:

$$
\boxed{
S \xrightarrow[\;K,C\;]{\tau} o
}
$$

with the edge itself constituting the semantic transition.

---

# 5. Semantic State

A semantic state \(S\) is a representation of the semantic structure relevant to computation at a particular point.

STC does not require a semantic state to be:

* a memory image;
* a process;
* a file;
* a database;
* a tensor;
* a graph;
* a machine register set.

Those may represent or contain semantic state.

A semantic state may itself contain structured semantic entities and relationships.

In particular, executable semantic hypergraphs may occur within semantic state.

The STC kernel therefore treats \(S\) abstractly.

The authoritative distinction is:

$$
SemanticState \neq RepresentationState
$$

A representation may change while semantic state remains equivalent.

---

# 6. Semantic Context

A context \(C\) supplies semantic conditions under which a transformation is interpreted.

Context may include:

* semantic environment;
* authority;
* identity;
* temporal conditions;
* spatial conditions;
* partition membership;
* locality;
* available capabilities;
* declared constraints;
* observation conditions;
* semantic scope.

Context is not equivalent to implementation state.

A physical runtime environment may contain information that has no semantic significance.

Only information elevated into the semantic field contributes to STC meaning.

Thus:

$$
PhysicalContext \neq SemanticContext
$$

unless the relevant physical property has explicitly become semantically observable or constraining.

---

# 7. Transformation

A transformation \(\tau\) identifies a semantic operation capable of producing a change or consequence.

A transformation is not:

* a CPU instruction;
* a function call;
* a thread;
* a message;
* a kernel syscall;
* an MLIR operation;
* a provider invocation.

Those may be realizations of a transformation.

The transformation itself belongs to the semantic domain.

A transformation may be:

* deterministic;
* nondeterministic;
* partial;
* state-preserving;
* state-changing;
* failure-producing;
* branching;
* conditional;
* composable;
* concurrent;
* spatial;
* temporal.

---

# 8. Applicability

Applicability asks whether a transformation is defined for a given semantic state and context.

$$
S,C\vdash\tau\;applicable
$$

Applicability is a domain property.

It does not mean:

* the transformation has been authorised;
* the transformation has been consented to;
* a provider exists;
* physical resources are available;
* execution will succeed.

A transformation may therefore be applicable but inadmissible.

---

# 9. Consent and Admissibility

STC retains the distinction between applicability and consent.

Let:

$$
Consents(\tau,S,C,K)
$$

express semantic consent under the constraint environment \(K\).

Then:

$$
Admissible(\tau,S,C,K)
\iff
Applicable(\tau,S,C)
\land
Consents(\tau,S,C,K)
$$

The important invariant is:

$$
Admissible \Rightarrow Applicable
$$

but not:

$$
Applicable \Rightarrow Admissible
$$

This distinction is essential.

A transformation may be semantically meaningful but prohibited.

A prohibited transformation is not equivalent to a nonexistent transition.

Therefore **rejection is not represented merely by the absence of an edge**.

---

# 10. Semantic Edge

For an admissible transformation, the semantic machine admits consequences through the edge relation:

$$
edge(\tau,K,S,C,o)
$$

or equivalently:

$$
S \xrightarrow[\;C,K\;]{\tau} o
$$

The edge is the fundamental semantic transition carrier.

The edge may contain or determine:

* resulting semantic state;
* semantic outcome;
* failure status;
* delta;
* identity effects;
* provenance;
* successor relationships;
* observation-relevant properties.

These are consequences or projections of the edge rather than independent transition carriers.

---

# 11. Typed Consequences

Every transformation has a consequence domain:

$$
Out:T\rightarrow Type
$$

Therefore:

$$
o\in Out(\tau)
$$

The consequence type may distinguish transformations whose input and output states are otherwise identical.

This is necessary because:

$$
\tau_1\neq\tau_2
$$

may hold even when:

$$
S_0=S_1
$$

and:

$$
S'_0=S'_1
$$

The semantic transformation itself may be observable or relevant to provenance.

An untyped graph relation:

$$
R\subseteq S\times S
$$

is therefore insufficient as the complete STC representation.

---

# 12. Consequence Structure

A semantic consequence may expose several projections.

Conceptually:

```text
Consequence
 ├── value/outcome
 ├── successor state relation
 ├── status
 ├── delta
 ├── identity effects
 ├── provenance
 └── observation-relevant metadata
```

These projections are not automatically independent semantic primitives.

The calculus must prefer derivation over duplication.

In particular:

```text
OutcomeOf        → projection
ResultState      → projection
Delta            → consequence/span-derived semantic structure
Provenance       → path/edge derivation
Observation      → derived relation
```

unless a counterexample demonstrates that a proposed primitive is irreducible.

---

# 13. Successor State

A consequence may contain a relation to successor semantic states.

Conceptually:

$$
succRel(o,S,S')
$$

or:

$$
S \xrightarrow{\tau,o} S'
$$

The successor relation is **relational**, not necessarily functional.

Thus:

$$
S \leadsto \{S_1,S_2,\ldots\}
$$

is permitted.

A transformation may therefore be nondeterministic.

The calculus must not impose:

$$
Out(\tau)\rightarrow Option(S)
$$

as a universal successor representation.

---

# 14. Semantic Delta

A semantic delta describes the semantic change represented by a transition.

Where applicable:

$$
S_1 = S_0 \oplus \Delta
$$

The delta is associated with the consequence.

The graph carrier exposes the endpoint span of the transition, but endpoint span and semantic delta are not identical.

Two transitions may share:

$$
S_0\rightarrow S_1
$$

while carrying different semantic deltas.

Therefore:

$$
Span(\delta)\neq Delta(\delta)
$$

in general.

The delta remains semantic content of the consequence rather than an additional transition carrier.

---

# 15. Outcomes

An outcome is a semantic projection of a consequence.

Possible semantic outcome classes include:

```text
Success
Failure
Partial
Indeterminate
Rejected
```

These labels are descriptive semantic classifications, not necessarily the final Lean datatype.

The crucial distinction is:

### Rejection

The transformation is not admitted.

### Failure

The transformation is admitted and produces a failure consequence.

### Partiality

The transformation is admissible but its consequence is incomplete or unavailable under the semantic model.

### Indeterminate

The semantic model permits uncertainty or unresolved outcome.

### Success

The consequence satisfies the relevant success conditions.

These distinctions must not be collapsed into:

```text
edge exists = success
edge absent = failure
```

---

# 16. Rejection Is Not Missing Edge

A transformation may satisfy:

$$
Applicable(\tau,S,C)
$$

while failing:

$$
Consents(\tau,S,C,K)
$$

Therefore:

$$
\neg Admissible(\tau,S,C,K)
$$

does not imply:

$$
\neg Applicable(\tau,S,C)
$$

Nor does it imply that the transformation is semantically meaningless.

The calculus therefore distinguishes:

```text
not applicable
      ≠
applicable but rejected
      ≠
admissible but partial
      ≠
admissible and failed
```

This distinction is normative.

---

# 17. Nondeterminism

Nondeterminism is naturally represented by multiple valid consequences from the same transition context.

$$
edge(\tau,K,S,C,o_1)
$$

and:

$$
edge(\tau,K,S,C,o_2)
$$

may both hold where:

$$
o_1\not\equiv_C o_2
$$

Nondeterminism is therefore not an implementation accident.

A physical implementation may choose among valid realizations only when the semantic model permits such choice.

Where the field constrains the outcome distribution, stochastic semantics may additionally be defined.

Probability is semantic only when probability itself is semantically observable or constrained.

---

# 18. Determinism

There is no single universal notion of determinism.

At minimum distinguish:

1. value determinism;
2. successor determinism;
3. consequence determinism;
4. transition-result determinism;
5. observational determinism.

A transition may be deterministic under one projection while nondeterministic under another.

For example:

```text
same outcome
different successor
```

is outcome-deterministic but successor-nondeterministic.

Therefore the calculus must state **determinism relative to an observation/projection**.

---

# 19. Composition

Semantic transitions compose through their consequences and successor relations.

Given:

$$
S_0\xrightarrow{\tau_1}o_1
$$

and a successor:

$$
S_1\in Succ(o_1)
$$

followed by:

$$
S_1\xrightarrow{\tau_2}o_2
$$

the composed transition is represented by relational composition.

For relations:

$$
R\subseteq X\times Y
$$

and:

$$
Q\subseteq Y\times Z
$$

their composition is:

$$
Q\circ R
=
\{(x,z)\mid
\exists y:
(x,y)\in R
\land
(y,z)\in Q
\}
$$

This is the semantic basis of transition composition.

---

# 20. Associativity

Relational composition is associative:

$$
R_3\circ(R_2\circ R_1)
=
(R_3\circ R_2)\circ R_1
$$

Therefore STC does not need a separately postulated associativity law merely to make graph composition work.

Associativity is structural.

This is preferable to encoding associativity as an additional primitive law where the carrier already guarantees it.

The semantic interpretation of the composed transition must nevertheless preserve:

* transformation identity;
* consequence typing;
* provenance;
* context;
* constraints;
* observation;
* identity obligations.

---

# 21. Conditional Composition

A transformation may select subsequent transitions based on its consequence.

Conceptually:

$$
\tau_1;
\begin{cases}
\tau_2 & P(o_1)\\
\tau_3 & \neg P(o_1)
\end{cases}
$$

This is semantic branching.

It is not inherently:

* an `if` instruction;
* a CPU branch;
* a control-flow block;
* a scheduler decision.

Those are possible manifestations.

Conditional composition belongs to the semantic graph.

---

# 22. Independence

Independence is a semantic relation.

$$
\delta_1\perp_C\delta_2
$$

means that the transitions can be reordered or composed without producing a semantically distinguishable result under the relevant conditions.

Independence must not be inferred from:

* different CPUs;
* different threads;
* different machines;
* different GPUs;
* different memory regions;
* different providers.

Physical separation is not semantic independence.

Conversely, physically co-located operations may be semantically independent.

---

# 23. Footprints and Interference

STC retains `Footprint` and `Overlap`, but their interpretation is narrower than in STC-001.

A footprint describes semantic interference-relevant structure.

It may include:

* semantic reads;
* semantic writes;
* influence;
* observation;
* mutation;
* dependency;
* resource-like semantic domains where explicitly elevated into meaning.

Conceptually:

$$
Footprint(\delta)
$$

and:

$$
Overlap(\delta_1,\delta_2)
$$

are used to establish interference conditions.

They do **not** define causality by themselves.

The distinction is:

```text
footprint
    ↓
possible interference
    ↓
conflict / enablement
    ↓
causal dependence
```

rather than:

```text
overlap
    =
causality
```

---

# 24. Conflict

Two semantic transitions conflict when their interaction creates a semantic requirement that cannot be ignored.

Conflict may arise from:

* incompatible writes;
* incompatible transformations;
* ordering-sensitive state mutation;
* mutually exclusive consequences;
* semantic resource contention;
* other field-defined interference.

Conflict is distinct from mere physical contention.

A physical resource may be shared without the computation being semantically conflicting.

---

# 25. Enablement

A transition may semantically enable another transition.

Conceptually:

$$
Enable(\delta_1,\delta_2)
$$

means that the existence or validity of the second transition depends on a semantic consequence of the first.

Enablement may exist even when the two transitions are not order-sensitive in a simplistic operational sense.

It is therefore a distinct causal relation.

---

# 26. Causality

STC-002 rejects the earlier hypothesis:

$$
CausalDependency
:=
\neg Independent
$$

This conflated semantic independence with causal dependence.

The adopted causal relation is:

$$
\boxed{
CausalDependency
=
Enablement
\cup
Conflict
}
$$

Thus:

$$
\delta_1 \prec_C \delta_2
$$

when \(\delta_1\) semantically enables or conflicts with \(\delta_2\), according to the machine's causal relation.

Successor order-sensitivity is an observational **shadow** of causality, not its definition.

This distinction is important because order-sensitive behaviour may fail to expose the complete causal structure.

---

# 27. Causality Is Not Physical Ordering

Semantic causality must not be identified with:

* wall-clock order;
* CPU instruction order;
* message delivery order;
* thread scheduling;
* network topology;
* process placement.

A semantic cause may be physically computed later.

A semantic consequence may be physically materialized before another event that is semantically prior.

Therefore:

$$
PhysicalOrder \neq SemanticCausality
$$

unless the physical order has explicitly been made semantically observable.

---

# 28. Temporal Ordering

Temporal relations are distinct from causality.

STC may represent relations such as:

* before;
* after;
* simultaneous;
* during;
* duration;
* deadline;
* periodicity;
* temporal window.

Temporal order may exist without causal dependence.

Conversely, semantic causal dependence may exist without meaningful wall-clock ordering.

Therefore:

$$
TemporalOrder \neq CausalDependency
$$

Physical wall-clock time enters semantic equivalence only when the field makes it observable or constraining.

---

# 29. Concurrency

Concurrency is a semantic property of transition relationships, not a promise of physical parallel execution.

If:

$$
\delta_1\perp_C\delta_2
$$

then the semantic model may permit unordered composition.

A realization may nevertheless execute the transitions:

* sequentially;
* concurrently;
* distributed;
* speculatively;
* fused;
* cached;
* replicated.

All are conforming when their observations remain semantically equivalent.

---

# 30. Atomicity

Atomicity is defined by semantic observation boundaries.

$$
Atomic(\delta,C)
$$

means that prohibited intermediate semantic states are not observable under context \(C\).

Atomicity therefore does not require:

* a CPU atomic instruction;
* a mutex;
* a transaction engine;
* a lock;
* a single physical execution step.

An implementation may use any mechanism capable of preserving the semantic atomicity contract.

---

# 31. Identity Effects

A semantic transition may:

* preserve identity;
* refine identity;
* replace identity;
* split identity;
* merge identities;
* create identity;
* destroy identity.

Identity obligations are semantic.

Physical operations do not determine identity automatically.

Therefore:

$$
PhysicalCopy \not\Rightarrow NewIdentity
$$

$$
PhysicalMove \not\Rightarrow IdentityChange
$$

$$
RepresentationChange \not\Rightarrow IdentityChange
$$

This includes spatial movement and migration.

A semantic object may move between partitions, machines, providers, or execution spaces without changing identity.

---

# 32. Spatial Transitions

STC consumes the spatial model defined by the Semantic Machine Model and spatial specifications.

STC does not redefine spatial ontology.

The following remain distinct:

$$
Coordinate
\neq
Partition
\neq
State
\neq
ExecutionResource
$$

A transition may therefore involve:

* coordinate transformation;
* partition migration;
* state relocation;
* replication;
* materialisation;
* dematerialisation;
* execution relocation.

These are distinct semantic changes.

A transition moving state from one partition to another does not inherently change semantic identity.

Similarly:

$$
PartitionMigration \neq IdentityTransformation
$$

---

# 33. Spatial Partition Migration

A semantic partition may migrate between execution resources.

Conceptually:

$$
\Pi_i@R_1
\rightarrow
\Pi_i@R_2
$$

while:

$$
Identity(\Pi_i)=constant
$$

Migration therefore changes residency, not necessarily identity.

The calculus must preserve this distinction when spatial transitions are represented.

Partition migration may require preservation of:

* partition identity;
* semantic membership;
* hierarchy;
* state integrity;
* routing obligations;
* consistency;
* provenance.

The physical migration mechanism is outside STC.

---

# 34. State Migration

Semantic state may move between spatial or computational locations.

Conceptually:

$$
S@L_1\rightarrow S@L_2
$$

without requiring:

$$
S_1\neq S_2
$$

as semantic identities.

A realization may:

* copy;
* move;
* replicate;
* reconstruct;
* recompute;
* lazily materialize

the state.

The semantic transition is valid if the resulting observations satisfy the STC contract.

---

# 35. Observation

Observation is context-indexed.

Let:

$$
Obs_C(x)
$$

be the semantic observation of \(x\) under context \(C\).

Observation may inspect:

* state;
* consequence;
* transformation identity;
* path;
* provenance;
* temporal properties;
* spatial properties;
* identity;
* other field-defined semantic properties.

Therefore observation is not limited to final state equality.

Two transitions may produce equivalent states while remaining distinguishable because their transformation or provenance is observable.

---

# 36. Semantic Equivalence

Semantic equivalence is context-indexed:

$$
x\equiv_C y
$$

and is defined through the relevant observation relation.

Conceptually:

$$
Obs_C(x)\equiv Obs_C(y)
\Rightarrow
x\equiv_C y
$$

The exact equivalence relation is determined by the semantic machine.

Equivalence must satisfy the required setoid laws:

* reflexivity;
* symmetry;
* transitivity.

The calculus must additionally establish the congruence properties required by composition.

---

# 37. Consequence Equivalence

STC-002 establishes equivalence over consequences rather than merely emitted values.

A consequence equivalence may distinguish:

```text
value
successor
label
provenance
```

as separate dimensions.

At minimum, successor congruence must hold where successor observations are semantically relevant.

A consequence equivalence that ignores successor structure can incorrectly identify transitions that produce different future computation.

Therefore:

$$
o_1\equiv_C o_2
$$

must imply the required successor congruence obligations.

---

# 38. Path Equivalence

A composed semantic computation forms a path through the transition graph.

A path contains at least:

```text
semantic span
+
transformation labels
```

The span describes behavioural consequence.

The labels preserve semantic transition identity and provenance.

Thus two paths may have:

$$
same\;span
$$

while remaining distinguishable because:

$$
labels_1\neq labels_2
$$

This is necessary for provenance-sensitive semantics.

---

# 39. Provenance

Provenance is derived from semantic edges and paths unless independently elevated into semantic state.

A composed path can preserve:

$$
Provenance(path)
$$

through its edge sequence.

Provenance may become semantically observable when the field requires it.

Otherwise it may remain implementation metadata.

The distinction is:

$$
SemanticProvenance
\neq
ImplementationTrace
$$

A runtime execution log does not automatically become semantic history.

---

# 40. Representation Independence

A representation function may be conceptualized as:

$$
\rho:S\rightarrow R
$$

where \(R\) is a representation domain.

Multiple representations may correspond to semantically equivalent structures.

Therefore:

$$
\rho_1(S)\neq\rho_2(S)
$$

does not imply:

$$
S_1\not\equiv S_2
$$

MLIR is a representation and lowering mechanism.

Mojo is an implementation mechanism.

Neither defines STC semantics.

---

# 41. Realization Boundary

STC deliberately separates semantic validity from physical realization.

Let:

$$
Requires(\delta,c)
$$

mean that a transition requires capability \(c\).

Let:

$$
Provides(I,c)
$$

mean that implementation \(I\) provides capability \(c\).

Then:

$$
Valid(\delta)
\not\Rightarrow
Realizable(I,\delta)
$$

and:

$$
Realizable(I,\delta)
\not\Rightarrow
PhysicalSuccess(I,\delta)
$$

A valid semantic transition may have no available implementation.

An implementation may possess the required capability but fail physically.

Neither fact changes the semantic definition of the transition.

---

# 42. Provider Boundary

Providers realize capabilities.

They do not define semantic meaning.

Conceptually:

```text
STC transition
      │
      ▼
semantic capability requirement
      │
      ▼
EGS
      │
      ▼
provider
      │
      ▼
physical mechanism
```

Examples include:

* Chrono;
* CGAL;
* H3;
* OpenVDB;
* Vulkan;
* CUDA;
* BLAS;
* AMQP infrastructure.

The provider may expose additional implementation semantics, but those do not become SCR semantics unless explicitly incorporated into the semantic field.

---

# 43. EGS Boundary

The Executable Graph Server (EGS) realizes executable semantic hypergraphs.

From STC's perspective, EGS is a realization mechanism.

EGS may:

* instantiate execution contexts;
* resolve capabilities;
* select providers;
* manage execution;
* route semantic messages;
* establish resource mappings;
* manifest semantic graphs.

STC does not depend on EGS.

An STC-conforming realization may exist without the production EGS implementation.

---

# 44. Reference Executor

The Reference Executor is a conforming realization and executable witness.

$$
RE\models SMM
$$

subject to the semantic conformance relation.

The Reference Executor is not ontologically privileged.

Its purpose is to:

* provide executable evidence;
* validate semantic definitions;
* expose counterexamples;
* provide a baseline for other realizations;
* test semantic equivalence.

A behaviour is not correct merely because the Reference Executor produces it.

The executor itself must conform to the calculus.

---

# 45. Conformance

An implementation \(I\) conforms where its observable behaviour is equivalent to the semantic behaviour prescribed by STC.

Conceptually:

$$
I\models_C SMM
$$

when, for every required semantic transition:

$$
Obs_C(I(\delta))
\equiv_C
Obs_C(\delta)
$$

subject to the implementation's declared realization capabilities.

Conformance therefore compares semantic observations rather than implementation representations.

---

# 46. Semantic Failure vs Realization Failure

The calculus makes a strict distinction.

### Semantic failure

The semantic transformation is admitted but its consequence is classified as failure.

### Realization failure

The implementation cannot or does not successfully realize an otherwise valid semantic transition.

For example:

```text
semantic division-by-zero
```

may be a semantic failure.

Whereas:

```text
GPU unavailable
```

is not automatically a semantic failure.

It is a realization problem unless the field explicitly defines GPU availability as semantic state or constraint.

---

# 47. Semantic No-Op

A transition may produce a consequence whose semantic state is equivalent to its input.

$$
S'\equiv_C S
$$

This does not necessarily mean the transition is semantically irrelevant.

The transformation may remain observable through:

* provenance;
* labels;
* counters;
* temporal effects;
* external semantic state;
* identity effects;
* other observations.

Therefore:

$$
NoStateChange \not\Rightarrow NoSemanticEffect
$$

---

# 48. Hypergraph Interpretation

STC is naturally represented as a graph-relational calculus.

A semantic transition can be represented as:

```text
      τ
S ─────────► o
             │
             ├── successor state(s)
             ├── outcome
             ├── delta
             ├── identity effects
             └── provenance
```

For multiple successors:

```text
             ┌──► S₁
             │
S ──τ──────► o
             │
             └──► S₂
```

For semantic hypergraphs, consequences may connect multiple semantic entities and relationships.

STC does not require endpoint states to be simple scalar values.

The endpoints may contain semantic graph structures.

The executable hypergraph model therefore becomes a natural representation of composed STC relations.

---

# 49. STC and Executable Semantic Hypergraphs

An executable semantic hypergraph may be understood as a structured composition of STC edges.

Its nodes represent semantic structures.

Its labelled edges represent transformations.

Its consequences provide successor structure and semantic effects.

This yields:

$$
ExecutableHypergraph
\approx
Composition\;of\;STC\;Relations
$$

The approximation symbol is intentional.

The hypergraph ontology contains additional structural information that belongs to the graph domain rather than to the minimal STC kernel.

---

# 50. Transition Graph Invariants

The following invariants are normative.

### STC-001 — Applicability

A transition cannot be instantiated outside its semantic applicability domain.

### STC-002 — Consent

Applicability does not imply admissibility.

### STC-003 — Typed Consequence

Every semantic edge has a transformation-specific consequence domain.

### STC-004 — Relational Semantics

A transition may have zero, one, or multiple valid consequences.

### STC-005 — No Missing-Edge Failure

Absence of a consequence is not sufficient to classify semantic rejection or failure.

### STC-006 — Transformation Identity

Transformation labels are semantically significant where observed.

### STC-007 — Structural Composition

Semantic composition is relational composition.

### STC-008 — Associativity

Relational composition is associative.

### STC-009 — Contextual Equivalence

Semantic equivalence is context-indexed.

### STC-010 — Successor Congruence

Equivalent consequences must preserve the required equivalence of successor observations.

### STC-011 — Independence

Independence is semantic and cannot be inferred from physical resource separation.

### STC-012 — Conflict

Semantic conflict is distinct from physical contention.

### STC-013 — Causality

Causal dependence is derived from semantic enablement and conflict.

### STC-014 — Temporal Separation

Temporal ordering is distinct from causal dependence.

### STC-015 — Identity Preservation

Physical movement or representation change does not imply semantic identity change.

### STC-016 — Spatial Separation

Coordinate, partition, state, and execution resource remain distinct.

### STC-017 — Representation Independence

Equivalent semantic structures may possess different representations.

### STC-018 — Provider Independence

Provider implementations cannot redefine semantic meaning.

### STC-019 — Realization Separation

Semantic validity is distinct from physical realizability and physical success.

### STC-020 — Observation Authority

Conformance is determined by semantic observation, not representation equality.

### STC-021 — Primitive Elimination

A new kernel primitive requires a semantic distinction that cannot be expressed by the existing calculus.

---

# 51. Anti-Expansion Rule

Do not add an STC primitive merely because an implementation has a component with the same name.

The existence of a:

* scheduler;
* processor;
* thread;
* executor;
* memory manager;
* storage engine;
* message broker;
* namespace;
* process;
* cache;
* device;
* container;
* VM;
* provider

does not establish that the concept belongs in STC.

The required test is:

> **What semantic distinction becomes impossible if this primitive is removed?**

If no minimal counterexample exists, the primitive does not belong in the kernel.

Convenience is not evidence.

---

# 52. Falsification Method

STC development is explicitly falsification-driven.

For every proposed primitive or law:

1. state the hypothesis;
2. construct the smallest semantic counterexample;
3. formalize the premises;
4. determine whether the existing calculus can express the distinction;
5. reject, demote, or retain the proposed construct;
6. record the evidence.

The calculus must not conceal insufficiency by introducing abstractions merely to make proofs convenient.

A failed proof is evidence.

A counterexample is evidence.

An implementation requirement is **not** automatically semantic evidence.

---

# 53. STC-001 Historical Result

STC-001 established the initial tuple-based calculus:

$$
\langle S,C,T,K,O,\equiv\rangle
$$

It successfully expressed:

* applicability;
* admissibility;
* basic outcomes;
* rejection;
* determinism;
* nondeterminism;
* observation;
* equivalence;
* identity;
* basic composition;
* basic independence;
* causal hypotheses.

However, STC-001 exposed structural insufficiencies.

In particular:

* outcome values did not uniquely determine successor state;
* state transitions were not universally functional;
* outcome equivalence was insufficient for transition equivalence;
* causality could not be defined as simply `¬independent`;
* composition carried unnecessary explicit associativity burden;
* transformation labels were semantically necessary.

These results motivated the graph-relational refinement.

---

# 54. STC-002 Graph-Relational Result

STC-002 established the following adopted model:

```text
typed
+
labelled
+
relational
+
graph-carried consequence
```

The transition carrier is:

$$
edge :
\forall\tau,K,S,C,\;
Out(\tau)\rightarrow Prop
$$

The following were retained:

* `Applicable`;
* `Consents`;
* semantic context;
* semantic state;
* transformation identity;
* typed consequences;
* `Footprint` / `Overlap` as interference structure;
* contextual equivalence;
* provenance.

The following were demoted from primitives to projections:

* `OutcomeOf`;
* `ResultState`.

The following earlier hypotheses were rejected:

* outcome-only transition carrier;
* pure `S → S` transition graphs;
* unlabelled relations;
* functional successor requirement;
* rejection as missing edge;
* causality as non-independence;
* hand-carried associativity laws.

The graph-relational carrier survived machine-checked counterexample testing and gate closure.

---

# 55. Causality Decision

The final STC-002 causality decision is:

$$
\boxed{
CausalDependency
=
Enablement
\cup
Conflict
}
$$

Successor order-sensitivity is retained as an observational shadow.

This distinction is required because:

* conflict may exist without observable ordering;
* enablement may exist without ordering sensitivity;
* temporal ordering may exist without causal dependency;
* successor order-sensitivity may under-report causal structure.

Therefore no single order-sensitive predicate is sufficient as the definition of causality.

---

# 56. Delta Decision

The semantic delta is carried by the consequence.

The graph-level endpoint span:

$$
S_0\rightarrow S_1
$$

is not itself the semantic delta.

The consequence may contain the delta required to establish:

$$
S_1=S_0\oplus\Delta
$$

Therefore:

```text
edge
 └── consequence
      ├── successor
      ├── outcome
      └── delta
```

is preferred over introducing an independent transition-level delta carrier.

---

# 57. Hyperedge Decision

Hypergraph fan-out is representable by the relational consequence carrier.

A single consequence may identify multiple valid successors.

Therefore:

```text
one transition
     │
     ▼
one consequence
     │
     ├── successor A
     ├── successor B
     └── successor C
```

does not require a separate hyperedge transition primitive.

Internal hypergraph incidence remains the responsibility of the graph domain.

STC only requires that semantic consequences can participate in graph composition.

---

# 58. Continuation Congruence

Consequence equivalence must support the continuation of computation.

If:

$$
o_1\equiv_C o_2
$$

then any continuation that is semantically insensitive to the distinction must remain equivalent.

This requirement is stronger than value equality.

It includes successor congruence.

The general continuation-congruence theorem remains a formalization concern where the continuation's sensitivity is not fully characterized.

No additional carrier should be introduced merely to make the theorem easier to state.

---

# 59. Formal Lean Model

The Lean formalization should model the adopted kernel rather than reproduce the historical tuple as independent structures.

The minimum conceptual components are:

```text
SemanticState
SemanticContext
Transformation
Constraint
Consequence
Applicable
Consents
Admissible
Edge
ConsequenceEquivalence
SuccessorRelation
Footprint
Overlap
Enablement
Conflict
CausalDependency
Observation
Equivalence
Composition
Realization
Conformance
```

Where a concept is derivable from another structure, Lean should prefer a definition or theorem over a duplicated primitive.

The implementation must preserve the SCR ontology already established in the core library.

No parallel semantic ontology is permitted.

---

# 60. Formalization Requirements

The Lean model must demonstrate:

1. applicability;
2. admissibility;
3. typed semantic consequences;
4. nondeterministic consequences;
5. semantic rejection;
6. semantic failure;
7. partiality;
8. relational composition;
9. associativity;
10. conditional composition;
11. consequence equivalence;
12. successor congruence;
13. path equivalence;
14. semantic independence;
15. interference;
16. conflict;
17. enablement;
18. causal dependence;
19. temporal ordering;
20. observation;
21. identity obligations;
22. provenance;
23. realization/conformance;
24. spatial transition separation.

The formalization must contain explicit counterexamples where a stronger or simpler hypothesis fails.

---

# 61. Required Counterexample Classes

The STC formal test suite should retain the following classes.

### Transition carrier

* identical outcome, different successor;
* equivalent outcome, distinguishable successor;
* distinguishable outcome, equivalent successor;
* different transformations, same endpoints;
* nondeterministic branching.

### Failure and partiality

* admissible edge-less transition;
* failure with state change;
* rejection versus failure;
* no-op versus failure.

### Composition

* relational composition;
* associativity;
* conditional branching;
* refused intermediate transition.

### Independence

* compatible but overlapping transitions;
* non-commuting transitions;
* physically separated but semantically dependent transitions;
* physically co-located but semantically independent transitions.

### Causality

* enablement without ordering sensitivity;
* conflict without ordering sensitivity;
* order sensitivity without complete causal exposure;
* temporal ordering without causality;
* causality without wall-clock ordering.

### Observation

* state observation;
* edge observation;
* provenance observation;
* equivalent states with distinguishable transition paths.

### Spatial semantics

* state migration without identity change;
* partition migration without identity change;
* coordinate transformation without partition change;
* partition change without coordinate change;
* materialization change without semantic-state change.

Each counterexample must identify:

```text
Premises
Semantic distinction
Existing representation
Required conclusion
```

---

# 62. STC and Spatial Semantics

The spatial model defined by the Semantic Machine Model establishes:

$$
Coordinate
\neq
Partition
\neq
State
\neq
ExecutionResource
$$

STC consumes these distinctions when a transition changes them.

Examples:

```text
CoordinateTransform
PartitionRefinement
PartitionMigration
StateMigration
StateReplication
Materialize
Dematerialize
ExecutionRelocation
```

These are semantically distinct transition classes.

A physical provider such as H3 or OpenVDB may realize one of these operations, but neither provider defines the STC semantics.

---

# 63. STC and H3

H3 may realize semantic partitioning operations such as:

* hierarchy;
* locality;
* partition membership;
* refinement;
* coarsening;
* routing locality.

H3 does not define the SCR coordinate system.

Therefore an STC transition may change:

$$
Partition(x)
$$

without changing:

$$
Coordinate(x)
$$

and vice versa.

---

# 64. STC and OpenVDB

OpenVDB may realize sparse spatial state.

Its provider-local voxel/index coordinates are not automatically SCR semantic coordinates.

Therefore a transition may change:

$$
StateRepresentation
$$

without changing:

$$
SemanticCoordinate
$$

or:

$$
SemanticState
$$

This preserves provider independence.

---

# 65. STC and Physical Scheduling

Scheduling is outside the STC kernel.

A scheduler may choose:

```text
execute A then B
execute B then A
execute A || B
move A to data
move data to A
replicate A
fuse A+B
```

The choice is valid only if the resulting observation conforms to STC semantics.

Thus:

$$
SemanticOrder \neq SchedulerOrder
$$

and:

$$
SemanticConcurrency \neq PhysicalParallelism
$$

---

# 66. STC and Messaging

Messages may carry semantic consequences between execution contexts.

However:

$$
MessageDelivery \neq SemanticTransition
$$

unless the message operation itself is part of the semantic field.

AMQP, HyrxMQ, or another transport may realize communication between semantic execution contexts.

The transport does not define semantic causality.

A message may physically arrive before a semantic predecessor is observed, provided the semantic observation remains valid.

---

# 67. STC and Time

STC does not require a single universal physical clock.

A context may include temporal information where relevant.

Semantic time becomes part of the equivalence relation only when it is observable or constraining.

Therefore an implementation may use:

* wall-clock time;
* monotonic clocks;
* logical clocks;
* vector clocks;
* event counters;
* simulation time;
* provider-specific temporal models

provided the resulting semantic observations conform.

---

# 68. STC and Identity

Identity is not derived from physical execution.

A transition may preserve identity across:

```text
representation change
partition migration
state migration
provider substitution
execution relocation
replication
materialization
dematerialization
```

unless the semantic transformation explicitly changes identity.

This is particularly important for distributed semantic fields.

---

# 69. STC and Manifestation

Manifestation is the physical realization of semantic transitions.

Conceptually:

$$
\mu :
(\delta,P)
\rightarrow
PhysicalExecution
$$

where \(P\) represents selected capabilities/providers.

Correctness requires:

$$
\mu(\delta,P)\models\delta
$$

The manifestation may involve arbitrary implementation machinery.

STC does not prescribe:

* instruction selection;
* memory layout;
* kernel scheduling;
* network transport;
* GPU execution;
* provider internals.

The physical mechanism is subordinate to the semantic contract.

---

# 70. Semantic Preservation Principle

The central conformance principle is:

> **Manifestation may change representation, location, scheduling, resource allocation, or physical execution strategy without changing semantic meaning.**

Therefore:

$$
PhysicalTransformation
\neq
SemanticTransformation
$$

but a physical transformation is correct when it realizes an admissible semantic transition.

---

# 71. Kernel Boundary

The STC kernel must remain small.

The following do **not** belong in the kernel merely because they are useful runtime concepts:

```text
Processor
Thread
Scheduler
Memory
Storage
Network
Broker
Provider
Device
Container
VM
Process
GPU
CPU
Filesystem
Database
```

They belong in semantic context, capability models, spatial models, provider models, or realization models where required.

A new primitive requires a counterexample showing that its semantic distinction cannot otherwise be represented.

---

# 72. Relationship to SMM

SMM defines the semantic machine.

STC defines its transition calculus.

The separation is:

```text
SMM:
    What is a semantic machine?

STC:
    How can its semantic structures change?

Graph:
    How are those changes represented and composed?

EGS:
    How are executable semantic graphs manifested?

Provider:
    Which physical mechanism realizes the capability?
```

No layer should silently absorb the ontology of another.

---

# 73. Relationship to the Core Library

STC must use the established SCR ontology.

In particular:

* `State`;
* `Context`;
* `Transformation`;
* `Operation`;
* `Relationship`;
* `Hypergraph`;
* `Observation`;
* `Equivalence`;
* `Delta`.

must not be duplicated under alternative names merely to satisfy STC implementation convenience.

Where STC discovers that an existing core concept is insufficient, the insufficiency must be recorded and tested before the ontology is changed.

---

# 74. Architectural Invariants

The following invariants summarize the adopted calculus.

### Meaning

Meaning precedes representation.

### State

Semantic state is distinct from physical representation.

### Transition

A semantic transition is a labelled typed relation.

### Consequence

A transition may have zero, one, or multiple valid consequences.

### Composition

Composition is relational.

### Equivalence

Equivalence is contextual and observational.

### Independence

Independence is semantic.

### Causality

Causality is enablement plus conflict.

### Time

Temporal order is not causality.

### Identity

Physical movement does not imply identity change.

### Space

Coordinate, partition, state, and execution resource are distinct.

### Providers

Providers realize capabilities.

### EGS

EGS realizes executable semantic graphs.

### Realization

Physical execution is subordinate to semantic meaning.

### Verification

Every kernel expansion requires falsification evidence.

---

# 75. Current Formal Status

The current STC-002 trajectory establishes:

| Area                                | Status                                          |
| ----------------------------------- | ----------------------------------------------- |
| Typed relational transition carrier | **ADOPTED**                                     |
| Transformation labels               | **ADOPTED**                                     |
| Typed consequence domain            | **ADOPTED**                                     |
| Applicability                       | **ADOPTED**                                     |
| Consent/admissibility               | **ADOPTED**                                     |
| Relational successor                | **ADOPTED**                                     |
| Outcome as primitive carrier        | **DEMOTED**                                     |
| ResultState as primitive carrier    | **DEMOTED**                                     |
| Relational composition              | **ADOPTED**                                     |
| Associativity                       | **STRUCTURAL**                                  |
| Consequence equivalence             | **ADOPTED**                                     |
| Successor congruence                | **ADOPTED**                                     |
| Path equivalence                    | **ADOPTED**                                     |
| Footprint                           | **RETAINED — interference annotation**          |
| Overlap                             | **RETAINED — interference relation**            |
| `causal := ¬independent`            | **REJECTED**                                    |
| Enablement                          | **ADOPTED**                                     |
| Conflict                            | **ADOPTED**                                     |
| Causal dependence                   | **ADOPTED = enablement ∪ conflict**             |
| Order-sensitivity                   | **DERIVED OBSERVATIONAL SHADOW**                |
| Temporal ordering                   | **SEPARATE**                                    |
| Delta                               | **CONSEQUENCE-CARRIED / DERIVED SPAN RELATION** |
| Hyperedge fan-out                   | **SUPPORTED BY RELATIONAL CARRIER**             |
| Hypergraph internal incidence       | **DOMAIN SCOPE**                                |
| Reference Executor                  | **CONFORMING WITNESS**                          |
| Provider ontology in kernel         | **REJECTED**                                    |
| Runtime ontology in kernel          | **REJECTED**                                    |

---

# 76. Formal Evidence

The adopted model is supported by the STC graph-relational formalization and gate-closure work.

The relevant formal evidence includes:

```text
SCRFormal/SCR/STCGraphCounterexamples.lean
SCRFormal/SCR/STCGraphLaws.lean
SCRFormal/SCR/STCGraphMigration.lean
SCRFormal/SCR/STCGraphCausality.lean
SCRFormal/SCR/STCGraphHyperedges.lean
```

The evidence establishes, among other results:

* relational composition;
* composition associativity;
* typed consequence semantics;
* nondeterministic successors;
* rejection distinct from missing edges;
* failure as a typed consequence;
* consequence equivalence;
* successor congruence;
* path equivalence;
* separation of conflict, enablement, and order sensitivity;
* delta mapping;
* hyperedge fan-out;
* golden-path migration from the earlier STC model.

The formal artifacts remain the executable evidence for the normative claims.

---

# 77. Required Continuing Formal Work

The next formal increments should focus on:

1. general continuation congruence;
2. richer causal algebra;
3. semantic read/write/influence sensitivity;
4. internal hypergraph incidence where required;
5. structure-valued endpoint semantics;
6. spatial transition witnesses;
7. partition migration;
8. state migration;
9. coordinate transformation;
10. materialization/dematerialization;
11. conformance of the Reference Executor;
12. cross-provider semantic equivalence.

The burden of proof remains on any proposed kernel expansion.

---

# 78. Exit Criteria

STC is sufficiently mature for production semantic execution when:

* the adopted graph-relational carrier is fully formalized;
* applicability and consent are formally distinct;
* typed consequences are formally defined;
* nondeterminism is supported;
* rejection, failure and partiality are distinct;
* relational composition is complete;
* associativity is established structurally;
* consequence equivalence is established;
* successor congruence is established;
* path equivalence is established;
* independence and conflict are formally distinguishable;
* enablement is formally defined;
* causal dependence is formally defined;
* temporal ordering remains independent of causality;
* identity obligations are expressible;
* spatial transition classes are expressible;
* realization and physical failure remain outside semantic failure;
* Reference Executor conformance is demonstrated;
* at least one production-oriented executable semantic graph can be derived and executed entirely through STC semantics;
* provider substitution preserves semantic observations.

---

# 79. Final STC Model

The adopted model can be summarized as:

$$
\boxed{
S
\xrightarrow[\;C,K\;]{\tau}
o
}
$$

where:

$$
o\in Out(\tau)
$$

and the edge may induce:

$$
S'
$$

through a relational successor relation.

Composition is:

$$
R_2\circ R_1
$$

Equivalence is:

$$
x\equiv_C y
$$

Independence is:

$$
\delta_1\perp_C\delta_2
$$

Interference is represented through:

$$
Footprint,\;Overlap
$$

Causality is:

$$
\boxed{
CausalDependency
=
Enablement
\cup
Conflict
}
$$

Observation determines semantic equivalence.

Realization is subordinate to the semantic relation.

---

# 80. Final Architectural Principle

> **A semantic transition is not an execution event. It is a typed, labelled relation describing a permitted semantic consequence of transforming a semantic state under a semantic context and constraint environment.**

The implementation may execute that relation:

* sequentially;
* concurrently;
* speculatively;
* remotely;
* on a CPU;
* on a GPU;
* through a provider;
* through a message fabric;
* through a replicated state;
* through a migrated partition;
* through a different representation.

None of those mechanisms define the transition.

The invariant is:

$$
\boxed{
Meaning
\rightarrow
Semantic\ Relation
\rightarrow
Observation
\rightarrow
Conforming\ Manifestation
}
$$

not:

$$
Physical\ Execution
\rightarrow
Assumed\ Meaning
$$

Therefore:

> **STC defines semantic change; graph structure carries that change; observation defines equivalence; EGS and providers manifest it; physical execution remains an implementation detail unless explicitly elevated into semantic meaning.**
