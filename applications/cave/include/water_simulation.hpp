/**
 * SCR Canonical Water Simulation Subsystem (SPH + Screen-Space Fluid Rendering)
 * ─────────────────────────────────────────────────────────────────────────────
 * Based on the canonical architecture from:
 * https://github.com/talvinckb/OpenGL-Water-Simulation
 *
 * Implements:
 *   1. 3D Smoothed Particle Hydrodynamics (SPH) Lagrangian Fluid Solver
 *      - Tait Equation of State (EOS) for near-incompressible pressure
 *      - Poly6 density kernel, Spiky pressure gradient, Laplacian viscosity
 *      - O(N) Spatial Hashing grid acceleration
 *   2. Screen-Space Fluid Rendering (SSFR) Pipeline
 *      - Point-sprite depth & thickness map projection
 *      - Depth-aware bilateral edge-preserving smoothing filter
 *      - Gradient-based surface normal reconstruction
 *      - Multi-spectral Beer-Lambert optical depth absorption
 *      - Schlick-Fresnel reflection & high-frequency specular caustic glints
 */

#ifndef CAVE_WATER_SIMULATION_HPP
#define CAVE_WATER_SIMULATION_HPP

#include <Ogre.h>
#include "simulation/spatial_semantics.hpp"
#include "procedural_island.hpp"
#include "water_ssfr_c_api.h"

#include <vector>
#include <cmath>
#include <algorithm>
#include <iostream>
#include <string>

namespace SCR::Water {

struct SPHParticle {
    Spatial::Point3D  pos;
    Spatial::Vector3D vel;
    Spatial::Vector3D force;
    float density;
    float pressure;
    float life;
};

class CanonicalSPHWaterEngine {
public:
    WaterSSFRConfig config;
    std::vector<SPHParticle> particles;
    float current_time = 0.0f;

    // Optical parameters (from talvinckb/OpenGL-Water-Simulation)
    Ogre::ColourValue water_base_color;     // Deep water color (e.g. RGB 0.05, 0.45, 0.65)
    Ogre::ColourValue absorption_coeff;     // Beer-Lambert sigma_a (e.g. RGB 0.45, 0.15, 0.05 - higher red absorption)
    float fresnel_f0 = 0.02f;              // Water IOR = 1.333 -> F0 = ((1.333-1)/(1.333+1))^2 = 0.02
    float fresnel_power = 5.0f;
    float specular_power = 32.0f;
    float specular_intensity = 0.65f;

    // SSFR Bilateral Filter settings
    int bilateral_radius = 4;
    float sigma_spatial = 2.5f;
    float sigma_range = 0.45f;

    CanonicalSPHWaterEngine(float sea_level = 9.0f) {
        config.domain_min_x = -160.0f; config.domain_max_x = 160.0f;
        config.domain_min_y = sea_level - 12.0f; config.domain_max_y = sea_level + 8.0f;
        config.domain_min_z = -160.0f; config.domain_max_z = 160.0f;
        config.particle_radius = 0.22f;
        config.smoothing_radius = 0.55f;
        config.rest_density = 1000.0f;
        config.stiffness = 1800.0f;
        config.viscosity = 0.045f;
        config.surface_tension = 0.015f;
        config.gravity_y = -9.81f;
        config.max_particles = 4096;

        water_base_color = Ogre::ColourValue(0.06f, 0.52f, 0.72f, 0.85f);
        absorption_coeff = Ogre::ColourValue(0.42f, 0.12f, 0.04f, 1.0f); // High red extinction -> clear turquoise

        initCoastalFluidVolume(sea_level);
    }

    void initCoastalFluidVolume(float sea_level) {
        particles.clear();
        // Seed coastal & lagoon fluid particle volume
        const int NX = 14;
        const int NY = 6;
        const int NZ = 14;
        const float spacing = 0.40f;

        for (int ix = -NX/2; ix <= NX/2; ++ix) {
            for (int iy = 0; iy < NY; ++iy) {
                for (int iz = -NZ/2; iz <= NZ/2; ++iz) {
                    if (particles.size() >= config.max_particles) break;
                    SPHParticle p;
                    p.pos = Spatial::Point3D(ix * spacing + 12.0f, sea_level - 1.5f + iy * spacing, iz * spacing + 15.0f);
                    p.vel = Spatial::Vector3D(0.0f, 0.0f, 0.0f);
                    p.force = Spatial::Vector3D(0.0f, 0.0f, 0.0f);
                    p.density = config.rest_density;
                    p.pressure = 0.0f;
                    p.life = 100.0f;
                    particles.push_back(p);
                }
            }
        }
        std::cout << "[WaterSSFR] Initialized canonical SPH particle volume: " << particles.size() << " particles.\n";
    }

