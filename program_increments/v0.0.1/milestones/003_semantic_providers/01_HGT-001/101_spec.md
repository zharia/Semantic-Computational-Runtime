# SCR Development Agent Instruction

## HGT-001 — Hypergraph Semantic Foundation

You are implementing **HGT-001 — Hypergraph Semantic Foundation** for the Semantic Computational Runtime (SCR).

Repository:

`github.com/zharia/Semantic-Computational-Runtime`

Your task is to establish the **normative semantic foundation for hypergraphs** in SCR before continuing development of ordinary Graph semantics or graph-provider integrations.

This is a foundational architecture task. Do not treat it as an ordinary graph-library implementation task.

---

# 1. Primary Objective

Establish the SCR semantic model for a **general hypergraph topology** in which:

* elements are first-class semantic objects;
* relations are first-class semantic objects;
* incidences are first-class semantic objects;
* relations may connect arbitrary numbers of elements;
* incidences may carry role and/or direction;
* multiple distinct relations may connect the same participant set;
* relation identity is independent of participant-set equality;
* incidence identity is independent of storage position;
* ordinary graphs are a specialization/projection of the hypergraph model;
* graph projections are representations/transformations, not replacements for the underlying semantic model;
* provider implementations remain below/outside the semantic library;
* SCR semantics must remain valid if the selected provider is replaced.

The fundamental principle is:

> **Hypergraph semantics precede Graph semantics. Graph is a specialization or projection of hypergraph topology, not the foundation underneath it.**

Do not proceed from an assumption that an ordinary graph `(V,E)` is the primitive SCR topology.

---

# 2. Read Before Modifying Code

Before making implementation changes, inspect:

1. `docs/architecture/102_provider_architecture.md`
2. `docs/architecture/101_language_and_api.md`
3. `lib/101_Core/101_spec.md`
4. `lib/201_Data/101_spec.md`
5. `lib/202_Math/101_spec.md`
6. the existing `lib/203_Graph/` contents
7. existing repository documentation conventions
8. existing test conventions
9. existing MLIR/Mojo architecture
10. existing provider/integration conventions

The provider architecture is normative.

In particular, preserve these principles:

> SCR defines what computation means; providers perform computation; SCR composes the providers into a coherent semantic system.

and:

> SCR is a semantic gateway over kernel providers.

Do not introduce a graph or hypergraph implementation into the semantic library merely because implementing it locally appears convenient.

---

# 3. Architectural Boundary

SCR has three conceptually distinct layers:

## 3.1 Semantic Library

Defines:

* semantic concepts;
* terminology;
* relationships;
* contracts;
* invariants;
* semantic operations;
* identity;
* equivalence;
* transformations;
* projections;
* provider-neutral interfaces.

The semantic library must not depend on:

* Rust data structures;
* Boost;
* oxgraph;
* GraphBLAS;
* database schemas;
* memory layouts;
* CSR offsets;
* provider-specific identifiers;
* provider-specific storage models.

## 3.2 Provider Layer

Provides implementations of semantic capabilities.

Potential hypergraph providers may include:

* oxgraph;
* Rust hypergraph implementations;
* NWHy;
* a future SCR-native reference implementation.

Provider selection is an implementation concern.

Applications must request **capabilities**, not provider names.

## 3.3 Execution Layer

EGS/runtime infrastructure resolves semantic capability requirements against available providers and manages:

* provider discovery;
* lifecycle;
* resource binding;
* execution;
* scheduling;
* messaging;
* composition;
* verification.

Do not collapse these layers.

---

# 4. Do Not Reimplement a Kernel Prematurely

Before writing a substantial hypergraph implementation:

1. inspect candidate providers;
2. determine what capabilities they actually provide;
3. determine where their semantic model aligns with SCR;
4. determine what adapters would be required;
5. determine what semantic gaps remain.

Candidate qualification order:

1. **oxgraph**
2. Rust `hypergraph`
3. NWHy
4. minimal internal/reference implementation

Ordinary graph providers such as:

* Boost.Graph
* GraphBLAS

are **not candidates for the foundational hypergraph semantic layer**.

They may later become providers for graph projections or specialized graph computation.

---

# 5. Hypergraph Semantic Model

Establish a normative model approximately of the form:

[
\mathcal{H} = (E,R,I,\rho)
]

where:

* `E` = elements;
* `R` = relations;
* `I` = incidences;
* `ρ` = optional role/direction semantics associated with incidences.

