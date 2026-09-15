# Milestone 010: PI-CAVE-001J — EGS & Reference Executor Integration

**Parent RoadMap:** [milestones/README.md](../README.md)  
**Target Area:** `applications/cave/program_increments/v0.0.1_PI-CAVE-001/milestones/010_PI-CAVE-001J_egs_executor/`  
**Derived from:** `spec.md` (Sections 32, 33, 35, 36, 37, 38, 61, 63, 66)  
**Governing Documents:** [`docs/102_ARCHITECTURE.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/docs/102_ARCHITECTURE.md), [`docs/106_SEMANTIC_MACHINE_MODEL.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/docs/106_SEMANTIC_MACHINE_MODEL.md), [`docs/108_EXECUTION_MANIFESTATION_AND_CONFORMANCE.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/docs/108_EXECUTION_MANIFESTATION_AND_CONFORMANCE.md), [`docs/114_REFERENCE_EXECUTOR_SEMANTIC_CONFORMANCE.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/docs/114_REFERENCE_EXECUTOR_SEMANTIC_CONFORMANCE.md), [`docs/120_SCR_Core_MLIR_Mojo_Relationship.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/docs/120_SCR_Core_MLIR_Mojo_Relationship.md)  
**Status:** Planned  

---

## 1. Objective

Integrate the **Execution Graph Substrate (EGS)** and the canonical **Mojo Reference Executor** as the central runtime orchestration layer for Cave. Resolve provider capabilities dynamically from semantic contracts, orchestrate temporal frame evaluation across Wayland, rendering, and volumetric providers, and enforce differential execution verification against lowered MLIR code.

---

## 2. Compliance with Authoritative Architecture

1. **Provider Resolution Contract ([`docs/102_ARCHITECTURE.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/docs/102_ARCHITECTURE.md) §5.2):**
   EGS resolves capabilities dynamically: a semantic requirement (`NeedsRender2DQuad`, `NeedsSparseGridAdvection`) is matched against registered provider capability matrices. The semantic definition never names specific provider libraries.
2. **Reference Executor as Oracle ([`docs/114_REFERENCE_EXECUTOR_SEMANTIC_CONFORMANCE.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/docs/114_REFERENCE_EXECUTOR_SEMANTIC_CONFORMANCE.md)):**
   The Mojo Reference Executor executes pure semantic hypergraph transitions. If lowered C++ or MLIR execution disagrees with the Reference Executor, the specification governs and the lowering is corrected.
3. **MLIR First-Representation Policy ([`docs/116_SCR_MLIR_DIALECT_SPECIFICATION.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/docs/116_SCR_MLIR_DIALECT_SPECIFICATION.md)):**
   Standard MLIR dialects (`arith`, `memref`, `scf`, `func`) represent computational graphs; no custom shadow IRs are permitted.

---

## 3. Sprint Breakdown

```text
010_PI-CAVE-001J_egs_executor/
├── spec.md
└── sprints/
    ├── sprint_01_provider_capability_resolution.md # Capability matching & dynamic provider binding
    ├── sprint_02_egs_operational_orchestration.md   # Frame tick loop & provider synchronization
    └── sprint_03_reference_executor_oracle.md       # Mojo reference execution & differential verification
```

### [Sprint 01: Provider Capability Model & Resolution](sprints/sprint_01_provider_capability_resolution.md)
- Implement `ProviderCapabilityMatrix` querying system.
- Map semantic operational requests to matching providers:
  - Compositor capability $\to$ Louvre
  - 3D Rendering capability $\to$ OGRE / OpenGL
  - Volumetric capability $\to$ OpenVDB
- Verify hot-swapping mock providers during runtime tests.

### [Sprint 02: EGS Operational Orchestration](sprints/sprint_02_egs_operational_orchestration.md)
- Implement the EGS Frame Coordinator:
  $$\text{Input Poll} \longrightarrow \text{Spatial Update} \longrightarrow \text{Effect Step} \longrightarrow \text{Render Dispatch} \longrightarrow \text{Frame Present}$$
- Manage temporal frame timestamps and inter-provider synchronization fences.

### [Sprint 03: Reference Executor Semantic Oracle](sprints/sprint_03_reference_executor_oracle.md)
- Connect Mojo Reference Executor to the Cave hypergraph.
- Execute differential verification: assert state equivalence between Mojo reference execution and lowered provider manifestation.

---

## 4. Milestone Exit Criteria

1. EGS dynamically resolves and binds all required providers without hardcoded library references.
2. The temporal frame execution loop achieves jitter-free 60 FPS coordination.
3. Differential verification proves 100% equivalence between Reference Executor and native pipeline.
