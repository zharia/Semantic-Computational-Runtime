# Milestone 011: Reference Implementation and Conformance Gate

## 1. Scope & Objective

Establish evidence-backed semantic baseline and implement minimal executable SCR reference path demonstrating canonical SCR semantics → provider → observation → conformance verification.

Uses completed objective 002 results as starting point. Does not assume 002's claims are correct without independent verification.

## 2. Deliverables

- **A** Baseline Acceptance Report
- **B** Reference Implementation (minimal end-to-end semantic execution path)
- **C** Provider Adapter Specification
- **D** Conformance Harness (reusable tests)
- **E** Formal Artifacts (Lean proofs for mathematical claims)
- **F** Evidence and Status Updates
- **G** Final Implementation Report

## 3. Governing Principles

1. SCR is semantic authority for SCR contracts
2. Integrate rather than replace (Align → integrate → project → adapt → execute)
3. Evidence before claims
4. Minimize scope (smallest meaningful vertical slice)

## 4. Formal Invariants

1. Every acceptance criterion (AC-01 through AC-17) verifiably satisfied
2. Evidence statuses truthful (documented ≠ implemented ≠ tested ≠ validated)
3. No silent contradictions remain after final audit
4. Provider observations not treated as exact SCR state
5. Identity preservation verified across manifestation boundary

## 5. Exit Criteria

- [ ] Baseline inspection complete (AC-01, AC-02)
- [ ] No duplicated semantic model (AC-03)
- [ ] Real execution path demonstrated (AC-04)
- [ ] SID-to-provider mapping explicit and tested (AC-05)
- [ ] Transform correctness verified (AC-06)
- [ ] Lifecycle correctness verified (AC-07)
- [ ] Provider boundary documented (AC-08)
- [ ] Observation mapping defined (AC-09)
- [ ] Failure behavior tested (AC-10)
- [ ] Reusable conformance tests exist (AC-11)
- [ ] Negative tests challenge assumptions (AC-12)
- [ ] Formal claims supported by proofs (AC-13)
- [ ] Status is truthful and evidence-backed (AC-14)
- [ ] Scope controlled (AC-15)
- [ ] Reproducibility documented (AC-16)
- [ ] Remaining work explicit (AC-17)

## 6. Dependencies

- Milestone 010 (Provider Mapping, Verification & Gate) complete
- Objective 002 committed results available
- Lean/mathlib infrastructure functional
- Existing provider interfaces and adapters available

## 7. Phases → Sprints

| Phase | Sprint | Description |
|-------|--------|-------------|
| 1 | sprint_01 | Repository Archaeology |
| 2 | sprint_02 | Baseline Acceptance |
| 3 | sprint_03 | Slice Selection |
| 4 | sprint_04 | Contract Definition |
| 5 | sprint_05 | Reference Implementation |
| 6 | sprint_06 | Conformance Harness |
| 7 | sprint_07 | Formal Verification |
| 8 | sprint_08 | Adversarial Testing |
| 9 | sprint_09 | Documentation & Status |
| 10 | sprint_10 | Final Audit |

## 8. Explicit Prohibitions

See objective document §20. Key prohibitions:
- Assume 002's completion proves all claims
- Skip repository inspection
- Duplicate canonical SCR definitions
- Treat provider IDs as SID
- Claim formal verification without proof artifact
- Create mock-only evidence as real execution
