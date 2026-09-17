---

document: 101_definition
document_type: normative_semantic_definition
schema_version: 1.0.0

id: SCR-LIB-TOPOLOGY-IR
name: Topology IR

version: 0.1.0
status: operational

created: 2026-09-05
updated: 2026-09-16

parent: SCR-LIB-TOPOLOGY
authority: SCR
domain: semantic-library
---

# SCR Topology: IR

## Summary

MLIR dialect interfaces and IR representations for topological semantics and compiler lowering pipelines.

---

## 1. Semantic Definition

The **Topology IR** subdomain defines the MLIR dialect interfaces, operations, and types through which topological semantics are represented in the SCR compiler infrastructure.

```
Topological Semantics
       ↓
  SCR Topology MLIR Dialect
       ↓
  Lowering Passes
       ↓
  Target Execution
```

## 2. MLIR-First Policy

Per the SCR MLIR-First Policy:

- MLIR is the sole canonical compiler IR;
- SCR does not maintain a parallel IR;
- topology-specific operations SHOULD be expressed as MLIR operations.

MLIR does not define topological semantics. It carries them.

## 3. Topological Operations in MLIR

Topology IR MAY provide:

- type representations for topological structures (complexes, spaces, manifolds);
- operations for connectivity queries;
- operations for boundary computation;
- operations for topological predicates;
- transformations expressed as MLIR passes;
- lowering to accelerated backends.

## 4. Invariants

- **TOPOLOGY-INV-014**: Representation Independence — MLIR representation MUST NOT redefine topological meaning.
- **TOPOLOGY-INV-016**: Provider Independence — MLIR backend substitution MUST preserve the semantic contract.

## 5. Notes

The SCR MLIR-First Policy forbids parallel IRs. Topology IR MUST be implemented as MLIR dialect infrastructure, not as a standalone data format.

---

# Definition Authority

This document defines the normative semantic meaning of the **IR** subdomain of SCR Topology.

Conforming implementations MUST satisfy the semantic contracts established here.

Representation, storage, and provider choices MUST NOT redefine these semantics.

---

# Definition Principle

> **IR is a topological concept whose meaning is authoritative. Implementation, representation, and computational substrate are subordinate to this semantic definition.**
