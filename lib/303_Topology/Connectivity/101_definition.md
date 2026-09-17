---

document: 101_definition
document_type: normative_semantic_definition
schema_version: 1.0.0

id: SCR-LIB-TOPOLOGY-CONNECTIVITY
name: Topology Connectivity

version: 0.1.0
status: operational

created: 2026-09-05
updated: 2026-09-16

parent: SCR-LIB-TOPOLOGY
authority: SCR
domain: semantic-library
---

# SCR Topology: Connectivity

## Summary

Topological connectivity — connected components, path connectivity, and structural reachability within topological spaces.

---

## 1. Semantic Definition

**Connectivity** describes whether elements of a topological structure can be joined by a path or belong to the same connected component.

Connectivity is:

- **not** geometric proximity — two regions may be spatially close but topologically disconnected;
- **not** graph edge count — graph reachability approximates but does not define topological connectivity;
- **not** array contiguity — memory layout does not determine connectivity.

## 2. Connected Components

A topological space X decomposes into maximal connected subsets: its connected components.

- each element belongs to exactly one component;
- components may merge (topology change);
- components may split (topology change).

Component transitions MUST be represented as explicit semantic topology changes.

## 3. Path Connectivity

A space is **path-connected** if any two points can be joined by a continuous path within the space.

Path connectivity implies connectivity but connectivity does not imply path connectivity in general.

## 4. Simple Connectivity

A space is **simply connected** if it is path-connected and every loop can be continuously contracted to a point.

## 5. Invariants

- **TOPOLOGY-INV-002**: Connectivity integrity MUST be maintained.
- **TOPOLOGY-INV-009**: Component membership MUST remain consistent with connectivity semantics.

---

# Definition Authority

This document defines the normative semantic meaning of the **Connectivity** subdomain of SCR Topology.

Conforming implementations MUST satisfy the semantic contracts established here.

Representation, storage, and provider choices MUST NOT redefine these semantics.

---

# Definition Principle

> **Connectivity is a topological concept whose meaning is authoritative. Implementation, representation, and computational substrate are subordinate to this semantic definition.**
