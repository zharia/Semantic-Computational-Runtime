# Milestone 002: PI-CAVE-001B — Semantic Hypergraph Carrier

**Parent RoadMap:** [milestones/README.md](../README.md)  
**Target Area:** `applications/cave/program_increments/v0.0.1_PI-CAVE-001/milestones/002_PI-CAVE-001B_hypergraph/`  
**Derived from:** `spec.md` (Sections 6, 7, 30, 31, 34, 50, 72)  
**Governing Documents:** [`docs/112_STC_GRAPH_RELATIONAL_REFINEMENT.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/docs/112_STC_GRAPH_RELATIONAL_REFINEMENT.md), [`docs/115_EXECUTABLE_SEMANTIC_HYPERGRAPH.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/docs/115_EXECUTABLE_SEMANTIC_HYPERGRAPH.md)  
**Status:** Planned  

---

## 1. Objective

Implement the **Semantic Hypergraph** as the primary relational and operational carrier for the Cave spatial desktop. The hypergraph represents entities, typed multi-entity relations with explicit roles, nullary environmental contexts, and dynamic frame dependencies, serving as the executable graph structure for the runtime.

---

## 2. Compliance with Authoritative Architecture

1. **Hypergraph Relational Model ([`docs/112_STC_GRAPH_RELATIONAL_REFINEMENT.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/docs/112_STC_GRAPH_RELATIONAL_REFINEMENT.md)):**
   Relationships in Cave are not restricted to binary edges. Spatial containment, event dispatch, and volumetric effects connect multiple entities simultaneously through directed, typed hyperedges with named roles.
2. **Nullary Relations:**
   Environmental properties (e.g. ambient lighting, field gravity, desktop-wide visual theme) that apply globally without targeting specific entities must be expressed as nullary hyperedges ($\text{arity} = 0$).
3. **Executable Hypergraph ([`docs/115_EXECUTABLE_SEMANTIC_HYPERGRAPH.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/docs/115_EXECUTABLE_SEMANTIC_HYPERGRAPH.md)):**
   The hypergraph is executable: operational hyperedges represent dependencies that trigger state transitions during frame composition.

---

## 3. Sprint Breakdown

```text
002_PI-CAVE-001B_hypergraph/
├── spec.md
└── sprints/
    ├── sprint_01_hypergraph_structure_and_roles.md   # Directed typed hyperedges, endpoints, roles
    ├── sprint_02_nullary_relations.md                # Nullary relations for global environment/context
    ├── sprint_03_mutation_and_traversal.md           # Atomic mutation, topological evaluation engine
    └── sprint_04_hypergraph_conformance.md           # Conformance test suite & structural invariants
```

### [Sprint 01: Hypergraph Structure & Relational Roles](sprints/sprint_01_hypergraph_structure_and_roles.md)
- Implement `HyperNode` (entities, attributes) and `HyperEdge` (directed, typed multi-endpoint links).
- Implement explicit relational roles: `CONTAINER`, `MEMBER`, `PARENT_FRAME`, `CHILD_FRAME`, `SOURCE_BUFFER`, `TARGET_SURFACE`, `INFLUENCE_FIELD`.
- Implement incidence functions mapping hyperedges to ordered sequences of $(role, node)$ pairs.

### [Sprint 02: Nullary Relations & Context Hyperedges](sprints/sprint_02_nullary_relations.md)
- Formalize nullary relations ($\text{arity} = 0$) within the hypergraph schema.
- Represent desktop-wide ambient context: global illumination, gravity vector, spatial coordinate base units, and rendering quality profiles as nullary hyperedges.

### [Sprint 03: Hypergraph Mutation & Traversal Engine](sprints/sprint_03_mutation_and_traversal.md)
- Implement atomic mutation operations: `add_node`, `remove_node`, `connect_hyperedge`, `disconnect_hyperedge`.
- Implement topological traversal, role-filtered neighborhood queries, and frame dependency extraction.
- Implement frame hypergraph snapshotting.

### [Sprint 04: Hypergraph Conformance & Invariant Suite](sprints/sprint_04_hypergraph_conformance.md)
- Implement test suite for hypergraph structural invariants:
  - Role uniqueness per hyperedge instance where required.
  - Dangling edge prevention.
  - Cycle detection for spatial transformation subgraphs.
  - Nullary relation cardinality validation.

---

## 4. Milestone Exit Criteria

1. Complete Mojo implementation of the Semantic Hypergraph carrier.
2. Full support for arbitrary arity ($k \ge 0$) hyperedges, including nullary ($k=0$) and n-ary relations.
3. Topological traversal and role queries pass automated benchmarks.
4. Conformance suite passes with zero structural invariant violations.