This notation may be refined if the repository's existing formal conventions require it, but do not weaken the model merely to make an implementation easier.

## 5.1 Element

An Element is a first-class semantic object that may participate in one or more relations.

An Element:

* has semantic identity;
* may have semantic value/data;
* may participate in arbitrary numbers of relations;
* must not be identified by provider-local index;
* must not be identified by memory address;
* must not be identified by array offset.

## 5.2 Relation

A Relation is a first-class semantic object connecting zero or more Elements through Incidences.

A Relation:

* has its own identity;
* may have arbitrary cardinality;
* may contain zero, one, or many incidences;
* may connect the same Elements as another Relation;
* may distinguish participants through incidence roles;
* must not be reduced to an unordered set of Elements.

This distinction is mandatory.

For example:

```text
Relation R1:
    A --input--> R1
    B --parameter--> R1
    C --output--> R1

Relation R2:
    A --input--> R2
    B --parameter--> R2
    C --output--> R2
```

`R1 != R2` even though their participant sets and roles may be identical.

## 5.3 Incidence

An Incidence is a first-class semantic relationship between an Element and a Relation.

An Incidence may carry:

* identity;
* role;
* direction;
* ordering where semantically required;
* multiplicity where semantically required;
* provenance;
* semantic attributes.

Do not model incidence merely as an implementation detail.

The distinction between:

```text
Element
Relation
Element ↔ Relation Incidence
```

must remain explicit.

---

# 6. Roles and Direction

Roles must be represented semantically rather than inferred from storage order.

Examples:

```text
input
output
parameter
source
target
subject
object
operand
constraint
cause
effect
```

These are examples, not necessarily a closed SCR enumeration.

The model must support provider-independent representation of role semantics.

Direction must not be conflated with:

* array order;
* insertion order;
* CSR ordering;
* memory layout.

If a provider cannot directly represent the semantic role model, an adapter must perform the translation.

---

# 7. Fundamental Semantic Cases

The specification and conformance suite MUST address:

### 7.1 Unary relation

A relation with one participant is valid.

### 7.2 Nullary relation

A relation with zero participants must have explicitly defined semantics.

Do not silently reject it merely because a provider cannot represent it.

If SCR ultimately chooses to prohibit nullary relations, that must be a deliberate semantic decision supported by rationale and tests.

### 7.3 Self-incidence

An Element may participate in a Relation in a way that creates a self-referential topology.

Define the semantics explicitly.

### 7.4 Multiple incidences

An Element may have multiple incidences with the same Relation where multiplicity is semantically meaningful.

Do not assume participant uniqueness unless the semantic contract explicitly requires it.

### 7.5 Multiple relations with identical participants

This is mandatory.

Two relations may connect exactly the same participants while remaining distinct semantic relations.

### 7.6 Directed relations

Direction must be representable independently of storage representation.

### 7.7 Role-bearing relations

Role must be semantic information, not metadata accidentally attached by a provider.

---

# 8. Identity

SCR semantic identity must remain independent from provider identity.

At minimum distinguish:

```text
Semantic Element Identity
Semantic Relation Identity
Semantic Incidence Identity

Provider-local identifier
Storage position
Memory address
Database key
Array index
CSR offset
```

Do not substitute one for another.

Where SCR SID semantics apply, use the established SCR identity architecture.

Do not invent a competing UUID/ULID-based identity system.

Provider-local identifiers may be mapped to SCR identity, but they are not authoritative semantic identity.

---

# 9. Equality

Define separate concepts for:

### Identity equality

Two objects are the same semantic object.

### Structural equality

Two structures contain equivalent topology.

### Referential equality

Two references designate the same semantic object.

### Representation equality

Two provider representations are byte-for-byte or layout-equivalent.

These must not be conflated.

In particular:

```text
same participants != same relation
same structure != same identity
same provider representation != same semantic representation
```

---

# 10. Representation Independence

The following must be treated as representations or projections, not as the semantic hypergraph itself:

* adjacency representation;
* incidence representation;
* incidence matrix;
* bipartite incidence graph;
* clique expansion;
* star expansion;
* CSR;
* CSC;
* database tables;
* serialized formats;
* memory layouts.

A provider may use any of these internally.

SCR semantics must not depend on which representation is selected.

---

# 11. Graph as a Specialization

Define ordinary Graph as a constrained hypergraph.

