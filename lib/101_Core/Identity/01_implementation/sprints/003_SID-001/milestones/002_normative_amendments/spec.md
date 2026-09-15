# Milestone 002: Normative Semantics & Specification Amendments (IAM-001 v0.2)

**Parent RoadMap:** [milestones/README.md](../README.md)  
**Target Area:** `lib/101_Core/Identity/01_implementation/sprints/003_SID-001/milestones/002_normative_amendments/`  
**Derived from:** [spec.md](../../spec.md) (Sections 4, 5, 6, 10, 11, 19, 20)  
**Status:** Planned  

---

## 1. Objective

Formulate the architectural and operational discoveries of IAM-RM-001 into normative specification amendments for the IAM-001 identity model (advancing from v0.1 to v0.2). This includes establishing historical consistency and transaction uniqueness invariants, resolving multi-root architecture and deterministic allocation models, while keeping concrete SID representations abstract.

---

## 2. Scope & Guiding Constraints

1. **Primacy of Semantics:** Amendments must define semantic contracts and relationships, not low-level implementation details.
2. **Representation Independence:** Do NOT design concrete SID bit encodings (e.g. 128-bit, UUID, ULID), bit fields, or embedded timestamps/signatures in this milestone. Coordinate representation remains abstract until SID-001.
3. **Traceable Versioning:** Maintain an explicit change log recording the transition of IAM-001 from v0.1 to v0.2 with clear rationale and counterexample references.

---

## 3. Sprint Breakdown

```text
002_normative_amendments/
├── spec.md
└── sprints/
    ├── sprint_01_historical_consistency.md                  # Historical consistency & IAM-I017
    ├── sprint_02_transaction_identity.md                    # Transaction identity & non-rebinding
    ├── sprint_03_multi_root_and_derived_allocation.md       # Multi-root & derived allocation decisions
    └── sprint_04_specification_amendments_consolidation.md   # IAM-001 v0.1 -> v0.2 consolidation
```

### [Sprint 01: Historical Consistency Semantics & IAM-I017](sprints/sprint_01_historical_consistency.md)
- Formalize requirement beyond simple monotonicity ($H_t \subseteq H_{t+1}$):
  $$s \in H \implies \text{ConsistentHistoricalState}(s, \Sigma)$$
- Verify mutual consistency among history ($H$), provenance ($P$), domain ($D$), binding ($B$), and manifestation ($M$).
- Formulate and independently test invariant `IAM-I017 Historical Consistency` against adversarial corruption scenarios.
- Deliverable: `reports/report_J_historical_consistency.md`.

### [Sprint 02: Transaction Identity & Non-Rebinding Semantics](sprints/sprint_02_transaction_identity.md)
- Formalize transaction semantics: $\text{TransactionId} \to \text{at most one SID}$.
- Guarantee idempotent replay for $(tx, sid)$ and mandatory rejection for $(tx, \text{different\_sid})$.
- Enforce that transaction tables can never be used to bypass historical non-reuse.
- Deliverable: `reports/report_K_transaction_semantics.md`.

### [Sprint 03: Architectural Decisions — Multi-Root & Derived Allocation](sprints/sprint_03_multi_root_and_derived_allocation.md)
- Analyze Multi-Root Identity: Model A (Universal single root), Model B (Independent roots with $\text{GlobalIdentity} = (\text{Root}, \text{SID})$), Model C (Federated roots).
- Analyze Derived Allocation: Differentiate deterministic derivation $SID = F(\text{parent}, \text{local})$ from authorized allocation; evaluate domain containment $F(k) \in D$, injectivity, and non-membership in $H$.
- Deliverables: `reports/report_N_multi_root_decision.md`, `reports/report_O_derived_allocation.md`.

### [Sprint 04: Specification Amendments Consolidation (IAM-001 v0.2)](sprints/sprint_04_specification_amendments_consolidation.md)
- Consolidate all verified amendments into the parent specification, progressing IAM-001 from v0.1 to v0.2.
- Preserve explicit change history with rationale and test evidence for every semantic change.
- Deliverable: `reports/report_I_iam001_amendments.md`.

---

## 4. Milestone Exit Criteria

1. Historical consistency is normatively defined and protected by invariant `IAM-I017`.
2. Transaction rebinding is strictly forbidden by normative rule and invariant check.
3. Multi-root and derived-allocation architectural decisions are formally documented with unambiguous boundaries.
4. `reports/report_I_iam001_amendments.md` documents IAM-001 v0.2 with zero modifications to concrete SID encodings.
