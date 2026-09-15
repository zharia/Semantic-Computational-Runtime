# Sprint 01: OpenVDB Runtime Initialization & Adapter

**Parent Milestone:** [Milestone 008: PI-CAVE-001H OpenVDB Volumetric Provider](../spec.md)  
**Derived from:** `spec.md` (Sections 22, 75)  
**Governing Documents:** [`docs/118_LIBRARY_DOMAIN_AND_SUBDOMAIN_MODEL.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/docs/118_LIBRARY_DOMAIN_AND_SUBDOMAIN_MODEL.md)  
**Status:** Planned  

---

## 1. Mission

Initialize the OpenVDB C++ runtime environment, establish memory management policies, and implement the Provider Adapter boundary wrapping OpenVDB grid instances behind the SCR spatial provider interface.

---

## 2. Technical Specifications

### 2.1 Provider Adapter Interface
```cpp
// providers/spatial/openvdb/src/cave_openvdb_adapter.h
#include <openvdb/openvdb.h>

class CaveOpenVdbAdapter {
public:
    CaveOpenVdbAdapter();
    void initialize();
    
    // Grid management
    uint64_t createFloatGrid(float background_val = 0.0f, float voxel_size = 0.01f);
    uint64_t createVec3Grid(openvdb::Vec3f background_val = openvdb::Vec3f(0.0f), float voxel_size = 0.01f);
    void releaseGrid(uint64_t grid_id);
    
    // Value access
    void setValueFloat(uint64_t grid_id, int x, int y, int z, float value);
    float getValueFloat(uint64_t grid_id, int x, int y, int z);
    
    // World transforms
    openvdb::Vec3R indexToWorld(uint64_t grid_id, int x, int y, int z);
    openvdb::Coord worldToIndex(uint64_t grid_id, double wx, double wy, double wz);
};
```

---

## 3. Verification & Testing Tasks

1. **Initialization & Cleanup:** Verify that `openvdb::initialize()` executes without crashing or conflicting with host allocators.
2. **Index-to-World Transform:** Test grid with voxel size $0.02\text{m}$; assert coordinate $(10, 20, 30)$ maps to world point $(0.2, 0.4, 0.6)$.
3. **Sparse Node Allocation:** Write 10 voxels scattered across a $1000 \times 1000 \times 1000$ index range; assert that memory consumption remains $< 1\text{MB}$ due to sparse B-tree allocation.
