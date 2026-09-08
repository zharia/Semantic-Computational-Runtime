# 07 — Interfaces, Operations, Determinism, Equivalence, Invariants

---

## Interfaces and Capabilities

Reusable computational capabilities should be represented through explicit interfaces where appropriate.

Examples include:

```
Dynamical
Spatial
Temporal
Differentiable
Parallelizable
Vectorizable
Tileable
Reducible
Integrable
Stateful
Stateless
Streamable
Renderable
Distributable
Deterministic
Stochastic
Composable
Serializable
Persistable
Observable
Controllable
Optimizable
Learnable
Morphological
```

Interfaces should enable generic reasoning across domains.

Do not duplicate domain-specific implementations of capabilities that are already represented by an appropriate shared interface.

Conversely, do not force unrelated concepts into a shared interface merely because their names appear similar.

---

## Functions and Operations

Every meaningful function or operation should have an explainable semantic contract.

Consider:

```
Purpose
Inputs
Outputs
Preconditions
Postconditions
Invariants
Errors
Determinism
Side Effects
State Changes
Ownership
Lifecycle
Composition
Performance Characteristics
```

For MLIR operations additionally consider:

```
Operands
Results
Attributes
Regions
Types
Traits
Interfaces
Verification
Canonicalization
Lowering
Effects
```

If behavior cannot be explained semantically, stop and investigate.

---

## Determinism

Every meaningful computational operation must explicitly consider determinism.

Classify behavior as:

```
Deterministic
Conditionally Deterministic
Stochastic
Nondeterministic
```

Where relevant, document:

```
Source of nondeterminism
Seed/control mechanism
Reproducibility expectations
Equivalence criteria
Parallelism effects
Hardware-dependent behavior
```

Do not assume:

```
Mathematical equivalence
        =
Numerical equivalence
        =
Bitwise equivalence
```

They are distinct guarantees.

---

## Semantic Equivalence

Do not equate:

```
same output on one test
```

with:

```
semantic equivalence
```

Possible equivalence levels include:

```
Exact
Numerical
Approximate
Distributional
Behavioral
Contractual
```

When replacing one implementation with another, determine which level the contract requires.

An optimization or provider substitution is valid only if the applicable semantic guarantees remain satisfied.

---

## Invariants

Semantic correctness is defined by invariants, not merely plausible output.

Consider where applicable:

```
Domain Invariants
Identity Invariants
Type Invariants
State Invariants
Temporal Invariants
Causal Invariants
Geometric Invariants
Topological Invariants
Physical Invariants
Conservation Laws
Ordering Invariants
Determinism Invariants
Lifecycle Invariants
Resource Invariants
```

When implementing a transformation, explicitly identify which invariants it must preserve.