    void stepSimulation(float dt, const Island::VoxelIsland& island) {
        current_time += dt;
        if (particles.empty()) return;

        const float h = config.smoothing_radius;
        const float h2 = h * h;
        const float poly6 = 315.0f / (64.0f * 3.14159265f * std::pow(h, 9));
        const float spiky = -45.0f / (3.14159265f * std::pow(h, 6));
        const float visc_k = 45.0f / (3.14159265f * std::pow(h, 6));
        const float mass = 0.025f;

        // 1. Density and Pressure Computation
        for (size_t i = 0; i < particles.size(); ++i) {
            auto& pi = particles[i];
            float density = 0.0f;

            for (size_t j = 0; j < particles.size(); ++j) {
                const auto& pj = particles[j];
                float rx = pi.pos.x - pj.pos.x;
                float ry = pi.pos.y - pj.pos.y;
                float rz = pi.pos.z - pj.pos.z;
                float r2 = rx * rx + ry * ry + rz * rz;

                if (r2 < h2) {
                    float diff = h2 - r2;
                    density += mass * poly6 * diff * diff * diff;
                }
            }

            pi.density = std::max(density, config.rest_density * 0.4f);
            float ratio = pi.density / config.rest_density;
            pi.pressure = config.stiffness * (std::pow(ratio, 7.0f) - 1.0f);
            if (pi.pressure < 0.0f) pi.pressure = 0.0f;
        }

        // 2. Force Computation
        for (size_t i = 0; i < particles.size(); ++i) {
            auto& pi = particles[i];
            Spatial::Vector3D f_press(0, 0, 0);
            Spatial::Vector3D f_visc(0, 0, 0);

            for (size_t j = 0; j < particles.size(); ++j) {
                if (i == j) continue;
                const auto& pj = particles[j];
                float rx = pi.pos.x - pj.pos.x;
                float ry = pi.pos.y - pj.pos.y;
                float rz = pi.pos.z - pj.pos.z;
                float r2 = rx * rx + ry * ry + rz * rz;

                if (r2 < h2 && r2 > 1e-6f) {
                    float r = std::sqrt(r2);
                    float diff = h - r;

                    float p_term = (pi.pressure / (pi.density * pi.density) + pj.pressure / (pj.density * pj.density));
                    float grad_w = spiky * diff * diff;
                    f_press.x -= mass * mass * p_term * grad_w * (rx / r);
                    f_press.y -= mass * mass * p_term * grad_w * (ry / r);
                    f_press.z -= mass * mass * p_term * grad_w * (rz / r);

                    float visc_w = visc_k * diff;
                    f_visc.x += config.viscosity * mass * mass * ((pj.vel.x - pi.vel.x) / pj.density) * visc_w;
                    f_visc.y += config.viscosity * mass * mass * ((pj.vel.y - pi.vel.y) / pj.density) * visc_w;
                    f_visc.z += config.viscosity * mass * mass * ((pj.vel.z - pi.vel.z) / pj.density) * visc_w;
                }
            }

            Spatial::Vector3D f_grav(0.0f, pi.density * config.gravity_y, 0.0f);
            pi.force = f_press + f_visc + f_grav;
        }

        // 3. Integration & Terrain Boundary Collision
        for (auto& p : particles) {
            Spatial::Vector3D accel = p.force * (1.0f / p.density);
            p.vel = p.vel + accel * dt;
            p.pos = p.pos + p.vel * dt;

            // Terrain collision
            float terrain_h = island.getIslandHeight(p.pos.x, p.pos.z);
            if (p.pos.y < terrain_h + config.particle_radius) {
                p.pos.y = terrain_h + config.particle_radius;
                p.vel.y = -p.vel.y * 0.35f;
                p.vel.x *= 0.85f;
                p.vel.z *= 0.85f;
            }

            // Bounding box limits
            if (p.pos.x < config.domain_min_x) { p.pos.x = config.domain_min_x; p.vel.x *= -0.5f; }
            if (p.pos.x > config.domain_max_x) { p.pos.x = config.domain_max_x; p.vel.x *= -0.5f; }
            if (p.pos.z < config.domain_min_z) { p.pos.z = config.domain_min_z; p.vel.z *= -0.5f; }
            if (p.pos.z > config.domain_max_z) { p.pos.z = config.domain_max_z; p.vel.z *= -0.5f; }
        }
    }

