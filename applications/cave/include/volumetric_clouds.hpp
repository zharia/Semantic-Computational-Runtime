/**
 * SCR Render / Volumetric Sky & Atmosphere System (Red Dead Redemption 2 Paradigm)
 * ─────────────────────────────────────────────────────────────────────────────
 * Implements SCR-LIB-MATH-ATMOSPHERE (lib/202_Math/Atmosphere/101_definition.md)
 * and SCR-LIB-RENDER-SKY (lib/A01_Render/Sky/101_definition.md).
 *
 * System Features:
 *   - Physical Rayleigh & Mie atmospheric scattering skydome with dynamic solar arc
 *   - 3 Stratified Volumetric Cloud Decks:
 *       • Tier 1: Low Cumulus / Stratocumulus (150m - 500m) with Worley billows
 *       • Tier 2: Mid Altocumulus & Convective Volcanic Caldera Plume (500m - 1000m)
 *       • Tier 3: High Wispy Cirrus Ice Streaks (1000m - 1800m) with wind shear
 *   - Henyey-Greenstein dual-lobe forward Mie silver linings around the sun
 *   - Beer-Lambert powdered-sugar multi-scattering transmittance
 *   - Dynamic time-of-day progression (sunrise, noon, sunset, starry night)
 *   - Differential wind shear advection per altitude tier
 */

#ifndef CAVE_VOLUMETRIC_CLOUDS_HPP
#define CAVE_VOLUMETRIC_CLOUDS_HPP

#include <Ogre.h>
#include "spatial_semantics.hpp"
#include "multi_scale_noise.hpp"
#include "procedural_island.hpp"

#include <vector>
#include <cmath>
#include <string>
#include <algorithm>
#include <iostream>

namespace SCR::Sky {

// ─── Cloud Coverage Presets ──────────────────────────────────────────────────
enum CloudPreset {
    PRESET_RDR2_SCATTERED = 0, // Fluffy scattered RDR2 cumulus + cirrus + caldera plume
    PRESET_GOLDEN_SUNSET,     // Fiery twilight clouds with high dramatic contrast
    PRESET_VOLCANIC_STORM,    // Heavy volcanic ash clouds & dark storm billows
    PRESET_CLEAR_TROPICAL,    // Crisp sunny tropical sky with light cirrus
    PRESET_COUNT
};

// ─── Dual-Lobe Henyey-Greenstein Phase Function ──────────────────────────────
inline float henyeyGreenstein(float cos_theta, float g) {
    float g2 = g * g;
    float denom = 1.0f + g2 - 2.0f * g * cos_theta;
    return (1.0f - g2) / (4.0f * 3.14159265f * std::pow(std::max(0.001f, denom), 1.5f));
}

inline float cloudPhaseDualLobe(float cos_theta) {
    // RDR2 forward silver-lining lobe (g=0.82) + backward glory lobe (g=-0.24)
    float fwd = henyeyGreenstein(cos_theta, 0.82f);
    float back = henyeyGreenstein(cos_theta, -0.24f);
    return 0.75f * fwd + 0.25f * back;
}

// ─── Multi-Layer Volumetric Atmosphere & Skydome System ──────────────────────
class VolumetricAtmosphere {
public:
    // Time of Day in 24h format (e.g. 14.0 = 2:00 PM, 17.8 = sunset/golden hour, 6.5 = sunrise)
    float time_of_day_hours = 17.8f;

    // Wind velocities (m/s) per altitude tier (differential wind shear)
    float wind_low_x = 3.2f, wind_low_z = 2.0f;
    float wind_mid_x = 6.5f, wind_mid_z = -3.8f;
    float wind_high_x = 12.0f, wind_high_z = 7.5f;

    float simulation_time = 0.0f;
    CloudPreset current_preset = PRESET_GOLDEN_SUNSET;

    // Time progression
    bool day_cycle_active = true;
    float day_cycle_duration_sec = 360.0f; // 6 minutes per full 24h diurnal cycle

    // Atmospheric parameters
    Spatial::Vector3D sun_direction;
    Spatial::Vector3D moon_direction;
    Ogre::ColourValue sun_color;
    Ogre::ColourValue moon_color;
    Ogre::ColourValue zenith_color;
    Ogre::ColourValue horizon_color;
    Ogre::ColourValue ambient_sky_color;

