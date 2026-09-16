# openvdb Provider Contract

**Provider:** openvdb  
**Domain:** spatial  
**Subdomain:** volumetric  
**Version:** 0.1.0  
**Status:** Normative Contract  
**Governing Documents:** [`docs/108_EXECUTION_MANIFESTATION_AND_CONFORMANCE.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/docs/108_EXECUTION_MANIFESTATION_AND_CONFORMANCE.md), [`docs/117_FIELD_PARTITIONING_AND_DISTRIBUTED_EXECUTION.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/docs/117_FIELD_PARTITIONING_AND_DISTRIBUTED_EXECUTION.md)  

---

## 1. Contract Overview

This document specifies the concrete Provider Contract implemented by the `openvdb` provider for the `spatial/volumetric` capability domain. It defines the operations, boundaries, invariants, numerical semantics, and failure modes supported by the native OpenVDB adapter.

The OpenVDB provider implements the execution substrate for sparse volumetric scalar fields (density, distance fields) and vector fields (velocity).

---

## 2. Semantic Capabilities

The provider declares and satisfies the following capability tags:
* `[spatial, volumetric, sparse_grid]` — Hierarchical sparse tree data structure.
* `[field, scalar, float_grid]` — 32-bit floating point scalar field.
* `[field, vector, vec3s_grid]` — 3-component single-precision vector field.
* `[field, transformation, advection]` — Semi-Lagrangian and RK3 field advection.
* `[field, levelset, narrow_band]` — Signed distance field representation.

---

## 3. Operations & Signatures

### 3.1 Grid Lifecycle
* `vdb_grid_create_scalar(float background_value) -> GridHandle`
* `vdb_grid_create_vector() -> GridHandle`
* `vdb_grid_destroy(GridHandle handle) -> void`

### 3.2 Voxel Access & Mutation
* `vdb_grid_set_voxel_scalar(GridHandle handle, int x, int y, int z, float val) -> int`
* `vdb_grid_get_voxel_scalar(GridHandle handle, int x, int y, int z) -> float`
* `vdb_grid_set_voxel_vector(GridHandle handle, int x, int y, int z, float vx, float vy, float vz) -> int`
* `vdb_grid_get_voxel_vector(GridHandle handle, int x, int y, int z, float* out_v3) -> int`

### 3.3 Spatial Sampling & Field Evolution
* `vdb_grid_sample_scalar(GridHandle handle, float world_x, float world_y, float world_z) -> float`
* `vdb_grid_advect(GridHandle density_grid, GridHandle velocity_grid, float dt) -> int`
* `vdb_grid_active_voxel_count(GridHandle handle) -> uint64_t`
* `vdb_grid_bounding_box(GridHandle handle, int* min_xyz, int* max_xyz) -> int`

---

## 4. Preconditions & Postconditions

1. **Precondition (Handle Validity):** Any `GridHandle` passed into access or transformation functions must be non-null and allocated by this provider. Passing a dangling or foreign handle must return `VDB_ERR_INVALID_HANDLE` without memory corruption.
2. **Precondition (Grid Type Match):** Calling scalar operations on vector grids or vice versa must return `VDB_ERR_TYPE_MISMATCH`.
3. **Postcondition (Sparse Conservation):** Inactive background voxels must not consume heap nodes; tree leaf nodes must allocate only for active or non-background values.
4. **Postcondition (Advection Monotonicity):** An advection step with $dt > 0$ on a valid velocity field must transform density conservatively without introducing NaN or infinite values.

---

## 5. State & Effects

* Grid handles are mutable computational state references.
* Advection operations mutate the density grid in place using double-buffered leaf swapping.
* All allocations are confined to process heap; zero global static state is mutated.

---

## 6. Failure Semantics & Error Codes

All operations return standard negative status codes on failure:
* `VDB_SUCCESS = 0`
* `VDB_ERR_INVALID_HANDLE = -1`
* `VDB_ERR_TYPE_MISMATCH = -2`
* `VDB_ERR_OUT_OF_MEMORY = -3`
* `VDB_ERR_COMPUTATION_FAILED = -4`

The provider guarantees that failed operations leave the input grids in an uncorrupted, recoverable state.

---

## 7. Resource Requirements

* **Memory:** Dynamic sparse tree scaling $O(V_{\text{active}})$. Typical memory per active leaf node (8x8x8 voxels) is approximately 2 KB.
* **Threading:** Thread-safe concurrent read-sampling; external synchronization required for concurrent write mutations.
* **Dependencies:** `libopenvdb`, `tbb`, `cblosc`.

---

## 8. Determinism & Numerical Semantics

* Floating-point operations adhere to IEEE 754 single precision (`float32`).
* Sequential field evaluation produces bitwise identical results across runs on the same CPU architecture.
* Spatial interpolation uses trilinear interpolation across voxel neighbors.

---

## 9. Conformance Test Suite

The provider is validated against the conformance suite in `tests/test_openvdb_contract.cpp`:
1. `test_scalar_grid_sparse_allocation()`: Verifies zero memory allocated for empty space.
2. `test_scalar_voxel_roundtrip()`: Verifies exact coordinate-to-value integrity.
3. `test_vector_field_evaluation()`: Verifies 3D velocity field sampling.
4. `test_field_advection_step()`: Verifies numerical stability during kinematic advection.
5. `test_handle_isolation_and_teardown()`: Verifies zero memory leaks upon grid destruction.
