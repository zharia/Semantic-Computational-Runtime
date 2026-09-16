# SCR Architecture: Hypergraph Provider Qualification

**Document ID:** `SCR-DOC-ARCH-103`  
**Status:** Normative Architecture Assessment  
**Version:** 0.1.0  
**Domain:** `203_Graph` / `Hypergraph`  
**Task Association:** HGT-001  
**Governing Documents:** [`docs/architecture/102_provider_architecture.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/docs/architecture/102_provider_architecture.md), [`program_increments/v0.0.1/milestones/003_semantic_providers/01_HGT-001/101_spec.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/program_increments/v0.0.1/milestones/003_semantic_providers/01_HGT-001/101_spec.md)  

---

## 1. Executive Summary

This document evaluates potential hypergraph kernel implementations for participation as Providers in the Semantic Computational Runtime (SCR). 

Per SCR Principle 2:
> **"Do not build a kernel when a good kernel already exists. Build the semantic bridge that allows it to participate in SCR."**

Per SCR Principle 6:
> **"Providers implement contracts; they do not own them."**

No provider implementation may redefine SCR hypergraph semantics. The canonical model $\mathcal{H} = (E, R, I, \rho)$ requires first-class Element, Relation, and Incidence entities, arbitrary cardinality, first-class nullary relations ($|I(R)| = 0$), semantic roles and directions, and provider-independent identity.

---

## 2. Candidate Provider Assessments

### 2.1 Candidate: `oxgraph` (SPARQL / Graph Database Engine)
* **Topology Model:** Quad-store / RDF graph (Subject, Predicate, Object, GraphName).
* **Hypergraph Support:** Simulated via reification or named graphs; no native generalized hyperedges.
* **Incidence Representation:** Reified RDF statements; lacks native first-class incidence identities.
* **Nullary Relations:** Cannot represent a predicate without subject and object without custom blank-node dummy hacks.
* **Zero-Copy & Embedded Suitability:** High-performance disk/memory store, but heavy footprint; not `no_std` suitable.
* **License:** Apache-2.0 / MIT.
* **Verdict:** **REJECTED** as a foundational hypergraph provider. Qualified as a downstream persistence / query engine provider for RDF/SPARQL projection.

### 2.2 Candidate: Rust `hypergraph` (crates.io / open-source)
* **Topology Model:** Directed hypergraph with vertices and hyperedges.
* **Hypergraph Support:** Native hyperedge indices connecting sets of vertices.
* **Semantic Gaps Identified:**
  * Hyperedges are modeled as index sets; Incidences are not first-class objects carrying independent semantic identities.
  * Nullary hyperedges ($|I(R)| = 0$) cause index out-of-bounds or panic in default traversals.
  * Roles and directions are inferred from vector position rather than typed semantic contracts.
* **License:** MIT / Apache-2.0.
* **Verdict:** **CONDITIONALLY QUALIFIED** as a downstream acceleration engine for pure topological algorithms, provided an adapter wraps its storage and maps first-class incidences.

### 2.3 Candidate: `NWHy` (Pacific Northwest National Laboratory Hypergraph Library)
* **Topology Model:** High-performance C++ hypergraph analytics library for big data / clustering.
* **Hypergraph Support:** High-scale spectral hypergraph algorithms and partitioning.
* **Semantic Gaps Identified:** Focused on batch analytics and incidence matrices; lacks dynamic atomic mutation and persistent semantic identity tracking.
* **License:** BSD-3-Clause.
* **Verdict:** **DEFERRED** for high-performance distributed analytics (HPC/accelerator provider phase).

### 2.4 Candidate: SCR Reference Hypergraph Kernel (`scr-hypergraph`)
* **Topology Model:** Strict implementation of $\mathcal{H} = (E, R, I, \rho)$.
* **Capabilities:** First-class elements, relations, and incidences; full support for $|I(R)| = 0$ (nullary relations); typed roles; direction semantics; deterministic traversal; graph projections (clique, bipartite, ordinary edge); provider-isolated C and Rust interfaces.
* **Verdict:** **SELECTED** as the canonical reference implementation.

---

## 3. Capability Resolution Matrix

| Provider Capability | `oxgraph` | Rust `hypergraph` | `NWHy` | `scr-hypergraph` (Reference) |
|---|:---:|:---:|:---:|:---:|
| `HypergraphTopology` | ⚠️ Reified | ✅ Native | ✅ Matrix | ✅ **Full $\mathcal{H}$** |
| `HypergraphIncidence` (First-Class) | ❌ | ❌ Implicit | ❌ Column index | ✅ **First-Class Identity** |
| `NullaryRelation` ($|I(R)| = 0$) | ❌ | ❌ Panics | ❌ Empty column | ✅ **Explicit Support** |
| `RoleAndDirection` | ⚠️ Predicate | ❌ Positional | ❌ Weight only | ✅ **Typed Semantic Contract** |
| `DynamicMutation` | ✅ | ✅ | ⚠️ Batch only | ✅ **Atomic Mutations** |
| `GraphProjection` | ⚠️ Construct | ❌ | ⚠️ Clique | ✅ **Reversible & Disclosed** |
| `ZeroCopyInterchange` | ❌ | ⚠️ Rust only | ⚠️ C++ vectors | ✅ **Linear memory slices** |

---

## 4. Strategic Integration Recommendation

1. **Adopt `scr-hypergraph` as the authoritative Reference Provider:** Establishes the ground-truth oracle for all hypergraph operations across the runtime.
2. **Implement Capability Adapters:** As external performance providers (`NWHy` or `GraphBLAS`) are introduced, they must implement the declared `HypergraphTopology` capability contract without redefining SCR identities.