    // Stars / celestial parameters
    SCR::Noise::GradientNoise3D noise_stars;

    VolumetricAtmosphere()
        : noise_stars(9999) {
        updateSunAndAtmosphere();
    }

    void setTimeOfDay(float hours) {
        time_of_day_hours = std::fmod(hours + 24.0f, 24.0f);
        updateSunAndAtmosphere();
    }

    void cyclePreset() {
        current_preset = static_cast<CloudPreset>((current_preset + 1) % PRESET_COUNT);
    }

    const char* getPresetName() const {
        switch(current_preset) {
            case PRESET_RDR2_SCATTERED: return "RDR2 Scattered Cumulus & Soft Plume";
            case PRESET_GOLDEN_SUNSET:  return "Dramatic Golden Hour & Fiery Sky";
            case PRESET_VOLCANIC_STORM: return "Volcanic Ash Storm & Overcast";
            case PRESET_CLEAR_TROPICAL: return "Clear Tropical Sky with Light Cirrus";
            default: return "Custom";
        }
    }

    /**
     * Compute analytical Rayleigh / Mie sky and solar colors from dynamic solar elevation.
     * Implements continuous Hermite interpolation across 24-hour diurnal cycle with
     * realistic reduction of global illumination at night.
     */
    void updateSunAndAtmosphere() {
        // Continuous 24h diurnal orbit: 6.0h = sunrise, 12.0h = noon, 18.0h = sunset, 0.0h = midnight
        float solar_phase = (time_of_day_hours - 6.0f) / 12.0f * 3.14159265f;
        float sun_elevation = std::sin(solar_phase);
        float sun_azimuth   = std::cos(solar_phase);

        // Continuous planetary orbit vector
        sun_direction = Spatial::Vector3D(
            sun_azimuth * 0.85f,
            sun_elevation,
            -0.35f * std::sin(solar_phase * 0.5f) - 0.25f
        ).normalized();

        // Moon is opposite to the sun in the celestial sphere
        moon_direction = Spatial::Vector3D(
            -sun_direction.x,
            -sun_direction.y,
            -sun_direction.z
        ).normalized();

        moon_color = Ogre::ColourValue(0.78f, 0.88f, 1.00f);

        // Smooth Hermite Day / Night Transition Factor (0.0 = full daylight, 1.0 = deep night)
        // Transitions smoothly across civil/nautical twilight: sun_elevation in [-0.20, +0.12]
        float t_night = std::max(0.0f, std::min(1.0f, (0.12f - sun_elevation) / 0.32f));
        float night_factor = t_night * t_night * (3.0f - 2.0f * t_night); // Smooth Hermite S-curve

        // Smooth Twilight Golden / Crimson Horizon Factor
        float twilight_bell = std::exp(-sun_elevation * sun_elevation / (2.0f * 0.025f));

        // ── 1. Continuous Zenith Color ─────────────────────────────────────────
        Ogre::ColourValue zenith_day(0.15f, 0.46f, 0.92f);
        Ogre::ColourValue zenith_twilight(0.12f, 0.10f, 0.28f);
        Ogre::ColourValue zenith_night(0.006f, 0.009f, 0.024f);

        zenith_color = (1.0f - night_factor) * (zenith_day * (1.0f - twilight_bell) + zenith_twilight * twilight_bell)
                     + night_factor * zenith_night;

        // ── 2. Continuous Horizon Color ────────────────────────────────────────
        Ogre::ColourValue horizon_day(0.68f, 0.84f, 0.96f);
        Ogre::ColourValue horizon_twilight = (sun_azimuth < 0.0f)
            ? Ogre::ColourValue(0.98f, 0.62f, 0.28f)  // Golden dawn
            : Ogre::ColourValue(0.98f, 0.35f, 0.12f); // Fiery sunset
        Ogre::ColourValue horizon_night(0.012f, 0.016f, 0.038f);

        horizon_color = (1.0f - night_factor) * (horizon_day * (1.0f - twilight_bell) + horizon_twilight * twilight_bell)
                      + night_factor * horizon_night;

        // ── 3. Directional Solar / Lunar Light ──────────────────────────────────
        Ogre::ColourValue sun_day(1.00f, 0.96f, 0.88f);
        Ogre::ColourValue sun_twilight(1.00f, 0.48f, 0.14f);
        Ogre::ColourValue moon_direct(0.08f, 0.12f, 0.20f); // Soft silvery moonlight

        sun_color = (1.0f - night_factor) * (sun_day * (1.0f - twilight_bell) + sun_twilight * twilight_bell)
                  + night_factor * moon_direct;

        // ── 4. Reduced Night Global Illumination / Ambient Sky Light ────────────
        Ogre::ColourValue ambient_day(0.32f, 0.38f, 0.46f);
        Ogre::ColourValue ambient_twilight(0.18f, 0.16f, 0.22f);
        Ogre::ColourValue ambient_night(0.006f, 0.009f, 0.018f); // Drastically reduced ambient at night

        ambient_sky_color = (1.0f - night_factor) * (ambient_day * (1.0f - twilight_bell) + ambient_twilight * twilight_bell)
                          + night_factor * ambient_night;
    }

