/**
 * SCR Render / Multi-Level Horizon Mountain & Atmospheric Parallax System
 * ─────────────────────────────────────────────────────────────────────────────
 * Implements a small-planet aesthetic with:
 *   1. Planetary curvature horizon drop (R_planet ~ 1800m)
 *   2. Multi-tier low-poly procedural horizon mountain silhouettes (Mid & Far ranges)
 *   3. Low-lying sea-mist ribbon blending the ocean horizon seamlessly into the sky
 *   4. Multi-level drifting low-poly cloud billows & stratocumulus rafts
 *   5. Full diurnal sun illumination & aerial atmospheric perspective blending
 */

#ifndef CAVE_HORIZON_PLANET_PARALLAX_HPP
#define CAVE_HORIZON_PLANET_PARALLAX_HPP

#include <Ogre.h>
#include "spatial_semantics.hpp"
#include "volumetric_clouds.hpp"
#include "procedural_island.hpp"
#include "multi_scale_noise.hpp"

#include <vector>
#include <cmath>
#include <string>
#include <algorithm>
#include <iostream>

namespace SCR::Atmosphere {

struct ParallaxVertex {
    Ogre::Vector3 position;
    Ogre::Vector3 normal;
    Ogre::ColourValue color;
};

class HorizonPlanetParallaxSystem {
public:
    // Planetary Curvature Radius (m) — creating small-planet curvature
    float planet_radius = 1800.0f;
    float sea_level = 9.0f;

    // Simulation timers
    float simulation_time = 0.0f;

    // Drifting cloud parameters
    float cloud_drift_speed_1 = 2.4f;
    float cloud_drift_speed_2 = 1.2f;

    // Noise generators for mountain ridges and mist undulation
    SCR::Noise::GradientNoise3D noise_mountains;
    SCR::Noise::GradientNoise3D noise_mist;

    HorizonPlanetParallaxSystem()
        : noise_mountains(54321), noise_mist(12345) {}

    /**
     * Calculates planetary curvature drop: delta_y = - d^2 / (2 * R_planet)
     */
    inline float computePlanetaryDrop(float distance_from_center) const {
        return -(distance_from_center * distance_from_center) / (2.0f * planet_radius);
    }

    /**
     * Synthesizes and updates:
     *   1. Mid Horizon Mountain Ridge (650m - 850m)
     *   2. Distant Planetary Crater Rim (1300m - 1700m)
     *   3. Low-lying Horizon Sea-Mist Ribbon
     *   4. Floating Low-Poly Cloud Rafts (Tiers 1 & 2)
     */
    void updateParallaxMesh(
        Ogre::ManualObject* parallaxObj,
        float dt,
        const Sky::VolumetricAtmosphere& sky,
        const Spatial::Point3D& camera_pos,
        float center_x,
        float center_z
    ) {
        if (!parallaxObj) return;
        simulation_time += dt;

        parallaxObj->clear();
        // Horizon is handled cleanly by the VolumetricAtmosphere and SeaOfThieves ocean without artificial billboard curtains.
    }

private:
    void buildHorizonMountainRing(
        float cx, float cz,
        float ring_radius,
        float max_height,
        int segments,
        float roughness,
        const Sky::VolumetricAtmosphere& sky,
        float fog_blend,
        std::vector<ParallaxVertex>& out_verts,
        std::vector<uint32_t>& out_indices
    ) {
        uint32_t base_idx = static_cast<uint32_t>(out_verts.size());
        float planetary_drop = computePlanetaryDrop(ring_radius);

        Ogre::ColourValue base_rock_col(0.18f, 0.16f, 0.22f, 1.0f);
        Ogre::ColourValue sunlit_peak_col = sky.sun_color * 0.85f + Ogre::ColourValue(0.35f, 0.25f, 0.22f, 1.0f);

        // Aerial atmospheric perspective tint
        Ogre::ColourValue fog_col = sky.horizon_color;

        for (int i = 0; i <= segments; ++i) {
            float angle = (float(i) / float(segments)) * 6.2831853f;
            float cos_a = std::cos(angle);
            float sin_a = std::sin(angle);

            // Multi-octave ridged mountain height
            float nx = cos_a * 2.5f;
            float nz = sin_a * 2.5f;
            float n1 = noise_mountains.fbm(nx, float(ring_radius * 0.01f), nz, 4, 2.1f, 0.5f);
            float n2 = std::abs(noise_mountains.sample(nx * 3.2f, 1.2f, nz * 3.2f));
            float ridge = (1.0f - n2) * (n1 * 0.5f + 0.5f);

            // Gaps in mountain ring (sea vistas between distant island chains)
            float island_mask = std::max(0.0f, std::sin(angle * 3.0f + 0.8f) * 0.7f + std::sin(angle * 5.0f) * 0.4f);
            float peak_h = ridge * max_height * island_mask * roughness;

            float wx = cx + cos_a * ring_radius;
            float wz = cz + sin_a * ring_radius;

            // Base vertex (dipped under sea horizon)
            float base_y = sea_level + planetary_drop - 25.0f;
            Ogre::Vector3 p_base(wx, base_y, wz);

            // Peak vertex (projected above curved horizon)
            float peak_y = sea_level + planetary_drop + peak_h;
            Ogre::Vector3 p_peak(wx, peak_y, wz);

            // Low-poly normal
            Ogre::Vector3 norm(-cos_a, 0.35f, -sin_a);
            norm.normalise();

            // Sun illumination on peaks
            float NdotL = std::max(0.0f, norm.x * -sky.sun_direction.x + norm.y * -sky.sun_direction.y + norm.z * -sky.sun_direction.z);
            Ogre::ColourValue peak_shaded = (1.0f - NdotL * 0.6f) * base_rock_col + (NdotL * 0.6f) * sunlit_peak_col;
            Ogre::ColourValue base_shaded = base_rock_col * 0.5f + sky.ambient_sky_color * 0.5f;

            // Blend with atmospheric haze (aerial perspective)
            Ogre::ColourValue col_peak = (1.0f - fog_blend) * peak_shaded + fog_blend * fog_col;
            Ogre::ColourValue col_base = (1.0f - fog_blend * 0.9f) * base_shaded + (fog_blend * 0.9f) * fog_col;

            ParallaxVertex vb{p_base, norm, col_base};
            ParallaxVertex vp{p_peak, norm, col_peak};

            out_verts.push_back(vb);
            out_verts.push_back(vp);
        }

        for (int i = 0; i < segments; ++i) {
            uint32_t b0 = base_idx + i * 2;
            uint32_t p0 = b0 + 1;
            uint32_t b1 = b0 + 2;
            uint32_t p1 = b0 + 3;

            out_indices.push_back(b0); out_indices.push_back(p0); out_indices.push_back(p1);
            out_indices.push_back(b0); out_indices.push_back(p1); out_indices.push_back(b1);
        }
    }

