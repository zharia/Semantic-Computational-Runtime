# SCR Provider Contract: Canonical SPH Fluid & Screen-Space Fluid Rendering

**Contract ID:** `SCR-CONTRACT-RENDER-WATER-SSFR-001`  
**Provider:** `providers/render/water_ssfr`  
**Language ABI:** C ABI (`water_ssfr_c_api.h`)

---

## 1. C ABI Exported Functions

```c
// System lifecycle
WaterSSFRHandle scr_water_ssfr_create(const WaterSSFRConfig* config);
void            scr_water_ssfr_destroy(WaterSSFRHandle handle);

// SPH Physics step
int scr_water_ssfr_step_simulation(WaterSSFRHandle handle, float dt);
int scr_water_ssfr_add_particle(WaterSSFRHandle handle, float x, float y, float z, float vx, float vy, float vz);
int scr_water_ssfr_get_particle_count(WaterSSFRHandle handle, uint32_t* out_count);
int scr_water_ssfr_get_particle_data(WaterSSFRHandle handle, uint32_t index, WaterParticleData* out_data);

// Screen-Space Depth & Bilateral Filtering
int scr_water_ssfr_rasterize_depth(WaterSSFRHandle handle, const CameraViewProjection* cam, uint32_t width, uint32_t height, float* out_depth_buffer);
int scr_water_ssfr_bilateral_filter(WaterSSFRHandle handle, const float* in_depth, float* out_smooth_depth, uint32_t width, uint32_t height, int filter_radius, float sigma_s, float sigma_r);
int scr_water_ssfr_reconstruct_normal(WaterSSFRHandle handle, const float* smooth_depth, uint32_t width, uint32_t height, uint32_t px, uint32_t py, float* out_nx, float* out_ny, float* out_nz);
```

---

## 2. Invariants

- **INV-SSFR-001**: Depth bilateral filter strictly converges and maintains edge preservation across depth discontinuities $> \sigma_r$.
- **INV-SPH-001**: SPH particle integration maintains stability under CFL condition $\Delta t \le 0.4 \frac{h}{c_s + \|\mathbf{v}\|_{\max}}$.
