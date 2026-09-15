# Sprint 01: Lean 4 Formal Proof Assessment

**Parent Milestone:** [Milestone 004: Verification Closure & SID-001 Gate](../spec.md)  
**Derived from:** [spec.md](../../../spec.md) (Section 21)  
**Deliverable:** Integrated section in `reports/report_S_iam001_verification_closure.md` (and Lean candidate definitions in `SCRFormal/` if indicated)  
**Status:** Planned  

---

## 1. Mission

Evaluate whether the current identity address space algebra requires mechanized formal proof in Lean 4 prior to initiating concrete SID-001 encoding, or whether bounded exhaustive verification combined with rigorous mathematical specification theorems is sufficient.

---

## 2. Core Candidate Theorems for Formalization

Evaluate expressibility and proof effort in `SCRFormal/` for:

### 1. Global Injectivity from Local Injectivity over Disjoint Partitions
Given:
$$D_i \cap D_j = \emptyset \quad \forall i \neq j$$
and:
$$f_i: L_i \to D_i \quad \text{with each } f_i \text{ injective}$$
Prove:
$$\bigcup_i f_i \text{ is injective}$$

### 2. Containment & Non-Overlap
Prove that sub-domain delegations preserve strict disjointness:
$$\text{Partition}(D, D_1, D_2) \implies D_1 \cap D_2 = \emptyset \land D_1 \cup D_2 \subseteq D$$

### 3. Generation Fencing Non-Interference
Prove that authority rotation $g \to g+1$ cannot alter or invalidate allocations issued under $g$.

### 4. Historical Consistency Preservation
Prove that valid state transitions maintain:
$$s \in H \implies \text{ConsistentHistoricalState}(s, \Sigma)$$

---

## 3. Decision Framework

Assess whether to conclude:
* **Option A:** Mechanized Lean 4 proof is mandatory before SID-001 can begin.
* **Option B:** Bounded model checking + independent assertion testing + formal mathematical specification is sufficient for SID-001, scheduling full Lean mechanization as an asynchronous track.

The assessment must be strictly evidence-driven, weighing proof complexity, proof utility, and known edge-case coverage.

---

## 4. Deliverable Requirements

Document in the closure report:
- Mathematical statements of the candidate theorems.
- Assessment of Lean 4 mechanization feasibility and effort.
- Explicit, justified decision on formal proof gating for SID-001.