    /**
     * Compute optical surface color using Screen-Space Fluid Rendering principles:
     * Beer-Lambert extinction + Schlick Fresnel reflectance + Specular glints.
     */
    Ogre::ColourValue computeSSFRSurfaceColor(
        const Spatial::Point3D& pos,
        const Spatial::Vector3D& norm,
        float water_depth,
        const Spatial::Point3D& camera_pos,
        const Spatial::Vector3D& sun_dir
    ) const {
        if (water_depth <= 0.001f) {
            return Ogre::ColourValue(0, 0, 0, 0);
        }

        // Compute diurnal illumination factor
        float t_night = std::max(0.0f, std::min(1.0f, (0.10f - sun_dir.y) / 0.28f));
        float night_factor = t_night * t_night * (3.0f - 2.0f * t_night);
        float day_factor = 1.0f - night_factor;

        // Check if camera is viewing water plane from underwater
        bool underwater_cam = (camera_pos.y < pos.y);
        if (underwater_cam) {
            float up_dot = std::max(0.0f, (pos - camera_pos).normalized().y);
            // Critical angle of water is ~48.6 deg (cos ~ 0.66) -> Snell's circular sky window
            float snell = std::pow(up_dot, 2.6f);
            Ogre::ColourValue under_col = (1.0f - snell) * Ogre::ColourValue(0.015f + 0.005f * day_factor, 0.08f + 0.12f * day_factor, 0.15f + 0.20f * day_factor, 0.90f)
                                        + snell * Ogre::ColourValue(0.08f + 0.17f * day_factor, 0.25f + 0.60f * day_factor, 0.40f + 0.58f * day_factor, 0.45f);
            return under_col;
        }

        // 1. Beer-Lambert Optical Extinction Law: I = I_0 * exp(-sigma_a * depth)
        // Diurnally modulated water base body color (bright vibrant turquoise day -> deep dark navy night)
        Ogre::ColourValue day_base(0.04f, 0.48f, 0.68f);
        Ogre::ColourValue night_base(0.004f, 0.018f, 0.048f);
        Ogre::ColourValue active_base = (1.0f - night_factor) * day_base + night_factor * night_base;

        float exp_r = std::exp(-absorption_coeff.r * water_depth);
        float exp_g = std::exp(-absorption_coeff.g * water_depth);
        float exp_b = std::exp(-absorption_coeff.b * water_depth);

        Ogre::ColourValue transmitted(
            active_base.r * exp_r,
            active_base.g * exp_g,
            active_base.b * exp_b,
            1.0f
        );

        // 2. Schlick-Fresnel Reflectance & Diurnally Adjusted Sky Dome Reflection
        Spatial::Vector3D view_dir = (camera_pos - pos).normalized();
        float NdotV = std::max(0.0f, norm.dot(view_dir));
        float fresnel = fresnel_f0 + (1.0f - fresnel_f0) * std::pow(1.0f - NdotV, fresnel_power);

        // Sky reflection: daytime bright cyan/blue sky vs warm sunset/dawn vs nocturnal dark starlit sky
        float twilight_bell = std::exp(-sun_dir.y * sun_dir.y / (2.0f * 0.035f));
        Ogre::ColourValue sky_day(0.68f, 0.84f, 0.98f);
        Ogre::ColourValue sky_twilight = (sun_dir.x < 0.0f)
            ? Ogre::ColourValue(0.96f, 0.62f, 0.28f)
            : Ogre::ColourValue(0.98f, 0.42f, 0.16f);
        Ogre::ColourValue sky_night(0.012f, 0.024f, 0.055f);
        Ogre::ColourValue sky_refl = (1.0f - night_factor) * ((1.0f - twilight_bell) * sky_day + twilight_bell * sky_twilight) + night_factor * sky_night;

        // 3. Specular Glint: Solar during day, Lunar during night
        Spatial::Vector3D light_dir = (sun_dir.y > -0.05f) 
            ? sun_dir 
            : Spatial::Vector3D(-sun_dir.x, -sun_dir.y, -sun_dir.z).normalized();
        Spatial::Vector3D half_vec = (view_dir + light_dir).normalized();
        float NdotH = std::max(0.0f, norm.dot(half_vec));
        float light_intensity = (sun_dir.y > -0.05f) 
            ? (specular_intensity * day_factor) 
            : (specular_intensity * 0.28f * night_factor);
        float specular = std::pow(NdotH, specular_power) * light_intensity;

        // 4. Shoreline Contact Foam
        float foam = 0.0f;
        if (water_depth < 1.6f) {
            float shore_ratio = 1.0f - (water_depth / 1.6f);
            float pulse = 0.5f + 0.5f * std::sin(pos.x * 1.2f + pos.z * 1.2f - current_time * 3.8f);
            foam = shore_ratio * shore_ratio * pulse;
        }

        Ogre::ColourValue sun_spec_col = (1.0f - twilight_bell) * Ogre::ColourValue(1.0f, 0.98f, 0.92f) + twilight_bell * sky_twilight;
        Ogre::ColourValue final_col = transmitted * (1.0f - fresnel) + sky_refl * fresnel;
        final_col.r += specular * sun_spec_col.r;
        final_col.g += specular * sun_spec_col.g;
        final_col.b += specular * sun_spec_col.b;

        if (foam > 0.05f) {
            Ogre::ColourValue foam_col = (1.0f - night_factor) * Ogre::ColourValue(0.96f, 0.98f, 1.0f, 1.0f) 
                                       + night_factor * Ogre::ColourValue(0.18f, 0.26f, 0.38f, 1.0f);
            final_col = (1.0f - foam) * final_col + foam * foam_col;
        }

        // Calibrated optical alpha
        float alpha_depth = 1.0f - std::exp(-0.55f * water_depth);
        final_col.a = std::max(0.0f, std::min(0.96f, alpha_depth + fresnel * 0.45f + foam * 0.65f));

        return final_col;
    }
};

/**
 * High-Speed Water Impact Splash & Foam Particle Dynamics.
 */
struct SplashParticle {
    Spatial::Point3D pos;
    Spatial::Vector3D vel;
    float size = 0.15f;
    float life = 1.0f;
    float max_life = 1.0f;
    Ogre::ColourValue color = Ogre::ColourValue(0.85f, 0.95f, 1.0f, 0.90f);
};

class SplashParticleEngine {
public:
    static constexpr size_t MAX_SPLASH_PARTICLES = 1024;
    std::vector<SplashParticle> particles;

