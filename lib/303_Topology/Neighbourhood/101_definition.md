---

document: 101_definition
document_type: normative_semantic_definition
schema_version: 1.0.0

id: SCR-LIB-TOPOLOGY-NEIGHBOURHOOD
name: Topology Neighbourhood

version: 0.1.0
status: operational

created: 2026-09-05
updated: 2026-09-16

parent: SCR-LIB-TOPOLOGY
authority: SCR
domain: semantic-library
---

# SCR Topology: Neighbourhood

## Summary

Topological neighbourhood structures defining local context — the fundamental basis for continuity and convergence.

---

## 1. Semantic Definition

A **neighbourhood** of a point x in a topological space X is a subset N ⊆ X such that x belongs to the interior of N.

Neighbourhoods define local topological structure and are fundamental to:

- continuity;
- convergence;
- limit points;
- closures and interiors.

## 2. Neighbourhood Systems

A neighbourhood system at x is the collection of all neighbourhoods of x. The neighbourhood system satisfies:

- x ∈ every neighbourhood of x;
- intersection of two neighbourhoods of x is a neighbourhood of x;
- any superset of a neighbourhood is a neighbourhood.

## 3. Neighbourhood ≠ Metric Ball

```
Neighbourhood ≠ Ball of radius r
Neighbourhood ≠ Bounding Box
Neighbourhood ≠ Pixel Window
```

A metric ball provides one family of neighbourhoods in a metric space, but topology does not require a metric.

## 4. Open Sets and Neighbourhoods

The topology τ on X and the neighbourhood systems are equivalent representations:
- N is a neighbourhood of x iff N contains an open set containing x.

## 5. Invariants

- **TOPOLOGY-INV-005**: Continuity integrity depends on correct neighbourhood semantics.
- **TOPOLOGY-INV-015**: Neighbourhood structure is metric-independent in general topology.

---

# Definition Authority

This document defines the normative semantic meaning of the **Neighbourhood** subdomain of SCR Topology.

Conforming implementations MUST satisfy the semantic contracts established here.

Representation, storage, and provider choices MUST NOT redefine these semantics.

---

# Definition Principle

> **Neighbourhood is a topological concept whose meaning is authoritative. Implementation, representation, and computational substrate are subordinate to this semantic definition.**
