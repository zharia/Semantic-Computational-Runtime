---

document: 101_definition
document_type: normative_semantic_definition
schema_version: 1.0.0

id: SCR-LIB-DYNAMICS-NONLINEAR
name: Dynamics Nonlinear

version: 0.1.0
status: operational

created: 2026-09-05
updated: 2026-09-16

parent: SCR-LIB-DYNAMICS
authority: SCR
domain: semantic-library
---

# SCR Dynamics: Nonlinear

## Summary

Systems violating superposition, exhibiting complex phenomena such as multi-stability and chaos.

---

## 1. Semantic Definition

**Nonlinear** is a first-class subdomain of SCR Dynamics (`SCR-LIB-DYNAMICS`). It defines systems violating superposition, exhibiting complex phenomena such as multi-stability and chaos.

Dynamics defines state evolution independently of transient numerical solvers, graphics engines, or hardware acceleration substrates.

## 2. Invariant Conformance

All operations within `Nonlinear` MUST adhere to the normative invariants of `SCR-LIB-DYNAMICS`:

- **DYNAMICS-INV-001 (Semantic Primacy)**: Dynamical meaning is authoritative and independent of solver implementations.
- **DYNAMICS-INV-002 (State Integrity)**: Semantic state remains distinct from implementation-level memory representations.
- **DYNAMICS-INV-003 (Transition Integrity)**: State transitions preserve declared semantic evolution laws.
- **DYNAMICS-INV-004 (Temporal Integrity)**: Temporal ordering and relationships remain explicit.
- **DYNAMICS-INV-010 (Delta Integrity)**: State transitions produce valid semantic state deltas.
- **DYNAMICS-INV-011 (History Integrity)**: Trajectory history and provenance remain recoverable.
- **DYNAMICS-INV-018 (Runtime Independence)**: Dynamical semantics remain independent of host runtime and hardware substrates.

## 3. Relationships to Other Domains

- **lib/101_Core/Identity**: Supplies canonical `SemanticId` identifiers for dynamical systems, states, and trajectories.
- **lib/202_Math**: Provides calculus, linear algebra, vector fields, and numerical analysis infrastructure.
- **lib/203_Graph/Hypergraph**: Provides the canonical hypergraph representation for transition graphs and causal dependencies.
- **lib/501_Physics**: Supplies physical equations of motion, forces, and conservation laws.

---

# Definition Authority

This document establishes the normative semantic meaning of `Nonlinear` in SCR Dynamics. Numerical engines, solvers, and simulation runtimes are subordinate to the contracts specified herein.
