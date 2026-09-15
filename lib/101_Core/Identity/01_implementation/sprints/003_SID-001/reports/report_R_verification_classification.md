# Report R: Verification Classification & Evidence Standards

**Repository:** `Semantic-Computational-Runtime`  
**Milestone:** IAM-001 Verification Closure  
**Specification Reference:** `lib/101_Core/Identity/01_implementation/sprints/003_SID-001/spec.md` (§7, §17)  
**Status:** Completed  

---

## 1. Executive Summary

This report establishes the normative **Verification Taxonomy** and **Evidence Discipline** for the SCR Identity architecture. Historical documentation in earlier sprints occasionally used terms such as *"formally enforced"* or *"proven"* to describe runtime guards and bounded Python test executions. 

To eliminate semantic drift between empirical software testing and mathematical proof, this report establishes four mutually exclusive verification tiers and mandates a strict four-part evidence discipline for all technical findings.

---

## 2. The Four Verification Categories

Every claim, invariant, and assertion within the SCR Identity subsystem must be classified under exactly one of the following four tiers:

```text
┌──────────────────────────────────────────────────────────────────┐
│                   SCR VERIFICATION TAXONOMY                      │
├────────────────────────────────┬─────────────────────────────────┤
│ Tier 1: MACHINE ENFORCED       │ Operational transition guards   │
│ Tier 2: EXECUTABLY CHECKED     │ Independent post-state checkers │
│ Tier 3: BOUNDED-EXHAUSTIVE     │ Finite model exploration (BFS)  │
│ Tier 4: FORMALLY PROVEN        │ Mechanized Lean 4 mathematical  │
└────────────────────────────────┴─────────────────────────────────┘
```

### Tier 1: MACHINE ENFORCED
* **Formal Definition:** The state transition operator $\mathcal{T}: \Sigma \times \text{Event} \to \Sigma \cup \{\text{Error}\}$ actively evaluates preconditions and structural constraints, rejecting an invalid transition before any state mutation can occur.
* **Mechanism:** Precondition checks, input validation guards, atomic reservation maps, exception dispatch.
* **Scope:** Enforces operational safety locally at each invocation.

### Tier 2: EXECUTABLY CHECKED
* **Formal Definition:** An independent, side-effect-free invariant assertion function $\mathcal{I}: \Sigma \to \{\text{True}, \text{False}\}$ inspects an existing system state $\Sigma$ (or transition pair $(\Sigma_{t}, \Sigma_{t+1})$) to verify global semantic consistency.
* **Mechanism:** Dedicated checker functions in `invariants.py`, post-operation sanity assertions, corruption scanners.
* **Scope:** Decoupled from transition logic; capable of detecting latent or out-of-band state corruptions.

### Tier 3: BOUNDED-EXHAUSTIVELY VERIFIED
* **Formal Definition:** Every reachable state within a formally declared finite model boundary ($\forall s \in \text{Reachable}(\mathcal{M}_{N, d})$) has been systematically generated and evaluated against all relevant invariants without counterexample.
* **Mechanism:** Breadth-first / depth-first state-space exploration with symmetry reduction (e.g. `StateExplorer` at $N=8$, depth=3).
* **Mandatory Constraint:** All claims must explicitly cite the parameter bounds $(N, d)$ and search termination status (`complete`, `pruned`). Extrapolating bounded exploration to an unbounded mathematical theorem is strictly prohibited.

### Tier 4: FORMALLY PROVEN
* **Formal Definition:** A generalized mathematical, machine-checked theorem (e.g., in Lean 4) proves that an invariant or transition property holds across arbitrary unbounded domains independently of execution or finite model bounds.
* **Mechanism:** Mechanized proofs in `SCRFormal/` using inductive types, tactics, and type-theoretic deduction.
* **Mandatory Constraint:** Must reference verifiable Lean proof files; test suite execution results can never be cited as formal proof.

---

## 3. Mandatory Evidence Discipline

All SCR verification reports, test summaries, and architecture evaluations must structure their assertions according to four distinct components:

