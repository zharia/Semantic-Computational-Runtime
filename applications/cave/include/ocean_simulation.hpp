/**
 * SCR Render / Liquid — Configurable Liquid & Ocean Rendering Subsystem
 * ─────────────────────────────────────────────────────────────────────────────
 * Implements SCR-LIB-RENDER-WATER (lib/A01_Render/Water/101_definition.md)
 * and SCR-LIB-MATH-GERSTNER (lib/202_Math/Gerstner/101_definition.md).
 *
 * Provides runtime configurable liquid rendering methods:
 *   1. NVJOB_FAST_SHADER: #NVJOB Simple & Fast Dual Scrolling Flow Wave Shader
 *      - High performance, dual scrolling wave displacement & flow interference
 *      - Real-time bathymetric shoreline contact foam & caustics
 *      - Vibrant multi-tier shallow-to-abyss depth extinction & solar specular
 *   2. SEA_OF_THIEVES_GERSTNER: 6-harmonic Trochoidal Gerstner Ocean Simulation
 *      - Analytical wave normals, Jacobian whitecaps, physical buoyancy
 *   3. CEL_STYLED_TOON_WATER: 3-tier Quantized Cel / Toon Shaded Water
 *      - Discrete stepped lighting bands & stylized graphic shoreline foam
 *   4. CALM_REFLECTIVE_GLASS: Calm Mirror Lagoon & Crystal Water
 */

#ifndef CAVE_OCEAN_SIMULATION_HPP
#define CAVE_OCEAN_SIMULATION_HPP

#include <Ogre.h>
#include "simulation/spatial_semantics.hpp"
#include "procedural_island.hpp"

#include <vector>
#include <cmath>
#include <algorithm>
#include <iostream>
#include <string>

#include "water_simulation.hpp"

namespace SCR::Ocean {

// ─── Configurable Liquid Rendering Methods ───────────────────────────────────
enum class LiquidRenderingMethod {
    CANONICAL_OPENGL_SPH_SSFR = 0,  // Canonical 3D SPH & Screen-Space Fluid Rendering (talvinckb)
    NVJOB_FAST_SHADER        = 1,  // NVJOB Simple & Fast Dual-Flow Shader
    SEA_OF_THIEVES_GERSTNER  = 2,  // Multi-Harmonic Trochoidal Gerstner Ocean
    CEL_STYLED_TOON_WATER    = 3,  // 3-Tier Quantized Anime/Comic Toon Water
    CALM_REFLECTIVE_GLASS    = 4   // Mirror-like Calm Lagoon
};

inline const char* getLiquidMethodName(LiquidRenderingMethod method) {
    switch (method) {
        case LiquidRenderingMethod::CANONICAL_OPENGL_SPH_SSFR: return "Canonical 3D SPH & SSFR Water (talvinckb/OpenGL-Water-Simulation)";
        case LiquidRenderingMethod::NVJOB_FAST_SHADER:        return "NVJOB Simple & Fast Dual-Flow Shader";
        case LiquidRenderingMethod::SEA_OF_THIEVES_GERSTNER:  return "Sea of Thieves 6-Octave Gerstner Ocean";
        case LiquidRenderingMethod::CEL_STYLED_TOON_WATER:    return "Anime / Cel-Shaded Quantized Water";
        case LiquidRenderingMethod::CALM_REFLECTIVE_GLASS:    return "Calm Reflective Glass Lagoon";
        default: return "Unknown Liquid Method";
    }
}

// ─── Smoothed Blue-Noise Wave Decorrelation Spectrum ──────────────────────────
struct BlueNoiseWaveField {
    float elevation;    // Subtle aperiodic height displacement (m)
    float normal_dx;    // Gradient d/dx for non-symmetric lighting response
    float normal_dz;    // Gradient d/dz for non-symmetric lighting response
    float warp_u;       // Incommensurate coordinate warp u (m)
    float warp_v;       // Incommensurate coordinate warp v (m)
    float sparkle;      // High-frequency subtle surface micro-caustic
};

/**
 * Computes isotropic, smoothed blue noise across space and time.
 * Suppresses low-frequency symmetry while providing continuous C1-smooth
 * aperiodic perturbation that breaks up wave alignment and phase synchronization.
 */
inline BlueNoiseWaveField sampleSmoothedBlueNoise(float x, float z, float t) {
    // 4 Incommensurate wave vectors rotated by non-rational golden angles
    static const float KX[4] = {  0.3712f, -0.5841f,  0.8129f, -0.2947f };
    static const float KZ[4] = {  0.6419f,  0.4927f, -0.3781f, -0.8415f };
    static const float WT[4] = {  0.4142f,  0.5320f,  0.6360f,  0.7457f }; // Gentle, calming temporal frequencies
    static const float PH[4] = {  0.0000f,  2.3999f,  4.7999f,  1.1999f };
    static const float AM[4] = {  0.0240f,  0.0160f,  0.0100f,  0.0060f }; // Subtle natural amplitudes

    float elev = 0.0f;
    float ndx  = 0.0f;
    float ndz  = 0.0f;
    float wu   = 0.0f;
    float wv   = 0.0f;

    for (int i = 0; i < 4; ++i) {
        float arg = KX[i] * x + KZ[i] * z - WT[i] * (t * 0.45f) + PH[i];
        float cross = -KZ[i] * x + KX[i] * z + WT[i] * (t * 0.35f) + PH[i] * 1.618f;

        float s = std::sin(arg);
        float c = std::cos(cross);

        float s_smooth = s * (1.5f - 0.5f * s * s);
        float wave_contrib = s_smooth * c;

        elev += AM[i] * wave_contrib;

        float d_dx = KX[i] * std::cos(arg) * (1.5f - 1.5f * s * s) * c - (-KZ[i]) * s_smooth * std::sin(cross);
        float d_dz = KZ[i] * std::cos(arg) * (1.5f - 1.5f * s * s) * c - ( KX[i]) * s_smooth * std::sin(cross);
        ndx += AM[i] * d_dx;
        ndz += AM[i] * d_dz;

        wu += AM[i] * 2.5f * (-KZ[i]) * std::sin(cross * 0.8f);
        wv += AM[i] * 2.5f * ( KX[i]) * std::cos(arg * 0.8f);
    }

    BlueNoiseWaveField result;
    result.elevation = elev;
    result.normal_dx = ndx;
    result.normal_dz = ndz;
    result.warp_u    = wu;
    result.warp_v    = wv;
    result.sparkle   = 0.0f;
    return result;
}

// ─── Single Gerstner Harmonic ────────────────────────────────────────────────
struct GerstnerHarmonic {
    float dir_x = 0.0f;
    float dir_z = 0.0f;
    float wavelength = 10.0f;
    float amplitude = 0.1f;
    float speed = 1.0f;
    float steepness = 0.5f;    // Q parameter (0 = pure sine, 1 = maximum trochoid)
    float phase = 0.0f;

