# lib/

> Directory documentation for the current Semantic Computational Runtime (SCR) semantic library tree.

**Path:** `lib/`
**Documentation role:** Semantic library root definition
**Status:** Normative
**Version:** 0.0.2
**Semantic authority:** Semantic Computational Runtime

---

## 1. Purpose

`lib/` is the root of the SCR semantic library.

The semantic library defines the **meaning, structure, relationships, contracts, invariants, and execution semantics** required by the Semantic Computational Runtime.

It is the authoritative semantic layer from which SCR computational structures are defined.

The semantic library does **not** constitute a general-purpose programming language, operating system, execution provider collection, or implementation repository.

Its purpose is to define the semantic structures upon which those implementations operate.

---

## 2. Fundamental Principle

SCR treats computation as transformation of semantic structure within a semantic field.

The semantic library therefore defines:

* semantic entities;
* values and information;
* relationships;
* states;
* transformations;
* fields;
* spaces;
* processes;
* interactions;
* observations;
* actions;
* operations;
* capabilities;
* execution contracts;
* interfaces;
* invariants;
* identity and provenance;
* domain-specific computational semantics.

Concrete implementations may vary, but their participation in SCR is governed by the semantic contracts defined by the library.

The semantic library is therefore **semantically authoritative but implementation-independent**.

---

## 3. Semantic Authority

The canonical SCR semantic model is the hypergraph.

Semantic entities are represented by identities and relationships.

The semantic library defines the meaning of those identities and relationships.

The filesystem hierarchy under `lib/` is **not itself a semantic ontology**.

Directory placement is an organizational mechanism for locating semantic definitions.

A semantic relationship between two concepts exists because it is explicitly defined by their semantic contracts and graph relationships, not because one directory happens to contain another.

---

## 4. Semantic Library Boundaries

The semantic library owns:

* semantic definitions;
* semantic contracts;
* semantic types;
* semantic relationships;
* state models;
* transformation semantics;
* domain invariants;
* execution semantics;
* identity semantics;
* reference semantics;
* deletion semantics;
* nullary relation semantics;
* provenance semantics;
* capability semantics;
* cross-domain semantic interfaces.

The semantic library does **not** own:

* concrete external libraries;
* device drivers;
* vendor APIs;
* rendering engines;
* physics engines;
* databases;
* message brokers;
* operating-system services;
* accelerator implementations;
* executable artifacts;
* provider-specific implementation details.

Those belong to the implementation/provider architecture.

---

## 5. Current Semantic Library

The current SCR semantic library is organized into the following principal domains and cross-cutting areas.

### Foundational

* `000_meta` — Repository metadata and semantic-library control information
* `101_Core` — Foundational semantic structures and universal concepts

### Information and Computation

* `201_Data` — Data structures and information
* `202_Math` — Mathematical semantics and computation
* `203_Graph` — Graph structures and graph computation

### Fields and Structure

* `301_Field` — Field semantics
* `302_Geometry` — Geometric structures and operations
* `303_Topology` — Topological structures and relationships
* `401_Morphology` — Morphological structures and transformations

### Physical and Dynamic Systems

* `501_Physics` — Physical quantities, laws, and physical semantics
* `502_Dynamics` — Dynamic systems and state evolution
* `503_Simulation` — Simulation semantics

### Agents and Interaction

* `601_Agent` — Agent semantics and autonomous computational entities
* `602_Neural` — Neural computation
* `603_Perception` — Perception and observation semantics
* `604_Control` — Control semantics
* `605_Interaction` — Interaction, gesture, intent, action, and human/machine interaction semantics

### Adaptation and Optimization

* `701_Optimization` — Optimization semantics
* `702_Learning` — Learning semantics
* `703_Adaptation` — Adaptive systems
* `704_Evolution` — Evolutionary semantics
* `705_Ecology` — Ecological and interacting-system semantics

### Spatial and Streaming

* `801_Spatial` — Spatial structures, spaces, locality, and spatial indexing
* `802_Stream` — Streaming computation and temporal information flow

### Cross-Cutting Semantic Infrastructure

* `901_Analysis` — Analysis and semantic examination
* `902_Interfaces` — Semantic interfaces and boundaries
* `903_Lowering` — Semantic-to-execution lowering
* `905_Transforms` — Semantic transformations

