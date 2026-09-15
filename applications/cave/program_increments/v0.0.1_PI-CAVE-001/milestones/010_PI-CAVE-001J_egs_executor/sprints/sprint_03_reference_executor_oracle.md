# Sprint 03: Reference Executor Semantic Oracle

**Parent Milestone:** [Milestone 010: PI-CAVE-001J EGS & Reference Executor](../spec.md)  
**Derived from:** `spec.md` (Sections 33, 36, 37, 38)  
**Governing Documents:** [`docs/114_REFERENCE_EXECUTOR_SEMANTIC_CONFORMANCE.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/docs/114_REFERENCE_EXECUTOR_SEMANTIC_CONFORMANCE.md), [`docs/116_SCR_MLIR_DIALECT_SPECIFICATION.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/docs/116_SCR_MLIR_DIALECT_SPECIFICATION.md), [`docs/120_SCR_Core_MLIR_Mojo_Relationship.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/docs/120_SCR_Core_MLIR_Mojo_Relationship.md)  
**Status:** Planned  

---

## 1. Mission

Connect the canonical Mojo Reference Executor as the authoritative semantic oracle for Cave, establishing differential verification between high-level Mojo semantic execution and lowered MLIR / native provider execution.

---

## 2. Technical Specifications & Differential Verification Pipeline

```text
                     Semantic Spatial Transition
                                 │
                 ┌───────────────┴───────────────┐
                 ▼                               ▼
       Mojo Reference Executor             MLIR Pipeline
          (Canonical Oracle)               (Lowering / Passes)
                 │                               │
                 ▼                               ▼
       Reference State Output             Native Compiled Output
                 │                               │
                 └───────────────┬───────────────┘
                                 ▼
                     Differential Comparator
                                 │
                   (Assert State Equivalence ≡)
```

### 2.1 The Differential Conformance Rule
If lowered MLIR execution disagrees with the Mojo Reference Executor:
1. Determine which implementation diverged from the normative specification.
2. The specification is the sole authority; correct the diverging implementation.
3. Add a permanent regression test to the test suite.

---

## 3. Verification & Testing Tasks

1. **Spatial Differential Test:** Lower a 3D matrix transform composition pipeline to MLIR (`mlir-opt` $\to$ LLVM $\to$ native); compare output against Mojo Reference Executor; assert numerical equivalence within $10^{-6}$.
2. **State Transition Differential Test:** Execute an 8-step window move and resize pipeline in both the Reference Executor and native EGS; assert bitwise identical semantic hypergraph state.
3. **Automated Differential Test Script:** Implement `test_differential_cave.sh` in the test architecture.
