# Report N: Multi-Root Identity Architecture Decision

**Repository:** `Semantic-Computational-Runtime`  
**Milestone:** IAM-001 Verification Closure  
**Specification Reference:** `lib/101_Core/Identity/01_implementation/sprints/003_SID-001/spec.md` (§10)  
**Status:** Completed  

---

## 1. Executive Summary

This report delivers the authoritative architectural decision regarding **Multi-Root Identity** in the Semantic Computational Runtime. A foundational design question in SCR is whether the identity architecture permits multiple independent root authorities or mandates a single, monolithic universal root.

Following comparative algebraic analysis and experimental simulation, **SCR adopts Model B: Independent Roots with Scoped Global Identity** ($\text{GlobalIdentity} = (\text{Root}, \text{SID})$). Crucially, this decision preserves the foundational invariant: **the Root authority identifier is external contextual metadata and MUST NOT be embedded into the internal bit representation of the SID coordinate**.

---

## 2. Evaluation of Candidate Structural Models

Three candidate architectural models were evaluated:

### Model A: Single Universal Root
```text
Genesis → Single Root Authority → Identity Address Space → All SCR Identities
```
* **Characteristics:** A single global root authority issues and coordinates all SIDs across all SCR clusters worldwide.
* **Evaluation:** Unacceptable for a general-purpose runtime. It introduces a global point of failure, enforces global network synchronization, and prevents autonomous operation in air-gapped, sovereign, embedded, or multi-tenant cloud environments.

### Model B: Independent Autonomous Roots (Adopted)
```text
Genesis_A → Root_A → IdentitySpace_A → SID_A
Genesis_B → Root_B → IdentitySpace_B → SID_B
```
* **Characteristics:** Independent administrative domains, enterprises, or runtime clusters instantiate autonomous root authorities with distinct Genesis identifiers and independent address spaces.
* **Algebraic Formulation:** Global identity is defined as the ordered pair:
  $$\text{GlobalIdentity} = (\text{Root}, \text{SID})$$
* **Non-Collision Theorem:** Coordinate equality does not imply identity equivalence across distinct roots:
  $$\text{SID}_A = \text{SID}_B \land \text{Root}_A \neq \text{Root}_B \implies \text{Identity}_A \neq \text{Identity}_B$$
* **Evaluation:** Perfectly matches SCR's heterogeneous execution substrate philosophy. Allows independent local allocations while maintaining unambiguous global identity resolution.

### Model C: Federated Roots
* **Characteristics:** Autonomous roots establish explicit cross-authority trust and namespace federation agreements.
* **Evaluation:** Fully compatible with Model B as an operational extension, but does not alter the fundamental algebra of Model B.

---

## 3. Mandatory Representation Boundary

> [!IMPORTANT]
> **Root Context Remains External to the Coordinate.**
> 
> Under Model B, an SID is an internal coordinate within its respective Identity Address Space. The Root identifier:
> 1. MUST NOT be prefixed or packed into the concrete SID coordinate bits.
> 2. MUST NOT constrain the geometry or width of the coordinate.
> 3. MUST be supplied by resolution context (the caller, envelope, or transport frame), preserving the separation:
>    $$\text{Coordinate} \neq \text{Resolution Context}$$

---

## 4. Empirical Simulation & Verification

To verify Model B, `run_multi_root_simulation()` was executed within `closure_verification.py`. The simulation constructed two completely autonomous reference machines:
* `Machine_A` under `Root_A` in `SPACE_A`
* `Machine_B` under `Root_B` in `SPACE_B`

### Execution Findings:
1. **Local Allocation:** Both machines independently allocated local coordinate `42` within their respective root spaces:
   $$42 \in H_A \quad \land \quad 42 \in H_B$$
2. **Global Identity Resolution:**
   $$\text{GID}_A = (\text{"ROOT\_A"}, 42)$$
   $$\text{GID}_B = (\text{"ROOT\_B"}, 42)$$
3. **Disjointness Assertion:**
   $$\text{GID}_A \neq \text{GID}_B \implies \text{True} \quad (\text{PASS})$$

The simulation demonstrated that local coordinate allocation is completely autonomous and free of cross-cluster coordination, while global disambiguation is guaranteed by the context pair $(\text{Root}, \text{SID})$.

---

## 5. Evidence Discipline Summary

* **Claim:** SCR identity architecture supports independent roots where global identity is defined by $\text{GlobalIdentity} = (\text{Root}, \text{SID})$, without embedding Root into the SID coordinate.
* **Evidence:** Multi-root simulation in `verification_closure_evidence.json` (`multi_root`: `passed: true`, `gid_a != gid_b`).
* **Inference:** Model B provides complete administrative autonomy without compromising global semantic uniqueness.
* **Limitation:** Federation protocols between roots (e.g. cross-root delegation bridges) are specified in transport-layer contracts.
