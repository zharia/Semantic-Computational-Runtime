#include "water_ssfr_adapter.hpp"
#include <cstring>
#include <limits>

namespace SCR::Render::WaterSSFR {

WaterSSFREngine::WaterSSFREngine(const WaterSSFRConfig& cfg) : config(cfg) {
    cell_size = cfg.smoothing_radius > 0.001f ? cfg.smoothing_radius : 0.4f;
    particles.reserve(cfg.max_particles);
}

int WaterSSFREngine::addParticle(float x, float y, float z, float vx, float vy, float vz) {
    if (particles.size() >= config.max_particles) return WATER_SSFR_ERR_OUT_OF_BOUNDS;
    Particle p;
    p.x = x; p.y = y; p.z = z;
    p.vx = vx; p.vy = vy; p.vz = vz;
    p.fx = 0.0f; p.fy = 0.0f; p.fz = 0.0f;
    p.density = config.rest_density;
    p.pressure = 0.0f;
    particles.push_back(p);
    return WATER_SSFR_SUCCESS;
}

uint64_t WaterSSFREngine::hashCell(int cx, int cy, int cz) const {
    const uint64_t p1 = 73856093;
    const uint64_t p2 = 19349663;
    const uint64_t p3 = 83492791;
    return ((uint64_t(cx) * p1) ^ (uint64_t(cy) * p2) ^ (uint64_t(cz) * p3));
}

void WaterSSFREngine::buildSpatialHash() {
    grid.clear();
    for (uint32_t i = 0; i < particles.size(); ++i) {
        int cx = (int)std::floor(particles[i].x / cell_size);
        int cy = (int)std::floor(particles[i].y / cell_size);
        int cz = (int)std::floor(particles[i].z / cell_size);
        uint64_t h = hashCell(cx, cy, cz);
        grid[h].push_back(i);
    }
}

void WaterSSFREngine::computeDensityPressure() {
    const float h = config.smoothing_radius;
    const float h2 = h * h;
    const float poly6_coeff = 315.0f / (64.0f * 3.14159265f * std::pow(h, 9));
    const float mass = 0.02f; // particle mass (kg)

    for (size_t i = 0; i < particles.size(); ++i) {
        auto& pi = particles[i];
        float density = 0.0f;

        int cx = (int)std::floor(pi.x / cell_size);
        int cy = (int)std::floor(pi.y / cell_size);
        int cz = (int)std::floor(pi.z / cell_size);

        for (int dx = -1; dx <= 1; ++dx) {
            for (int dy = -1; dy <= 1; ++dy) {
                for (int dz = -1; dz <= 1; ++dz) {
                    uint64_t h_idx = hashCell(cx + dx, cy + dy, cz + dz);
                    auto it = grid.find(h_idx);
                    if (it == grid.end()) continue;

                    for (uint32_t j : it->second) {
                        const auto& pj = particles[j];
                        float rx = pi.x - pj.x;
                        float ry = pi.y - pj.y;
                        float rz = pi.z - pj.z;
                        float r2 = rx * rx + ry * ry + rz * rz;

                        if (r2 < h2) {
                            float diff = h2 - r2;
                            density += mass * poly6_coeff * diff * diff * diff;
                        }
                    }
                }
            }
        }

        pi.density = std::max(density, config.rest_density * 0.5f);
        // Tait equation of state: P = B * ((rho / rho0)^7 - 1)
        float ratio = pi.density / config.rest_density;
        pi.pressure = config.stiffness * (std::pow(ratio, 7.0f) - 1.0f);
        if (pi.pressure < 0.0f) pi.pressure = 0.0f;
    }
}

void WaterSSFREngine::computeForces() {
    const float h = config.smoothing_radius;
    const float h2 = h * h;
    const float spiky_coeff = -45.0f / (3.14159265f * std::pow(h, 6));
    const float visc_coeff = 45.0f / (3.14159265f * std::pow(h, 6));
    const float mass = 0.02f;

    for (size_t i = 0; i < particles.size(); ++i) {
        auto& pi = particles[i];
        float f_press_x = 0.0f, f_press_y = 0.0f, f_press_z = 0.0f;
        float f_visc_x = 0.0f, f_visc_y = 0.0f, f_visc_z = 0.0f;

        int cx = (int)std::floor(pi.x / cell_size);
        int cy = (int)std::floor(pi.y / cell_size);
        int cz = (int)std::floor(pi.z / cell_size);

        for (int dx = -1; dx <= 1; ++dx) {
            for (int dy = -1; dy <= 1; ++dy) {
                for (int dz = -1; dz <= 1; ++dz) {
                    uint64_t h_idx = hashCell(cx + dx, cy + dy, cz + dz);
                    auto it = grid.find(h_idx);
                    if (it == grid.end()) continue;

                    for (uint32_t j : it->second) {
                        if (i == j) continue;
                        const auto& pj = particles[j];
                        float rx = pi.x - pj.x;
                        float ry = pi.y - pj.y;
                        float rz = pi.z - pj.z;
                        float r2 = rx * rx + ry * ry + rz * rz;

                        if (r2 < h2 && r2 > 1e-6f) {
                            float r = std::sqrt(r2);
                            float diff = h - r;

                            // Pressure gradient force
                            float p_term = (pi.pressure / (pi.density * pi.density) + pj.pressure / (pj.density * pj.density));
                            float grad_w = spiky_coeff * diff * diff;
                            f_press_x -= mass * mass * p_term * grad_w * (rx / r);
                            f_press_y -= mass * mass * p_term * grad_w * (ry / r);
                            f_press_z -= mass * mass * p_term * grad_w * (rz / r);

                            // Viscosity force
                            float visc_w = visc_coeff * diff;
                            f_visc_x += config.viscosity * mass * mass * ((pj.vx - pi.vx) / pj.density) * visc_w;
                            f_visc_y += config.viscosity * mass * mass * ((pj.vy - pi.vy) / pj.density) * visc_w;
                            f_visc_z += config.viscosity * mass * mass * ((pj.vz - pi.vz) / pj.density) * visc_w;
                        }
                    }
                }
            }
        }

        // Gravity force
        float f_grav_y = pi.density * config.gravity_y;

        pi.fx = f_press_x + f_visc_x;
        pi.fy = f_press_y + f_visc_y + f_grav_y;
        pi.fz = f_press_z + f_visc_z;
    }
}

void WaterSSFREngine::integrate(float dt) {
    const float damping = -0.6f; // Bounding wall restitution

    for (auto& p : particles) {
        float ax = p.fx / p.density;
        float ay = p.fy / p.density;
        float az = p.fz / p.density;

        p.vx += ax * dt;
        p.vy += ay * dt;
        p.vz += az * dt;

        p.x += p.vx * dt;
        p.y += p.vy * dt;
        p.z += p.vz * dt;

        // Domain boundary collision
        if (p.x < config.domain_min_x) { p.x = config.domain_min_x; p.vx *= damping; }
        if (p.x > config.domain_max_x) { p.x = config.domain_max_x; p.vx *= damping; }
        if (p.y < config.domain_min_y) { p.y = config.domain_min_y; p.vy *= damping; }
        if (p.y > config.domain_max_y) { p.y = config.domain_max_y; p.vy *= damping; }
        if (p.z < config.domain_min_z) { p.z = config.domain_min_z; p.vz *= damping; }
        if (p.z > config.domain_max_z) { p.z = config.domain_max_z; p.vz *= damping; }
    }
}

int WaterSSFREngine::stepSimulation(float dt) {
    if (particles.empty()) return WATER_SSFR_SUCCESS;
    buildSpatialHash();
    computeDensityPressure();
    computeForces();
    integrate(dt);
    return WATER_SSFR_SUCCESS;
}

int WaterSSFREngine::rasterizeDepth(const CameraViewProjection& cam, uint32_t width, uint32_t height, float* out_depth) {
    if (!out_depth || width == 0 || height == 0) return WATER_SSFR_ERR_INVALID_ARG;
    for (size_t i = 0; i < width * height; ++i) {
        out_depth[i] = 1e9f; // Far depth clear
    }

    float fov_factor = 1.0f / std::tan(cam.fov_y_rad * 0.5f);
    float pr = config.particle_radius;

    for (const auto& p : particles) {
        // Camera space transform (simplified view look-at)
        float dx = p.x - cam.eye_x;
        float dy = p.y - cam.eye_y;
        float dz = p.z - cam.eye_z;

        // View space coordinates
        float view_z = dx * cam.forward_x + dy * cam.forward_y + dz * cam.forward_z;
        if (view_z <= cam.near_clip || view_z >= cam.far_clip) continue;

        // Right vector = forward x up
        float right_x = cam.forward_y * cam.up_z - cam.forward_z * cam.up_y;
        float right_y = cam.forward_z * cam.up_x - cam.forward_x * cam.up_z;
        float right_z = cam.forward_x * cam.up_y - cam.forward_y * cam.up_x;

        float view_x = dx * right_x + dy * right_y + dz * right_z;
        float view_y = dx * cam.up_x + dy * cam.up_y + dz * cam.up_z;

        // Perspective projection
        float ndc_x = (view_x / view_z) * (fov_factor / cam.aspect_ratio);
        float ndc_y = (view_y / view_z) * fov_factor;

        int screen_x = (int)((ndc_x * 0.5f + 0.5f) * width);
        int screen_y = (int)((1.0f - (ndc_y * 0.5f + 0.5f)) * height);

        int pixel_radius = std::max(1, (int)((pr / view_z) * fov_factor * height * 0.5f));

        for (int py = screen_y - pixel_radius; py <= screen_y + pixel_radius; ++py) {
            if (py < 0 || py >= (int)height) continue;
            for (int px = screen_x - pixel_radius; px <= screen_x + pixel_radius; ++px) {
                // Spherical cap calculation
                float rx_norm = float(px - screen_x) / float(pixel_radius);
                float ry_norm = float(py - screen_y) / float(pixel_radius);
                float r2 = rx_norm * rx_norm + ry_norm * ry_norm;
                if (r2 > 1.0f) continue;

                float sphere_depth = view_z - pr * std::sqrt(1.0f - r2);
                size_t idx = py * width + px;
                if (sphere_depth < out_depth[idx]) {
                    out_depth[idx] = sphere_depth;
                }
            }
        }
    }
    return WATER_SSFR_SUCCESS;
}

int WaterSSFREngine::bilateralFilter(const float* in_depth, float* out_smooth, uint32_t width, uint32_t height, int radius, float sigma_s, float sigma_r) {
    if (!in_depth || !out_smooth || width == 0 || height == 0) return WATER_SSFR_ERR_INVALID_ARG;

    const float two_sigma_s2 = 2.0f * sigma_s * sigma_s;
    const float two_sigma_r2 = 2.0f * sigma_r * sigma_r;

    for (uint32_t y = 0; y < height; ++y) {
        for (uint32_t x = 0; x < width; ++x) {
            float center_depth = in_depth[y * width + x];
            if (center_depth > 1e8f) {
                out_smooth[y * width + x] = center_depth;
                continue;
            }

            float sum_weights = 0.0f;
            float sum_depth = 0.0f;

            for (int dy = -radius; dy <= radius; ++dy) {
                int ny = (int)y + dy;
                if (ny < 0 || ny >= (int)height) continue;

                for (int dx = -radius; dx <= radius; ++dx) {
                    int nx = (int)x + dx;
                    if (nx < 0 || nx >= (int)width) continue;

                    float sample_depth = in_depth[ny * width + nx];
                    if (sample_depth > 1e8f) continue;

                    float spatial_dist2 = float(dx * dx + dy * dy);
                    float range_diff = sample_depth - center_depth;
                    float range_diff2 = range_diff * range_diff;

                    float w_spatial = std::exp(-spatial_dist2 / two_sigma_s2);
                    float w_range   = std::exp(-range_diff2 / two_sigma_r2);
                    float weight    = w_spatial * w_range;

                    sum_weights += weight;
                    sum_depth += sample_depth * weight;
                }
            }

            out_smooth[y * width + x] = (sum_weights > 1e-5f) ? (sum_depth / sum_weights) : center_depth;
        }
    }
    return WATER_SSFR_SUCCESS;
}

int WaterSSFREngine::reconstructNormal(const float* smooth_depth, uint32_t width, uint32_t height, uint32_t px, uint32_t py, float& nx, float& ny, float& nz) {
    if (!smooth_depth || px >= width || py >= height) return WATER_SSFR_ERR_INVALID_ARG;

    float z_center = smooth_depth[py * width + px];
    if (z_center > 1e8f) {
        nx = 0.0f; ny = 1.0f; nz = 0.0f;
        return WATER_SSFR_SUCCESS;
    }

    float z_left  = (px > 0) ? smooth_depth[py * width + (px - 1)] : z_center;
    float z_right = (px + 1 < width) ? smooth_depth[py * width + (px + 1)] : z_center;
    float z_up    = (py > 0) ? smooth_depth[(py - 1) * width + px] : z_center;
    float z_down  = (py + 1 < height) ? smooth_depth[(py + 1) * width + px] : z_center;

    if (z_left > 1e8f) z_left = z_center;
    if (z_right > 1e8f) z_right = z_center;
    if (z_up > 1e8f) z_up = z_center;
    if (z_down > 1e8f) z_down = z_center;

    float dz_dx = (z_right - z_left) * 0.5f;
    float dz_dy = (z_down - z_up) * 0.5f;

    // View-space surface normal
    float norm_x = -dz_dx;
    float norm_y = -dz_dy;
    float norm_z = 1.0f;

    float len = std::sqrt(norm_x * norm_x + norm_y * norm_y + norm_z * norm_z);
    if (len > 1e-4f) {
        nx = norm_x / len;
        ny = norm_y / len;
        nz = norm_z / len;
    } else {
        nx = 0.0f; ny = 1.0f; nz = 0.0f;
    }

    return WATER_SSFR_SUCCESS;
}

} // namespace SCR::Render::WaterSSFR