At minimum, an ordinary graph can be understood as a topology in which relations satisfy stricter cardinality/direction constraints.

Do not define:

```text
Hypergraph = Graph + extra feature
```

if that makes Graph conceptually primary.

Instead establish:

```text
Hypergraph
    └── Graph specialization/projection
```

Graph may then impose restrictions such as:

* bounded relation cardinality;
* conventional edge semantics;
* conventional source/target semantics.

The exact restrictions must be formally specified rather than assumed.

---

# 12. Projection Semantics

Define projection as a semantic transformation.

Examples:

```text
Hypergraph
    → ordinary Graph
    → incidence Graph
    → bipartite representation
    → incidence matrix
    → provider-specific representation
```

A projection may lose information.

Therefore every projection must specify:

* source semantic structure;
* target structure;
* preservation guarantees;
* information lost;
* whether the transformation is reversible;
* whether identity is preserved;
* whether provenance is preserved.

Do not claim two projections are semantically equivalent merely because they encode the same connectivity.

---

# 13. Traversal

Traversal is a semantic capability, not necessarily a local implementation.

Define traversal in terms of semantic objects.

Examples:

```text
Element → Incidence → Relation → Incidence → Element
```

Traversal must not assume that the provider stores a conventional adjacency list.

Where deterministic traversal is required, define what determinism means.

Do not accidentally make provider iteration order part of SCR semantics.

---

# 14. Mutation

Define semantic operations such as:

```text
create_element
create_relation
create_incidence
remove_element
remove_relation
remove_incidence
attach
detach
set_role
set_direction
```

Do not assume these exact names are mandatory.

The semantic distinction is what matters.

Mutation must define:

* identity preservation;
* provenance;
* invalidation;
* reference behavior;
* concurrent access expectations;
* transactional/atomic semantics where applicable.

A provider may implement mutation using a completely different mechanism.

---

# 15. Provider Capability Model

Do not create one monolithic `HypergraphProvider` interface if the architecture can support capability-specific contracts.

Prefer capability decomposition such as:

```text
HypergraphTopology
HypergraphIncidence
HypergraphMutation
HypergraphTraversal
HypergraphProjection
HypergraphPersistence
HypergraphParallel
HypergraphStreaming
HypergraphQuery
```

Not every provider must implement every capability.

EGS/provider discovery should be capable of determining:

```text
provider
    capability
    version
    semantic compatibility
    limitations
    dependencies
    platform
    resources
    health
```

Applications request semantic capabilities.

They do not request:

```text
use oxgraph
use Boost
use provider X
```

unless an explicit implementation-level override is being made.

---

# 16. Provider Qualification

Create:

```text
docs/architecture/103_hypergraph_provider.md
```

This document must describe the qualification process and current candidate assessment.

Evaluate at least:

## oxgraph

Investigate:

* topology model;
* hypergraph model;
* incidence representation;
* roles;
* direction;
* identity;
* storage independence;
* traversal;
* mutation;
* persistence;
* zero-copy design;
* `no_std` suitability;
* Rust integration;
* license;
* maturity;
* API stability;
* semantic alignment;
* missing capabilities.

Do not assume that oxgraph is automatically selected.

## Rust hypergraph

Evaluate:

* semantic alignment;
* representation;
* directed hypergraph support;
* mutation;
* traversal;
* identity;
* persistence;
* performance;
* API stability;
* license.

## NWHy

Evaluate:

* hypergraph representation;
* processing model;
* scalability;
* C++ integration;
* semantic flexibility;
* applicability to SCR.

Then explicitly state:

```text
Selected
Conditionally selected
Rejected
Deferred
```

with reasons.

---

# 17. Adoption Rule

An existing provider may be adopted or stabilized only if:

1. its semantic model can represent SCR semantics;
2. its implementation architecture is sound;
3. its license is compatible;
4. its project is technically salvageable/stabilizable;
5. upstream contribution is feasible where appropriate;
6. performance is appropriate;
7. it does not force SCR to adopt its ontology;
8. it can remain behind the SCR provider contract;
9. it can be replaced without changing SCR semantic meaning.

If oxgraph is architecturally appropriate but incomplete:

> Prefer upstream contribution and stabilization over immediately forking.

If no existing provider satisfies the semantic contract:

> Implement the smallest viable SCR reference kernel necessary to establish the missing capability.

That implementation must itself remain behind the provider boundary.

---

# 18. Conformance Tests

Create:

