# 01 — Philosophy, Identity, Authority Model, Source-of-Truth

---

## Purpose

This document defines how AI coding agents must operate within the Semantic Computational Runtime (SCR) repository.

It is an **agent control-plane document**.

It defines:

- how agents discover the architecture;
- how agents determine authority;
- how agents scope work;
- how agents modify semantic definitions and implementations;
- how agents validate changes;
- when agents must stop and escalate ambiguity.

It does **not** attempt to define every SCR semantic domain.

Normative semantic definitions belong in the semantic library and associated specifications.

> **AGENTS.md defines how an agent works on SCR. It does not define what SCR's domains mean.**

---

## SCR Identity

SCR is an:

> **MLIR-based Language Runtime for Computational Semantics.**

Its purpose is to provide a common semantic environment in which heterogeneous computational domains can be represented through explicit semantic contracts and compiled into implementations across heterogeneous execution substrates.

The conceptual execution architecture is:

```
Application
    ↓
Semantic API / Frontend
    ↓
Semantic Library
    ↓
Semantic Model
    ↓
SCR Semantic MLIR
    ↓
MLIR Infrastructure
    ↓
Analysis / Transformation
    ↓
Provider Selection
    ↓
Lowering
    ↓
Runtime
    ↓
Execution Substrate
```

Execution substrates may include:

```
CPU
GPU
Accelerator
External Library
Distributed System
Specialized Hardware
```

The implementation substrate may change.

The semantic contract must not silently change with it.

---

## Governing Principle

SCR separates:

```
Semantic Meaning
      ↓
Semantic Contract
      ↓
Representation
      ↓
Transformation
      ↓
Lowering
      ↓
Provider
      ↓
Runtime
      ↓
Execution Substrate
```

These are different architectural layers.

Do not collapse them.

In particular:

```
Specification ≠ Implementation
Status ≠ Specification
Graph ≠ Source of Truth
Representation ≠ Concept
Provider ≠ Semantic Authority
Backend ≠ Semantic Meaning
Filesystem ≠ Semantic Architecture
```

The governing rule is:

> **Never allow implementation convenience to silently redefine computational semantics.**

---

## Agent Authority Model

Agents must distinguish three classes of information.

### Normative

Defines what SCR means.

Examples:

- semantic definitions;
- explicit contracts;
- invariants;
- formally specified operations;
- architecture specifications;
- approved interface contracts.

Normative material has authority over implementation.

### Descriptive

Describes current engineering reality.

Examples:

- implementation status;
- known limitations;
- blockers;
- current provider availability;
- build state;
- test state.

Descriptive material must not redefine semantics.

### Derived

Generated from authoritative information.

Examples:

- relationship graphs;
- indexes;
- generated manifests;
- derived metadata;
- dependency views.

Derived artifacts must not silently become independent authorities.

---

## Source-of-Truth Hierarchy

When sources conflict, resolve them in this order:

```
1. Normative project architecture/specification
2. Parent semantic domain definition
3. Child semantic domain definition
4. Explicit interface/contract specification
5. Specification tests
6. Current implementation
7. Comments
8. Documentation/examples
9. Agent assumptions
```

For semantic-library control-plane files:

```
101_definition.md
    ↓
normative meaning

102_status.yaml
    ↓
current engineering state

103_library.graph.json
    ↓
derived relationships
```

Therefore:

> `101_definition.md` may invalidate an implementation.

> `102_status.yaml` may describe an incomplete implementation.

> `103_library.graph.json` may expose relationships but does not establish semantic authority.

Never reverse these relationships.

---

## Semantic Definitions Are Authoritative

A semantic definition describes what a domain means.

It may specify:

- purpose;
- scope;
- primitives;
- entities;
- values;
- operations;
- state;
- transitions;
- invariants;
- relationships;
- constraints;
- errors;
- composition;
- interfaces;
- representation requirements;
- runtime semantics;
- provider contracts;
- validation requirements.

A semantic definition is not an implementation plan.

Do not introduce implementation details into a semantic definition merely because they are convenient.

For example:

```
Physics ≠ Chrono
Field ≠ Tensor
Position ≠ Rust struct
Rendering ≠ Vulkan
```

Implementation technologies may realize semantic contracts. They do not define them.

---

## Status Is Not Semantics

`102_status.yaml` describes the current state of implementation.

It may record:

- planned;
- specified;
- designed;
- partially implemented;
- implemented;
- tested;
- validated;
- blocked;
- deprecated.

Agents must not mark something as implemented merely because:

- a directory exists;
- a type exists;
- a stub compiles;
- an interface exists;
- documentation describes it;
- a test fixture exists;
- an external dependency provides equivalent functionality.

Implementation status requires evidence.

When status and implementation disagree, investigate the discrepancy rather than silently changing the status.