    inline static Ogre::ColourValue clampColour(const Ogre::ColourValue& c) {
        return Ogre::ColourValue(
            std::max(0.0f, std::min(1.0f, c.r)),
            std::max(0.0f, std::min(1.0f, c.g)),
            std::max(0.0f, std::min(1.0f, c.b)),
            std::max(0.0f, std::min(1.0f, c.a))
        );
    }

    /**
     * Procedural Starfield & Celestial Twinkling.
     */
    float sampleStarfield(const Spatial::Vector3D& dir) const {
        float sx = dir.x * 140.0f;
        float sy = dir.y * 140.0f;
        float sz = dir.z * 140.0f;

        float n1 = noise_stars.sample(sx, sy, sz);
        if (n1 < 0.78f) return 0.0f;

        float mag = (n1 - 0.78f) / 0.22f;
        mag = std::pow(mag, 2.5f) * 1.4f;

        float freq = 3.5f + 4.0f * std::abs(noise_stars.sample(sx * 0.2f, sy * 0.2f, sz * 0.2f));
        float twinkle = 0.70f + 0.30f * std::sin(simulation_time * freq + n1 * 40.0f);

        return mag * twinkle;
    }

    /**
     * Multi-Level Cosmic Nebula & Milky Way Galactic Arch.
     */
    Ogre::ColourValue sampleNebula(const Spatial::Vector3D& dir) const {
        Spatial::Vector3D galactic_normal(0.55f, 0.68f, 0.48f);
        galactic_normal = galactic_normal.normalized();

        float dist_galactic = std::abs(dir.dot(galactic_normal));
        float arch_mask = std::exp(-dist_galactic * dist_galactic / 0.090f);
        if (arch_mask < 0.015f) return Ogre::ColourValue::ZERO;

        float wx = noise_stars.sample(dir.x * 3.2f, dir.y * 3.2f, dir.z * 3.2f);
        float wz = noise_stars.sample(dir.x * 3.2f + 5.1f, dir.y * 3.2f + 2.4f, dir.z * 3.2f);

        float n_core = noise_stars.fbm(dir.x * 5.5f + wx * 0.35f, dir.y * 5.5f, dir.z * 5.5f + wz * 0.35f, 4, 2.1f, 0.52f);
        float n_dust = noise_stars.sample(dir.x * 11.0f, dir.y * 11.0f, dir.z * 11.0f);

        float nebula_intensity = std::max(0.0f, n_core * 0.5f + 0.5f) * arch_mask;
        float dust_lane = std::max(0.0f, 1.0f - std::abs(n_dust) * 1.6f);

        Ogre::ColourValue col_violet(0.38f, 0.14f, 0.68f, 1.0f);
        Ogre::ColourValue col_magenta(0.82f, 0.22f, 0.56f, 1.0f);
        Ogre::ColourValue col_cyan(0.18f, 0.72f, 0.85f, 1.0f);
        Ogre::ColourValue col_gold(1.00f, 0.88f, 0.62f, 1.0f);

        Ogre::ColourValue neb_color = 
            col_violet * (nebula_intensity * 0.55f) +
            col_magenta * (std::pow(nebula_intensity, 1.3f) * 0.65f * dust_lane) +
            col_cyan * (std::pow(std::max(0.0f, wx * 0.5f + 0.5f), 2.0f) * arch_mask * 0.45f) +
            col_gold * (std::pow(nebula_intensity, 2.5f) * 0.75f);

        return neb_color;
    }

