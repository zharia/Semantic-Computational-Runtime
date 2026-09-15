# Sprint 03: Architectural Decisions — Multi-Root & Derived Allocation

**Parent Milestone:** [Milestone 002: Normative Semantics & Amendments](../spec.md)  
**Derived from:** [spec.md](../../../spec.md) (Sections 10, 11)  
**Deliverables:**
- `reports/report_N_multi_root_decision.md`
- `reports/report_O_derived_allocation.md`  
**Status:** Planned  

---

## 1. Mission

Resolve two major architectural questions within the IAM-001 specification: (1) whether the identity architecture supports single or multiple independent root authorities, and (2) the formal conditions under which deterministic or derived allocation functions are semantically authorized.

---

## 2. Topic 1: Multi-Root Identity Architecture

Evaluate three structural models against SCR's governing architecture:

### Model A: Single Universal Root
```text
Genesis → Root Authority → Identity Address Space → All SCR Identities
```
* **Pros:** Absolute global coordinate uniqueness without scoping qualifiers.
* **Cons:** Single point of coordination; friction with multi-tenant, air-gapped, or federated runtime deployments.

### Model B: Independent Roots
```text
Genesis_A → Root_A → IdentitySpace_A
Genesis_B → Root_B → IdentitySpace_B
```
* **Implication:** $\text{GlobalIdentity} = (\text{Root}, \text{SID})$.
* **Invariant:** $\text{SID}_A == \text{SID}_B \not\implies \text{Identity}_A == \text{Identity}_B$ when $\text{Root}_A \neq \text{Root}_B$.
* **Critical Rule:** The Root identifier MUST remain external context and must NOT be embedded into the SID coordinate representation.

### Model C: Federated Roots
Autonomous roots establish explicit trust and namespace federation relationships.

**Deliverable:** Produce `reports/report_N_multi_root_decision.md` detailing the architectural selection, implications on resolution, and algebraic properties.

---

## 3. Topic 2: Deterministic / Derived Allocation

Formalize the boundary between functional calculation and authoritative allocation for expressions of the form:
$$SID = F(\text{parent}, \text{local\_identity})$$

### Invariant Criteria for Derived Allocators:
1. **Domain Containment:**
   $$F(k) \in D$$
2. **Local Injectivity:**
   $$F(k_1) = F(k_2) \implies k_1 = k_2$$
3. **Historical Non-Collision:**
   $$F(k) \notin H$$
4. **Authority Separation:** A deterministic mathematical function is **never** an allocation authority by itself; it is only a candidate coordinate generator authorized by a domain policy.

**Deliverable:** Produce `reports/report_O_derived_allocation.md` establishing verification tests and abstract reference models for deterministic allocators.
