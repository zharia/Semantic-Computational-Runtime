# 115 — Executable Semantic Hypergraph Specification

**Specification Identifier:** SCR-SPEC-HYPERGRAPH-115  
**Status:** PROVEN / NORMATIVE  
**Date:** 2026-09-11  
**Semantic Domain:** `lib/203_Graph/Hypergraph/`  
**Formal Implementation:** `SCRFormal/SCR/Hypergraph.lean`

---

## 1. Executive Summary

This document establishes the normative mathematical and formal execution model for the **Executable Semantic Hypergraph** substrate in SCR.

A Semantic Hypergraph represents entities and their higher-order relationships without flattening them into binary edge approximations (`GRAPH-RULE-003`). Transitions across hypergraph states follow a transactional, fail-stop transition calculus formalized in Lean 4 and embedded in the `GMachine` transition framework.

---

## 2. Mathematical Definition

A **Semantic Hypergraph** is a tuple:

\[
\mathcal{H} = (V, E, \tau, \rho, \alpha, \lambda)
\]

where:
1. $V$ is a finite set of **Semantic Entities** (Nodes) with unique identities $\text{Id}(v)$.
2. $E$ is a finite set of **Semantic Hyperedges** with unique identities $\text{Id}(e)$.
3. $\tau : (V \cup E) \to \text{TypeName}$ assigns semantic types.
4. $\rho : E \to \mathcal{P}(\text{RoleName} \times V)$ binds role-labelled endpoints to each hyperedge.
5. $\alpha : (V \cup E) \times \text{Key} \to \text{Value}$ attaches typed semantic attributes.
6. $\lambda \in \mathbb{N}$ denotes the logical transition step.

---

## 3. Structural Invariants

A hypergraph $\mathcal{H}$ is **well-formed** ($\text{ValidHypergraph}(\mathcal{H})$) if and only if:

1. **Incidence Well-Formedness** (`IncidenceWellFormed`):
   \[
   \forall e \in E, \forall (r, v) \in \rho(e), \quad v \in V
   \]
   No hyperedge contains dangling role targets.

2. **Entity Identity Uniqueness** (`NodesUnique`):
   \[
   \forall v_1, v_2 \in V, \quad \text{Id}(v_1) = \text{Id}(v_2) \implies v_1 = v_2
   \]

3. **Hyperedge Identity Uniqueness** (`EdgesUnique`):
   \[
   \forall e_1, e_2 \in E, \quad \text{Id}(e_1) = \text{Id}(e_2) \implies e_1 = e_2
   \]

4. **Role Uniqueness per Hyperedge** (`RolesUnique`):
   \[
   \forall e \in E, \forall (r_1, v_1), (r_2, v_2) \in \rho(e), \quad r_1 = r_2 \implies v_1 = v_2
   \]

---

## 4. Transition Calculus & Operational Semantics

Semantic operations evolve the hypergraph via a deterministic step function:

\[
\text{step} : \text{HyperOp} \times \mathcal{H} \to \text{HyperOutcome}
\]

### Operation Semantics:
- `addNode(e)`: Adds node $e$ if $\text{Id}(e) \notin V$; otherwise fails with no change.
- `removeNode(id)`: Removes node $id$ if $id \in V$ and $\forall e \in E, \forall (r, v) \in \rho(e), \text{Id}(v) \ne id$; otherwise rolls back.
- `addEdge(e)`: Adds hyperedge $e$ if $\text{Id}(e) \notin E$ and all role targets exist in $V$; otherwise rolls back.
- `removeEdge(id)`: Removes hyperedge $id$ if $id \in E$; otherwise rolls back.
- `updateNodeValue(id, v)`: Updates attribute value of node $id$ in place.

---

## 5. Formal Machine-Checked Theorems in Lean 4

All theorems verified in `SCRFormal/SCR/Hypergraph.lean` with clean axiom profiles:

| Theorem | Formal Name | Proven Invariant | Axioms |
|---|---|---|---|
| **Determinism** | `step_deterministic` | Graph transitions are strictly deterministic | `propext` |
| **Totality** | `step_total` | Transition relation is total over all operations | `propext` |
| **Transactional Rollback** | `step_rollback_on_failure` | On precondition violation, graph state is unchanged | `propext` |
| **Node Addition Safety** | `addNode_preserves_incidence` | Adding nodes preserves existing edge incidence | `propext`, `Quot.sound` |
| **Hyperedge Addition Safety** | `addEdge_preserves_incidence` | Adding validated hyperedges preserves incidence | None (0) |
| **Hyperedge Removal Safety** | `removeEdge_preserves_incidence` | Removing hyperedges preserves incidence | `propext` |
| **Unincident Node Removal Safety** | `removeNode_preserves_incidence` | Removing free nodes preserves incidence | `propext`, `Quot.sound` |
| **Value Update Safety** | `updateNodeValue_preserves_incidence` | Modifying node attributes preserves incidence | `propext` |
| **Binary Embedding Preservation** | `stateToHypergraph_preserves_incidence` | Binary relationship state embeds into hypergraph | `propext`, `Quot.sound` |
| **Witness Pipeline** | `sample_hyperedge_pipeline_incidence` | Multi-endpoint observation hyperedge workflow | `propext` |

---

## 6. Binary Relation Embedding

Binary relationships from legacy models are canonically embedded into the hypergraph as 2-endpoint hyperedges:

\[
\text{binaryToHyperedge}(r) = \langle \text{Id}(r), \text{Type}(r), [(\text{"source"}, \text{src}(r)), (\text{"target"}, \text{tgt}(r))] \rangle
\]

Theorem `stateToHypergraph_preserves_incidence` proves that any well-formed binary state $\text{RelationshipsWellFormed}(s)$ yields a valid, incidence-preserving hypergraph.
