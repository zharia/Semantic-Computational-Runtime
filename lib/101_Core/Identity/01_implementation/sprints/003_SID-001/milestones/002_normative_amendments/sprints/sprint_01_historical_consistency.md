# Sprint 01: Historical Consistency Semantics & IAM-I017

**Parent Milestone:** [Milestone 002: Normative Semantics & Amendments](../spec.md)  
**Derived from:** [spec.md](../../../spec.md) (Sections 4, 5)  
**Deliverable:** `reports/report_J_historical_consistency.md`  
**Status:** Planned  

---

## 1. Mission

Codify the remediation of Counterexample 1 into a normative semantic specification rule and formulate an independent, explicitly checked invariant (`IAM-I017 Historical Consistency`) that enforces mutual consistency between historical allocation state and allocation provenance/domain structures under snapshot and recovery.

---

## 2. Theoretical Formulation

Monotonicity of the historical set ($H_t \subseteq H_{t+1}$) is necessary but insufficient. Durable identity requires:

$$
s \in H \implies \text{ConsistentHistoricalState}(s, \Sigma)
$$

For every committed or historical SID $s$, the system state $\Sigma$ must maintain:
* **Provenance Structure ($P$):** Valid record of issuing authority, allocation epoch, and transaction association.
* **Domain Structure ($D$):** Legitimate domain membership within which $s$ was partitioned.
* **Binding State ($B$):** Preservation of semantic binding if one existed prior to snapshot/recovery.
* **Manifestation State ($M$):** Preserved or reconcilable physical mapping without corrupting $s$.

---

## 3. Normative Rule Specification

Add the following normative rule to IAM-001:

> **IAM-R017 Snapshot Historical Consistency:**  
> Snapshot recovery MUST NOT produce a state in which a SID exists in historical allocation state without the corresponding historical structures required to establish its allocation provenance and domain membership. If binding or manifestation history existed before snapshot/recovery, recovery must preserve the corresponding state according to lifecycle semantics.

---

## 4. Invariant Formulation: IAM-I017

Formulate `IAM-I017` (or designated equivalent):
```python
def check_iam_i017_historical_consistency(state) -> bool:
    for sid in state.H:
        # Provenance invariant:
        if sid not in state.P or not state.P[sid].is_valid():
            return False
        # Domain membership invariant:
        if not any(sid in domain for domain in state.D.values()):
            return False
    return True
```

### Verification & Testing Tasks:
1. **Independent Checking:** Test `IAM-I017` as a post-state assertion separate from the recovery procedure itself.
2. **Adversarial Corruption Scenarios:** Inject deliberate corruptions:
   - Historical SID in $H$ with removed provenance in $P$.
   - Historical SID in $H$ with orphaned domain in $D$.
   - Snapshot restoration of stale or truncated historical state.
3. Verify that `IAM-I017` reliably fails on each corruption scenario.

---

## 5. Deliverable Requirements

Author:
```text
lib/101_Core/Identity/01_implementation/sprints/003_SID-001/reports/report_J_historical_consistency.md
```
Document:
- Mathematical definition of historical consistency.
- Exact formulation of normative rule IAM-R017.
- Implementation of invariant IAM-I017 in the reference machine.
- Adversarial test harness results demonstrating corruption detection.