    float k = 0.0f;            // wavenumber = 2pi / wavelength
    float omega = 0.0f;        // angular frequency = sqrt(g * k)
    float QA = 0.0f;           // Q * A
};

// ─── Gerstner Wave Spectrum ──────────────────────────────────────────────────
class GerstnerWaveSet {
public:
    static constexpr int NUM_HARMONICS = 8;
    GerstnerHarmonic waves[NUM_HARMONICS];
    float rest_sea_level = 9.0f;
    float total_amplitude = 0.0f;

    GerstnerWaveSet(float sea_level = 9.0f) : rest_sea_level(sea_level) {
        initTropicalPreset();
    }

    void initTropicalPreset() {
        // Natural Rolling Ocean Spectrum:
        // Dominant deep swells + harmonious secondary cross-seas + gentle capillary ripples
        waves[0] = {  0.92f,  0.39f, 85.0f, 0.45f, 0.65f, 0.35f, 0.0f }; // Primary deep rolling swell (85m)
        waves[1] = {  0.88f,  0.47f, 54.0f, 0.28f, 0.70f, 0.38f, 1.4f }; // Primary swell harmonic (54m)
        waves[2] = {  0.71f,  0.71f, 36.0f, 0.18f, 0.75f, 0.40f, 2.8f }; // Secondary cross-sea (36m)
        waves[3] = {  0.95f,  0.31f, 24.0f, 0.11f, 0.80f, 0.42f, 0.7f }; // Intermediate swell (24m)
        waves[4] = {  0.64f,  0.77f, 15.0f, 0.06f, 0.85f, 0.45f, 3.9f }; // Wind sea (15m)
        waves[5] = {  0.82f,  0.57f,  9.5f, 0.035f,0.90f, 0.45f, 5.1f }; // Surface chop (9.5m)
        waves[6] = {  0.50f,  0.86f,  5.5f, 0.020f,0.95f, 0.40f, 1.9f }; // Fine ripple (5.5m)
        waves[7] = {  0.77f,  0.64f,  3.0f, 0.010f,1.00f, 0.35f, 4.2f }; // Micro capillary (3m)

        total_amplitude = 0.0f;
        const float g = 9.81f;
        for(int i = 0; i < NUM_HARMONICS; ++i) {
            float len = std::sqrt(waves[i].dir_x * waves[i].dir_x + waves[i].dir_z * waves[i].dir_z);
            if(len > 1e-4f) {
                waves[i].dir_x /= len;
                waves[i].dir_z /= len;
            }
            waves[i].k = 2.0f * 3.14159265f / waves[i].wavelength;
            waves[i].omega = std::sqrt(g * waves[i].k) * waves[i].speed;
            waves[i].QA = waves[i].steepness * waves[i].amplitude;
            total_amplitude += waves[i].amplitude;
        }
    }

    float sampleHeight(float x, float z, float t) const {
        float y = rest_sea_level;
        for(int i = 0; i < NUM_HARMONICS; ++i) {
            const auto& w = waves[i];
            float dot = w.dir_x * x + w.dir_z * z;
            float theta = w.k * dot - w.omega * t + w.phase;
            y += w.amplitude * std::cos(theta);
        }
        return y;
    }

    struct SurfaceSample {
        Spatial::Point3D  displaced_pos;
        Spatial::Vector3D normal;
        float             elevation;       // Height above rest level (y - sea_level)
        float             crest_foam;      // 0..1 wave peak foam intensity
        float             jacobian;        // Surface compression
    };

    SurfaceSample sampleSurface(float x0, float z0, float t) const {
        float dx = 0.0f, dz = 0.0f, dy = 0.0f;
        float norm_x = 0.0f, norm_z = 0.0f, norm_y = 1.0f;
        float dxx = 0.0f, dzz = 0.0f, dxz = 0.0f;

        for(int i = 0; i < NUM_HARMONICS; ++i) {
            const auto& w = waves[i];
            float dot = w.dir_x * x0 + w.dir_z * z0;
            float theta = w.k * dot - w.omega * t + w.phase;
            float s = std::sin(theta);
            float c = std::cos(theta);

            dx -= w.QA * w.dir_x * s;
            dz -= w.QA * w.dir_z * s;
            dy += w.amplitude * c;

            norm_x -= w.dir_x * (w.k * w.amplitude) * s;
            norm_z -= w.dir_z * (w.k * w.amplitude) * s;
            norm_y -= w.QA * w.k * c;

            dxx += w.QA * (w.dir_x * w.dir_x) * w.k * c;
            dzz += w.QA * (w.dir_z * w.dir_z) * w.k * c;
            dxz += w.QA * (w.dir_x * w.dir_z) * w.k * c;
        }

        float J = (1.0f - dxx) * (1.0f - dzz) - (dxz * dxz);

        float height_ratio = dy / std::max(0.01f, total_amplitude);
        float crest_foam = 0.0f;
        if(J < 0.75f || height_ratio > 0.55f) {
            float foam_j = std::max(0.0f, (0.75f - J) / 0.75f);
            float foam_h = std::max(0.0f, (height_ratio - 0.55f) / 0.45f);
            crest_foam = std::min(1.0f, foam_j * 1.3f + foam_h * 1.5f);
        }

        Spatial::Vector3D n(norm_x, norm_y, norm_z);
        n = n.normalized();

        SurfaceSample sample;
        sample.displaced_pos = Spatial::Point3D(x0 + dx, rest_sea_level + dy, z0 + dz);
        sample.normal = n;
        sample.elevation = dy;
        sample.crest_foam = crest_foam;
        sample.jacobian = J;
        return sample;
    }
};

// ─── Master Configurable Liquid Simulation & Rendering Subsystem ─────────────
class SeaOfThievesWater {
public:
    LiquidRenderingMethod active_method = LiquidRenderingMethod::CANONICAL_OPENGL_SPH_SSFR;

