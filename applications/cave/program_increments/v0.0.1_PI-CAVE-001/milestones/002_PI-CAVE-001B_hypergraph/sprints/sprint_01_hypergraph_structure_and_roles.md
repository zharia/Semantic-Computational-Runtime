# Sprint 01: Hypergraph Structure & Relational Roles

**Parent Milestone:** [Milestone 002: PI-CAVE-001B Semantic Hypergraph](../spec.md)  
**Derived from:** `spec.md` (Sections 6, 30, 31)  
**Governing Documents:** [`docs/112_STC_GRAPH_RELATIONAL_REFINEMENT.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/docs/112_STC_GRAPH_RELATIONAL_REFINEMENT.md)  
**Status:** Planned  

---

## 1. Mission

Implement the core data structures of the SCR Semantic Hypergraph in Mojo, supporting directed, typed hyperedges with named endpoints and relational roles to represent complex multi-entity spatial and computational relationships.

---

## 2. Technical Specifications & Data Models

### 2.1 Hypergraph Primitives
```mojo
@value
struct Role:
    var name: String
    
    alias CONTAINER = Role("container")
    alias MEMBER = Role("member")
    alias PARENT_FRAME = Role("parent_frame")
    alias CHILD_FRAME = Role("child_frame")
    alias SOURCE_BUFFER = Role("source_buffer")
    alias TARGET_SURFACE = Role("target_surface")
    alias INFLUENCE_FIELD = Role("influence_field")

@value
struct HyperEndpoint:
    var node_id: SemanticId
    var role: Role
    var is_source: Bool

struct HyperEdge:
    var id: SemanticId
    var edge_type: String
    var endpoints: List[HyperEndpoint]
    var attributes: Dict[String, String]

struct SemanticHypergraph:
    var nodes: Dict[SemanticId, SemanticObject]
    var edges: Dict[SemanticId, HyperEdge]
    var incidence_index: Dict[SemanticId, List[SemanticId]] # Node -> Incident Edge IDs
```

### 2.2 Relational Semantics
* **Multi-Arity:** A single hyperedge can connect $k \ge 1$ endpoints. For example, a `SurfaceAttachmentRelation` connects:
  - `(Workspace, CONTAINER)`
  - `(Surface, MEMBER)`
  - `(Application, OWNER)`
  - `(SpatialTransform, GEOMETRY)`
* **Role Invariance:** Every endpoint in a hyperedge must possess an explicit `Role`. Endpoints are never untyped positional parameters.

---

## 3. Verification & Invariants

1. **Incidence Completeness:** Verify that every endpoint node in an active edge exists in `nodes`.
2. **Bidirectional Index Consistency:** Verify that `node_id in edge.endpoints` strictly mirrors `edge.id in incidence_index[node_id]`.
3. **Role Validation:** Enforce role constraints specified by the `edge_type` schema.
