# SCR Semantic Seed

## Definition

The Semantic Seed is SCR's foundational semantic vocabulary.

It establishes:

- canonical terms;
- semantic meanings;
- relations;
- distinctions;
- foundational laws;
- external evidence;
- formalization mappings;
- provenance.

It does not replace domain specifications.

## Authority

1. SCR normative semantic specifications define SCR meaning.
2. The Seed provides the vocabulary used by those specifications.
3. Lean formalization establishes mechanically checked properties for the portion explicitly formalized.
4. External sources provide evidence and interoperability context, but do not acquire SCR semantic authority.

## Core distinction

> The Seed defines the language in which SCR semantics are expressed; `lib/` defines the domain semantics expressed in that language.

## Initial semantic kernel

The initial formal kernel contains:

- `SemanticField`
- `EntityId`
- `Identity`
- `Value`
- `Entity`
- `Relationship`
- `State`
- `Context`
- `Operation`
- `Transformation`
- `Transition`
- `Validity`
- `Determinism`
- `Equivalence`

## Canonical distinctions

- Semantic Entity ≠ Representation
- Identity ≠ Storage identity
- State ≠ Storage
- Relationship ≠ Pointer
- Geometry ≠ Topology
- Morphology ≠ Mesh
- Information ≠ Data
- Provider ≠ Semantic Authority
- Execution ≠ Semantic Meaning
- Observation ≠ Rendering
- Semantic Field ≠ Hypergraph representation
- Semantic type ≠ implementation class

## Seed update rule

Before introducing a new semantic term, operation, type, capability, relationship, or abstraction:

1. search the Seed;
2. identify existing concepts with overlapping meaning;
3. prefer reuse, refinement, specialization, or composition;
4. introduce a new concept only when existing vocabulary is semantically insufficient;
5. record the distinction and rationale when a new term is introduced.