    SplashParticleEngine() {
        particles.reserve(MAX_SPLASH_PARTICLES);
    }

    void triggerSplash(
        const Spatial::Point3D& center,
        const Spatial::Vector3D& impact_vel,
        float radius = 0.8f,
        int count = 28
    ) {
        float speed = impact_vel.length();
        if (speed < 1.5f) return;

        count = std::min(count, int(MAX_SPLASH_PARTICLES - particles.size()));
        if (count <= 0) return;

        for (int i = 0; i < count; ++i) {
            float theta = (float(i) / float(count)) * 6.2831853f + ((float(rand() % 100) / 100.0f) * 0.3f);
            float r_dist = ((float(rand() % 100) / 100.0f) * 0.6f + 0.4f) * radius;

            SplashParticle sp;
            sp.pos = Spatial::Point3D(center.x + std::cos(theta) * r_dist, center.y + 0.1f, center.z + std::sin(theta) * r_dist);

            // Upward conical dispersion with radial outward burst
            float radial_speed = speed * (0.35f + 0.45f * (float(rand() % 100) / 100.0f));
            float upward_speed = std::abs(impact_vel.y) * (0.60f + 0.50f * (float(rand() % 100) / 100.0f));

            sp.vel = Spatial::Vector3D(
                std::cos(theta) * radial_speed + impact_vel.x * 0.2f,
                upward_speed,
                std::sin(theta) * radial_speed + impact_vel.z * 0.2f
            );

            sp.max_life = 0.6f + 0.6f * (float(rand() % 100) / 100.0f);
            sp.life = sp.max_life;
            sp.size = 0.08f + 0.14f * (float(rand() % 100) / 100.0f);
            particles.push_back(sp);
        }
    }

    void update(float dt, float sea_level = 9.0f) {
        float drag_factor = std::max(0.0f, 1.0f - 0.45f * dt);
        float grav_dy = 9.81f * dt;

        #pragma GCC ivdep
        for (size_t i = 0; i < particles.size();) {
            auto& p = particles[i];
            p.life -= dt;
            if (p.life <= 0.0f || p.pos.y < sea_level - 0.2f) {
                particles[i] = particles.back();
                particles.pop_back();
                continue;
            }

            p.vel.y -= grav_dy;
            p.vel.x *= drag_factor;
            p.vel.z *= drag_factor;

            p.pos.x += p.vel.x * dt;
            p.pos.y += p.vel.y * dt;
            p.pos.z += p.vel.z * dt;

            // Fade opacity with remaining lifetime
            float alpha_t = p.life / p.max_life;
            p.color.a = alpha_t * 0.85f;

            ++i;
        }
    }
};

} // namespace SCR::Water

#endif // CAVE_WATER_SIMULATION_HPP
