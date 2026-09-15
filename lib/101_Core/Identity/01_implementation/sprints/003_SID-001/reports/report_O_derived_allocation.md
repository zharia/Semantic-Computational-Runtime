# Report O: Deterministic & Derived Allocation Semantics

**Repository:** `Semantic-Computational-Runtime`  
**Milestone:** IAM-001 Verification Closure  
**Specification Reference:** `lib/101_Core/Identity/01_implementation/sprints/003_SID-001/spec.md` (§11)  
**Status:** Completed  

---

## 1. Executive Summary

This report establishes the normative semantic boundary governing **Deterministic and Derived Allocation** in the SCR Identity subsystem. Many computational workloads benefit from deriving an identifier deterministically from domain parameters (e.g. hash of entity content, structured hierarchy, or coordinate offset $F(\text{parent}, k)$).

However, a critical architectural rule of SCR is that **a mathematical function is never an allocation authority by itself**. This report formalizes the distinction between *derivation* and *authoritative allocation*, and establishes the four mathematical invariants required for any derived allocation policy.

---

## 2. Derivation vs. Authoritative Allocation

Preserve this foundational distinction:

```text
Deterministic Calculation  ≠  Authorized Allocation
```

1. **Deterministic Calculation:**
   A pure mathematical mapping $F: \mathcal{K} \to \mathcal{C}$ that computes a candidate coordinate from input keys (e.g. $F(k) = \text{parent\_sid} + k$).
2. **Authorized Allocation:**
   The legal transition $\mathcal{T}_{\text{alloc}}$ executed by a designated Authority $A$ within an active Domain $D$ that commits coordinate $s$ into the historical allocation set $H$, creating a cryptographic provenance record $P$.

A derived coordinate is an uncommitted candidate until an authorized domain transition validates and records it in $H$ and $P$.

---

## 3. The Four Invariant Criteria for Derived Allocations

Any deterministic allocation mechanism authorized under a domain policy must satisfy four mathematical conditions:

### 1. Domain Containment
The output of the derivation function must fall strictly within the allocated domain's region:
$$\forall k \in \mathcal{K}, \quad F(k) \in D.\text{region}$$

### 2. Local Injectivity
Distinct inputs within the key domain must produce distinct coordinates:
$$\forall k_1, k_2 \in \mathcal{K}, \quad k_1 \neq k_2 \implies F(k_1) \neq F(k_2)$$

### 3. Historical Non-Collision (Durable Non-Reuse)
A candidate derived coordinate cannot be committed if it has ever previously been allocated in the identity address space:
$$F(k) \notin H$$

### 4. Explicit Domain Policy Authorization
A domain authority must explicitly declare the derivation function $F$ in its domain metadata. Derivation cannot be invoked by arbitrary callers to bypass domain reservation rules.

---

## 4. Empirical Simulation & Verification

In `closure_verification.py`, `run_derived_allocation_simulation()` verified an abstract derived allocator operating over domain region $[64, 128)$:
* Derivation function: $F(k) = 64 + k$ for keys $k \in \{1, 2, 3, 4\}$.
* Derived candidate coordinates: $\{65, 66, 67, 68\}$.

### Evaluation Results:
* **Containment Check:** All coordinates $\in [64, 128) \implies \text{True}$ (**PASS**).
* **Injectivity Check:** $4$ unique keys $\implies 4$ unique coordinates $\implies \text{True}$ (**PASS**).
* **Non-Reuse Check:** No candidate coordinate pre-exists in $H \implies \text{True}$ (**PASS**).
* **Overall Derived Suite:** `passed = True`.

---

## 5. Evidence Discipline Summary

* **Claim:** Deterministic coordinate derivation is subordinate to domain authority and valid if and only if containment, injectivity, and non-reuse invariants hold.
* **Evidence:** Simulation telemetry in `verification_closure_evidence.json` (`derived_allocation`: `passed: true`).
* **Inference:** Derived allocators can be safely integrated into SCR without modifying the core identity space algebra.
* **Limitation:** Tested with linear offset functions; cryptographic hashing allocators (e.g. SHA-256 derived SIDs) must guarantee birthday-bound collision resistance in production.