    GerstnerWaveSet wave_set;
    SCR::Water::CanonicalSPHWaterEngine sph_engine;
    float current_time = 0.0f;

    // Grid bounds and resolution (expanded for doubled scene expanse)
    float grid_min_x = -320.0f;
    float grid_max_x = 640.0f;
    float grid_min_z = -320.0f;
    float grid_max_z = 640.0f;
    int   grid_res   = 128; // High-density tessellation across 960m span

    // Multidirectional Flow Parameters
    float nvjob_flow_speed_1 = 0.075f;
    float nvjob_flow_speed_2 = 0.045f;
    float nvjob_flow_scale_1 = 0.065f;
    float nvjob_flow_scale_2 = 0.115f;
    float nvjob_wave_height  = 0.35f;

    // Color Palettes (Linear RGB)
    inline static const Ogre::ColourValue COL_DEEP_ABYSS     = Ogre::ColourValue(0.010f, 0.100f, 0.220f, 0.88f);
    inline static const Ogre::ColourValue COL_MID_CERULEAN   = Ogre::ColourValue(0.025f, 0.450f, 0.600f, 0.60f);
    inline static const Ogre::ColourValue COL_SHALLOW_CYAN  = Ogre::ColourValue(0.080f, 0.820f, 0.740f, 0.30f);
    inline static const Ogre::ColourValue COL_SSS_DAY        = Ogre::ColourValue(0.120f, 0.580f, 0.620f, 0.65f);
    inline static const Ogre::ColourValue COL_FOAM_WHITECAP = Ogre::ColourValue(0.960f, 0.980f, 1.000f, 0.95f);

    SeaOfThievesWater(float sea_level = 9.0f) : wave_set(sea_level), sph_engine(sea_level) {}

    void applyWeather(float wind_speed, float barometric_pressure_hpa, float rain_intensity) {
        float pressure_factor = std::max(0.6f, std::min(2.2f, (1025.0f - barometric_pressure_hpa) / 20.0f));
        float wind_factor = std::max(0.5f, std::min(2.8f, wind_speed / 4.0f));
        float combined_scale = pressure_factor * 0.45f + wind_factor * 0.55f;
        nvjob_wave_height = 0.35f * combined_scale + rain_intensity * 0.005f;
    }

    void setLiquidMethod(LiquidRenderingMethod method) {
        active_method = method;
        std::cout << "[LiquidSystem] Active liquid rendering method -> " << getLiquidMethodName(active_method) << std::endl;
    }

    void cycleLiquidMethod() {
        int next = (int(active_method) + 1) % 5;
        setLiquidMethod(LiquidRenderingMethod(next));
    }

    float sampleHeight(float x, float z, float t) const {
        if (active_method == LiquidRenderingMethod::CALM_REFLECTIVE_GLASS) {
            return wave_set.rest_sea_level;
        } else if (active_method == LiquidRenderingMethod::NVJOB_FAST_SHADER) {
            auto bn = sampleSmoothedBlueNoise(x, z, t);
            float xw = x + bn.warp_u;
            float zw = z + bn.warp_v;

            // Non-separable multidirectional wave propagation
            float u1 = ( 0.819f * xw + 0.573f * zw) * nvjob_flow_scale_1 + t * nvjob_flow_speed_1;
            float v1 = (-0.573f * xw + 0.819f * zw) * nvjob_flow_scale_1 + t * nvjob_flow_speed_1 * 0.75f;
            float u2 = ( 0.342f * xw - 0.940f * zw) * nvjob_flow_scale_2 - t * nvjob_flow_speed_2 * 0.85f;
            float v2 = ( 0.940f * xw + 0.342f * zw) * nvjob_flow_scale_2 + t * nvjob_flow_speed_2;

            float w1 = std::sin(u1 * 6.28f + bn.elevation * 3.5f) * std::cos(v1 * 6.28f - bn.elevation * 2.5f);
            float w2 = std::sin((u2 + v2 * 0.6f) * 4.5f - t * 2.2f + bn.elevation * 2.0f);
            return wave_set.rest_sea_level + (w1 * 0.55f + w2 * 0.40f) * nvjob_wave_height + bn.elevation;
        } else {
            auto bn = sampleSmoothedBlueNoise(x, z, t);
            return wave_set.sampleHeight(x + bn.warp_u * 0.5f, z + bn.warp_v * 0.5f, t) + bn.elevation * 0.65f;
        }
    }

    inline static Ogre::ColourValue clampColour(const Ogre::ColourValue& c) {
        return Ogre::ColourValue(
            std::max(0.0f, std::min(1.0f, c.r <= 1.0f ? c.r : (1.0f - std::exp(-c.r)))),
            std::max(0.0f, std::min(1.0f, c.g <= 1.0f ? c.g : (1.0f - std::exp(-c.g)))),
            std::max(0.0f, std::min(1.0f, c.b <= 1.0f ? c.b : (1.0f - std::exp(-c.b)))),
            std::max(0.0f, std::min(1.0f, c.a))
        );
    }