    void buildSeaMistRibbon(
        float cx, float cz,
        float radius,
        float ribbon_height,
        int segments,
        const Sky::VolumetricAtmosphere& sky,
        std::vector<ParallaxVertex>& out_verts,
        std::vector<uint32_t>& out_indices
    ) {
        uint32_t base_idx = static_cast<uint32_t>(out_verts.size());
        float planetary_drop = computePlanetaryDrop(radius);

        Ogre::ColourValue mist_col = sky.horizon_color * 0.85f + sky.ambient_sky_color * 0.15f;
        mist_col.a = 0.55f; // Translucent atmospheric mist band

        for (int i = 0; i <= segments; ++i) {
            float angle = (float(i) / float(segments)) * 6.2831853f;
            float cos_a = std::cos(angle);
            float sin_a = std::sin(angle);

            float undulate = std::sin(angle * 4.0f + simulation_time * 0.35f) * 4.0f
                           + std::cos(angle * 7.0f - simulation_time * 0.25f) * 2.5f;

            float wx = cx + cos_a * radius;
            float wz = cz + sin_a * radius;

            float y_bot = sea_level + planetary_drop - 2.0f;
            float y_top = sea_level + planetary_drop + ribbon_height + undulate;

            Ogre::Vector3 p_bot(wx, y_bot, wz);
            Ogre::Vector3 p_top(wx, y_top, wz);

            Ogre::ColourValue c_bot = mist_col; c_bot.a = 0.70f;
            Ogre::ColourValue c_top = mist_col; c_top.a = 0.00f; // Fade out to sky at top

            ParallaxVertex vb{p_bot, Ogre::Vector3(0, 1, 0), c_bot};
            ParallaxVertex vt{p_top, Ogre::Vector3(0, 1, 0), c_top};

            out_verts.push_back(vb);
            out_verts.push_back(vt);
        }

        for (int i = 0; i < segments; ++i) {
            uint32_t b0 = base_idx + i * 2;
            uint32_t t0 = b0 + 1;
            uint32_t b1 = b0 + 2;
            uint32_t t1 = b0 + 3;

            out_indices.push_back(b0); out_indices.push_back(t0); out_indices.push_back(t1);
            out_indices.push_back(b0); out_indices.push_back(t1); out_indices.push_back(b1);
            // Double-sided
            out_indices.push_back(b0); out_indices.push_back(t1); out_indices.push_back(t0);
            out_indices.push_back(b0); out_indices.push_back(b1); out_indices.push_back(t1);
        }
    }