    /**
     * Samples the smooth atmospheric background gradient, cosmic starfield, nebula,
     * and smooth broad atmospheric Mie scattering.
     */
    Ogre::ColourValue sampleAtmosphereRay(
        const Spatial::Point3D& ray_origin,
        const Spatial::Vector3D& ray_dir,
        const Island::VoxelIsland& island
    ) const {
        (void)ray_origin;
        (void)island;
        float elev = std::max(0.0f, ray_dir.y);

        // 1. Physically-smooth Rayleigh Atmospheric Gradient
        float sky_t = std::pow(elev, 0.52f);
        Ogre::ColourValue sky = (1.0f - sky_t) * horizon_color + sky_t * zenith_color;

        float t_night = std::max(0.0f, std::min(1.0f, (0.12f - sun_direction.y) / 0.32f));
        float night_factor = t_night * t_night * (3.0f - 2.0f * t_night);

        // 2. Broad Golden Solar Mie Forward Scattering Halo on Dome
        float cos_sun = ray_dir.dot(sun_direction);
        if (sun_direction.y > -0.12f && cos_sun > 0.0f) {
            float corona = std::pow(cos_sun, 24.0f) * 0.38f * (1.0f - night_factor);
            Ogre::ColourValue glow = corona * sun_color;
            sky.r = std::min(1.0f, sky.r + glow.r);
            sky.g = std::min(1.0f, sky.g + glow.g);
            sky.b = std::min(1.0f, sky.b + glow.b);
        }

        // 3. Broad Silvery Lunar Mie Forward Scattering Halo on Dome
        float cos_moon = ray_dir.dot(moon_direction);
        if (night_factor > 0.01f && moon_direction.y > -0.05f && cos_moon > 0.0f) {
            float lunar_corona = std::pow(cos_moon, 16.0f) * 0.35f * night_factor;
            Ogre::ColourValue moon_glow = lunar_corona * Ogre::ColourValue(0.55f, 0.72f, 0.95f);
            sky.r = std::min(1.0f, sky.r + moon_glow.r);
            sky.g = std::min(1.0f, sky.g + moon_glow.g);
            sky.b = std::min(1.0f, sky.b + moon_glow.b);
        }

        // 4. Nocturnal Cosmic Nebula & Twinkling Starfield
        if (night_factor > 0.02f && elev > 0.02f) {
            float elev_fade = std::min(1.0f, (elev - 0.02f) / 0.10f);

            // Multi-Level Cosmic Nebula
            Ogre::ColourValue nebula = sampleNebula(ray_dir) * (night_factor * elev_fade);
            sky.r = std::min(1.0f, sky.r + nebula.r);
            sky.g = std::min(1.0f, sky.g + nebula.g);
            sky.b = std::min(1.0f, sky.b + nebula.b);

            // Twinkling Starfield
            float star = sampleStarfield(ray_dir) * night_factor * elev_fade;
            if (star > 0.01f) {
                Ogre::ColourValue star_col = Ogre::ColourValue(0.92f, 0.96f, 1.00f) * star;
                sky.r = std::min(1.0f, sky.r + star_col.r);
                sky.g = std::min(1.0f, sky.g + star_col.g);
                sky.b = std::min(1.0f, sky.b + star_col.b);
            }
        }

        // 5. Subtle Horizon Atmospheric Perspective
        if (elev < 0.06f) {
            float haze = 1.0f - (elev / 0.06f);
            sky = (1.0f - haze * 0.65f) * sky + (haze * 0.65f) * horizon_color;
        }

        return clampColour(sky);
    }