    /**
     * Compute vertex color for NVJOB Simple & Fast Dual Flow Water with Physical Semi-Transparency.
     */
    Ogre::ColourValue computeNVJOBWaterColor(
        const Spatial::Point3D& pos,
        const Spatial::Vector3D& norm,
        float depth,
        const Spatial::Point3D& camera_pos,
        const Spatial::Vector3D& sun_dir
    ) const {
        auto bn = sampleSmoothedBlueNoise(pos.x, pos.z, current_time);
        float xw = pos.x + bn.warp_u;
        float zw = pos.z + bn.warp_v;

        // 1. Multidirectional Rotated Wave Coordinates
        float u1 = ( 0.819f * xw + 0.573f * zw) * nvjob_flow_scale_1 + current_time * nvjob_flow_speed_1;
        float v1 = (-0.573f * xw + 0.819f * zw) * nvjob_flow_scale_1 + current_time * nvjob_flow_speed_1 * 0.75f;
        float u2 = ( 0.342f * xw - 0.940f * zw) * nvjob_flow_scale_2 - current_time * nvjob_flow_speed_2 * 0.85f;
        float v2 = ( 0.940f * xw + 0.342f * zw) * nvjob_flow_scale_2 + current_time * nvjob_flow_speed_2;

        float ripple1 = std::sin(u1 * 6.28f + bn.elevation * 3.5f) * std::cos(v1 * 6.28f - bn.elevation * 2.5f);
        float ripple2 = std::cos(u2 * 5.5f - bn.elevation * 2.5f) * std::sin(v2 * 5.5f + bn.elevation * 2.0f);
        float ripple_comb = (ripple1 + ripple2) * 0.5f;

        // Diurnal illumination calculation
        float t_night = std::max(0.0f, std::min(1.0f, (0.10f - sun_dir.y) / 0.28f));
        float night_factor = t_night * t_night * (3.0f - 2.0f * t_night);
        float day_factor = 1.0f - night_factor;

        // 2. Optical Depth Extinction (Shallow Cyan -> Mid Cerulean -> Deep Abyss)
        float depth_ratio = std::max(0.0f, std::min(1.0f, depth / 7.0f));
        Ogre::ColourValue water_col;
        if (depth_ratio < 0.4f) {
            float t = depth_ratio / 0.4f;
            water_col = (1.0f - t) * COL_SHALLOW_CYAN + t * COL_MID_CERULEAN;
        } else {
            float t = (depth_ratio - 0.4f) / 0.6f;
            water_col = (1.0f - t) * COL_MID_CERULEAN + t * COL_DEEP_ABYSS;
        }

        // Modulate daytime bright turquoise into nocturnal obsidian navy
        Ogre::ColourValue night_palette(0.005f, 0.020f, 0.052f, water_col.a);
        water_col = (1.0f - night_factor) * water_col + night_factor * night_palette;

        // 3. Shoreline Foam Fringe
        float shore_foam = 0.0f;
        if (depth < 1.8f) {
            float shore_dist = 1.0f - (depth / 1.8f);
            float wash = 0.5f + 0.5f * std::sin(pos.x * 0.9f + pos.z * 0.9f - current_time * 3.2f);
            shore_foam = shore_dist * shore_dist * wash;
        }

        // 4. Caustic shimmering highlights (active mostly during daytime)
        float caustic = std::max(0.0f, ripple_comb * 0.18f) * (day_factor * 0.9f + 0.1f);
        water_col.r += caustic;
        water_col.g += caustic * 1.1f;
        water_col.b += caustic * 0.7f;

        if (shore_foam > 0.05f) {
            Ogre::ColourValue foam_col = (1.0f - night_factor) * COL_FOAM_WHITECAP + night_factor * Ogre::ColourValue(0.18f, 0.28f, 0.42f, 0.95f);
            water_col = (1.0f - shore_foam) * water_col + shore_foam * foam_col;
        }

        // 5. Broad Marine Sun/Moon Glint & Fresnel Reflection
        Spatial::Vector3D view_dir = (camera_pos - pos).normalized();
        bool underwater_cam = (camera_pos.y < pos.y);

        if (underwater_cam) {
            // View from underneath: Snell's window & Total Internal Reflection
            float up_dot = std::max(0.0f, (pos - camera_pos).normalized().y);
            float snell = std::pow(up_dot, 2.2f);
            Ogre::ColourValue under_col = (1.0f - snell) * Ogre::ColourValue(0.015f + 0.025f * day_factor, 0.08f + 0.20f * day_factor, 0.15f + 0.29f * day_factor, 0.85f)
                                        + snell * Ogre::ColourValue(0.08f + 0.10f * day_factor, 0.22f + 0.43f * day_factor, 0.35f + 0.45f * day_factor, 0.45f);
            return clampColour(under_col);
        }

        float NdotV = std::max(0.0f, norm.dot(view_dir));
        float fresnel = 0.03f + 0.97f * std::pow(1.0f - NdotV, 3.5f);

        // Sky reflection color (bright daytime vs warm twilight vs dark nocturnal)
        float twilight_bell = std::exp(-sun_dir.y * sun_dir.y / (2.0f * 0.035f));
        Ogre::ColourValue sky_day(0.68f, 0.84f, 0.98f);
        Ogre::ColourValue sky_twilight = (sun_dir.x < 0.0f)
            ? Ogre::ColourValue(0.96f, 0.62f, 0.28f)
            : Ogre::ColourValue(0.98f, 0.42f, 0.16f);
        Ogre::ColourValue sky_night(0.012f, 0.024f, 0.055f);
        Ogre::ColourValue sky_refl = (1.0f - night_factor) * ((1.0f - twilight_bell) * sky_day + twilight_bell * sky_twilight) + night_factor * sky_night;
        water_col = (1.0f - fresnel * 0.65f) * water_col + (fresnel * 0.65f) * sky_refl;

        // Specular glint from Sun or Moon
        Spatial::Vector3D light_dir = (sun_dir.y > -0.05f) 
            ? sun_dir 
            : Spatial::Vector3D(-sun_dir.x, -sun_dir.y, -sun_dir.z).normalized();
        Spatial::Vector3D half_vec = (view_dir + light_dir).normalized();
        float NdotH = std::max(0.0f, norm.dot(half_vec));
        float light_intensity = (sun_dir.y > -0.05f) ? (0.45f * day_factor) : (0.15f * night_factor);
        float spec = std::pow(NdotH, 24.0f) * light_intensity;

        Ogre::ColourValue sun_spec_col = (1.0f - twilight_bell) * Ogre::ColourValue(1.0f, 0.98f, 0.92f) + twilight_bell * sky_twilight;
        water_col.r += spec * sun_spec_col.r;
        water_col.g += spec * sun_spec_col.g;
        water_col.b += spec * sun_spec_col.b;

        // 6. Physical Transparency Calibration
        if (depth <= 0.001f) {
            water_col.a = 0.0f;
            return clampColour(water_col);
        }
        float alpha_depth = 1.0f - std::exp(-0.45f * depth);
        float alpha_eff = alpha_depth + fresnel * (1.0f - alpha_depth) * 0.65f;
        water_col.a = std::max(0.0f, std::min(0.96f, alpha_eff + shore_foam * 0.70f));

        return clampColour(water_col);
    }

