# 14 — Vertical Slices and Minimal Implementation

---

## Vertical Slices Over Broad Stubs

Do not attempt to implement the entire SCR library because the directory tree contains many domains.

Prefer an executable vertical slice.

The current architectural direction is:

```
Semantic Definition
       ↓
Semantic Model
       ↓
SCR Semantic MLIR
       ↓
MLIR Infrastructure
       ↓
Transformation / Lowering
       ↓
CPU Execution
       ↓
Simulation State
       ↓
Render State
       ↓
Rendering
       ↓
Visible Result
```

The v0.0.1 Golden Path is authoritative for the current vertical milestone.

Do not treat the existence of hundreds of semantic directories as a requirement to implement them all.

---

## Minimal Implementation Principle

When implementing a new capability:

> **Implement the smallest semantically complete vertical slice that proves the contract.**

Do not begin with:

- speculative abstractions;
- generalized frameworks;
- unused providers;
- premature optimization;
- comprehensive backend support;
- complete domain coverage.

First establish:

```
Meaning
 ↓
Contract
 ↓
Representation
 ↓
Execution
 ↓
Validation
```

Then generalize when evidence requires it.
