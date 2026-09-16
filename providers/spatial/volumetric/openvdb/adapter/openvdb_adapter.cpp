#include "openvdb_c_api.h"

#include <unordered_map>
#include <memory>
#include <cmath>
#include <cstring>
#include <cstdlib>
#include <vector>
#include <algorithm>

#if __has_include(<openvdb/openvdb.h>)
#include <openvdb/openvdb.h>
#include <openvdb/tools/Interpolation.h>
#define SCR_HAS_NATIVE_OPENVDB 1
#else
#define SCR_HAS_NATIVE_OPENVDB 0
#endif

// Internal Wrapper Representation
struct VdbInternalGrid {
    int grid_type;
    float background;
    
#if SCR_HAS_NATIVE_OPENVDB
    openvdb::FloatGrid::Ptr native_float_grid;
    openvdb::Vec3SGrid::Ptr native_vec_grid;
#else
    // Fallback self-contained sparse hash map representation for headless testing
    struct CoordHash {
        std::size_t operator()(const uint64_t key) const noexcept {
            // Splitmix64 hash
            uint64_t z = key + 0x9e3779b97f4a7c15ULL;
            z = (z ^ (z >> 30)) * 0xbf58476d1ce4e5b9ULL;
            z = (z ^ (z >> 27)) * 0x94d049bb133111ebULL;
            return (size_t)(z ^ (z >> 31));
        }
    };

    static uint64_t pack_coord(int32_t x, int32_t y, int32_t z) {
        uint64_t ux = (uint32_t)x;
        uint64_t uy = (uint32_t)y;
        uint64_t uz = (uint32_t)z;
        return (ux & 0x1FFFFF) | ((uy & 0x1FFFFF) << 21) | ((uz & 0x3FFFFF) << 42);
    }

    std::unordered_map<uint64_t, float, CoordHash> scalar_voxels;
    std::unordered_map<uint64_t, std::vector<float>, CoordHash> vector_voxels;
#endif
};

