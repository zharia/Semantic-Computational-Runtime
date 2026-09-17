# Milestone 005: MLIR Material & STC Dialect

## Metadata
- **Milestone ID**: `005_MLIRMaterialSTCDialect`
- **Program Increment**: `v0.0.2`
- **Domain**: MLIR Compilers / Semantic Intermediate Representation (`lib/001_Core/MLIR`)
- **Status**: Operational / Accepted
- **Exit Gate Date**: 2026-09-16
- **Policy Compliance**: SCR Rule 8 (MLIR-First Policy)

---

## 1. Executive Summary
Milestone 005 establishes the canonical MLIR TableGen operations, type system, canonicalization rules, and lowering passes for material lookups, constitutive physics tensor evaluation, and cellular semantic transition calculus (STC). In strict compliance with SCR Rule 8, semantic material operations lower directly into standard MLIR dialects (`scf`, `affine`, `gpu`, `llvm`).

---

## 2. Sprint Index
| Sprint | Name | Status | Artifacts |
|---|---|:---:|---|
| **Sprint 01** | TableGen Dialect Definition (`scr.material` & `stc`) | ACCEPTED | [`sprint_01_tablegen_dialect_definition`](file:///home/kobus/Projects/Semantic-Computational-Runtime/program_increments/v0.0.2/milestones/005_MLIRMaterialSTCDialect/sprints/sprint_01_tablegen_dialect_definition/reports/progress_report.md) |
| **Sprint 02** | Verification Traits, Type System & Canonicalization | ACCEPTED | [`sprint_02_verification_traits_and_types`](file:///home/kobus/Projects/Semantic-Computational-Runtime/program_increments/v0.0.2/milestones/005_MLIRMaterialSTCDialect/sprints/sprint_02_verification_traits_and_types/reports/progress_report.md) |
| **Sprint 03** | Lowering Passes to `scf.parallel` and `gpu.launch_kernel` | ACCEPTED | [`sprint_03_lowering_to_scf_and_gpu`](file:///home/kobus/Projects/Semantic-Computational-Runtime/program_increments/v0.0.2/milestones/005_MLIRMaterialSTCDialect/sprints/sprint_03_lowering_to_scf_and_gpu/reports/progress_report.md) |
| **Sprint 04** | Verification Suite & Milestone Exit Gate | ACCEPTED | [`sprint_04_verification_and_gate`](file:///home/kobus/Projects/Semantic-Computational-Runtime/program_increments/v0.0.2/milestones/005_MLIRMaterialSTCDialect/sprints/sprint_04_verification_and_gate/reports/progress_report.md) |
