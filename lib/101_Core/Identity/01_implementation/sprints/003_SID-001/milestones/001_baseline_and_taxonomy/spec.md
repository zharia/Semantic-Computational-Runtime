# Milestone 001: Baseline Assessment & Verification Taxonomy

**Parent RoadMap:** [milestones/README.md](../README.md)  
**Target Area:** `lib/101_Core/Identity/01_implementation/sprints/003_SID-001/milestones/001_baseline_and_taxonomy/`  
**Derived from:** [spec.md](../../spec.md) (Sections 1, 3, 7, 17)  
**Status:** Planned  

---

## 1. Objective

Inspect the current IAM-RM-001 reference machine baseline without making uncoordinated modifications, capture complete reproducible baseline evidence, and establish the 4-tier verification taxonomy and evidence discipline for all subsequent verification work.

---

## 2. Context & Discovery Baseline

IAM-RM-001 transformed the IAM model into an executable reference machine and subjected it to bounded exploration, adversarial scenarios, and crash/recovery testing:
```text
N = 8
states explored       = 155
transitions attempted = 504
legal transitions     = 170
rejected transitions  = 334
invariant violations  = 0
adversarial scenarios = 25/25 PASS
```
Two implementation defects were discovered and corrected in IAM-RM-001:
1. **Counterexample 1:** Snapshot recovery could produce historical allocation state without corresponding provenance/domain/binding/manifestation consistency.
2. **Counterexample 2:** A transaction identifier could originally be reused for a different SID.

This milestone locks this baseline into an authoritative assessment report and enforces rigorous verification nomenclature.

---

## 3. Sprint Breakdown

```text
001_baseline_and_taxonomy/
├── spec.md
└── sprints/
    ├── sprint_01_baseline_assessment.md        # Baseline inspection, test run & report
    └── sprint_02_verification_classification.md# 4-tier verification taxonomy & evidence discipline
```

### [Sprint 01: IAM-RM-001 Baseline Assessment & Defect Audit](sprints/sprint_01_baseline_assessment.md)
- Inspect all files under `sprints/002_IAM-RM-001/` (`spec.md`, `src/iam_rm_001/`, `reports/`, `verification_evidence.json`).
- Isolate the exact implementation changes made in response to Counterexamples 1 & 2.
- Execute the existing test suite without modification and record exact parameters, transition counts, and git revision.
- Deliverable: `reports/step_1_baseline_assessment.md`.

### [Sprint 02: Verification Classification & Evidence Standards](sprints/sprint_02_verification_classification.md)
- Replace ambiguous claims ("formally enforced", "proven") with a four-tier taxonomy:
  - `MACHINE ENFORCED`
  - `EXECUTABLY CHECKED`
  - `BOUNDED-EXHAUSTIVELY VERIFIED`
  - `FORMALLY PROVEN`
- Define the 4-part evidence discipline: `Claim`, `Evidence`, `Inference`, `Limitation`.
- Deliverable: `reports/report_R_verification_classification.md`.

---

## 4. Milestone Exit Criteria

1. `reports/step_1_baseline_assessment.md` exists and details current implementation state, test results, invariant status, exploration parameters, known limitations, and revision hash.
2. No implementation code was modified during baseline capture.
3. `reports/report_R_verification_classification.md` establishes normative verification categories and evidence discipline for the entire project.
