# Sprint 02: Transaction Identity & Non-Rebinding Semantics

**Parent Milestone:** [Milestone 002: Normative Semantics & Amendments](../spec.md)  
**Derived from:** [spec.md](../../../spec.md) (Sections 6, 13)  
**Deliverable:** `reports/report_K_transaction_semantics.md`  
**Status:** Planned  

---

## 1. Mission

Codify the discovery from Counterexample 2 into an unambiguous normative specification rule and implement invariant enforcement ensuring that durable allocation transaction identifiers are globally unique to a single SID, rejecting any subsequent re-association or re-binding attempt.

---

## 2. Theoretical Formulation

For durable allocation transactions:

$$
\text{TransactionId} \xrightarrow{\text{alloc}} \text{at most one } \text{SID}
$$

The transition function must satisfy:
1. **Idempotent Replay:**
   $$(\text{tx}, \text{sid}) \xrightarrow{\text{replay}} \text{Success (idempotent no-op)}$$
2. **Re-binding Rejection:**
   $$(\text{tx}, \text{sid}') \text{ where } \text{sid}' \neq \text{sid} \xrightarrow{} \text{REJECT (illegal re-binding)}$$
3. **Independent Transaction Allocation:**
   $$(\text{tx}', \text{sid}) \xrightarrow{} \text{evaluated under standard SID availability and non-reuse rules}$$

---

## 3. Normative Rule Specification

Add to IAM-001:

> **IAM-R018 Transaction Immutability and Non-Rebinding:**  
> A transaction identifier MUST NOT be rebound to a different SID after its first committed association. A retry of an existing transaction identifier with its original SID parameters MUST evaluate to idempotent success. Any attempt to associate an existing transaction identifier with a new or different SID MUST be rejected unconditionally.

---

## 4. Operational & Invariant Verification Tasks

1. **Transaction Lifecycle Clarification:**
   Define the exact state transitions of a transaction record:
   ```text
   Intent → Reservation → Committed Allocation → Archived History
   ```
2. **Crash & Recovery Idempotence Testing:**
   Verify transaction behavior across edge conditions:
   - Request $\to$ Reserve $\to$ Commit $\to$ Lost Ack $\to$ Retry (must succeed idempotently).
   - Request $\to$ Reserve $\to$ Crash $\to$ Recover $\to$ Retry (must handle reservation timeout or replay safely).
   - Request $(tx_1, sid_1)$ $\to$ Crash $\to$ Recover $\to$ Attempt $(tx_1, sid_2)$ (must strictly fail).
3. **Historical Non-Reuse Protection:**
   Assert that transaction table replay or snapshot recovery never circumvents historical non-reuse rules ($H$).

---

## 5. Deliverable Requirements

Author:
```text
lib/101_Core/Identity/01_implementation/sprints/003_SID-001/reports/report_K_transaction_semantics.md
```
Document:
- Formal specification of transaction identity and lifecycle.
- Machine enforcement logic in `transitions.py`.
- Executable invariant assertion for transaction mapping uniqueness.
- Comprehensive failure/retry scenario matrix and test logs.