extern "C" {

int vdb_runtime_initialize(void) {
#if SCR_HAS_NATIVE_OPENVDB
    openvdb::initialize();
#endif
    return VDB_SUCCESS;
}

void vdb_runtime_shutdown(void) {
#if SCR_HAS_NATIVE_OPENVDB
    openvdb::uninitialize();
#endif
}

VdbGridHandle vdb_grid_create_scalar(float background) {
    auto* grid = new (std::nothrow) VdbInternalGrid();
    if (!grid) return nullptr;

    grid->grid_type = VDB_GRID_TYPE_SCALAR_FLOAT;
    grid->background = background;

#if SCR_HAS_NATIVE_OPENVDB
    grid->native_float_grid = openvdb::FloatGrid::create(background);
#endif
    return static_cast<VdbGridHandle>(grid);
}

VdbGridHandle vdb_grid_create_vector(void) {
    auto* grid = new (std::nothrow) VdbInternalGrid();
    if (!grid) return nullptr;

    grid->grid_type = VDB_GRID_TYPE_VECTOR_FLOAT;
    grid->background = 0.0f;

#if SCR_HAS_NATIVE_OPENVDB
    grid->native_vec_grid = openvdb::Vec3SGrid::create(openvdb::Vec3s(0.0f, 0.0f, 0.0f));
#endif
    return static_cast<VdbGridHandle>(grid);
}

int vdb_grid_set_voxel_scalar(VdbGridHandle handle, int32_t x, int32_t y, int32_t z, float val) {
    if (!handle) return VDB_ERR_INVALID_HANDLE;
    auto* grid = static_cast<VdbInternalGrid*>(handle);
    if (grid->grid_type != VDB_GRID_TYPE_SCALAR_FLOAT) return VDB_ERR_TYPE_MISMATCH;

#if SCR_HAS_NATIVE_OPENVDB
    auto accessor = grid->native_float_grid->getAccessor();
    accessor.setValue(openvdb::Coord(x, y, z), val);
#else
    uint64_t k = VdbInternalGrid::pack_coord(x, y, z);
    grid->scalar_voxels[k] = val;
#endif
    return VDB_SUCCESS;
}

float vdb_grid_get_voxel_scalar(VdbGridHandle handle, int32_t x, int32_t y, int32_t z) {
    if (!handle) return 0.0f;
    auto* grid = static_cast<VdbInternalGrid*>(handle);
    if (grid->grid_type != VDB_GRID_TYPE_SCALAR_FLOAT) return grid->background;

#if SCR_HAS_NATIVE_OPENVDB
    auto accessor = grid->native_float_grid->getAccessor();
    return accessor.getValue(openvdb::Coord(x, y, z));
#else
    uint64_t k = VdbInternalGrid::pack_coord(x, y, z);
    auto it = grid->scalar_voxels.find(k);
    if (it != grid->scalar_voxels.end()) {
        return it->second;
    }
    return grid->background;
#endif
}

int vdb_grid_set_voxel_vector(VdbGridHandle handle, int32_t x, int32_t y, int32_t z, float vx, float vy, float vz) {
    if (!handle) return VDB_ERR_INVALID_HANDLE;
    auto* grid = static_cast<VdbInternalGrid*>(handle);
    if (grid->grid_type != VDB_GRID_TYPE_VECTOR_FLOAT) return VDB_ERR_TYPE_MISMATCH;

#if SCR_HAS_NATIVE_OPENVDB
    auto accessor = grid->native_vec_grid->getAccessor();
    accessor.setValue(openvdb::Coord(x, y, z), openvdb::Vec3s(vx, vy, vz));
#else
    uint64_t k = VdbInternalGrid::pack_coord(x, y, z);
    grid->vector_voxels[k] = {vx, vy, vz};
#endif
    return VDB_SUCCESS;
}

int vdb_grid_get_voxel_vector(VdbGridHandle handle, int32_t x, int32_t y, int32_t z, float out_v3[3]) {
    if (!handle || !out_v3) return VDB_ERR_INVALID_HANDLE;
    auto* grid = static_cast<VdbInternalGrid*>(handle);
    if (grid->grid_type != VDB_GRID_TYPE_VECTOR_FLOAT) return VDB_ERR_TYPE_MISMATCH;

#if SCR_HAS_NATIVE_OPENVDB
    auto accessor = grid->native_vec_grid->getAccessor();
    openvdb::Vec3s val = accessor.getValue(openvdb::Coord(x, y, z));
    out_v3[0] = val.x();
    out_v3[1] = val.y();
    out_v3[2] = val.z();
#else
    uint64_t k = VdbInternalGrid::pack_coord(x, y, z);
    auto it = grid->vector_voxels.find(k);
    if (it != grid->vector_voxels.end()) {
        out_v3[0] = it->second[0];
        out_v3[1] = it->second[1];
        out_v3[2] = it->second[2];
    } else {
        out_v3[0] = 0.0f;
        out_v3[1] = 0.0f;
        out_v3[2] = 0.0f;
    }
#endif
    return VDB_SUCCESS;
}

float vdb_grid_sample_scalar(VdbGridHandle handle, float world_x, float world_y, float world_z) {
    if (!handle) return 0.0f;
    auto* grid = static_cast<VdbInternalGrid*>(handle);
    if (grid->grid_type != VDB_GRID_TYPE_SCALAR_FLOAT) return grid->background;

#if SCR_HAS_NATIVE_OPENVDB
    openvdb::tools::GridSampler<openvdb::FloatGrid, openvdb::tools::BoxSampler> sampler(*grid->native_float_grid);
    return sampler.wsSample(openvdb::Vec3R(world_x, world_y, world_z));
#else
    // Trilinear interpolation fallback
    int x0 = (int)std::floor(world_x);
    int y0 = (int)std::floor(world_y);
    int z0 = (int)std::floor(world_z);

    float tx = world_x - (float)x0;
    float ty = world_y - (float)y0;
    float tz = world_z - (float)z0;

    auto get_v = [&](int x, int y, int z) -> float {
        return vdb_grid_get_voxel_scalar(handle, x, y, z);
    };

    float c000 = get_v(x0, y0, z0);
    float c100 = get_v(x0 + 1, y0, z0);
    float c010 = get_v(x0, y0 + 1, z0);
    float c110 = get_v(x0 + 1, y0 + 1, z0);
    float c001 = get_v(x0, y0, z0 + 1);
    float c101 = get_v(x0 + 1, y0, z0 + 1);
    float c011 = get_v(x0, y0 + 1, z0 + 1);
    float c111 = get_v(x0 + 1, y0 + 1, z0 + 1);

    float c00 = c000 * (1.0f - tx) + c100 * tx;
    float c10 = c010 * (1.0f - tx) + c110 * tx;
    float c01 = c001 * (1.0f - tx) + c101 * tx;
    float c11 = c011 * (1.0f - tx) + c111 * tx;

    float c0 = c00 * (1.0f - ty) + c10 * ty;
    float c1 = c01 * (1.0f - ty) + c11 * ty;

    return c0 * (1.0f - tz) + c1 * tz;
#endif
}

int vdb_grid_advect(VdbGridHandle density_grid, VdbGridHandle velocity_grid, float dt) {
    if (!density_grid || !velocity_grid) return VDB_ERR_INVALID_HANDLE;
    auto* d_grid = static_cast<VdbInternalGrid*>(density_grid);
    auto* v_grid = static_cast<VdbInternalGrid*>(velocity_grid);

    if (d_grid->grid_type != VDB_GRID_TYPE_SCALAR_FLOAT || v_grid->grid_type != VDB_GRID_TYPE_VECTOR_FLOAT) {
        return VDB_ERR_TYPE_MISMATCH;
    }

#if SCR_HAS_NATIVE_OPENVDB
    // For native OpenVDB, perform semi-Lagrangian backward trace across active voxels
    auto d_acc = d_grid->native_float_grid->getAccessor();
    auto v_acc = v_grid->native_vec_grid->getAccessor();
    openvdb::FloatGrid::Ptr new_grid = d_grid->native_float_grid->deepCopy();
    auto new_acc = new_grid->getAccessor();

    openvdb::tools::GridSampler<openvdb::FloatGrid, openvdb::tools::BoxSampler> sampler(*d_grid->native_float_grid);
    for (openvdb::FloatGrid::ValueOnIter iter = d_grid->native_float_grid->beginValueOn(); iter; ++iter) {
        openvdb::Coord coord = iter.getCoord();
        openvdb::Vec3s vel = v_acc.getValue(coord);
        openvdb::Vec3R back_pos((double)coord.x() - (double)vel.x() * dt,
                                (double)coord.y() - (double)vel.y() * dt,
                                (double)coord.z() - (double)vel.z() * dt);
        float sampled = sampler.isSample(back_pos);
        new_acc.setValue(coord, sampled);
    }
    d_grid->native_float_grid = new_grid;
#else
    // Fallback semi-Lagrangian advection
    auto copy_map = d_grid->scalar_voxels;
    for (auto& pair : copy_map) {
        int32_t x = (int32_t)(pair.first & 0x1FFFFF);
        int32_t y = (int32_t)((pair.first >> 21) & 0x1FFFFF);
        int32_t z = (int32_t)((pair.first >> 42) & 0x3FFFFF);
        // sign extend
        if (x & 0x100000) x |= ~0x1FFFFF;
        if (y & 0x100000) y |= ~0x1FFFFF;
        if (z & 0x200000) z |= ~0x3FFFFF;

        float vel[3] = {0.0f, 0.0f, 0.0f};
        vdb_grid_get_voxel_vector(velocity_grid, x, y, z, vel);

        float src_x = (float)x - vel[0] * dt;
        float src_y = (float)y - vel[1] * dt;
        float src_z = (float)z - vel[2] * dt;

        float sampled = vdb_grid_sample_scalar(density_grid, src_x, src_y, src_z);
        d_grid->scalar_voxels[pair.first] = sampled;
    }
#endif
    return VDB_SUCCESS;
}

uint64_t vdb_grid_active_voxel_count(VdbGridHandle handle) {
    if (!handle) return 0;
    auto* grid = static_cast<VdbInternalGrid*>(handle);

#if SCR_HAS_NATIVE_OPENVDB
    if (grid->grid_type == VDB_GRID_TYPE_SCALAR_FLOAT) {
        return grid->native_float_grid->activeVoxelCount();
    } else {
        return grid->native_vec_grid->activeVoxelCount();
    }
#else
    if (grid->grid_type == VDB_GRID_TYPE_SCALAR_FLOAT) {
        return grid->scalar_voxels.size();
    } else {
        return grid->vector_voxels.size();
    }
#endif
}

int vdb_grid_bounding_box(VdbGridHandle handle, int32_t out_bbox[6]) {
    if (!handle || !out_bbox) return VDB_ERR_INVALID_HANDLE;
    auto* grid = static_cast<VdbInternalGrid*>(handle);

#if SCR_HAS_NATIVE_OPENVDB
    openvdb::CoordBBox bbox;
    if (grid->grid_type == VDB_GRID_TYPE_SCALAR_FLOAT) {
        bbox = grid->native_float_grid->evalActiveVoxelBoundingBox();
    } else {
        bbox = grid->native_vec_grid->evalActiveVoxelBoundingBox();
    }
    out_bbox[0] = bbox.min().x();
    out_bbox[1] = bbox.min().y();
    out_bbox[2] = bbox.min().z();
    out_bbox[3] = bbox.max().x();
    out_bbox[4] = bbox.max().y();
    out_bbox[5] = bbox.max().z();
#else
    if (grid->scalar_voxels.empty() && grid->vector_voxels.empty()) {
        std::memset(out_bbox, 0, sizeof(int32_t) * 6);
        return VDB_SUCCESS;
    }
    int min_x = 1000000, min_y = 1000000, min_z = 1000000;
    int max_x = -1000000, max_y = -1000000, max_z = -1000000;
    for (const auto& p : grid->scalar_voxels) {
        int32_t x = (int32_t)(p.first & 0x1FFFFF);
        int32_t y = (int32_t)((p.first >> 21) & 0x1FFFFF);
        int32_t z = (int32_t)((p.first >> 42) & 0x3FFFFF);
        if (x & 0x100000) x |= ~0x1FFFFF;
        if (y & 0x100000) y |= ~0x1FFFFF;
        if (z & 0x200000) z |= ~0x3FFFFF;
        min_x = std::min(min_x, (int)x); max_x = std::max(max_x, (int)x);
        min_y = std::min(min_y, (int)y); max_y = std::max(max_y, (int)y);
        min_z = std::min(min_z, (int)z); max_z = std::max(max_z, (int)z);
    }
    out_bbox[0] = min_x; out_bbox[1] = min_y; out_bbox[2] = min_z;
    out_bbox[3] = max_x; out_bbox[4] = max_y; out_bbox[5] = max_z;
#endif
    return VDB_SUCCESS;
}

void vdb_grid_destroy(VdbGridHandle handle) {
    if (!handle) return;
    auto* grid = static_cast<VdbInternalGrid*>(handle);
    delete grid;
}

} // extern "C"