### Rendering

* `A01_Render` — Rendering and visual manifestation semantics

---

## 6. Interaction as a First-Class Domain

`605_Interaction` is a semantic domain because interaction is not fundamentally a property of graphical user interfaces.

Interaction describes how an actor, observer, agent, process, device, or computational entity participates in and influences a semantic field.

Interaction includes semantic concepts such as:

* Input
* Observation
* Pointer
* Gesture
* Gesture Path
* Gesture Recognition
* Gesture Expression
* Gesture Sequence
* Gesture Chord
* Multimodal Interaction
* Interaction Context
* Intent
* Action
* Interaction Mapping
* Interaction Session
* Control
* Feedback
* Commitment
* Cancellation
* Accessibility
* Interaction Cost

A physical mouse, touch surface, pen, controller, camera, microphone, gaze tracker, robot sensor, or other device is not itself the semantic definition of interaction.

Such mechanisms provide observations or actions through implementation and provider boundaries.

The semantic interaction remains independent of the modality used to produce or consume it.

---

## 7. Interaction Composition

Interaction semantics support compositional expressions.

At minimum, interaction composition must be capable of representing:

* temporal sequence;
* concurrent/chorded interaction;
* alternatives;
* optional interaction;
* repetition;
* multimodal composition.

The conceptual operators are:

```text
A ; B    temporal sequence
A & B    concurrent/chord composition
A | B    alternative
A ?      optional
A *      repetition
```

These are semantic relationships, not programming-language syntax.

A gesture sequence is not equivalent to a gesture chord.

Temporal ordering, overlap, duration, context, confidence, and commitment are semantic properties.

---

## 8. Semantic Domains and Cross-Cutting Domains

A semantic domain defines a coherent area of meaning.

A cross-cutting area defines concepts or mechanisms that participate across multiple semantic domains without necessarily constituting a domain-specific ontology.

For example:

* `Geometry` defines geometric meaning.
* `Topology` defines topological meaning.
* `Interaction` defines interaction meaning.
* `Interfaces` defines semantic boundaries between computational structures.
* `Lowering` defines transformations from semantic structures toward executable representations.

Cross-cutting infrastructure must not become a dumping ground for concepts that belong to an identifiable semantic domain.

Likewise, a concept must not be promoted into a top-level domain merely because it is used by multiple other domains.

Promotion requires a stable semantic boundary and independently meaningful ontology.

---

## 9. Relationship to the Semantic Field

The semantic field is foundational to SCR.

Library domains describe structures and transformations that may exist within, act upon, observe, or produce semantic fields.

The semantic field is therefore not merely another application-level data structure.

A domain contributes semantic structures to the field through explicitly defined relationships.

For example:

```text
Interaction
    ↓
Observation
    ↓
Gesture
    ↓
Intent
    ↓
Action
    ↓
Operation
    ↓
Transformation
    ↓
Semantic Field
    ↓
Feedback
```

The resulting field state remains authoritative.

Rendering, presentation, external storage, device state, and provider-specific representations are manifestations or implementations of that semantic state.

---

## 10. Hypergraph Authority

The SCR hypergraph is the canonical representation of semantic relationships.

The semantic library must not introduce independent competing relationship graphs for individual domains.

Domain-specific graph representations may exist as implementation or optimization structures, but they must remain subordinate to the canonical SCR semantic graph.

This applies equally to:

* interaction graphs;
* application graphs;
* provider graphs;
* execution graphs;
* rendering graphs;
* dependency graphs;
* spatial graphs;
* temporal graphs.

Where a domain requires specialized graph structures, those structures must have explicitly defined semantic correspondence with the canonical SCR hypergraph.

---

## 11. Identity and Reference Semantics

Semantic identity is independent of filesystem location.

An SCR Semantic Identifier (SID) need not be self-describing.

SID structure may be domain-specific and may be selected according to requirements such as:

* locality;
* hierarchy;
* allocation;
* namespace structure;
* routing;
* storage;
* performance.

The universal identity requirement is **root-authority verifiability**.

A semantic identity must be attributable through a cryptographically verifiable delegation or allocation chain anchored in the SCR root authority.

Identity, namespace metadata, delegation authority, and provenance are distinct semantic concerns.

