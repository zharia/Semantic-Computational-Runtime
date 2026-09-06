# Semantic Types

## 1. Principle

A semantic type defines what values mean and which operations and relationships are valid. It is not equivalent to a host-language type or machine storage type.

## 2. Type components

A semantic type may define:

- domain;
- identity rules;
- admissible values;
- units and dimensions;
- structural shape;
- invariants;
- operations;
- relationships;
- transformations;
- representations;
- observational properties.

## 3. Refinement

A type `B` refines `A` when every valid instance of `B` is valid under the contract of `A` and the additional constraints are explicit.

Refinement MUST preserve semantic substitutability unless the specification explicitly declares a variance boundary.

## 4. Structural and nominal identity

SCR permits semantic identity to be established through structural contracts, nominal declarations, or both. Machine layout MUST NOT be treated as semantic identity.

## 5. Capabilities

Capabilities describe participation in transformations or relationships. Examples include `Transformable`, `Observable`, `Stateful`, `Spatial`, `Temporal`, `Streamable`, `Renderable`, `Distributable`, `Differentiable`, and `Morphological`.

Capabilities are contracts, not class inheritance requirements.

## 6. Type erasure

A runtime MAY erase implementation-level type information when the semantic contract remains recoverable or preserved by another mechanism.
