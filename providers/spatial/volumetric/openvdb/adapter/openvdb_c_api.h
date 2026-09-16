#ifndef SCR_PROVIDERS_OPENVDB_C_API_H
#define SCR_PROVIDERS_OPENVDB_C_API_H

#include <stdint.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Return codes */
#define VDB_SUCCESS                0
#define VDB_ERR_INVALID_HANDLE   (-1)
#define VDB_ERR_TYPE_MISMATCH    (-2)
#define VDB_ERR_OUT_OF_MEMORY    (-3)
#define VDB_ERR_COMPUTATION      (-4)

/* Grid type descriptors */
#define VDB_GRID_TYPE_SCALAR_FLOAT 1
#define VDB_GRID_TYPE_VECTOR_FLOAT 2

typedef void* VdbGridHandle;

/**
 * Initialize the OpenVDB provider runtime environment.
 * Must be called once before grid creation.
 */
int vdb_runtime_initialize(void);

/**
 * Shut down the OpenVDB provider runtime environment.
 */
void vdb_runtime_shutdown(void);

/**
 * Create a sparse single-precision floating point scalar grid.
 * @param background Background value for inactive voxels.
 * @return Opaque handle to the grid, or NULL on allocation failure.
 */
VdbGridHandle vdb_grid_create_scalar(float background);

/**
 * Create a sparse single-precision 3D vector grid (Vec3s).
 * @return Opaque handle to the vector grid, or NULL on allocation failure.
 */
VdbGridHandle vdb_grid_create_vector(void);

/**
 * Set an active voxel in a scalar grid.
 */
int vdb_grid_set_voxel_scalar(VdbGridHandle handle, int32_t x, int32_t y, int32_t z, float val);

/**
 * Retrieve a voxel value from a scalar grid.
 */
float vdb_grid_get_voxel_scalar(VdbGridHandle handle, int32_t x, int32_t y, int32_t z);

/**
 * Set an active voxel in a vector grid.
 */
int vdb_grid_set_voxel_vector(VdbGridHandle handle, int32_t x, int32_t y, int32_t z, float vx, float vy, float vz);

/**
 * Retrieve a voxel value from a vector grid.
 */
int vdb_grid_get_voxel_vector(VdbGridHandle handle, int32_t x, int32_t y, int32_t z, float out_v3[3]);

/**
 * Sample a scalar field continuously at world coordinates (trilinear interpolation).
 */
float vdb_grid_sample_scalar(VdbGridHandle handle, float world_x, float world_y, float world_z);

/**
 * Perform a single semi-Lagrangian advection step:
 * Advances density_grid along velocity_grid by timestep dt.
 */
int vdb_grid_advect(VdbGridHandle density_grid, VdbGridHandle velocity_grid, float dt);

/**
 * Return the total number of currently active voxels in the sparse tree.
 */
uint64_t vdb_grid_active_voxel_count(VdbGridHandle handle);

/**
 * Retrieve the active bounding box bounds [min_x, min_y, min_z, max_x, max_y, max_z].
 */
int vdb_grid_bounding_box(VdbGridHandle handle, int32_t out_bbox[6]);

/**
 * Destroy a grid handle and release all internal tree memory.
 */
void vdb_grid_destroy(VdbGridHandle handle);

#ifdef __cplusplus
}
#endif

#endif /* SCR_PROVIDERS_OPENVDB_C_API_H */
