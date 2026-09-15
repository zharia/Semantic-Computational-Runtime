# Sprint 02: Semantic Spatial Field Mapping

**Parent Milestone:** [Milestone 008: PI-CAVE-001H OpenVDB Volumetric Provider](../spec.md)  
**Derived from:** `spec.md` (Sections 23, 55, 93)  
**Governing Documents:** [`docs/117_FIELD_PARTITIONING_AND_DISTRIBUTED_EXECUTION.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/docs/117_FIELD_PARTITIONING_AND_DISTRIBUTED_EXECUTION.md)  
**Status:** Planned  

---

## 1. Mission

Implement the bidirectional mapping between SCR high-level semantic fields (`DensityField`, `VelocityField`, `LevelSetField`) and low-level OpenVDB grid structures, supporting voxel manipulation, sparse tree traversal, and continuous spatial queries.

---

## 2. Technical Specifications

### 2.1 Semantic Field Mapping Matrix
| SCR Semantic Field Type | OpenVDB Physical Type | Grid Name | Semantic Usage in Cave |
|---|---|---|---|
| `DensityField` | `openvdb::FloatGrid` | `density` | Smoke, fog, visual field trails behind moving surfaces |
| `VelocityField` | `openvdb::Vec3SGrid` | `velocity` | Air currents, convective motion, surface drag impulses |
| `DistanceField` | `openvdb::FloatGrid` | `surface_sdf` | Signed distance field representing surface boundaries |

### 2.2 Continuous Value Interpolation
Implement continuous spatial evaluation in Mojo:
```mojo
struct SpatialFieldSampler:
    var provider_grid_id: Int

    fn sample_at_world_pos(self, pos: Point3D) -> Float64:
        # Calls C++ OpenVDB box/trilinear interpolation sampler
        ...
```

---

## 3. Verification & Testing Tasks

1. **Trilinear Interpolation Accuracy:** Sample density field between voxels $(0,0,0) = 0.0$ and $(1,0,0) = 1.0$; assert that position $(0.5, 0, 0)$ evaluates to $0.5 \pm 0.001$.
2. **Narrow-Band SDF Validation:** Generate a signed distance field around a planar quad surface; assert that points at distance $d$ from the quad evaluate to value $d$.
3. **Active Voxel Counting:** Verify that tree pruning algorithms clean up near-zero voxels ($< 10^{-4}$) to prevent memory bloat over time.
