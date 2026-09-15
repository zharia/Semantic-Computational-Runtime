# Milestone 008: PI-CAVE-001H — OpenVDB Volumetric Spatial Provider

**Parent RoadMap:** [milestones/README.md](../README.md)  
**Target Area:** `applications/cave/program_increments/v0.0.1_PI-CAVE-001/milestones/008_PI-CAVE-001H_openvdb/`  
**Derived from:** `spec.md` (Sections 22, 23, 28, 55, 75, 93, 94)  
**Governing Documents:** [`docs/117_FIELD_PARTITIONING_AND_DISTRIBUTED_EXECUTION.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/docs/117_FIELD_PARTITIONING_AND_DISTRIBUTED_EXECUTION.md), [`docs/119_SEMANTIC_REPRESENTATION_AND_INTERCHANGE_MODEL.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/docs/119_SEMANTIC_REPRESENTATION_AND_INTERCHANGE_MODEL.md)  
**Status:** Planned  

---

## 1. Objective

Integrate the **OpenVDB C++ sparse volumetric grid library** as a subordinate spatial field provider in SCR. Wrap OpenVDB data structures (`FloatGrid`, `Vec3SGrid`) behind SCR provider contracts, map semantic spatial fields (ScalarField, VectorField, DensityField, VelocityField, DistanceField / LevelSet) to OpenVDB sparse trees, and evaluate GPU NanoVDB leaf structures for hardware-accelerated queries.

---

## 2. Compliance with Authoritative Architecture

1. **Field Primacy ([`docs/103_SEMANTIC_MODEL.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/docs/103_SEMANTIC_MODEL.md)):**
   A spatial field in SCR is a computational entity mapping points in space $\mathbb{R}^3$ to values $\mathcal{V}$. OpenVDB is a sparse B-tree representation of that field; it is NOT the field definition itself.
2. **Provider Subordination ([`docs/102_ARCHITECTURE.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/docs/102_ARCHITECTURE.md)):**
   Removing or replacing OpenVDB with Field3D, sparse voxel octrees, or analytical field functions must not invalidate the semantic field definition in SCR.
3. **Sparse Representation ([`docs/117_FIELD_PARTITIONING_AND_DISTRIBUTED_EXECUTION.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/docs/117_FIELD_PARTITIONING_AND_DISTRIBUTED_EXECUTION.md)):**
   Volumetric fields must utilize OpenVDB sparse tree indexing so memory scales with active surface boundary volume ($O(N^2)$), rather than dense 3D bounding boxes ($O(N^3)$).

---

## 3. Sprint Breakdown

```text
008_PI-CAVE-001H_openvdb/
├── spec.md
└── sprints/
    ├── sprint_01_openvdb_runtime_and_adapter.md   # OpenVDB C++ runtime wrapper & Float/Vec3S grids
    ├── sprint_02_spatial_field_mapping.md         # Mapping density, velocity, level-sets to VDB trees
    └── sprint_03_nanovdb_gpu_evaluation.md        # NanoVDB read-only leaf grid generation & GPU queries
```

### [Sprint 01: OpenVDB Runtime Initialization & Adapter](sprints/sprint_01_openvdb_runtime_and_adapter.md)
- Initialize OpenVDB library (`openvdb::initialize()`), configure threading and memory allocators.
- Implement the C++/Mojo Provider Adapter interface wrapping OpenVDB grid handles.
- Support linear and affine coordinate transform mappings between OpenVDB index space and SCR world space.

### [Sprint 02: Semantic Spatial Field Mapping](sprints/sprint_02_spatial_field_mapping.md)
- Map SCR `DensityField` $\to$ `openvdb::FloatGrid` (scalar density values).
- Map SCR `VelocityField` $\to$ `openvdb::Vec3SGrid` (3D vector velocities).
- Map SCR `LevelSetField` $\to$ narrow-band signed distance field (SDF) grids.
- Implement voxel point sampling and trilinear interpolation queries.

### [Sprint 03: NanoVDB GPU Volume Evaluation](sprints/sprint_03_nanovdb_gpu_evaluation.md)
- Convert host OpenVDB grids into contiguous, linearized NanoVDB leaf buffers (`nanovdb::openvdbToNanoVDB`).
- Upload NanoVDB buffers to GPU memory for zero-copy read-only shader access.
- Benchmark raymarching performance on GPU.

---

## 4. Milestone Exit Criteria

1. OpenVDB adapter compiles and executes correctly within SCR runtime environment.
2. Density, velocity, and distance fields accurately instantiate and query values in world space.
3. Sparse memory footprint verified: active voxels restricted to narrow bands around active geometry.
4. NanoVDB conversion pipeline successfully executes without data corruption.
