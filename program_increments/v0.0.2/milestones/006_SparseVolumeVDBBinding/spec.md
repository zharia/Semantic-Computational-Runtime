# Milestone 006 Specification: Sparse Volume VDB Binding

## 1. Scope & Objective
Establish sparse hierarchical volume representation for multi-material voxel fields with leaf-level compression, bounding box culling, and zero-copy GPU linear serialization.

## 2. Architecture
1. **Tree Hierarchy**: Root -> Internal Nodes -> Leaf Nodes ($8^3 = 512$ voxels).
2. **Active Voxel Bitmask**: 64-bit word masks indicating non-background voxels.
3. **Dilation Operators**: Topology dilation for propagating reactive fronts.
4. **NanoVDB Export**: Self-contained byte-aligned linear buffer for GPU compute.
