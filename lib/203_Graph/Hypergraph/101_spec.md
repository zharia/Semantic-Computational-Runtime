# SCR Semantic Hypergraph Specification

**Document ID:** `SCR-LIB-SPEC-203-HG`  
**Domain:** `203_Graph`  
**Subdomain:** `Hypergraph`  
**Status:** Normative Specification  
**Version:** 0.1.0  
**Governing Documents:** [`docs/103_SEMANTIC_MODEL.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/docs/103_SEMANTIC_MODEL.md), [`docs/112_STC_GRAPH_RELATIONAL_REFINEMENT.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/docs/112_STC_GRAPH_RELATIONAL_REFINEMENT.md), [`docs/115_EXECUTABLE_SEMANTIC_HYPERGRAPH.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/docs/115_EXECUTABLE_SEMANTIC_HYPERGRAPH.md)  
**Parent Task:** HGT-001  

---

## 1. Foundational Principle

> **Hypergraph semantics precede Graph semantics. Graph is a specialization or projection of hypergraph topology, not the foundation underneath it.**

The Semantic Computational Runtime organizes entities, fields, relationships, transformations, and execution flows as a generalized topological hypergraph.

---

## 2. Mathematical Definition

A Semantic Hypergraph $\mathcal{H}$ is defined as the quadruple:
$$\mathcal{H} = (E, R, I, \rho)$$

where:
* $E = \{e_1, e_2, \dots\}$ is the set of **Elements** (semantic entities, states, or concepts).
* $R = \{r_1, r_2, \dots\}$ is the set of **Relations** (higher-order associative connections).
* $I = \{i_1, i_2, \dots\}$ is the set of **Incidences**, where each incidence $i = (e, r) \in E \times R$ connects an Element to a Relation.
* $\rho: I \to \text{Role} \times \text{Direction}$ is the semantic assignment mapping each incidence to its relational **Role** and **Direction**.

---

## 3. First-Class Semantic Objects

### 3.1 Element ($E$)
An Element represents an independent semantic object with:
* Unique Semantic Identifier ($\text{ElementId} \in \text{SID}$).
* Semantic State Vector ($V \in \mathcal{S}$).
* Content Hash ($\text{SHA-256}(V)$).
* Set of incident relations $\text{incidences}(e) \subset I$.

### 3.2 Relation ($R$)
A Relation represents an association among zero or more Elements:
* Unique Semantic Identifier ($\text{RelationId} \in \text{SID}$).
* Set of incident connections $I(r) = \{i \in I \mid \text{relation}(i) = r\}$.
* **Arbitrary Cardinality:** The degree of a relation $|I(r)|$ is unconstrained ($\ge 0$).
* **Distinct Identity:** Two relations $r_1, r_2 \in R$ are distinct ($r_1 \ne r_2$) even if they connect identical participant sets with identical roles.

### 3.3 Incidence ($I$)
An Incidence is **not** an array index or implicit pointer; it is a first-class semantic entity:
* Unique Semantic Identifier ($\text{IncidenceId} \in \text{SID}$).
* Link to Element $e \in E$ and Relation $r \in R$.
* Relational Role ($\text{Role} \in \{\text{Input}, \text{Output}, \text{Parameter}, \text{Subject}, \text{Object}, \text{Operand}, \text{Constraint}, \text{Cause}, \text{Effect}, \dots\}$).
* Direction ($\text{Direction} \in \{\text{Undirected}, \text{Ingoing}, \text{Outgoing}\}$).

---

## 4. Normative Nullary Relation Policy

In strict accordance with HGT-001 amendments:
1. **Valid Semantic State:** A relation with zero incidences ($|I(r)| = 0$) is valid SCR semantic state. It represents an asserted proposition, global ambient environmental factor (e.g. gravity, lighting), or a relation awaiting participant attachment.
2. **Identity Autonomy:** Nullary relations have independent identities:
   $$r_1 \ne r_2 \quad \text{even if} \quad I(r_1) = \emptyset \land I(r_2) = \emptyset$$
3. **Dynamic Mutation:** A nullary relation may transition to unary or n-ary by attaching an incidence without altering its persistent $\text{RelationId}$.
4. **Provider Protection:** If an external provider cannot store zero-degree hyperedges, the provider adapter must encapsulate it; provider limitations must never redefine SCR semantics.

---

## 5. Projections & Graph Specializations

Ordinary graph structures $(V, E_{\text{graph}})$ are defined strictly as projections or specializations:
1. **Ordinary Binary Graph Specialization:**
   A hypergraph $\mathcal{H}$ specializes to an ordinary graph if and only if:
   $$\forall r \in R, \quad |I(r)| = 2 \quad \text{and} \quad \text{roles}(I(r)) = \{\text{Source}, \text{Target}\}$$
2. **Bipartite Graph Projection:**
   Hypergraph $\mathcal{H} = (E, R, I, \rho)$ maps isomorphically to a bipartite graph $G = (V_E \cup V_R, E_I)$ where edges connect Elements to Relations.
3. **Clique / Line Graph Projection:**
   Hyperedges are expanded into 2-cliques connecting all pairwise participant elements. This projection **discloses information loss** (loses relation identity and higher-order multi-way association).

---

## 6. Normative Invariants

* **HYPERGRAPH-I001 (Identity Independence):** Semantic identity is independent of provider storage addresses, array indices, or CSR offsets.
* **HYPERGRAPH-I002 (Relation Autonomy):** Distinct relations remain distinct regardless of participant equality.
* **HYPERGRAPH-I003 (First-Class Incidence):** Incidences are first-class entities with persistent identities.
* **HYPERGRAPH-I004 (Unconstrained Cardinality):** $|I(r)| \in [0, \infty)$ is valid.
* **HYPERGRAPH-I005 (Role/Direction Independence):** Roles and directions are semantic attributes, not positional artifacts of memory layout.
* **HYPERGRAPH-I006 (Representation Independence):** Changing layout (e.g. CSR $\leftrightarrow$ Adjacency Map) does not alter semantic state.
* **HYPERGRAPH-I007 (Provider Independence):** Replacing a provider does not redefine hypergraph topology or identity.
* **HYPERGRAPH-I008 (Projection Explicitness):** Every projection must formally disclose information loss and reversibility.
* **HYPERGRAPH-I009 (Provenance Preservation):** All graph mutations preserve lineage and audit trails.
* **HYPERGRAPH-I010 (Boundary Isolation):** Provider-specific storage types never leak into the public semantic API.
* **HYPERGRAPH-I011 (Nullary Validity):** A Relation with zero Incidences ($|I(R)| = 0$) is valid semantic state.
* **HYPERGRAPH-I012 (Incidence Independence):** Deleting an Incidence does not delete its connected Element or Relation.
* **HYPERGRAPH-I013 (Relation Lifecycle Independence):** A Relation remains semantically existent when its final Incidence is detached unless the Relation itself is explicitly deleted.
* **HYPERGRAPH-I014 (Element Lifecycle Independence):** Deleting an Element cascades to detach/delete its incident Incidences, but never deletes connected Relations (which transition to lower arity or nullary).
* **HYPERGRAPH-I015 (Reference Stability):** A valid reference continues to designate the same semantic object across arbitrary topology mutations of other entities.
* **HYPERGRAPH-I016 (No Silent Retargeting):** A reference or identifier of a deleted object cannot resolve to a different or newly created semantic object.
* **HYPERGRAPH-I017 (Identity Mutation Separation):** Topology mutation (attaching/detaching incidences) does not mutate the semantic identity of the Relation or Element.
* **HYPERGRAPH-I018 (Provider Handle Independence):** Provider storage compaction, pointer movement, or identifier recycling does not alter SCR semantic identity.
* **HYPERGRAPH-I019 (Historical Identity Separation):** Historical recognition of a deleted object does not imply that the object remains active.
* **HYPERGRAPH-I020 (Referential Integrity Under Deletion):** Deletion of an entity never leaves dangling pointers or corrupted references in the hypergraph.
* **HYPERGRAPH-I021 (Complete Incidence Cascade):** Deleting a Relation cascades to delete all its Incidences while preserving participating Elements.

---

## 7. Semantic Lifecycle Model

The dynamic state of a Semantic Hypergraph at step $t$ is expressed as:
$$\mathcal{H}_t = (E_t, R_t, I_t, \rho_t, \Lambda_t)$$

where $\Lambda_t$ tracks semantic lifecycle, tombstone states, and reference validity:
1. **Created $\to$ Active:** An Element, Relation, or Incidence is instantiated with an immutable semantic identifier.
2. **Topology Mutation:** Incidences are attached or detached; participating Elements and Relations retain identity.
3. **Explicit Deletion:** An entity is removed from active topology $\mathcal{H}_t$; referential integrity is preserved via complete incidence cascading; stale references return explicit lookup errors rather than silently resolving to reused IDs.