    /**
     * Compute vertex color for Cel-Shaded / Anime Stylized Water.
     */
    Ogre::ColourValue computeCelWaterColor(
        const Spatial::Point3D& pos,
        const Spatial::Vector3D& norm,
        float depth,
        const Spatial::Point3D& camera_pos,
        const Spatial::Vector3D& sun_dir
    ) const {
        if (depth <= 0.001f) {
            Ogre::ColourValue c = COL_SHALLOW_CYAN;
            c.a = 0.0f;
            return c;
        }

        float t_night = std::max(0.0f, std::min(1.0f, (0.10f - sun_dir.y) / 0.28f));
        float night_factor = t_night * t_night * (3.0f - 2.0f * t_night);

        float depth_ratio = std::max(0.0f, std::min(1.0f, depth / 6.0f));

        Ogre::ColourValue base_col;
        if (depth_ratio < 0.25f) {
            base_col = COL_SHALLOW_CYAN;
        } else if (depth_ratio < 0.65f) {
            base_col = COL_MID_CERULEAN;
        } else {
            base_col = COL_DEEP_ABYSS;
        }

        Ogre::ColourValue night_base(0.006f, 0.022f, 0.058f, base_col.a);
        base_col = (1.0f - night_factor) * base_col + night_factor * night_base;

        // Stepped Shoreline Foam Edge
        float shore_foam = 0.0f;
        if (depth < 1.2f) {
            float wave_pulse = 0.5f + 0.5f * std::sin(pos.x * 1.2f + pos.z * 1.2f - current_time * 4.0f);
            if (wave_pulse > 0.45f) shore_foam = 1.0f;
        }

        if (shore_foam > 0.5f) {
            base_col = (1.0f - night_factor) * COL_FOAM_WHITECAP + night_factor * Ogre::ColourValue(0.18f, 0.28f, 0.42f);
        }

        // Smooth Continuous Specular Glint
        Spatial::Vector3D view_dir = (camera_pos - pos).normalized();
        Spatial::Vector3D light_dir = (sun_dir.y > -0.05f) ? sun_dir : Spatial::Vector3D(-sun_dir.x, -sun_dir.y, -sun_dir.z).normalized();
        Spatial::Vector3D half_vec = (view_dir + light_dir).normalized();
        float NdotH = std::max(0.0f, norm.dot(half_vec));
        float twilight_bell = std::exp(-sun_dir.y * sun_dir.y / (2.0f * 0.035f));
        Ogre::ColourValue sky_twilight = (sun_dir.x < 0.0f)
            ? Ogre::ColourValue(0.96f, 0.62f, 0.28f)
            : Ogre::ColourValue(0.98f, 0.42f, 0.16f);
        float spec_factor = std::pow(NdotH, 28.0f) * ((sun_dir.y > -0.05f) ? (0.50f * (1.0f - night_factor)) : (0.15f * night_factor));
        if (spec_factor > 0.002f) {
            Ogre::ColourValue sun_spec_col = (1.0f - twilight_bell) * Ogre::ColourValue(1.0f, 0.98f, 0.92f) + twilight_bell * sky_twilight;
            base_col.r += spec_factor * sun_spec_col.r;
            base_col.g += spec_factor * sun_spec_col.g;
            base_col.b += spec_factor * sun_spec_col.b;
        }

        // Calibrated semi-transparency
        float alpha_depth = 1.0f - std::exp(-0.45f * depth);
        base_col.a = std::max(0.0f, std::min(0.85f, alpha_depth + (shore_foam > 0.5f ? 0.70f : 0.0f)));

        return clampColour(base_col);
    }

    static constexpr int RINGS   = 44;
    static constexpr int SECTORS = 64;
    static constexpr size_t TOTAL_VERTS = 1 + RINGS * SECTORS;

    std::vector<Spatial::Point3D>  positions_buf_;
    std::vector<Spatial::Vector3D> normals_buf_;
    std::vector<Ogre::ColourValue> colors_buf_;
    float ring_radii_cache_[RINGS];
    float sector_cos_[SECTORS];
    float sector_sin_[SECTORS];
    bool tables_initialized_ = false;