References between semantic entities must therefore remain valid independently of implementation-specific memory addresses, filenames, database keys, or provider handles.

---

## 12. Nullary Relations

SCR permits nullary relations where semantically meaningful.

A nullary relation has no participating entity references but may still carry semantic existence, identity, state, provenance, or other attributes.

Nullary relations must not be implicitly discarded merely because they have zero arguments.

Their interpretation and lifecycle are defined by the semantic contract of the domain in which they occur.

---

## 13. Deletion and Reference Semantics

Deletion is a semantic operation, not merely removal of storage.

When an entity is deleted, SCR must distinguish between:

* removal of the entity;
* invalidation of its identity;
* removal of references;
* historical references;
* tombstone state;
* dependent relationships;
* retained provenance;
* provider-level resource destruction.

A semantic deletion operation must preserve graph integrity and must not silently create dangling semantic references.

The exact deletion behaviour is domain-dependent but must conform to the foundational reference and lifecycle semantics defined by `101_Core`.

---

## 14. Execution and Implementation Boundary

The semantic library defines what a computation **means**.

It does not prescribe how that computation must be implemented.

The general relationship is:

```text
Semantic Domain
      ↓
Semantic Capability
      ↓
Semantic Contract
      ↓
Implementation Binding
      ↓
Adapter / Executable Artifact
      ↓
Provider
      ↓
Execution Runtime
      ↓
Computational Resource
```

This separation permits the same semantic capability to be implemented by different technologies while preserving semantic invariants.

---

## 15. Providers Are Outside the Semantic Library

Concrete providers are not semantic-library domains.

Providers belong to the SCR provider architecture under:

```text
providers/
```

rather than being defined as semantic domains under `lib/`.

Examples include implementations based on:

* BLAS;
* CGAL;
* H3;
* OpenVDB;
* Chrono;
* Vulkan;
* CUDA;
* RabbitMQ;
* OGRE;
* databases;
* operating-system facilities;
* accelerators;
* external services.

The semantic library defines the required meaning and contract.

The provider supplies a concrete implementation of that capability.

Therefore:

```text
lib/
    semantic meaning

providers/
    concrete capability implementations
```

A provider may be canonical or reference, but canonical status does not make the provider part of semantic authority.

---

## 16. Provider Independence

SCR follows the principle:

> Do not build a kernel when a good kernel already exists. Build the semantic bridge that allows it to participate in SCR.

Where a suitable leading implementation exists, SCR should define the semantic contract and integration boundary rather than unnecessarily recreating the implementation.

Where no suitable implementation exists, SCR may create the missing capability, provided that the capability is exposed through a semantic contract that permits future substitution.

Provider substitution preserves semantic invariants rather than requiring numerical or implementation identity.

---

## 17. Rendering and Manifestation

Rendering is a semantic manifestation mechanism.

The rendered representation is not inherently the authoritative state.

For example:

```text
Semantic Field
      ↓
Spatial / Geometric State
      ↓
Rendering Semantics
      ↓
Rendering Provider
      ↓
Display
```

A rendering provider may therefore be replaced without changing the semantic model being rendered.

The same principle applies to other manifestations, including:

* audio;
* haptic output;
* user interfaces;
* virtual environments;
* robotic actuation;
* external APIs.

---

## 18. Semantic Library and Applications

Applications consume semantic capabilities defined by the library.

An application may contain:

* Modules;
* Services;
* Operations;
* Controllers;
* Ports;
* Adapters;
* Implementation Bindings;
* executable artifacts.

These are application/runtime architecture concepts and do not replace the underlying semantic domains.

An application is represented semantically as a graph/hypergraph segment participating in the larger SCR semantic field.

---

## 19. Verification and Validation

Every semantic library domain is subject to the SCR development principle:

> Describe → Specify → Test → Validate.

A semantic definition is not considered complete merely because its terminology has been documented.

A domain must progressively establish:

1. semantic definition;
2. invariants;
3. graph relationships;
4. reference semantics;
5. lifecycle semantics;
6. contracts;
7. executable representation where applicable;
8. tests;
9. validation;
10. provider/implementation conformance where applicable.

Semantic ambiguity must be resolved before implementation is allowed to establish de facto semantics.

---