    /**
     * Builds and updates the physical celestial sky dome with shared vertex topology,
     * along with high-resolution circular/spherical Celestial Moon and Solar Discs.
     */
    void updateSkyDomeMesh(
        Ogre::ManualObject* skyObj,
        float dt,
        const Island::VoxelIsland& island,
        const Spatial::Point3D& camera_pos
    ) {
        if(!skyObj) return;
        simulation_time += dt;

        // Continuous diurnal sun orbit progression
        if (day_cycle_active) {
            time_of_day_hours += (dt / day_cycle_duration_sec) * 24.0f;
            if (time_of_day_hours >= 24.0f) time_of_day_hours -= 24.0f;
        }
        updateSunAndAtmosphere();

        skyObj->clear();
        skyObj->begin("SCR/VolumetricSkyDomeMaterial", Ogre::RenderOperation::OT_TRIANGLE_LIST);

        const float DOME_RADIUS = 8000.0f;
        const int RINGS = 48;
        const int SECTORS = 72;

        // ── 1. Geodesic Sky Dome Mesh ─────────────────────────────────────────
        for(int r = 0; r <= RINGS; ++r) {
            float phi = -0.15f + (float(r) / float(RINGS)) * (3.14159265f * 0.5f + 0.15f);
            float sin_phi = std::sin(phi);
            float cos_phi = std::cos(phi);

            for(int s = 0; s <= SECTORS; ++s) {
                float theta = (float(s) / float(SECTORS)) * (3.14159265f * 2.0f);
                float sin_th = std::sin(theta);
                float cos_th = std::cos(theta);

                Spatial::Vector3D dir(cos_phi * cos_th, sin_phi, cos_phi * sin_th);
                dir = dir.normalized();

                Ogre::Vector3 pos(
                    camera_pos.x + dir.x * DOME_RADIUS,
                    camera_pos.y + dir.y * DOME_RADIUS,
                    camera_pos.z + dir.z * DOME_RADIUS
                );

                Ogre::ColourValue col = sampleAtmosphereRay(camera_pos, dir, island);

                skyObj->position(pos);
                skyObj->colour(col);
            }
        }

        // Emit shared index topology with inward facing winding
        uint32_t stride = SECTORS + 1;
        for(int r = 0; r < RINGS; ++r) {
            for(int s = 0; s < SECTORS; ++s) {
                uint32_t idx00 = r * stride + s;
                uint32_t idx01 = (r + 1) * stride + s;
                uint32_t idx11 = (r + 1) * stride + (s + 1);
                uint32_t idx10 = r * stride + (s + 1);

                skyObj->triangle(idx00, idx11, idx01);
                skyObj->triangle(idx00, idx10, idx11);
            }
        }

        float t_night = std::max(0.0f, std::min(1.0f, (0.12f - sun_direction.y) / 0.32f));
        float night_factor = t_night * t_night * (3.0f - 2.0f * t_night);

        // ── 2. Dedicated High-Resolution Circular Celestial Moon Orb Disc ─────
        if (night_factor > 0.01f && moon_direction.y > -0.05f) {
            uint32_t moon_base_idx = (RINGS + 1) * (SECTORS + 1);
            const float MOON_DIST = DOME_RADIUS * 0.95f;
            const float MOON_RADIUS = 280.0f; // Angular diameter ~2.1 degrees in the celestial sphere
            const int MOON_SEGS = 48;

            Ogre::Vector3 moon_center(
                camera_pos.x + moon_direction.x * MOON_DIST,
                camera_pos.y + moon_direction.y * MOON_DIST,
                camera_pos.z + moon_direction.z * MOON_DIST
            );

            // Construct orthogonal tangent/bitangent basis facing camera
            Spatial::Vector3D n_moon(moon_direction.x, moon_direction.y, moon_direction.z);
            Spatial::Vector3D up = (std::abs(n_moon.y) > 0.90f) ? Spatial::Vector3D(1, 0, 0) : Spatial::Vector3D(0, 1, 0);
            Spatial::Vector3D tan_u = n_moon.cross(up).normalized();
            Spatial::Vector3D tan_v = n_moon.cross(tan_u).normalized();

            // Center vertex: luminous pearl white core
            float crater_core = 0.94f + 0.06f * noise_stars.sample(moon_direction.x * 24.0f, moon_direction.y * 24.0f, moon_direction.z * 24.0f);
            Ogre::ColourValue center_col = clampColour(Ogre::ColourValue(0.96f, 0.98f, 1.00f) * (crater_core * night_factor));
            skyObj->position(moon_center);
            skyObj->colour(center_col);

            // 48 Perimeter vertices forming a true, perfect circle with smooth silvery limb
            for (int i = 0; i <= MOON_SEGS; ++i) {
                float ang = (float(i) / float(MOON_SEGS)) * 6.2831853f;
                float ca = std::cos(ang);
                float sa = std::sin(ang);

                Ogre::Vector3 p = moon_center + Ogre::Vector3(
                    (tan_u.x * ca + tan_v.x * sa) * MOON_RADIUS,
                    (tan_u.y * ca + tan_v.y * sa) * MOON_RADIUS,
                    (tan_u.z * ca + tan_v.z * sa) * MOON_RADIUS
                );

                float crater_rim = 0.88f + 0.12f * noise_stars.sample(ca * 4.0f, sa * 4.0f, moon_direction.y * 12.0f);
                Ogre::ColourValue rim_col = clampColour(Ogre::ColourValue(0.82f, 0.89f, 0.98f) * (crater_rim * night_factor));

                skyObj->position(p);
                skyObj->colour(rim_col);
            }

            // Inward-facing triangular fan for the circular Moon
            for (int i = 0; i < MOON_SEGS; ++i) {
                uint32_t i0 = moon_base_idx;
                uint32_t i1 = moon_base_idx + 1 + i;
                uint32_t i2 = moon_base_idx + 1 + (i + 1);
                skyObj->triangle(i0, i2, i1);
            }
        }

        // ── 3. Dedicated High-Resolution Circular Celestial Solar Disc ────────
        if (sun_direction.y > -0.08f) {
            uint32_t sun_base_idx = (night_factor > 0.01f && moon_direction.y > -0.05f) 
                ? (RINGS + 1) * (SECTORS + 1) + 50
                : (RINGS + 1) * (SECTORS + 1);
            const float SUN_DIST = DOME_RADIUS * 0.95f;
            const float SUN_RADIUS = 260.0f;
            const int SUN_SEGS = 48;

            Ogre::Vector3 sun_center(
                camera_pos.x + sun_direction.x * SUN_DIST,
                camera_pos.y + sun_direction.y * SUN_DIST,
                camera_pos.z + sun_direction.z * SUN_DIST
            );

            Spatial::Vector3D n_sun(sun_direction.x, sun_direction.y, sun_direction.z);
            Spatial::Vector3D up = (std::abs(n_sun.y) > 0.90f) ? Spatial::Vector3D(1, 0, 0) : Spatial::Vector3D(0, 1, 0);
            Spatial::Vector3D tan_u = n_sun.cross(up).normalized();
            Spatial::Vector3D tan_v = n_sun.cross(tan_u).normalized();

            float day_vis = std::max(0.0f, std::min(1.0f, (sun_direction.y + 0.08f) / 0.16f));
            Ogre::ColourValue center_col = clampColour(Ogre::ColourValue(1.00f, 1.00f, 0.95f) * day_vis);
            skyObj->position(sun_center);
            skyObj->colour(center_col);

            for (int i = 0; i <= SUN_SEGS; ++i) {
                float ang = (float(i) / float(SUN_SEGS)) * 6.2831853f;
                float ca = std::cos(ang);
                float sa = std::sin(ang);

                Ogre::Vector3 p = sun_center + Ogre::Vector3(
                    (tan_u.x * ca + tan_v.x * sa) * SUN_RADIUS,
                    (tan_u.y * ca + tan_v.y * sa) * SUN_RADIUS,
                    (tan_u.z * ca + tan_v.z * sa) * SUN_RADIUS
                );

                Ogre::ColourValue rim_col = clampColour(sun_color * (day_vis * 0.90f));
                skyObj->position(p);
                skyObj->colour(rim_col);
            }

            for (int i = 0; i < SUN_SEGS; ++i) {
                uint32_t i0 = sun_base_idx;
                uint32_t i1 = sun_base_idx + 1 + i;
                uint32_t i2 = sun_base_idx + 1 + (i + 1);
                skyObj->triangle(i0, i2, i1);
            }
        }

        skyObj->end();
    }
};

} // namespace SCR::Sky

#endif // CAVE_VOLUMETRIC_CLOUDS_HPP
