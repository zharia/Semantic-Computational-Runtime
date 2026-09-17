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
    // Time of Day in 24h format (15.0 = mid-afternoon tropical sun, 17.8 = golden hour/sunset, 23.0 = starry night)
    float time_of_day_hours = 15.0f;

    // Wind velocities (m/s) per altitude tier (differential wind shear)
    float wind_low_x = 3.2f, wind_low_z = 2.0f;
    float wind_mid_x = 6.5f, wind_mid_z = -3.8f;
    float wind_high_x = 12.0f, wind_high_z = 7.5f;

    float simulation_time = 0.0f;
    CloudPreset current_preset = PRESET_RDR2_SCATTERED;

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
    SCR::Noise::GradientNoise3D noise_clouds_low;
    SCR::Noise::GradientNoise3D noise_clouds_mid;
    SCR::Noise::GradientNoise3D noise_clouds_high;

    struct CloudDeckResult {
        float density = 0.0f;
        float optical_depth = 0.0f;
        float height_norm = 0.5f;
    };

    VolumetricAtmosphere()
        : noise_stars(9999),
          noise_clouds_low(4242),
          noise_clouds_mid(8818),
          noise_clouds_high(1919) {
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

    // Weather modulation parameters
    float weather_coverage_mult = 1.0f;
    float weather_density_mult = 1.0f;
    float weather_lightning_flash = 0.0f;
    Ogre::ColourValue weather_sky_tint{1.0f, 1.0f, 1.0f, 1.0f};
    float weather_ambient_scale = 1.0f;

    void applyWeather(
        float coverage_mult,
        float density_mult,
        const Spatial::Vector3D& wind_vel,
        const Ogre::ColourValue& sky_tint,
        float ambient_scale,
        float lightning_flash
    ) {
        weather_coverage_mult = coverage_mult;
        weather_density_mult = density_mult;
        weather_sky_tint = sky_tint;
        weather_ambient_scale = ambient_scale;
        weather_lightning_flash = lightning_flash;

        wind_low_x = wind_vel.x;
        wind_low_z = wind_vel.z;
        wind_mid_x = wind_vel.x * 1.4f;
        wind_mid_z = wind_vel.z * 1.2f - 1.5f;
        wind_high_x = wind_vel.x * 2.0f;
        wind_high_z = wind_vel.z * 1.8f;
    }

    /**
     * Samples the continuous 3-tier volumetric cloud deck density.
     */
    CloudDeckResult sampleVolumetricCloudDecks(
        const Spatial::Vector3D& dir,
        float time
    ) const {
        CloudDeckResult res;
        if (dir.y <= 0.005f) return res;

        float inv_y = 1.0f / dir.y;
        float coverage_mult = 1.0f;
        float density_mult = 1.0f;

        switch (current_preset) {
            case PRESET_RDR2_SCATTERED:
                coverage_mult = 1.0f;
                density_mult = 1.0f;
                break;
            case PRESET_GOLDEN_SUNSET:
                coverage_mult = 1.25f;
                density_mult = 1.35f;
                break;
            case PRESET_VOLCANIC_STORM:
                coverage_mult = 1.8f;
                density_mult = 2.0f;
                break;
            case PRESET_CLEAR_TROPICAL:
                coverage_mult = 0.65f;
                density_mult = 0.75f;
                break;
            default:
                break;
        }

        coverage_mult *= weather_coverage_mult;
        density_mult *= weather_density_mult;

        // ── 1. Tier 1: Low Cumulus & Stratocumulus Deck (1200m) ────────────────
        float alt_1 = 1200.0f;
        float dist_1 = alt_1 * inv_y;
        if (dist_1 < 25000.0f) {
            float u1 = (dir.x * dist_1 + wind_low_x * time * 12.0f) * 0.00012f;
            float v1 = (dir.z * dist_1 + wind_low_z * time * 12.0f) * 0.00012f;

            // Macro coverage: 3-octave FBM for broad, sweeping cloud formations
            float macro1 = noise_clouds_low.fbm(u1, 0.4f, v1, 3, 2.0f, 0.55f);
            float cov_thresh = -0.05f - (coverage_mult - 1.0f) * 0.28f;

            if (macro1 > cov_thresh) {
                float d1 = (macro1 - cov_thresh) / (1.0f - cov_thresh);
                d1 = std::min(1.0f, d1 * 1.75f);

                // Micro billow puff variation
                float billow1 = noise_clouds_low.sample(u1 * 3.5f, 1.2f, v1 * 3.5f) * 0.5f + 0.5f;
                d1 *= (0.60f + 0.40f * billow1);

                float opt1 = d1 * 5.2f * density_mult;
                res.density = std::max(res.density, d1);
                res.optical_depth += opt1;
            }
        }

        // ── 2. Tier 2: Mid Altocumulus & Caldera Plume (2800m) ─────────────────
        float alt_2 = 2800.0f;
        float dist_2 = alt_2 * inv_y;
        if (dist_2 < 35000.0f) {
            float u2 = (dir.x * dist_2 + wind_mid_x * time * 16.0f) * 0.00009f;
            float v2 = (dir.z * dist_2 + wind_mid_z * time * 16.0f) * 0.00009f;

            float macro2 = noise_clouds_mid.fbm(u2 * 1.5f, 0.8f, v2 * 1.5f, 3, 2.0f, 0.52f);
            float cov_thresh2 = 0.02f - (coverage_mult - 1.0f) * 0.20f;

            if (macro2 > cov_thresh2) {
                float d2 = (macro2 - cov_thresh2) / (1.0f - cov_thresh2);
                d2 = std::min(1.0f, d2 * 1.6f);

                float billow2 = noise_clouds_mid.sample(u2 * 4.2f, 2.1f, v2 * 4.2f) * 0.5f + 0.5f;
                d2 *= (0.65f + 0.35f * billow2);

                res.density = std::max(res.density, d2 * 0.85f);
                res.optical_depth += d2 * 3.8f * density_mult;
            }

            // Convective Volcanic Caldera Plume (rising from island center x=0, z=0)
            float dist_center = std::sqrt(dir.x * dir.x + dir.z * dir.z) * dist_2;
            float plume_radius = 550.0f + dir.y * 950.0f;
            if (dist_center < plume_radius) {
                float plume_factor = 1.0f - (dist_center / plume_radius);
                float plume_noise = noise_clouds_mid.fbm(
                    dir.x * 0.012f + time * 0.03f,
                    dir.y * 0.020f - time * 0.10f,
                    dir.z * 0.012f,
                    3, 2.0f, 0.5f
                ) * 0.5f + 0.5f;
                float d_plume = plume_factor * plume_noise;
                res.density = std::max(res.density, d_plume);
                res.optical_depth += d_plume * 4.5f;
            }
        }

        // ── 3. Tier 3: High Wispy Cirrus Ice Streaks (6500m) ──────────────────
        float alt_3 = 6500.0f;
        float dist_3 = alt_3 * inv_y;
        if (dist_3 < 55000.0f) {
            float u3 = (dir.x * dist_3 + wind_high_x * time * 24.0f) * 0.00005f;
            float v3 = (dir.z * dist_3 + wind_high_z * time * 24.0f) * 0.00005f;

            float cirrus = noise_clouds_high.fbm(u3 * 2.8f, 4.0f, v3 * 0.7f, 3, 2.1f, 0.52f);
            if (cirrus > 0.04f) {
                float d3 = std::min(1.0f, (cirrus - 0.04f) * 1.8f);
                res.density = std::max(res.density, d3 * 0.65f);
                res.optical_depth += d3 * 1.6f;
            }
        }

        res.density = std::min(1.0f, res.density);
        res.optical_depth = std::min(8.0f, res.optical_depth);
        return res;
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
        // Transitions smoothly after sunset across civil/nautical twilight: sun_elevation in [-0.28, -0.02]
        float t_night = std::max(0.0f, std::min(1.0f, (-0.02f - sun_elevation) / 0.26f));
        float night_factor = t_night * t_night * (3.0f - 2.0f * t_night); // Smooth Hermite S-curve

        // Smooth Twilight Golden / Crimson Horizon Factor
        float twilight_bell = std::exp(-sun_elevation * sun_elevation / (2.0f * 0.040f));

        // ── 1. Continuous Zenith Color ─────────────────────────────────────────
        Ogre::ColourValue zenith_day(0.15f, 0.46f, 0.92f);
        Ogre::ColourValue zenith_twilight(0.14f, 0.12f, 0.28f);
        Ogre::ColourValue zenith_night(0.015f, 0.028f, 0.078f);

        zenith_color = (1.0f - night_factor) * (zenith_day * (1.0f - twilight_bell) + zenith_twilight * twilight_bell)
                     + night_factor * zenith_night;

        // ── 2. Continuous Horizon Color ────────────────────────────────────────
        Ogre::ColourValue horizon_day(0.68f, 0.84f, 0.96f);
        Ogre::ColourValue horizon_twilight = (time_of_day_hours < 12.0f)
            ? Ogre::ColourValue(0.98f, 0.62f, 0.28f)  // Golden dawn
            : Ogre::ColourValue(1.00f, 0.42f, 0.16f); // Rich fiery sunset
        Ogre::ColourValue horizon_night(0.042f, 0.062f, 0.138f);

        horizon_color = (1.0f - night_factor) * (horizon_day * (1.0f - twilight_bell) + horizon_twilight * twilight_bell)
                      + night_factor * horizon_night;

        // ── 3. Directional Solar / Lunar Light ──────────────────────────────────
        Ogre::ColourValue sun_day(1.00f, 0.96f, 0.88f);
        Ogre::ColourValue sun_twilight = (time_of_day_hours < 12.0f)
            ? Ogre::ColourValue(1.00f, 0.62f, 0.24f)
            : Ogre::ColourValue(1.00f, 0.48f, 0.14f);
        Ogre::ColourValue moon_direct(0.18f, 0.26f, 0.42f); // Soft silvery moonlight

        sun_color = (1.0f - night_factor) * (sun_day * (1.0f - twilight_bell) + sun_twilight * twilight_bell)
                  + night_factor * moon_direct;

        // ── 4. Reduced Night Global Illumination / Ambient Sky Light ────────────
        Ogre::ColourValue ambient_day(0.32f, 0.38f, 0.46f);
        Ogre::ColourValue ambient_twilight = (time_of_day_hours < 12.0f)
            ? Ogre::ColourValue(0.24f, 0.20f, 0.22f)
            : Ogre::ColourValue(0.26f, 0.18f, 0.20f);
        Ogre::ColourValue ambient_night(0.038f, 0.052f, 0.082f); // Balanced celestial ambient at night

        ambient_sky_color = (1.0f - night_factor) * (ambient_day * (1.0f - twilight_bell) + ambient_twilight * twilight_bell)
                          + night_factor * ambient_night;

        // ── 5. Weather Tint & Lightning Flash Illumination ───────────────────────
        zenith_color = zenith_color * weather_sky_tint * weather_ambient_scale;
        horizon_color = horizon_color * weather_sky_tint * weather_ambient_scale;
        ambient_sky_color = ambient_sky_color * weather_sky_tint * weather_ambient_scale;
        sun_color = sun_color * weather_sky_tint * weather_ambient_scale;

        if (weather_lightning_flash > 0.01f) {
            Ogre::ColourValue flash(0.92f, 0.96f, 1.0f);
            zenith_color = clampColour(zenith_color + flash * (weather_lightning_flash * 1.8f));
            horizon_color = clampColour(horizon_color + flash * (weather_lightning_flash * 2.2f));
            ambient_sky_color = clampColour(ambient_sky_color + flash * (weather_lightning_flash * 2.5f));
            sun_color = clampColour(sun_color + flash * (weather_lightning_flash * 2.0f));
        }
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

        // 2. Continuous Analytical Solar Disc & Golden Mie Forward Scattering Halo on Dome
        float cos_sun = ray_dir.dot(sun_direction);
        if (sun_direction.y > -0.12f && cos_sun > 0.0f) {
            float day_vis = (1.0f - night_factor);
            // Solar Disc: angular radius ~0.035 radians (cos ~ 0.9993)
            float sun_disc = std::max(0.0f, std::min(1.0f, (cos_sun - 0.9985f) / 0.0012f));
            float corona = std::pow(cos_sun, 28.0f) * 0.42f * day_vis;
            Ogre::ColourValue glow = corona * sun_color + sun_disc * Ogre::ColourValue(1.0f, 1.0f, 0.96f) * (day_vis * 1.5f);
            sky.r = std::min(1.0f, sky.r + glow.r);
            sky.g = std::min(1.0f, sky.g + glow.g);
            sky.b = std::min(1.0f, sky.b + glow.b);
        }

        // 3. Continuous Analytical Lunar Disc & Silvery Mie Forward Scattering Halo on Dome
        float cos_moon = ray_dir.dot(moon_direction);
        if (night_factor > 0.01f && moon_direction.y > -0.05f && cos_moon > 0.0f) {
            // Lunar Disc: angular radius ~0.030 radians (cos ~ 0.9995)
            float moon_disc = std::max(0.0f, std::min(1.0f, (cos_moon - 0.9988f) / 0.0010f));
            float crater = 0.92f + 0.08f * noise_stars.sample(ray_dir.x * 24.0f, ray_dir.y * 24.0f, ray_dir.z * 24.0f);
            float lunar_corona = std::pow(cos_moon, 20.0f) * 0.32f * night_factor;
            Ogre::ColourValue moon_glow = lunar_corona * Ogre::ColourValue(0.45f, 0.65f, 0.92f) 
                                        + moon_disc * Ogre::ColourValue(0.92f, 0.96f, 1.00f) * (night_factor * crater * 1.25f);
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

        // 6. Red Dead Redemption 2 Multi-Tier Volumetric Cloud Lighting
        if (elev > 0.035f) {
            auto cloud = sampleVolumetricCloudDecks(ray_dir, simulation_time);
            if (cloud.density > 0.005f) {
                // Dual-lobe Henyey-Greenstein forward Mie phase function (silver lining)
                float cos_theta_sun = ray_dir.dot(sun_direction);
                float phase_sun = cloudPhaseDualLobe(cos_theta_sun);
                float silver_lining = std::pow(std::max(0.0f, cos_theta_sun), 12.0f) * 2.4f;

                // Beer-Lambert transmittance with powdered-sugar multiple-scattering
                float T = std::exp(-cloud.optical_depth * 1.15f);
                float powder_sugar = 1.0f - std::exp(-cloud.optical_depth * 2.2f);
                float direct_light = (1.0f - T) * powder_sugar;

                // Day / Sunset / Twilight Cloud Colorimetry
                Ogre::ColourValue cloud_sunlit = (1.0f - night_factor) 
                    ? (Ogre::ColourValue(1.0f, 1.0f, 0.98f) * (1.10f + phase_sun * 0.40f + silver_lining * 0.50f))
                    : Ogre::ColourValue(0.72f, 0.84f, 0.98f);
                Ogre::ColourValue cloud_shadow = ambient_sky_color * 0.70f + horizon_color * 0.30f;

                // Twilight dramatic underbelly glow
                float twilight_boost = std::exp(-sun_direction.y * sun_direction.y / 0.04f);
                if (twilight_boost > 0.05f) {
                    Ogre::ColourValue fiery_amber = (sun_direction.x < 0.0f) 
                        ? Ogre::ColourValue(1.00f, 0.62f, 0.22f) 
                        : Ogre::ColourValue(1.00f, 0.40f, 0.16f);
                    cloud_sunlit = (1.0f - twilight_boost * 0.75f) * cloud_sunlit + (twilight_boost * 0.75f) * fiery_amber;
                    cloud_shadow = (1.0f - twilight_boost * 0.60f) * cloud_shadow + (twilight_boost * 0.60f) * Ogre::ColourValue(0.32f, 0.14f, 0.28f);
                }

                // Nocturnal Moonlight Cloud Lighting
                if (night_factor > 0.01f) {
                    float cos_theta_moon = ray_dir.dot(moon_direction);
                    float phase_moon = cloudPhaseDualLobe(cos_theta_moon);
                    Ogre::ColourValue moon_cloud_lit = Ogre::ColourValue(0.76f, 0.86f, 0.98f) * (night_factor * (0.40f + phase_moon * 0.30f));
                    Ogre::ColourValue moon_cloud_shadow = ambient_sky_color * (night_factor * 0.50f);

                    cloud_sunlit = (1.0f - night_factor) * cloud_sunlit + night_factor * moon_cloud_lit;
                    cloud_shadow = (1.0f - night_factor) * cloud_shadow + night_factor * moon_cloud_shadow;
                }

                // Composite illuminated cloud with self-shadowing
                Ogre::ColourValue cloud_color = (direct_light * 0.70f + 0.30f) * cloud_sunlit * (1.0f - cloud.density * 0.30f)
                                              + cloud_shadow * (cloud.density * 0.70f);

                // Alpha blending over Rayleigh/Mie sky background with horizon haze fade
                float horizon_fade = std::min(1.0f, (elev - 0.035f) / 0.085f);
                float cloud_alpha = std::min(1.0f, (1.0f - T) * 1.45f * horizon_fade);

                sky = (1.0f - cloud_alpha) * sky + cloud_alpha * cloud_color;
            }
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
        const int RINGS = 64;
        const int SECTORS = 96;

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

        skyObj->end();
    }
};

} // namespace SCR::Sky

#endif // CAVE_VOLUMETRIC_CLOUDS_HPP