// ─── C-ABI Export Implementation ─────────────────────────────────────────────

extern "C" {

WaterSSFRHandle scr_water_ssfr_create(const WaterSSFRConfig* config) {
    if (!config) return nullptr;
    return new SCR::Render::WaterSSFR::WaterSSFREngine(*config);
}

void scr_water_ssfr_destroy(WaterSSFRHandle handle) {
    if (handle) {
        delete static_cast<SCR::Render::WaterSSFR::WaterSSFREngine*>(handle);
    }
}

int scr_water_ssfr_add_particle(WaterSSFRHandle handle, float x, float y, float z, float vx, float vy, float vz) {
    if (!handle) return WATER_SSFR_ERR_NULL_HANDLE;
    return static_cast<SCR::Render::WaterSSFR::WaterSSFREngine*>(handle)->addParticle(x, y, z, vx, vy, vz);
}

int scr_water_ssfr_step_simulation(WaterSSFRHandle handle, float dt) {
    if (!handle) return WATER_SSFR_ERR_NULL_HANDLE;
    return static_cast<SCR::Render::WaterSSFR::WaterSSFREngine*>(handle)->stepSimulation(dt);
}

int scr_water_ssfr_get_particle_count(WaterSSFRHandle handle, uint32_t* out_count) {
    if (!handle || !out_count) return WATER_SSFR_ERR_NULL_HANDLE;
    auto engine = static_cast<SCR::Render::WaterSSFR::WaterSSFREngine*>(handle);
    *out_count = (uint32_t)engine->particles.size();
    return WATER_SSFR_SUCCESS;
}

int scr_water_ssfr_get_particle_data(WaterSSFRHandle handle, uint32_t index, WaterParticleData* out_data) {
    if (!handle || !out_data) return WATER_SSFR_ERR_NULL_HANDLE;
    auto engine = static_cast<SCR::Render::WaterSSFR::WaterSSFREngine*>(handle);
    if (index >= engine->particles.size()) return WATER_SSFR_ERR_OUT_OF_BOUNDS;
    const auto& p = engine->particles[index];
    out_data->x = p.x; out_data->y = p.y; out_data->z = p.z;
    out_data->vx = p.vx; out_data->vy = p.vy; out_data->vz = p.vz;
    out_data->density = p.density;
    out_data->pressure = p.pressure;
    return WATER_SSFR_SUCCESS;
}

int scr_water_ssfr_rasterize_depth(WaterSSFRHandle handle, const CameraViewProjection* cam, uint32_t width, uint32_t height, float* out_depth_buffer) {
    if (!handle || !cam || !out_depth_buffer) return WATER_SSFR_ERR_NULL_HANDLE;
    return static_cast<SCR::Render::WaterSSFR::WaterSSFREngine*>(handle)->rasterizeDepth(*cam, width, height, out_depth_buffer);
}

int scr_water_ssfr_bilateral_filter(WaterSSFRHandle handle, const float* in_depth, float* out_smooth_depth, uint32_t width, uint32_t height, int filter_radius, float sigma_s, float sigma_r) {
    if (!handle || !in_depth || !out_smooth_depth) return WATER_SSFR_ERR_NULL_HANDLE;
    return static_cast<SCR::Render::WaterSSFR::WaterSSFREngine*>(handle)->bilateralFilter(in_depth, out_smooth_depth, width, height, filter_radius, sigma_s, sigma_r);
}

int scr_water_ssfr_reconstruct_normal(WaterSSFRHandle handle, const float* smooth_depth, uint32_t width, uint32_t height, uint32_t px, uint32_t py, float* out_nx, float* out_ny, float* out_nz) {
    if (!handle || !smooth_depth || !out_nx || !out_ny || !out_nz) return WATER_SSFR_ERR_NULL_HANDLE;
    return static_cast<SCR::Render::WaterSSFR::WaterSSFREngine*>(handle)->reconstructNormal(smooth_depth, width, height, px, py, *out_nx, *out_ny, *out_nz);
}

}