    void initPrecomputedTables() {
        if (tables_initialized_) return;
        positions_buf_.resize(TOTAL_VERTS);
        normals_buf_.resize(TOTAL_VERTS);
        colors_buf_.resize(TOTAL_VERTS);

        const float TWO_PI = 6.2831853f;
        for (int s = 0; s < SECTORS; ++s) {
            float angle = (float(s) / float(SECTORS)) * TWO_PI;
            sector_cos_[s] = std::cos(angle);
            sector_sin_[s] = std::sin(angle);
        }

        for (int r = 0; r < RINGS; ++r) {
            float t = float(r + 1) / float(RINGS);
            ring_radii_cache_[r] = 2.0f * (std::exp(t * 5.8f) - 1.0f) + t * 40.0f;
            if (r == RINGS - 1) ring_radii_cache_[r] = 8500.0f;
        }
        tables_initialized_ = true;
    }

    /**
     * Main update and mesh synthesis loop supporting all configurable liquid methods.
     * Uses a Camera-Centered Infinite Radial Projective Clipmap spanning 0m to 8500m
     * with atmospheric horizon fog blending — guaranteeing zero square borders or cutoffs.
     */
    void updateOceanMesh(
        Ogre::ManualObject* oceanObj,
        float dt,
        const Island::VoxelIsland& island,
        const Spatial::Point3D& camera_pos,
        const Spatial::Vector3D& sun_dir
    ) {
        if(!oceanObj) return;
        initPrecomputedTables();
        current_time += dt;

        oceanObj->setRenderQueueGroup(Ogre::RENDER_QUEUE_6);
        oceanObj->clear();
        oceanObj->begin("SCR/OceanWaterMaterial", Ogre::RenderOperation::OT_TRIANGLE_LIST);

        size_t vert_count = 0;
        sph_engine.stepSimulation(dt, island);

        // 1. Center Vertex (Camera XZ)
        {
            float cx = camera_pos.x;
            float cz = camera_pos.z;
            float terrain_h = island.getIslandHeight(cx, cz);
            auto bn = sampleSmoothedBlueNoise(cx, cz, current_time);
            auto s = wave_set.sampleSurface(cx + bn.warp_u * 0.5f, cz + bn.warp_v * 0.5f, current_time);
            s.displaced_pos.y += bn.elevation * 0.65f;
            float depth = std::max(0.0f, s.displaced_pos.y - terrain_h);

            positions_buf_[vert_count] = s.displaced_pos;
            normals_buf_[vert_count] = s.normal;
            if (active_method == LiquidRenderingMethod::CANONICAL_OPENGL_SPH_SSFR) {
                colors_buf_[vert_count] = sph_engine.computeSSFRSurfaceColor(s.displaced_pos, s.normal, depth, camera_pos, sun_dir);
            } else {
                colors_buf_[vert_count] = computeNVJOBWaterColor(s.displaced_pos, s.normal, depth, camera_pos, sun_dir);
            }
            vert_count++;
        }

        // 2. Concentric Radial Ring Vertices
        for (int r = 0; r < RINGS; ++r) {
            float radius = ring_radii_cache_[r];
            float wave_falloff = std::max(0.0f, 1.0f - radius / 500.0f);
            float horizon_fog  = std::min(1.0f, std::max(0.0f, (radius - 600.0f) / 5400.0f));

            for (int s = 0; s < SECTORS; ++s) {
                float cos_a = sector_cos_[s];
                float sin_a = sector_sin_[s];

                float x0 = camera_pos.x + cos_a * radius;
                float z0 = camera_pos.z + sin_a * radius;
                float terrain_h = island.getIslandHeight(x0, z0);

                Spatial::Point3D pos(x0, wave_set.rest_sea_level, z0);
                Spatial::Vector3D norm(0.0f, 1.0f, 0.0f);
                Ogre::ColourValue vert_col;

                if (active_method == LiquidRenderingMethod::CANONICAL_OPENGL_SPH_SSFR) {
                    if (terrain_h >= wave_set.rest_sea_level + 0.05f) {
                        pos.y = wave_set.rest_sea_level;
                        vert_col = Ogre::ColourValue(0.0f, 0.0f, 0.0f, 0.0f);
                    } else {
                        auto bn = sampleSmoothedBlueNoise(x0, z0, current_time);
                        auto s = wave_set.sampleSurface(x0 + bn.warp_u * 0.5f, z0 + bn.warp_v * 0.5f, current_time);
                        pos = s.displaced_pos;
                        pos.y = wave_set.rest_sea_level + (s.displaced_pos.y - wave_set.rest_sea_level + bn.elevation * 0.65f) * wave_falloff;
                        norm = Spatial::Vector3D(s.normal.x * wave_falloff, 1.0f, s.normal.z * wave_falloff).normalized();
                        float depth = std::max(0.0f, pos.y - terrain_h);
                        vert_col = sph_engine.computeSSFRSurfaceColor(pos, norm, depth, camera_pos, sun_dir);
                    }

                } else if (active_method == LiquidRenderingMethod::NVJOB_FAST_SHADER) {
                    if (terrain_h >= wave_set.rest_sea_level + 0.05f) {
                        pos.y = wave_set.rest_sea_level;
                        vert_col = Ogre::ColourValue(0.0f, 0.0f, 0.0f, 0.0f);
                    } else {
                        auto bn = sampleSmoothedBlueNoise(x0, z0, current_time);
                        float xw = x0 + bn.warp_u;
                        float zw = z0 + bn.warp_v;

                        float u1 = ( 0.819f * xw + 0.573f * zw) * nvjob_flow_scale_1 + current_time * nvjob_flow_speed_1;
                        float v1 = (-0.573f * xw + 0.819f * zw) * nvjob_flow_scale_1 + current_time * nvjob_flow_speed_1 * 0.75f;
                        float u2 = ( 0.342f * xw - 0.940f * zw) * nvjob_flow_scale_2 - current_time * nvjob_flow_speed_2 * 0.85f;
                        float v2 = ( 0.940f * xw + 0.342f * zw) * nvjob_flow_scale_2 + current_time * nvjob_flow_speed_2;

                        float h1 = std::sin(u1 * 6.28f + bn.elevation * 3.5f) * std::cos(v1 * 6.28f - bn.elevation * 2.5f);
                        float h2 = std::sin((u2 + v2 * 0.6f) * 4.5f - current_time * 2.2f + bn.elevation * 2.0f);
                        float elevation = ((h1 * 0.55f + h2 * 0.40f) * nvjob_wave_height + bn.elevation) * wave_falloff;

                        float nx = ((-std::cos(u1 * 6.28f) * 0.12f + std::sin(u2 * 4.5f) * 0.08f) + bn.normal_dx * 0.50f) * wave_falloff;
                        float nz = (( std::sin(v1 * 6.28f) * 0.12f - std::cos(v2 * 4.5f) * 0.08f) + bn.normal_dz * 0.50f) * wave_falloff;
                        norm = Spatial::Vector3D(nx, 1.0f, nz).normalized();
                        pos.y = wave_set.rest_sea_level + elevation;

                        float depth = std::max(0.0f, pos.y - terrain_h);
                        vert_col = computeNVJOBWaterColor(pos, norm, depth, camera_pos, sun_dir);
                    }

                } else if (active_method == LiquidRenderingMethod::CEL_STYLED_TOON_WATER) {
                    if (terrain_h >= wave_set.rest_sea_level + 0.05f) {
                        pos.y = wave_set.rest_sea_level;
                        vert_col = Ogre::ColourValue(0.0f, 0.0f, 0.0f, 0.0f);
                    } else {
                        auto bn = sampleSmoothedBlueNoise(x0, z0, current_time);
                        float wave = std::sin((x0 + bn.warp_u) * 0.08f + current_time * 2.0f) * std::cos((z0 + bn.warp_v) * 0.08f + current_time * 1.5f);
                        float elevation = ((wave > 0.0f ? 0.22f : -0.22f) + bn.elevation * 0.5f) * wave_falloff;
                        norm = Spatial::Vector3D(bn.normal_dx * 0.2f * wave_falloff, 1.0f, bn.normal_dz * 0.2f * wave_falloff).normalized();
                        pos.y = wave_set.rest_sea_level + elevation;
                        float depth = std::max(0.0f, pos.y - terrain_h);
                        vert_col = computeCelWaterColor(pos, norm, depth, camera_pos, sun_dir);
                    }

                } else {
                    // Sea of Thieves Physical Gerstner Ocean
                    if (terrain_h >= wave_set.rest_sea_level + 0.05f) {
                        pos.y = wave_set.rest_sea_level;
                        vert_col = Ogre::ColourValue(0.0f, 0.0f, 0.0f, 0.0f);
                    } else {
                        auto bn = sampleSmoothedBlueNoise(x0, z0, current_time);
                        auto s = wave_set.sampleSurface(x0 + bn.warp_u * 0.5f, z0 + bn.warp_v * 0.5f, current_time);
                        pos = s.displaced_pos;
                        pos.y = wave_set.rest_sea_level + (s.displaced_pos.y - wave_set.rest_sea_level + bn.elevation * 0.65f) * wave_falloff;
                        norm = Spatial::Vector3D(s.normal.x * wave_falloff, 1.0f, s.normal.z * wave_falloff).normalized();
                        float depth = std::max(0.0f, pos.y - terrain_h);

                        if (depth <= 0.001f) {
                            vert_col = Ogre::ColourValue(0, 0, 0, 0);
                        } else {
                            float t_night = std::max(0.0f, std::min(1.0f, (0.10f - sun_dir.y) / 0.28f));
                            float night_factor = t_night * t_night * (3.0f - 2.0f * t_night);
                            float day_factor = 1.0f - night_factor;

                            float depth_factor = std::min(1.0f, depth / 8.0f);
                            Ogre::ColourValue base_col = (depth_factor < 0.35f)
                                ? ((1.0f - depth_factor / 0.35f) * COL_SHALLOW_CYAN + (depth_factor / 0.35f) * COL_MID_CERULEAN)
                                : ((1.0f - (depth_factor - 0.35f) / 0.65f) * COL_MID_CERULEAN + ((depth_factor - 0.35f) / 0.65f) * COL_DEEP_ABYSS);

                            Ogre::ColourValue night_base(0.005f, 0.020f, 0.052f, base_col.a);
                            base_col = (1.0f - night_factor) * base_col + night_factor * night_base;

                            Spatial::Vector3D view_dir = (camera_pos - pos).normalized();
                            float sun_view_dot = std::max(0.0f, sun_dir.dot(-view_dir));
                            float sss_intensity = std::pow(sun_view_dot, 3.0f) * std::max(0.0f, s.elevation / std::max(0.1f, wave_set.total_amplitude)) * 0.55f * wave_falloff * day_factor;

                            float twilight_bell = std::exp(-sun_dir.y * sun_dir.y / (2.0f * 0.035f));
                            Ogre::ColourValue sss_dawn_dusk = (sun_dir.x < 0.0f)
                                ? Ogre::ColourValue(0.96f, 0.58f, 0.22f, 0.65f)
                                : Ogre::ColourValue(0.98f, 0.42f, 0.15f, 0.65f);
                            Ogre::ColourValue dynamic_sss = (1.0f - twilight_bell) * COL_SSS_DAY + twilight_bell * sss_dawn_dusk;
                            Ogre::ColourValue water_col = base_col + sss_intensity * dynamic_sss;

                            float shore_foam = (depth < 2.0f) ? std::pow(1.0f - depth / 2.0f, 2.0f) * (0.6f + 0.4f * std::sin(x0 * 0.8f + z0 * 0.8f - current_time * 3.5f)) : 0.0f;
                            float total_foam = std::min(1.0f, (s.crest_foam * 1.1f + shore_foam * 1.2f) * wave_falloff);
                            if(total_foam > 0.02f) {
                                Ogre::ColourValue foam_col = (1.0f - night_factor) * COL_FOAM_WHITECAP + night_factor * Ogre::ColourValue(0.18f, 0.28f, 0.42f, 0.95f);
                                water_col = (1.0f - total_foam) * water_col + total_foam * foam_col;
                            }

                            float NdotV = std::max(0.0f, norm.dot(view_dir));
                            float fresnel = 0.03f + 0.97f * std::pow(1.0f - NdotV, 4.0f);

                            Spatial::Vector3D light_dir = (sun_dir.y > -0.05f) ? sun_dir : Spatial::Vector3D(-sun_dir.x, -sun_dir.y, -sun_dir.z).normalized();
                            float NdotH = std::max(0.0f, norm.dot((view_dir + light_dir).normalized()));
                            float light_int = (sun_dir.y > -0.05f) ? (0.45f * day_factor) : (0.15f * night_factor);
                            float specular = std::pow(NdotH, 28.0f) * light_int;

                            Ogre::ColourValue sky_day(0.68f, 0.84f, 0.98f);
                            Ogre::ColourValue sky_twilight = (sun_dir.x < 0.0f)
                                ? Ogre::ColourValue(0.96f, 0.62f, 0.28f)
                                : Ogre::ColourValue(0.98f, 0.42f, 0.16f);
                            Ogre::ColourValue sky_night(0.012f, 0.024f, 0.055f);
                            Ogre::ColourValue sky_refl = (1.0f - night_factor) * ((1.0f - twilight_bell) * sky_day + twilight_bell * sky_twilight) + night_factor * sky_night;
                            water_col = (1.0f - fresnel * 0.65f) * water_col + (fresnel * 0.65f) * sky_refl;

                            Ogre::ColourValue sun_spec_col = (1.0f - twilight_bell) * Ogre::ColourValue(1.0f, 0.98f, 0.92f) + twilight_bell * sky_twilight;
                            water_col.r += specular * sun_spec_col.r;
                            water_col.g += specular * sun_spec_col.g;
                            water_col.b += specular * sun_spec_col.b;

                            float alpha_depth = 1.0f - std::exp(-0.45f * depth);
                            float alpha_eff = alpha_depth + fresnel * (1.0f - alpha_depth) * 0.65f;
                            water_col.a = std::max(0.0f, std::min(0.96f, alpha_eff + total_foam * 0.70f));
                            vert_col = clampColour(water_col);
                        }
                    }
                }

                // 3. Atmospheric Horizon Aerial Perspective Blending
                if (horizon_fog > 0.001f && vert_col.a > 0.01f) {
                    bool under_water = (camera_pos.y < wave_set.rest_sea_level);
                    Ogre::ColourValue horizon_mist;
                    if (under_water) {
                        horizon_mist = Ogre::ColourValue(0.04f, 0.32f, 0.46f, 0.90f);
                    } else {
                        float t_night = std::max(0.0f, std::min(1.0f, (0.10f - sun_dir.y) / 0.28f));
                        float night_factor = t_night * t_night * (3.0f - 2.0f * t_night);
                        float twilight_bell = std::exp(-sun_dir.y * sun_dir.y / (2.0f * 0.035f));
                        Ogre::ColourValue mist_day(0.68f, 0.84f, 0.96f, 1.0f);
                        Ogre::ColourValue mist_twilight = (sun_dir.x < 0.0f)
                            ? Ogre::ColourValue(0.96f, 0.60f, 0.30f, 1.0f)
                            : Ogre::ColourValue(0.98f, 0.38f, 0.15f, 1.0f);
                        Ogre::ColourValue mist_night(0.012f, 0.022f, 0.050f, 1.0f);
                        horizon_mist = (1.0f - night_factor) 
                            ? ((1.0f - twilight_bell) * mist_day + twilight_bell * mist_twilight)
                            : mist_night;
                    }
                    vert_col.r = (1.0f - horizon_fog) * vert_col.r + horizon_fog * horizon_mist.r;
                    vert_col.g = (1.0f - horizon_fog) * vert_col.g + horizon_fog * horizon_mist.g;
                    vert_col.b = (1.0f - horizon_fog) * vert_col.b + horizon_fog * horizon_mist.b;
                    vert_col.a = (1.0f - horizon_fog) * vert_col.a + horizon_fog * horizon_mist.a;
                }

                positions_buf_[vert_count] = pos;
                normals_buf_[vert_count]   = norm;
                colors_buf_[vert_count]    = vert_col;
                vert_count++;
            }
        }

        // Commit all generated vertices from pre-allocated buffer
        for (size_t i = 0; i < vert_count; ++i) {
            oceanObj->position(positions_buf_[i].x, positions_buf_[i].y, positions_buf_[i].z);
            oceanObj->normal(normals_buf_[i].x, normals_buf_[i].y, normals_buf_[i].z);
            oceanObj->textureCoord(positions_buf_[i].x * 0.08f, positions_buf_[i].z * 0.08f);
            oceanObj->colour(colors_buf_[i]);
        }

        // Emit Triangles for Center Fan (Ring 0)
        for (int s = 0; s < SECTORS; ++s) {
            uint32_t c_idx  = 0;
            uint32_t v1_idx = 1 + s;
            uint32_t v2_idx = 1 + ((s + 1) % SECTORS);
            oceanObj->triangle(c_idx, v1_idx, v2_idx);
        }

        // Emit Quads for Concentric Rings
        for (int r = 0; r < RINGS - 1; ++r) {
            uint32_t r1_start = 1 + r * SECTORS;
            uint32_t r2_start = 1 + (r + 1) * SECTORS;

            for (int s = 0; s < SECTORS; ++s) {
                uint32_t next_s = (s + 1) % SECTORS;

                uint32_t idx00 = r1_start + s;
                uint32_t idx10 = r1_start + next_s;
                uint32_t idx01 = r2_start + s;
                uint32_t idx11 = r2_start + next_s;

                oceanObj->triangle(idx00, idx01, idx11);
                oceanObj->triangle(idx00, idx11, idx10);
            }
        }

        oceanObj->end();
    }
};

} // namespace SCR::Ocean

#endif // CAVE_OCEAN_SIMULATION_HPP
