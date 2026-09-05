# Semantic Computation

Semantic computation is computation in which the meaning of computational objects and operations is explicit enough to support analysis, transformation, verification, composition, and execution.

## Meaning, representation, implementation

SCR distinguishes:

```text
Semantic Meaning
        ≠
Language Representation
        ≠
IR Representation
        ≠
Memory Representation
        ≠
Device Representation
```

A semantic object may therefore have many valid representations.

For example, a position may exist as:

- a semantic position;
- a domain-level value;
- an MLIR value;
- a Rust structure;
- a GPU buffer;
- a renderer resource.

These representations can participate in one computation without becoming semantically identical.

## Semantic objects

The SCR model may include:

- values;
- entities;
- relationships;
- state;
- operations;
- events;
- fields;
- graphs;
- streams;
- patterns;
- morphology;
- capabilities;
- constraints;
- resources;
- observations.

## A simple semantic operation

Consider:

```text
step(state, dt) → state'
```

At the semantic level, this expresses a state transition.

The implementation might use a numerical integrator, vectorized CPU code, GPU code, or another mechanism.

The implementation can vary while the semantic contract remains stable.

## Why this matters

A compiler can only reason about properties that remain available to it.

If meaning disappears immediately into opaque implementation calls, later compilation stages can no longer reliably reason about the computation.

SCR therefore attempts to retain semantic information for as long as it is useful.

## Semantic computation as a compilation substrate

The resulting architecture is:

```text
Meaning
  ↓
Contract
  ↓
Representation
  ↓
Analysis
  ↓
Transformation
  ↓
Implementation
  ↓
Execution
```

The goal is not to prevent lowering. The goal is to delay irreversible implementation decisions until the compiler has extracted the useful semantic consequences of the higher-level description.