```text
tests/hypergraph/semantic/
tests/hypergraph/conformance/
tests/hypergraph/pathological/
```

At minimum establish tests corresponding to:

```text
HYPERGRAPH-C001  Element identity
HYPERGRAPH-C002  Relation identity
HYPERGRAPH-C003  Incidence identity
HYPERGRAPH-C004  Arbitrary relation cardinality
HYPERGRAPH-C005  Multiple relations with identical participants
HYPERGRAPH-C006  Directed / role-bearing incidence
HYPERGRAPH-C007  Self-incidence
HYPERGRAPH-C008  Unary relations
HYPERGRAPH-C009  Nullary relation semantics
HYPERGRAPH-C010  Deterministic traversal
HYPERGRAPH-C011  Dynamic mutation
HYPERGRAPH-C012  Stable identity under mutation
HYPERGRAPH-C013  Graph projection
HYPERGRAPH-C014  Incidence projection
HYPERGRAPH-C015  Provider-independent semantic identity
HYPERGRAPH-C016  Provider-independent semantic equality
HYPERGRAPH-C017  Provenance preservation
HYPERGRAPH-C018  Concurrent access
HYPERGRAPH-C019  Serialization/view equivalence
HYPERGRAPH-C020  Representation independence
```

Where the repository's existing testing framework requires different organization, preserve the intent while following repository conventions.

---

# 19. Pathological Cases

Explicitly test:

* empty hypergraph;
* nullary relation;
* unary relation;
* repeated participant;
* self-incidence;
* multiple identical participant sets;
* multiple roles between the same element and relation;
* relation deletion;
* element deletion;
* mutation while references exist;
* provider remapping;
* serialization/deserialization;
* projection followed by reconstruction;
* provider representation changes;
* very high relation cardinality;
* very high incidence count.

The purpose is to discover semantic ambiguity before implementation becomes entrenched.

---

# 20. Documentation

Update/create:

```text
lib/203_Graph/101_spec.md
lib/203_Graph/102_status.yaml
lib/203_Graph/103_library.graph.json

docs/architecture/103_hypergraph_provider.md
```

If the existing taxonomy makes `203_Graph` semantically inappropriate, do not silently rename the directory.

Document the issue and propose the taxonomy change separately.

The immediate objective is to establish semantics without destabilizing repository structure unnecessarily.

---

# 21. Existing Graph Specification

The existing Graph specification is expected to be too implementation-oriented for the new architecture.

Do not simply append hypergraph features to it.

Refactor it so that:

1. hypergraph topology is foundational;
2. graph is a specialization;
3. provider implementations are external;
4. projections are explicit;
5. semantic contracts precede implementation;
6. provider independence is testable.

Remove or relocate material that belongs to provider implementation rather than semantic definition.

---

# 22. Mojo / MLIR

Do not create a second semantic representation in Mojo.

Follow the established SCR language architecture:

```text
Semantic Specification
        ↓
      MLIR
        ↓
verification / transformation / lowering
        ↓
provider integration / runtime
        ↓
Mojo Semantic API
```

MLIR remains the canonical implementation/compiler representation.

Mojo remains the canonical user-facing API.

Do not make Rust provider types leak through the Mojo semantic API.

Do not expose provider-specific storage structures as semantic types.

---

# 23. Semantic API Principle

The eventual API should make semantic concepts obvious.

Prefer concepts resembling:

```text
Element
Relation
Incidence
Role
Hypergraph
Projection
Traversal
Identity
```

rather than exposing:

```text
CSRRow
CSRColumn
VecIndex
ArenaSlot
ProviderNode
ProviderEdge
DatabaseRecord
```

Provider implementation types may exist below the boundary.

They must not become SCR semantic ontology.

---

# 24. Verification Requirements

Follow SCR's established development process:

> Describe → Spec → Test → Validate

Do not consider the work complete merely because code compiles.

Completion requires:

1. semantic specification;
2. formal terminology;
3. invariants;
4. conformance tests;
5. pathological tests;
6. provider qualification;
7. provider-boundary validation;
8. MLIR representation where required;
9. Mojo projection where required;
10. build/test validation;
11. documentation consistency.

---

# 25. Required Invariants

Establish explicit hypergraph invariants.

At minimum include concepts equivalent to:

### HYPERGRAPH-I001 — Identity Independence

Semantic identity is independent of provider storage identity.

### HYPERGRAPH-I002 — Relation Identity

