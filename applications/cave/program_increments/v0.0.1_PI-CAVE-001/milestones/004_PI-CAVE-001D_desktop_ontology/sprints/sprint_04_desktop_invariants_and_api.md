# Sprint 04: Cave Invariant Suite & Desktop Application API

**Parent Milestone:** [Milestone 004: PI-CAVE-001D Desktop Ontology](../spec.md)  
**Derived from:** `spec.md` (Sections 45, 82)  
**Governing Documents:** [`docs/104_SEMANTIC_INVARIANTS.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/docs/104_SEMANTIC_INVARIANTS.md)  
**Status:** Planned  

---

## 1. Mission

Automate the verification of Cave-specific desktop invariants (`CAVE-INV-001` through `CAVE-INV-020`) and expose the programmatic Desktop Application API for high-level spatial window management.

---

## 2. Invariant Specifications (CAVE-INV-001 through 020)

| Invariant ID | Name | Semantic Invariant Rule |
|---|---|---|
| **CAVE-INV-001** | Desktop Exclusivity | Exactly one active Desktop entity exists per Cave session. |
| **CAVE-INV-002** | Workspace Membership | Every active workspace belongs to the active Desktop. |
| **CAVE-INV-003** | Active Workspace Uniqueness | At most one workspace is active/focused per Desktop at any instant. |
| **CAVE-INV-004** | Surface-to-Workspace Binding | Every surface is associated with exactly one workspace. |
| **CAVE-INV-005** | Surface Focus Scoping | Focused surface must reside in the currently active workspace. |
| **CAVE-INV-006** | Buffer Binding Validity | An attached buffer must point to a valid registered `BufferEntity`. |
| **CAVE-INV-007** | Application Process Integrity | A surface cannot exist without an active `ApplicationEntity`. |
| **CAVE-INV-008** | Spatial Frame Alignment | Surface frame parent must be the enclosing workspace frame. |
| **CAVE-INV-009** | Surface Bounds Positivity | Surface width and height must be strictly positive integers. |
| **CAVE-INV-010** | Z-Order Determinism | All surfaces in a workspace have distinct, deterministic Z-indices. |
| **CAVE-INV-011** | Focus Follows Z-Index | The top-most surface in Z-order receives active focus by default. |
| **CAVE-INV-012** | Input Event Boundedness | Pointer events deliver coordinates strictly normalized to $[0, 1] \times [0, 1]$. |
| **CAVE-INV-013** | Buffer Release Safety | Released buffers are never read by the compositor. |
| **CAVE-INV-014** | Workspace Transition Isolation | Surface position in workspace $W_1$ is unaffected by switching to $W_2$. |
| **CAVE-INV-015** | Manifestation Traceability | Every surface has at least one active rendering manifestation handle. |
| **CAVE-INV-016** | Application Exit Cleanup | When an application exits, all child surfaces are transitioned to `RETIRED`. |
| **CAVE-INV-017** | Inverse Mapping Invertibility | A ray hit at local $(u, v)$ unprojects back to world point on surface plane. |
| **CAVE-INV-018** | Zero-Copy Guarantee | Committed DMA-BUF buffers do not undergo CPU pixel copying. |
| **CAVE-INV-019** | Effect Influence Decay | Volumetric smoke velocity injections decay toward zero over time. |
| **CAVE-INV-020** | State Restoration Monotonicity | Restoring desktop state preserves all historical entity IDs. |

---

## 3. Desktop Application API Implementation

```mojo
struct DesktopApplicationAPI:
    var desktop: DesktopEntity

    fn create_surface(mut self, app_id: SemanticId, title: String, width: Int, height: Int) raises -> SemanticId:
        ...

    fn move_surface(mut self, surface_id: SemanticId, new_position: Vector3D) raises:
        ...

    fn focus_surface(mut self, surface_id: SemanticId) raises:
        ...

    fn destroy_surface(mut self, surface_id: SemanticId) raises:
        ...
```

### Verification Tasks:
1. Automated unit test suite verifying all 20 invariants against mocked window manager workloads.
2. Production of `reports/cave_desktop_invariants_report.md`.
