# Sprint 02: Verification Matrix & Counterexample Audit

**Parent Milestone:** [Milestone 004: Verification Closure & SID-001 Gate](../spec.md)  
**Derived from:** [spec.md](../../../spec.md) (Sections 22, 23)  
**Deliverable:** Integrated verification matrix & counterexample registry in final closure deliverables  
**Status:** Planned  

---

## 1. Mission

Construct the authoritative 12-column verification matrix for all IAM invariants (IAM-I001 through IAM-I017) and audit all historical and newly uncovered counterexamples to ensure complete remediation and regression test coverage.

---

## 2. The 12-Column Verification Matrix Structure

The final matrix must map every invariant across the verification dimensions:

| Col # | Header Name | Description |
|---|---|---|
| 1 | `Invariant` | Identifier (e.g. `IAM-I001`, `IAM-I017`) |
| 2 | `Definition` | Formal mathematical and semantic statement |
| 3 | `Machine Enforcement` | Specific guard/check in `transitions.py` |
| 4 | `Independent Assertion` | Post-state checker function in `invariants.py` |
| 5 | `Property Test` | Random/generative testing coverage |
| 6 | `Bounded Exhaustive Test` | State-space exploration parameter ($N$) |
| 7 | `Adversarial Test` | Specific adversarial scenario number |
| 8 | `Recovery Test` | Recovery resilience test identifier |
| 9 | `Concurrency Test` | Concurrent interleaving check identifier |
| 10 | `Formal Proof` | Lean theorem reference or "N/A" |
| 11 | `Evidence` | Log file, report reference, or test assertion line |
| 12 | `Status` | `MACHINE_ENFORCED`, `EXECUTABLY_CHECKED`, `BOUNDED_EXHAUSTIVE`, `FORMALLY_PROVEN`, `PARTIAL`, or `OPEN` |

---

## 3. Counterexample Protocol & Audit

For every counterexample discovered during IAM-RM-001 or subsequent exploration:
1. **Trace Preservation:** Record the shortest reproducible trace of actions.
2. **Defect Classification:** Categorize defect into:
   - Implementation defect
   - Specification defect
   - Invariant defect
   - Test harness defect
   - Model limitation
3. **Remediation Verification:** Verify patch at the appropriate layer.
4. **Permanent Regression Coverage:** Verify dedicated regression test preventing reoccurrence.
5. **No Suppression Policy:** Unresolved counterexamples must never be concealed or bypassed.