    void buildLowPolyCloudDecks(
        float cx, float cz,
        const Spatial::Point3D& camera_pos,
        const Sky::VolumetricAtmosphere& sky,
        std::vector<ParallaxVertex>& out_verts,
        std::vector<uint32_t>& out_indices
    ) {
        // Tier 1: Low-Poly Floating Cumulus Rafts (Scattered across mid altitude)
        const int NUM_RAFTS = 16;
        for (int r = 0; r < NUM_RAFTS; ++r) {
            float base_ang = (float(r) / float(NUM_RAFTS)) * 6.2831853f + (r % 3) * 0.4f;
            float drift = simulation_time * (cloud_drift_speed_1 * 0.008f);
            float ang = base_ang + drift;

            float dist = 420.0f + (r % 5) * 65.0f;
            float alt  = 160.0f + (r % 4) * 25.0f;

            float wx = cx + std::cos(ang) * dist;
            float wz = cz + std::sin(ang) * dist;
            float wy = alt + computePlanetaryDrop(dist);

            float size_x = 45.0f + (r % 3) * 18.0f;
            float size_y = 14.0f + (r % 2) * 6.0f;
            float size_z = 32.0f + (r % 4) * 12.0f;

            buildFacetedCloudBillow(Ogre::Vector3(wx, wy, wz), size_x, size_y, size_z, r, sky, out_verts, out_indices);
        }

        // Tier 2: High Stratocumulus Parallax Arcs (650m - 900m distance, 320m - 420m altitude)
        const int NUM_HIGH_CLOUDS = 8;
        for (int r = 0; r < NUM_HIGH_CLOUDS; ++r) {
            float base_ang = (float(r) / float(NUM_HIGH_CLOUDS)) * 6.2831853f + 0.6f;
            float drift = simulation_time * (cloud_drift_speed_2 * 0.004f);
            float ang = base_ang + drift;

            float dist = 780.0f + (r % 3) * 80.0f;
            float alt  = 340.0f + (r % 2) * 45.0f;

            float wx = cx + std::cos(ang) * dist;
            float wz = cz + std::sin(ang) * dist;
            float wy = alt + computePlanetaryDrop(dist);

            buildFacetedCloudBillow(Ogre::Vector3(wx, wy, wz), 85.0f, 22.0f, 55.0f, r + 101, sky, out_verts, out_indices);
        }
    }

    void buildFacetedCloudBillow(
        const Ogre::Vector3& center,
        float sx, float sy, float sz,
        unsigned seed,
        const Sky::VolumetricAtmosphere& sky,
        std::vector<ParallaxVertex>& out_verts,
        std::vector<uint32_t>& out_indices
    ) {
        int lat_segs = 3;
        int lon_segs = 6;
        uint32_t base_idx = static_cast<uint32_t>(out_verts.size());

        Ogre::ColourValue col_top = sky.sun_color * 0.90f + Ogre::ColourValue(0.20f, 0.20f, 0.25f, 1.0f);
        Ogre::ColourValue col_bot = sky.ambient_sky_color * 0.70f + sky.horizon_color * 0.30f;
        col_top.a = 0.88f;
        col_bot.a = 0.75f;

        for (int lat = 0; lat <= lat_segs; ++lat) {
            float theta = (float(lat) / float(lat_segs)) * 3.14159265f;
            float sin_t = std::sin(theta);
            float cos_t = std::cos(theta);

            for (int lon = 0; lon <= lon_segs; ++lon) {
                float phi = (float(lon) / float(lon_segs)) * 6.2831853f;
                float nx = sin_t * std::cos(phi);
                float ny = cos_t;
                float nz = sin_t * std::sin(phi);

                float pert = 1.0f + 0.22f * std::sin(phi * 2.0f + theta * 3.0f + float(seed % 17));
                Ogre::Vector3 pos = center + Ogre::Vector3(nx * sx * pert, ny * sy * pert, nz * sz * pert);
                Ogre::Vector3 norm(nx, ny, nz);
                norm.normalise();

                float t_up = std::max(0.0f, std::min(1.0f, (norm.y + 0.3f) / 1.3f));
                Ogre::ColourValue vert_col = (1.0f - t_up) * col_bot + t_up * col_top;

                ParallaxVertex v{pos, norm, vert_col};
                out_verts.push_back(v);
            }
        }

        for (int lat = 0; lat < lat_segs; ++lat) {
            for (int lon = 0; lon < lon_segs; ++lon) {
                uint32_t i00 = base_idx + lat * (lon_segs + 1) + lon;
                uint32_t i01 = base_idx + (lat + 1) * (lon_segs + 1) + lon;
                uint32_t i11 = base_idx + (lat + 1) * (lon_segs + 1) + (lon + 1);
                uint32_t i10 = base_idx + lat * (lon_segs + 1) + (lon + 1);

                out_indices.push_back(i00); out_indices.push_back(i01); out_indices.push_back(i11);
                out_indices.push_back(i00); out_indices.push_back(i11); out_indices.push_back(i10);
            }
        }
    }
};

} // namespace SCR::Atmosphere

#endif // CAVE_HORIZON_PLANET_PARALLAX_HPP
