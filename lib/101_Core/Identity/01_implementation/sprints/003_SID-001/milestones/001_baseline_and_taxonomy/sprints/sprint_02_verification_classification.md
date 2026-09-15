# Sprint 02: Verification Classification & Evidence Standards

**Parent Milestone:** [Milestone 001: Baseline Assessment & Verification Taxonomy](../spec.md)  
**Derived from:** [spec.md](../../../spec.md) (Sections 7, 17)  
**Deliverable:** `reports/report_R_verification_classification.md`  
**Status:** Planned  

---

## 1. Mission

Eliminate terminology conflation (such as describing test execution or bounded exploration as "formal proof"), establish the four mandatory SCR verification categories, and define the standard evidence discipline required for all subsequent identity reports.

---

## 2. Four Verification Categories

All findings, invariants, and assertions in milestone reports and codebases must strictly use one of the following four classifications:

### 1. MACHINE ENFORCED
* **Definition:** The operational transition implementation actively checks preconditions and runtime constraints, rejecting an invalid transition before state mutation can occur.
* **Mechanism:** Guards, validation predicates, and transition dispatch exceptions.

### 2. EXECUTABLY CHECKED
* **Definition:** An independent invariant assertion function inspects the resulting system state post-transition to verify semantic invariants.
* **Mechanism:** State inspection passes, postcondition invariant checkers, adversarial corruption detectors.

### 3. BOUNDED-EXHAUSTIVELY VERIFIED
* **Definition:** Every reachable state within a declared finite model boundary ($\forall s \in \text{Reachable}(\text{BoundedModel}_{N})$) has been systematically generated and evaluated against all invariants.
* **Mechanism:** State-space BFS/DFS exploration, explicit state model checking.
* **Constraint:** Must explicitly declare bound parameter $N$ and search depth; must never extrapolate to an unbounded mathematical theorem.

### 4. FORMALLY PROVEN
* **Definition:** A general mathematical, mechanized proof (e.g., in Lean 4) establishes that the property holds across all possible states independently of execution or bounds.
* **Requirement:** Must reference mechanized proof files or rigorous general induction, not Python test results.

---

## 3. Evidence Discipline

Every verification report and test document must structure its findings according to four discrete dimensions:

```text
Claim:       The exact semantic property being asserted.
Evidence:    Concrete execution logs, state exploration numbers, error traces, or proofs.
Inference:   What can strictly and deductively be inferred from the evidence.
Limitation:  The exact boundary (model assumptions, bounds, unmodeled dimensions).
```

### Prohibited Patterns
* Do **not** report: *"The architecture is formally proven"* when based on bounded execution or test suites.
* Do **not** state: *"Verified"* without explicitly specifying the verification tier and boundary.

---

## 4. Deliverable Requirements

Author:
```text
lib/101_Core/Identity/01_implementation/sprints/003_SID-001/reports/report_R_verification_classification.md
```
The deliverable must:
1. Formulate definitions and criteria for the four verification tiers.
2. Provide standardized reporting templates using the 4-part evidence discipline.
3. Map every existing IAM-RM-001 invariant into its proper category under the new taxonomy.
