# Sprint 02: Targeted Recovery & Resilience Verification

**Parent Milestone:** [Milestone 003: Deep Targeted Verification](../spec.md)  
**Derived from:** [spec.md](../../../spec.md) (Section 9)  
**Deliverable:** `reports/report_M_recovery_verification.md`  
**Status:** Planned  

---

## 1. Mission

Implement a dedicated recovery property verification suite testing that the IAM reference machine guarantees state integrity, non-resurrection, and structural consistency across snapshot, crash, and recovery cycles.

---

## 2. Mandatory Invariant Properties Under Recovery

Every recovery test sequence must formally assert all eight core properties:

1. **Historical Monotonicity:**
   $$H_{\text{before}} \subseteq H_{\text{after}}$$
   No allocated SID may vanish from the historical allocation ledger upon recovery.
2. **Historical Consistency:**
   $$\text{Consistent}(H_{\text{after}}, P_{\text{after}}, D_{\text{after}}, B_{\text{after}}, M_{\text{after}})$$
   Every historical SID must possess valid provenance, domain membership, and intact lifecycle references.
3. **No Resurrection:**
   Any SID ever committed remains unavailable for new durable allocation in any active domain.
4. **Identity Preservation:**
   Recovery does not alter the canonical SID assigned to an existing semantic entity.
5. **Authority Preservation:**
   Recovery does not accidentally reactivate a revoked or stale authority generation.
6. **Transaction Preservation:**
   Recovery preserves committed transaction identifiers, preventing rebinding to alternate SIDs.
7. **Binding Preservation:**
   Pre-existing SID $\to$ semantic entity bindings survive recovery without corruption.
8. **Manifestation Separation:**
   Physical/runtime manifestation handles may be re-initialized or modified upon recovery, but canonical SID coordinates remain unchanged.

---

## 3. Dual Recovery Semantics

Test and verify the two operational paradigms as distinct state transitions:
* **Workflow A (Controlled Rollback):**
  $$\text{Snapshot} \to \text{Mutation} \to \text{Restore}$$
* **Workflow B (Uncontrolled Failure & Recovery):**
  $$\text{Snapshot} \to \text{Simulated Crash} \to \text{Recovery Routine}$$

---

## 4. Deliverable Requirements

Author:
```text
lib/101_Core/Identity/01_implementation/sprints/003_SID-001/reports/report_M_recovery_verification.md
```
Document:
- Exhaustive test harness implementation for recovery operations.
- Verification matrix evaluating each of the 8 properties across Workflows A and B.
- Crash injection points and verified recovery state outputs.
