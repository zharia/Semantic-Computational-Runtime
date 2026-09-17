---

document: 101_definition
document_type: normative_semantic_definition
schema_version: 1.0.0

id: SCR-LIB-TOPOLOGY-CELL
name: Topology Cell

version: 0.1.0
status: operational

created: 2026-09-05
updated: 2026-09-16

parent: SCR-LIB-TOPOLOGY
authority: SCR
domain: semantic-library
---

# SCR Topology: Cell

## Summary

Atomic building block of a cell complex — a topological region homeomorphic to an open ball of a given dimension.

---

## 1. Semantic Definition

A **cell** is a topological element homeomorphic to an open n-ball for some dimension n. Cells are the atomic building blocks of cell complexes.

```
0-cell → point
1-cell → open arc
2-cell → open disk
3-cell → open ball
```

## 2. Cell Attachment

Cells are attached to lower-dimensional cells via attaching maps. Attaching maps define the boundary of a cell in terms of lower-dimensional cells.

## 3. Cell Semantics

A cell:

- has a well-defined dimension;
- has a boundary consisting of lower-dimensional cells;
- belongs to exactly one cell complex when indexed;
- MUST NOT redefine its dimension through representation choices.

## 4. CW Structure

A CW complex organises cells such that:

- each cell has an explicit attaching map;
- the closure of each cell intersects only finitely many other cells;
- the topology is the weak topology determined by cells.

## 5. Invariants

- **TOPOLOGY-INV-003**: Incidence integrity applies across cells.
- **TOPOLOGY-INV-004**: Boundary of each cell MUST be a union of lower-dimensional cells.

---

# Definition Authority

This document defines the normative semantic meaning of the **Cell** subdomain of SCR Topology.

Conforming implementations MUST satisfy the semantic contracts established here.

Representation, storage, and provider choices MUST NOT redefine these semantics.

---

# Definition Principle

> **Cell is a topological concept whose meaning is authoritative. Implementation, representation, and computational substrate are subordinate to this semantic definition.**
