# Sprint 04: Specification Amendments Consolidation (IAM-001 v0.2)

**Parent Milestone:** [Milestone 002: Normative Semantics & Amendments](../spec.md)  
**Derived from:** [spec.md](../../../spec.md) (Sections 19, 20)  
**Deliverable:** `reports/report_I_iam001_amendments.md`  
**Status:** Planned  

---

## 1. Mission

Consolidate all proven semantic amendments, architectural decisions, and newly defined invariants into a formal revision of the parent specification document, advancing IAM-001 from v0.1 to v0.2 while strictly preserving coordinate abstraction.

---

## 2. Mandatory Scope of Revision

The updated IAM-001 v0.2 specification must incorporate:

1. **Historical Recovery Consistency:**
   Normative requirement that snapshot/restore preserves complete provenance, domain, and lifecycle consistency.
2. **Transaction Identifier Invariance:**
   Normative rule prohibiting rebinding of transaction identifiers to distinct SIDs.
3. **Multi-Root Semantics:**
   Explicit normative specification of root boundary semantics ($\text{GlobalIdentity} = (\text{Root}, \text{SID})$).
4. **Derived Allocation Rules:**
   Explicit criteria separating deterministic derivation functions from domain allocation authority.
5. **Verification Taxonomy Integration:**
   Standardized categorization into `MACHINE ENFORCED`, `EXECUTABLY CHECKED`, `BOUNDED-EXHAUSTIVELY VERIFIED`, and `FORMALLY PROVEN`.
6. **Normative Invariant IAM-I017:**
   Formal addition of Historical Consistency to the canonical invariant suite.

---

## 3. Strict Negative Constraint: No Premature SID Representation

> **This sprint and milestone MUST NOT design the physical SID bit format.**
> 
> Forbidden activities:
> - Choosing 128-bit, 256-bit, or any fixed bit width.
> - Defining specific bit fields or bitmask layouts.
> - Embedding timestamps, authority generations, signatures, or root IDs into the coordinate.
> - Adopting UUID, ULID, or similar pre-packaged identifier schemes.
> 
> The coordinate geometry must remain entirely abstract. Physical encoding belongs exclusively to SID-001.

---

## 4. Deliverable Requirements

Author:
```text
lib/101_Core/Identity/01_implementation/sprints/003_SID-001/reports/report_I_iam001_amendments.md
```
Document:
- Comprehensive changelog detailing IAM-001 v0.1 $\to$ v0.2.
- Precise rationale and counterexample references for every amendment.
- Complete text of new normative rules and invariant definitions.