$$\text{Report Entry} = (\text{Claim}, \text{Evidence}, \text{Inference}, \text{Limitation})$$

1. **Claim:** The precise semantic invariant or property being asserted (expressed with formal mathematical symbols).
2. **Evidence:** Concrete, reproducible artifacts (exact terminal outputs, JSON evidence metrics, explored state counts, error trace listings, or Lean proof module references).
3. **Inference:** The rigorous, deductive conclusion that strictly follows from the evidence, avoiding unjustified generalizations.
4. **Limitation:** The exact boundary of the assertion (model simplifications, parameter bounds, unmodeled physical dimensions).

---

## 4. Invariant Classification Mapping (IAM-I001 to IAM-I017)

The canonical identity invariant suite is classified as follows:

| Invariant ID | Semantic Invariant Name | Machine Enforced | Executably Checked | Bounded Exhaustive | Formally Proven | Current Status |
|---|---|:---:|:---:|:---:|:---:|:---:|
| **IAM-I001** | Root Uniqueness | ✅ | ✅ | ✅ ($N=8$) | ❌ | `BOUNDED_EXHAUSTIVE` |
| **IAM-I002** | Domain Disjointness | ✅ | ✅ | ✅ ($N=8$) | ❌ | `BOUNDED_EXHAUSTIVE` |
| **IAM-I003** | Domain Containment | ✅ | ✅ | ✅ ($N=8$) | ❌ | `BOUNDED_EXHAUSTIVE` |
| **IAM-I004** | Allocation Containment | ✅ | ✅ | ✅ ($N=8$) | ❌ | `BOUNDED_EXHAUSTIVE` |
| **IAM-I005** | Allocation Injectivity | ✅ | ✅ | ✅ ($N=8$) | ❌ | `BOUNDED_EXHAUSTIVE` |
| **IAM-I006** | Authority Containment | ✅ | ✅ | ✅ ($N=8$) | ❌ | `BOUNDED_EXHAUSTIVE` |
| **IAM-I007** | Cryptographic Provenance | ✅ | ✅ | ✅ ($N=8$) | ❌ | `BOUNDED_EXHAUSTIVE` |
| **IAM-I008** | Generation Validity | ✅ | ✅ | ✅ ($N=8$) | ❌ | `BOUNDED_EXHAUSTIVE` |
| **IAM-I009** | Historical Monotonicity | ✅ | ✅ | ✅ ($N=8$) | ❌ | `BOUNDED_EXHAUSTIVE` |
| **IAM-I010** | Durable Non-Reuse | ✅ | ✅ | ✅ ($N=8$) | ❌ | `BOUNDED_EXHAUSTIVE` |
| **IAM-I011** | Crash Monotonicity | ✅ | ✅ | ✅ ($N=8$) | ❌ | `BOUNDED_EXHAUSTIVE` |
| **IAM-I012** | Snapshot Safety | ✅ | ✅ | ✅ ($N=8$) | ❌ | `BOUNDED_EXHAUSTIVE` |
| **IAM-I013** | Contextual Resolution | ✅ | ✅ | ✅ ($N=8$) | ❌ | `BOUNDED_EXHAUSTIVE` |
| **IAM-I014** | Manifestation Separation | ✅ | ✅ | ✅ ($N=8$) | ❌ | `BOUNDED_EXHAUSTIVE` |
| **IAM-I015** | Binding Separation | ✅ | ✅ | ✅ ($N=8$) | ❌ | `BOUNDED_EXHAUSTIVE` |
| **IAM-I016** | Transaction Idempotence | ✅ | ✅ | ✅ ($N=8$) | ❌ | `BOUNDED_EXHAUSTIVE` |
| **IAM-I017** | Historical Consistency | ✅ | ✅ | ✅ ($N=8$) | ❌ | `BOUNDED_EXHAUSTIVE` |

---

## 5. Conclusion & Normative Adoption

By adopting this classification standard, SCR eliminates ambiguity between machine-level enforcement and mathematical deduction. All subsequent reports in Sprint 003 adhere strictly to this terminology and evidence discipline.
