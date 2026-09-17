/**
 * SCR Canonical Water SSFR & SPH Provider — C ABI Interface
 * ─────────────────────────────────────────────────────────────────────────────
 * Normative Header: providers/render/water_ssfr/adapter/water_ssfr_c_api.h
 */

#ifndef SCR_WATER_SSFR_C_API_H
#define SCR_WATER_SSFR_C_API_H

#include <stdint.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

#define WATER_SSFR_SUCCESS                0
#define WATER_SSFR_ERR_NULL_HANDLE       -1
#define WATER_SSFR_ERR_INVALID_ARG       -2
#define WATER_SSFR_ERR_OUT_OF_BOUNDS     -3

typedef void* WaterSSFRHandle;

typedef struct {
    float domain_min_x, domain_max_x;
    float domain_min_y, domain_max_y;
    float domain_min_z, domain_max_z;
    float particle_radius;      // World-space particle radius (e.g. 0.15m)
    float smoothing_radius;     // SPH h kernel radius (e.g. 0.40m)
    float rest_density;         // kg/m^3 (e.g. 1000.0f)
    float stiffness;            // Bulk modulus / Tait EOS constant (e.g. 1500.0f)
    float viscosity;            // Dynamic viscosity mu (e.g. 0.05f)
    float surface_tension;      // Artificial surface tension coefficient
    float gravity_y;            // Gravity acceleration (e.g. -9.81f)
    uint32_t max_particles;     // Maximum capacity
} WaterSSFRConfig;

typedef struct {
    float x, y, z;
    float vx, vy, vz;
    float density;
    float pressure;
} WaterParticleData;

typedef struct {
    float eye_x, eye_y, eye_z;
    float forward_x, forward_y, forward_z;
    float up_x, up_y, up_z;
    float fov_y_rad;
    float aspect_ratio;
    float near_clip;
    float far_clip;
} CameraViewProjection;

WaterSSFRHandle scr_water_ssfr_create(const WaterSSFRConfig* config);
void            scr_water_ssfr_destroy(WaterSSFRHandle handle);

int scr_water_ssfr_add_particle(WaterSSFRHandle handle, float x, float y, float z, float vx, float vy, float vz);
int scr_water_ssfr_step_simulation(WaterSSFRHandle handle, float dt);
int scr_water_ssfr_get_particle_count(WaterSSFRHandle handle, uint32_t* out_count);
int scr_water_ssfr_get_particle_data(WaterSSFRHandle handle, uint32_t index, WaterParticleData* out_data);

int scr_water_ssfr_rasterize_depth(WaterSSFRHandle handle, const CameraViewProjection* cam, uint32_t width, uint32_t height, float* out_depth_buffer);
int scr_water_ssfr_bilateral_filter(WaterSSFRHandle handle, const float* in_depth, float* out_smooth_depth, uint32_t width, uint32_t height, int filter_radius, float sigma_s, float sigma_r);
int scr_water_ssfr_reconstruct_normal(WaterSSFRHandle handle, const float* smooth_depth, uint32_t width, uint32_t height, uint32_t px, uint32_t py, float* out_nx, float* out_ny, float* out_nz);

#ifdef __cplusplus
}
#endif

#endif // SCR_WATER_SSFR_C_API_H