Distinct relations remain distinct even with identical participant sets.

### HYPERGRAPH-I003 — Incidence Identity

Incidences are first-class semantic objects.

### HYPERGRAPH-I004 — Arbitrary Cardinality

Relations are not intrinsically limited to two participants.

### HYPERGRAPH-I005 — Role Independence

Semantic roles are independent of storage ordering.

### HYPERGRAPH-I006 — Representation Independence

Changing provider representation does not change semantic meaning.

### HYPERGRAPH-I007 — Provider Independence

Replacing a provider does not redefine hypergraph semantics.

### HYPERGRAPH-I008 — Projection Explicitness

A graph projection is a transformation and may lose information.

### HYPERGRAPH-I009 — Provenance Preservation

Semantic transformations preserve provenance according to their declared contract.

### HYPERGRAPH-I010 — Semantic/Implementation Separation

Provider implementation details do not become semantic ontology without an explicit promotion decision.

Add further invariants where required by the formal model.

---

# 26. What Not To Do

Do NOT:

* start by implementing a conventional graph library;
* make BGL the foundation;
* make GraphBLAS the foundation;
* assume an edge is always a pair of vertices;
* represent a hyperedge solely as a set of vertices;
* discard incidence identity;
* infer semantic role from array order;
* use provider IDs as SCR IDs;
* leak Rust types into the semantic layer;
* hard-code oxgraph into SCR semantics;
* create a monolithic provider interface unnecessarily;
* implement every graph algorithm internally;
* duplicate mature provider functionality;
* make provider storage formats normative;
* silently redefine existing SCR identity semantics;
* introduce UUID/ULID identity as a replacement for SID;
* treat serialization format as semantic identity;
* declare a provider selected without qualification evidence;
* declare the task complete because the code compiles.

---

# 27. Strategic Principle

The implementation should embody this SCR rule:

> **Do not build a kernel when a good kernel already exists. Build the semantic bridge that allows it to participate in SCR.**

And its complementary rule:

> **If no suitable kernel exists, SCR may create the missing capability, but it must expose that capability through a stable semantic contract so that the implementation can later be replaced.**

The objective is not to own a hypergraph implementation.

The objective is to make **hypergraph semantics a stable part of the SCR computational language**.

---

# 28. Definition of Done

HGT-001 is complete only when:

* [ ] Hypergraph semantic model is formally specified.
* [ ] Element, Relation, and Incidence are first-class concepts.
* [ ] Role and direction semantics are defined.
* [ ] Cardinality semantics are defined.
* [ ] Identity semantics are defined.
* [ ] Equality semantics are defined.
* [ ] Mutation semantics are defined.
* [ ] Projection semantics are defined.
* [ ] Graph specialization is defined.
* [ ] Representation independence is explicit.
* [ ] Provider independence is explicit.
* [ ] Provider capability model is documented.
* [ ] Candidate providers have been evaluated.
* [ ] No provider has been unnecessarily embedded into SCR semantics.
* [ ] HGT conformance tests exist.
* [ ] pathological cases are tested.
* [ ] semantic invariants are documented and tested where practical.
* [ ] `101_spec.md` is updated.
* [ ] `102_status.yaml` is updated.
* [ ] `103_library.graph.json` is updated.
* [ ] `docs/architecture/103_hypergraph_provider.md` exists.
* [ ] implementation boundaries are clear.
* [ ] MLIR remains canonical.
* [ ] Mojo remains the user-facing API.
* [ ] provider-specific structures do not leak into the semantic API.
* [ ] repository build/tests pass.
* [ ] documentation is internally consistent.

---

# 29. Final Agent Behaviour

Work incrementally.

At each stage:

1. inspect;
2. reason about semantic consequences;
3. document;
4. implement the smallest required change;
5. test;
6. validate against invariants;
7. inspect the resulting architecture again.

If an implementation decision would make a provider's representation normative, stop and reconsider the design.

If a semantic question is ambiguous, **do not silently choose the implementation-convenient interpretation**. Record the ambiguity, identify the alternatives, and resolve it at the semantic level before proceeding.

If an existing provider can satisfy the requirement, prefer integration over reimplementation.

If no provider can satisfy a required semantic capability, implement the minimum necessary reference capability and keep it behind the provider contract.

The final result should make it possible for SCR to say:

> **“This is what a hypergraph means.”**

without having to say:

> **“This is how oxgraph stores one.”**
