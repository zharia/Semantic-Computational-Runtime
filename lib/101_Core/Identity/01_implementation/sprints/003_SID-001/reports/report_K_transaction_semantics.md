# Report K: Transaction Identity & Non-Rebinding Semantics

**Repository:** `Semantic-Computational-Runtime`  
**Milestone:** IAM-001 Verification Closure  
**Specification Reference:** `lib/101_Core/Identity/01_implementation/sprints/003_SID-001/spec.md` (§6, §13)  
**Status:** Completed  

---

## 1. Executive Summary

In distributed identity runtimes, allocation requests frequently experience network retries, dropped acknowledgments, and crash-recovery cycles. Counterexample 2 in early IAM-RM-001 testing revealed a critical vulnerability: if a transaction record was mutable or inadequately bound, a caller could submit an existing `TransactionId` associated with an alternate coordinate $sid'$, thereby subverting deterministic allocation.

This report formalizes **Transaction Identity**, establishes the normative rule **IAM-R018 Transaction Immutability**, and documents the empirical verification of transaction idempotence under simulated failures.

---

## 2. Mathematical Formalization

Let $Q$ be the transactional state table containing transaction records $q \in Q$, where:
$$q = (\text{tx\_id}, \text{sid}, \text{domain\_id}, \text{authority\_id}, \text{generation}, \text{status})$$
with $\text{status} \in \{\text{INTENT}, \text{RESERVED}, \text{COMMITTED}, \text{ARCHIVED}\}$.

For durable identity allocation, the transaction mapping is strictly a partial function:
$$\text{tx\_id} \xrightarrow{\mathcal{T}_{\text{alloc}}} \text{at most one SID}$$

### Mandatory Operational Transitions:
1. **Idempotent Replay:**
   $$\forall (\text{tx}, s) \text{ committed in } Q, \quad \mathcal{T}(\Sigma, \text{Commit}(\text{tx}, s)) = \Sigma \quad (\text{Success, no-op})$$
2. **Re-binding Rejection:**
   $$\forall (\text{tx}, s) \in Q, \forall s' \neq s, \quad \mathcal{T}(\Sigma, \text{Commit}(\text{tx}, s')) = \text{Error}(\text{InvalidRequestError})$$
3. **Independent Transaction Submission:**
   $$\forall \text{tx}' \notin \text{dom}(Q), \quad \mathcal{T}(\Sigma, \text{Commit}(\text{tx}', s)) \text{ is evaluated under standard non-reuse } (s \notin H)$$
4. **Historical Isolation:**
   The transaction table $Q$ is strictly subordinate to $H$; presence in $Q$ can never be utilized to circumvent the durable non-reuse invariant ($s \notin H$).

---

## 3. Normative Specification Amendment

The following normative requirement is added to IAM-001:

> **IAM-R018 Transaction Immutability & Non-Rebinding (Normative):**  
> A transaction identifier MUST NOT be rebound to a different SID after its first committed association. A replay of an existing transaction identifier with its original SID parameters MUST evaluate to idempotent success. Any attempt to associate an existing transaction identifier with a new or different SID MUST be rejected unconditionally.

---

## 4. Empirical Verification & Failure Mode Stress Testing

Transaction resilience was evaluated across four critical distributed failure patterns:

| Failure Mode | Test Sequence | Expected Behavior | Observed Result | Status |
|---|---|---|---|:---:|
| **FM-1: Lost Ack / Replay** | Request $\to$ Reserve $\to$ Commit $\to$ Lost Ack $\to$ Retry $(\text{tx}_1, s_1)$ | Idempotent Success; no duplicate state mutation | `Idempotent success; H unchanged` | **PASS** |
| **FM-2: Rebind Attack** | Commit $(\text{tx}_1, s_1)$ $\to$ Request $(\text{tx}_1, s_2)$ ($s_2 \neq s_1$) | Hard rejection: `Tx already bound to different SID` | `InvalidRequestError: Tx TX1 already committed with different SID` | **PASS** |
| **FM-3: Crash After Commit** | Commit $(\text{tx}_1, s_1)$ $\to$ Crash $\to$ Recover $\to$ Retry $(\text{tx}_1, s_1)$ | Recovery preserves $Q$; retry remains idempotent | `evaluations['6_transaction_preservation']['idempotent'] = True` | **PASS** |
| **FM-4: Rebind Post-Recovery** | Commit $(\text{tx}_1, s_1)$ $\to$ Crash $\to$ Recover $\to$ Attempt $(\text{tx}_1, s_3)$ | Recovery preserves $Q$; rebind attempt rejected | `evaluations['6_transaction_preservation']['rebind_rejected'] = True` | **PASS** |

---

## 5. Machine Enforcement Architecture

In `src/iam_rm_001/machine.py`, the guards in `reserve_sid` (lines 286–298) and `commit_sid` (lines 354–362) machine-enforce these semantics prior to modifying the reservation table or historical allocation set:

```python
# Guard against transaction re-binding
if tx_id in new_state.Q:
    rec = new_state.Q[tx_id]
    if rec.status == "COMMITTED":
        if rec.sid == sid:
            return self.state  # Idempotent replay
        else:
            raise InvalidRequestError(f"Tx {tx_id} already committed with different SID {rec.sid}")
```

Additionally, `assert_IAM_I016_transaction_idempotence` validates that every committed transaction in $Q$ maps to a valid SID in $H$.

---

## 6. Evidence Discipline Summary

* **Claim:** Transaction identifiers are immutable single-SID mappings that support idempotent retries and reject rebinding.
* **Evidence:** Empirical tests FM-1 through FM-4 passed; deep temporal trace 3 verified rejection of `TX_UNIQUE` rebind attack.
* **Inference:** Transaction semantics are decoupled from coordinate geometry while guaranteeing distributed allocation safety.
* **Limitation:** In-memory synchronous reference machine; distributed consensus protocols (e.g. Raft/Paxos) will implement this contract in production.