## 20. Repository Structure

The conceptual repository boundary is:

```text
lib/
    semantic definitions and contracts

docs/
    architecture and project-level architectural rules

providers/
    concrete provider integrations

runtime/
    executable runtime systems

apps/
    application implementations where applicable
```

The exact repository structure may evolve, but the semantic/implementation/provider boundary must remain explicit.

---

## 21. Library Invariants

The following invariants apply to the library root:

### LIB-001 — Semantic Authority

`lib/` defines the authoritative SCR semantic model.

### LIB-002 — Implementation Independence

Semantic definitions must not require a particular implementation.

### LIB-003 — Provider Separation

Concrete providers are not semantic-library definitions.

### LIB-004 — Hypergraph Authority

The canonical SCR hypergraph remains the authoritative representation of semantic relationships.

### LIB-005 — No Duplicate Semantic Graphs

Domain-specific representations must not silently become competing semantic authorities.

### LIB-006 — Identity Independence

Semantic identity must not depend on filesystem location or provider-specific identifiers.

### LIB-007 — Reference Integrity

Semantic references must remain valid according to the reference semantics defined by SCR.

### LIB-008 — Deletion Integrity

Deletion must preserve semantic and graph integrity.

### LIB-009 — Nullary Relation Integrity

Meaningful nullary relations must be representable and must not be discarded solely because they have no arguments.

### LIB-010 — Domain Boundary

Each semantic concept must belong to the domain or cross-cutting area that owns its meaning.

### LIB-011 — Cross-Domain Explicitness

Relationships between domains must be explicitly defined and must not be inferred solely from directory structure.

### LIB-012 — Provider Substitutability

Provider-specific implementation must remain replaceable wherever the governing semantic contract permits substitution.

### LIB-013 — Contract Authority

Semantic contracts, rather than implementation behaviour discovered after the fact, define required semantics.

### LIB-014 — Verification Before Promotion

New semantic concepts must be sufficiently defined and validated before becoming foundational SCR concepts.

### LIB-015 — Manifestation Non-Authority

A rendered, stored, transmitted, or otherwise manifested representation does not become semantic authority merely by existing.

### LIB-016 — Interaction Independence

Interaction semantics must remain independent of any particular input device, interface toolkit, rendering system, or presentation modality.

### LIB-017 — Compositional Semantics

Semantic domains must support composition without requiring application-specific reinterpretation of their fundamental concepts.

### LIB-018 — Semantic/Execution Separation

Semantic meaning and executable realization must remain distinguishable even where they are tightly integrated at runtime.

---

## 22. Current Architectural Principle

The SCR semantic library should be understood as a **semantic substrate**, not a conventional utility library.

Its purpose is to establish the vocabulary and formal relationships from which computation can be represented as semantic structure.

The resulting architecture is:

```text
                         SCR SEMANTIC AUTHORITY
                                  │
                                  ▼
                         ┌─────────────────┐
                         │ Semantic Field  │
                         └────────┬────────┘
                                  │
                         Canonical Hypergraph
                                  │
          ┌───────────────────────┼────────────────────────┐
          │                       │                        │
          ▼                       ▼                        ▼
      Semantic               Interaction              Execution
       Domains                 Domains                 Semantics
          │                       │                        │
          └───────────────────────┼────────────────────────┘
                                  │
                                  ▼
                         Semantic Contracts
                                  │
                                  ▼
                       Implementation Bindings
                                  │
                         ┌────────┴────────┐
                         ▼                 ▼
                     Adapters          Artifacts
                         │                 │
                         └────────┬────────┘
                                  ▼
                              Providers
                                  │
                                  ▼
                         Execution Runtimes
                                  │
                                  ▼
                         Physical / Virtual
                          Computational Space
```

The semantic library therefore defines the **meaning of computation**, while EGS, implementations, providers, and execution runtimes determine how that meaning is physically or computationally manifested.

---

## 23. Status

This document defines the root semantic-library boundary.

Individual domain definitions remain authoritative for the detailed semantics of their respective domains.

Where a domain definition conflicts with this document, the conflict must be resolved explicitly rather than being silently interpreted through filesystem hierarchy.

**Version:** 0.0.2
**Status:** Normative Definition
**Semantic authority:** Semantic Computational Runtime
