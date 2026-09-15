# Sprint 03: Hypergraph Mutation & Traversal Engine

**Parent Milestone:** [Milestone 002: PI-CAVE-001B Semantic Hypergraph](../spec.md)  
**Derived from:** `spec.md` (Sections 30, 31, 34)  
**Governing Documents:** [`docs/115_EXECUTABLE_SEMANTIC_HYPERGRAPH.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/docs/115_EXECUTABLE_SEMANTIC_HYPERGRAPH.md)  
**Status:** Planned  

---

## 1. Mission

Implement atomic mutation operations and topological query/traversal algorithms for the Semantic Hypergraph, enabling dynamic frame construction, relationship evolution, and operational dependency ordering.

---

## 2. Technical Specifications

### 2.1 Atomic Mutation Interface
All hypergraph modifications are atomic transitions returning a new immutable snapshot or executing in a transactional boundary:
```mojo
trait HypergraphMutator:
    fn insert_node(mut self, node: SemanticObject) raises -> SemanticId
    fn remove_node(mut self, node_id: SemanticId) raises
    fn add_hyperedge(mut self, edge: HyperEdge) raises -> SemanticId
    fn remove_hyperedge(mut self, edge_id: SemanticId) raises
    fn mutate_endpoint_role(mut self, edge_id: SemanticId, node_id: SemanticId, new_role: Role) raises
```

### 2.2 Cascading Removal Semantics
* When a node is removed:
  - All hyperedges where this node was a mandatory participant must be removed or transitioned to a degraded state.
  - Sibling nodes in the hyperedge are notified of the relational transition.

### 2.3 Traversal & Query Algorithms
* **`find_by_role(node_id, role)`:** Returns all nodes connected to `node_id` via a hyperedge where the target fulfills `role`.
* **`extract_dependency_order()`:** Computes a topological sort over operational hyperedges, ensuring that buffer generation precedes surface composition, which precedes rendering.
* **`subgraph_by_domain(domain_id)`:** Extracts a filtered projection of the hypergraph belonging to a specific workspace or effect domain.

---

## 3. Verification & Testing Tasks

1. **Transaction Atomicity:** Verify that a failed multi-node insertion rolls back completely without leaving orphaned edges.
2. **Topological Sorter Benchmarks:** Test dependency sorting on a 100-node hypergraph; verify $O(V + E)$ performance.
3. **Cycle Rejection:** Verify that cyclic spatial containment relationships (e.g. Surface A inside Surface B inside Surface A) are rejected.
