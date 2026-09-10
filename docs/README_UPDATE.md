# README Update

The root README should be updated to incorporate the following architectural clarification.

## Replace / extend the "What is SCR?" section

Use:

> The Semantic Computational Runtime (SCR) is a computational architecture where semantic structure is primary and physical execution is its manifestation.
>
> SCR models computation as transformation of semantic structure within a Semantic Field.
>
> A computational Semantic Field induces an implementation-independent Semantic Machine. The Semantic Machine defines the semantic state, context, transformations, constraints, outcomes, and equivalence relations that determine what computation means.
>
> Physical implementations are realizations of that abstract machine. The Reference Executor is a canonical executable witness; EGS is the operational execution environment; providers realize semantic capabilities; MLIR represents and lowers computation; and Mojo implements semantic contracts.
>
> **Meaning precedes representation. Representation precedes physical realization.**

## Add the following architectural statement

```text
Semantic Field
      ↓
Semantic Machine Model
      ↓
Semantic Transition Calculus
      ↓
Executable Semantic Hypergraph
      ↓
Reference Executor / Conforming Implementations
      ↓
EGS
      ↓
Capability Resolution
      ↓
Providers
      ↓
Physical Manifestation
```

## Add a boundary statement

> SCR defines an implementation-independent abstract machine boundary, but it is not reducible to a conventional virtual machine architecture. JVM, CLR, ECMAScript, and RISC-V provide useful precedents for separating machine semantics from implementation; SCR generalizes the principle to semantic hypergraphs and Semantic Fields.

## Update "Core Concepts"

Retain the Semantic Field tuple, but clarify that:

```text
M — manifestation / physical realization
```

is a realization dimension and must not be interpreted as the source of semantic meaning.

The Semantic Machine should be introduced after Semantic Field, not before it.

## Update "What SCR Is Not"

Retain:

- object-oriented runtime;
- conventional virtual machine;
- graph database;
- message broker;
- programming language.

Add:

> SCR does define an abstract machine semantics, but that abstract machine is not itself a conventional VM implementation.

## Update "Engineering Principles"

Add:

### Abstract Machine Boundary

> Semantic Machine semantics MUST remain independent of physical realization.

### Realization Transparency

> Replacing a physical provider with another provider satisfying the same semantic capability MUST NOT require modification of the semantic computation.

### Conformance by Observation

> Implementations are judged by semantic observation and equivalence, not by implementation structure.

### No Infrastructure-Derived Ontology

> Runtime components MUST NOT become semantic primitives merely because implementations contain components with corresponding names.

### Falsification Before Expansion

> A new semantic primitive requires a demonstrated semantic counterexample showing that the existing semantic vocabulary and transition calculus cannot express the required behaviour.
