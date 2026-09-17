#ifndef SCR_WATER_SSFR_ADAPTER_HPP
#define SCR_WATER_SSFR_ADAPTER_HPP

#include "water_ssfr_c_api.h"
#include <vector>
#include <unordered_map>
#include <cmath>
#include <algorithm>
#include <iostream>

namespace SCR::Render::WaterSSFR {

struct Particle {
    float x, y, z;
    float vx, vy, vz;
    float fx, fy, fz;
    float density;
    float pressure;
};

class WaterSSFREngine {
public:
    WaterSSFRConfig config;
    std::vector<Particle> particles;

    // Spatial hash grid
    float cell_size;
    std::unordered_map<uint64_t, std::vector<uint32_t>> grid;

    WaterSSFREngine(const WaterSSFRConfig& cfg);

    int addParticle(float x, float y, float z, float vx, float vy, float vz);
    int stepSimulation(float dt);

    void buildSpatialHash();
    uint64_t hashCell(int cx, int cy, int cz) const;

    void computeDensityPressure();
    void computeForces();
    void integrate(float dt);

    int rasterizeDepth(const CameraViewProjection& cam, uint32_t width, uint32_t height, float* out_depth);
    int bilateralFilter(const float* in_depth, float* out_smooth, uint32_t width, uint32_t height, int radius, float sigma_s, float sigma_r);
    int reconstructNormal(const float* smooth_depth, uint32_t width, uint32_t height, uint32_t px, uint32_t py, float& nx, float& ny, float& nz);
};

} // namespace SCR::Render::WaterSSFR

#endif // SCR_WATER_SSFR_ADAPTER_HPP
