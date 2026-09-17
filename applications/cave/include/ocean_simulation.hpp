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
#include "spatial_semantics.hpp"
#include "procedural_island.hpp"

#include <vector>
#include <cmath>
#include <algorithm>
#include <iostream>
#include <string>

namespace SCR::Ocean {

// ─── Configurable Liquid Rendering Methods ───────────────────────────────────
enum class LiquidRenderingMethod {
    NVJOB_FAST_SHADER        = 0,  // NVJOB Simple & Fast Dual-Flow Shader
    SEA_OF_THIEVES_GERSTNER  = 1,  // Multi-Harmonic Trochoidal Gerstner Ocean
    CEL_STYLED_TOON_WATER    = 2,  // 3-Tier Quantized Anime/Comic Toon Water
    CALM_REFLECTIVE_GLASS    = 3   // Mirror-like Calm Lagoon
};

inline const char* getLiquidMethodName(LiquidRenderingMethod method) {
    switch (method) {
        case LiquidRenderingMethod::NVJOB_FAST_SHADER:       return "NVJOB Simple & Fast Dual-Flow Shader";
        case LiquidRenderingMethod::SEA_OF_THIEVES_GERSTNER: return "Sea of Thieves 6-Octave Gerstner Ocean";
        case LiquidRenderingMethod::CEL_STYLED_TOON_WATER:   return "Anime / Cel-Shaded Quantized Water";
        case LiquidRenderingMethod::CALM_REFLECTIVE_GLASS:   return "Calm Reflective Glass Lagoon";
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
    float dir_x;
    float dir_z;
    float wavelength;
    float amplitude;
    float speed;
    float steepness;    // Q parameter (0 = pure sine, 1 = maximum trochoid)
    float phase;

    float k;            // wavenumber = 2pi / wavelength
    float omega;        // angular frequency = sqrt(g * k)
    float QA;           // Q * A
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
    LiquidRenderingMethod active_method = LiquidRenderingMethod::SEA_OF_THIEVES_GERSTNER;

    GerstnerWaveSet wave_set;
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
    inline static const Ogre::ColourValue COL_SSS_SUNLIT    = Ogre::ColourValue(0.250f, 0.980f, 0.880f, 0.65f);
    inline static const Ogre::ColourValue COL_FOAM_WHITECAP = Ogre::ColourValue(0.960f, 0.980f, 1.000f, 0.95f);

    SeaOfThievesWater(float sea_level = 9.0f) : wave_set(sea_level) {}

    void setLiquidMethod(LiquidRenderingMethod method) {
        active_method = method;
        std::cout << "[LiquidSystem] Active liquid rendering method -> " << getLiquidMethodName(active_method) << std::endl;
    }

    void cycleLiquidMethod() {
        int next = (int(active_method) + 1) % 4;
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

        // 3. Shoreline Foam Fringe
        float shore_foam = 0.0f;
        if (depth < 1.8f) {
            float shore_dist = 1.0f - (depth / 1.8f);
            float wash = 0.5f + 0.5f * std::sin(pos.x * 0.9f + pos.z * 0.9f - current_time * 3.2f);
            shore_foam = shore_dist * shore_dist * wash;
        }

        // 4. Caustic shimmering highlights
        float caustic = std::max(0.0f, ripple_comb * 0.18f);
        water_col.r += caustic;
        water_col.g += caustic * 1.1f;
        water_col.b += caustic * 0.7f;

        if (shore_foam > 0.05f) {
            water_col = (1.0f - shore_foam) * water_col + shore_foam * COL_FOAM_WHITECAP;
        }

        // 5. Broad Marine Sun Glint & Fresnel Reflection (No pin-point dots)
        Spatial::Vector3D view_dir = (camera_pos - pos).normalized();
        float NdotV = std::max(0.0f, norm.dot(view_dir));
        float fresnel = 0.03f + 0.97f * std::pow(1.0f - NdotV, 3.5f);

        Spatial::Vector3D half_vec = (view_dir + sun_dir).normalized();
        float NdotH = std::max(0.0f, norm.dot(half_vec));
        float spec = std::pow(NdotH, 24.0f) * 0.45f;

        water_col.r += spec;
        water_col.g += spec;
        water_col.b += spec;

        // 6. Physical Transparency Calibration
        float alpha_depth = 1.0f - std::exp(-0.38f * depth);
        alpha_depth = std::max(0.20f, std::min(0.88f, alpha_depth));
        float alpha_eff = alpha_depth + fresnel * (1.0f - alpha_depth) * 0.65f;
        water_col.a = std::max(0.20f, std::min(0.96f, alpha_eff + shore_foam * 0.70f));

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
        float depth_ratio = std::max(0.0f, std::min(1.0f, depth / 6.0f));

        Ogre::ColourValue base_col;
        if (depth_ratio < 0.25f) {
            base_col = COL_SHALLOW_CYAN;
        } else if (depth_ratio < 0.65f) {
            base_col = COL_MID_CERULEAN;
        } else {
            base_col = COL_DEEP_ABYSS;
        }

        // Stepped Shoreline Foam Edge
        float shore_foam = 0.0f;
        if (depth < 1.2f) {
            float wave_pulse = 0.5f + 0.5f * std::sin(pos.x * 1.2f + pos.z * 1.2f - current_time * 4.0f);
            if (wave_pulse > 0.45f) shore_foam = 1.0f;
        }

        if (shore_foam > 0.5f) {
            base_col = COL_FOAM_WHITECAP;
        }

        // Stepped Specular Glint
        Spatial::Vector3D view_dir = (camera_pos - pos).normalized();
        Spatial::Vector3D half_vec = (view_dir + sun_dir).normalized();
        float NdotH = std::max(0.0f, norm.dot(half_vec));
        if (NdotH > 0.94f) {
            base_col = Ogre::ColourValue(1.0f, 1.0f, 1.0f, 1.0f);
        }

        // Calibrated semi-transparency
        float alpha_depth = 1.0f - std::exp(-0.45f * depth);
        base_col.a = std::max(0.25f, std::min(0.85f, alpha_depth + (shore_foam > 0.5f ? 0.70f : 0.0f)));

        return clampColour(base_col);
    }

    /**
     * Main update and mesh synthesis loop supporting all configurable liquid methods.
     */
    void updateOceanMesh(
        Ogre::ManualObject* oceanObj,
        float dt,
        const Island::VoxelIsland& island,
        const Spatial::Point3D& camera_pos,
        const Spatial::Vector3D& sun_dir
    ) {
        if(!oceanObj) return;
        current_time += dt;

        oceanObj->setRenderQueueGroup(Ogre::RENDER_QUEUE_6);
        oceanObj->clear();
        oceanObj->begin("SCR/OceanWaterMaterial", Ogre::RenderOperation::OT_TRIANGLE_LIST);

        float step_x = (grid_max_x - grid_min_x) / float(grid_res);
        float step_z = (grid_max_z - grid_min_z) / float(grid_res);

        const int num_verts_x = grid_res + 1;
        const int num_verts_z = grid_res + 1;

        std::vector<Spatial::Point3D>  positions(num_verts_x * num_verts_z);
        std::vector<Spatial::Vector3D> normals(num_verts_x * num_verts_z);
        std::vector<Ogre::ColourValue> colors(num_verts_x * num_verts_z);

        for(int j = 0; j <= grid_res; ++j) {
            float z0 = grid_min_z + float(j) * step_z;
            for(int i = 0; i <= grid_res; ++i) {
                float x0 = grid_min_x + float(i) * step_x;
                int idx = j * num_verts_x + i;

                float terrain_h = island.getIslandHeight(x0, z0);

                if (active_method == LiquidRenderingMethod::NVJOB_FAST_SHADER) {
                    auto bn = sampleSmoothedBlueNoise(x0, z0, current_time);
                    float xw = x0 + bn.warp_u;
                    float zw = z0 + bn.warp_v;

                    float u1 = ( 0.819f * xw + 0.573f * zw) * nvjob_flow_scale_1 + current_time * nvjob_flow_speed_1;
                    float v1 = (-0.573f * xw + 0.819f * zw) * nvjob_flow_scale_1 + current_time * nvjob_flow_speed_1 * 0.75f;
                    float u2 = ( 0.342f * xw - 0.940f * zw) * nvjob_flow_scale_2 - current_time * nvjob_flow_speed_2 * 0.85f;
                    float v2 = ( 0.940f * xw + 0.342f * zw) * nvjob_flow_scale_2 + current_time * nvjob_flow_speed_2;

                    float h1 = std::sin(u1 * 6.28f + bn.elevation * 3.5f) * std::cos(v1 * 6.28f - bn.elevation * 2.5f);
                    float h2 = std::sin((u2 + v2 * 0.6f) * 4.5f - current_time * 2.2f + bn.elevation * 2.0f);
                    float elevation = (h1 * 0.55f + h2 * 0.40f) * nvjob_wave_height + bn.elevation;

                    float nx = (-std::cos(u1 * 6.28f) * 0.12f + std::sin(u2 * 4.5f) * 0.08f) + bn.normal_dx * 0.50f;
                    float nz = ( std::sin(v1 * 6.28f) * 0.12f - std::cos(v2 * 4.5f) * 0.08f) + bn.normal_dz * 0.50f;
                    Spatial::Vector3D norm(nx, 1.0f, nz);
                    norm = norm.normalized();

                    Spatial::Point3D p(x0, wave_set.rest_sea_level + elevation, z0);
                    float depth = std::max(0.0f, p.y - terrain_h);

                    positions[idx] = p;
                    normals[idx]   = norm;
                    colors[idx]    = computeNVJOBWaterColor(p, norm, depth, camera_pos, sun_dir);

                } else if (active_method == LiquidRenderingMethod::CEL_STYLED_TOON_WATER) {
                    auto bn = sampleSmoothedBlueNoise(x0, z0, current_time);
                    float wave = std::sin((x0 + bn.warp_u) * 0.08f + current_time * 2.0f) * std::cos((z0 + bn.warp_v) * 0.08f + current_time * 1.5f);
                    float elevation = (wave > 0.0f ? 0.22f : -0.22f) + bn.elevation * 0.5f;
                    Spatial::Point3D p(x0, wave_set.rest_sea_level + elevation, z0);
                    Spatial::Vector3D norm(bn.normal_dx * 0.2f, 1.0f, bn.normal_dz * 0.2f);
                    norm = norm.normalized();
                    float depth = std::max(0.0f, p.y - terrain_h);

                    positions[idx] = p;
                    normals[idx]   = norm;
                    colors[idx]    = computeCelWaterColor(p, norm, depth, camera_pos, sun_dir);

                } else if (active_method == LiquidRenderingMethod::CALM_REFLECTIVE_GLASS) {
                    Spatial::Point3D p(x0, wave_set.rest_sea_level, z0);
                    Spatial::Vector3D norm(0.0f, 1.0f, 0.0f);
                    float depth = std::max(0.0f, p.y - terrain_h);
                    float depth_ratio = std::min(1.0f, depth / 8.0f);
                    Ogre::ColourValue col = (1.0f - depth_ratio) * COL_SHALLOW_CYAN + depth_ratio * COL_DEEP_ABYSS;
                    float alpha_depth = 1.0f - std::exp(-0.35f * depth);
                    col.a = std::max(0.20f, std::min(0.85f, alpha_depth));

                    positions[idx] = p;
                    normals[idx]   = norm;
                    colors[idx]    = clampColour(col);

                } else {
                    // Sea of Thieves 8-Harmonic Gerstner Physical Ocean with Trochoidal Horizontal Displacement
                    auto bn = sampleSmoothedBlueNoise(x0, z0, current_time);
                    auto s = wave_set.sampleSurface(x0 + bn.warp_u * 0.5f, z0 + bn.warp_v * 0.5f, current_time);
                    s.displaced_pos.y += bn.elevation * 0.65f;
                    s.normal.x += bn.normal_dx * 0.35f;
                    s.normal.z += bn.normal_dz * 0.35f;
                    s.normal = s.normal.normalized();
                    float depth = std::max(0.0f, s.displaced_pos.y - terrain_h);
                    positions[idx] = s.displaced_pos;
                    normals[idx]   = s.normal;

                    // Multi-spectral Sea of Thieves color evaluation
                    float depth_factor = std::min(1.0f, depth / 8.0f);
                    Ogre::ColourValue base_col = (depth_factor < 0.35f)
                        ? ((1.0f - depth_factor / 0.35f) * COL_SHALLOW_CYAN + (depth_factor / 0.35f) * COL_MID_CERULEAN)
                        : ((1.0f - (depth_factor - 0.35f) / 0.65f) * COL_MID_CERULEAN + ((depth_factor - 0.35f) / 0.65f) * COL_DEEP_ABYSS);

                    Spatial::Vector3D view_dir = (camera_pos - s.displaced_pos).normalized();
                    float sun_view_dot = std::max(0.0f, sun_dir.dot(-view_dir));
                    float sss_intensity = std::pow(sun_view_dot, 3.0f) * std::max(0.0f, s.elevation / std::max(0.1f, wave_set.total_amplitude)) * 0.55f;
                    Ogre::ColourValue water_col = base_col + sss_intensity * COL_SSS_SUNLIT;

                    float shore_foam = (depth < 2.0f) ? std::pow(1.0f - depth / 2.0f, 2.0f) * (0.6f + 0.4f * std::sin(x0 * 0.8f + z0 * 0.8f - current_time * 3.5f)) : 0.0f;
                    float total_foam = std::min(1.0f, s.crest_foam * 1.1f + shore_foam * 1.2f);
                    if(total_foam > 0.02f) water_col = (1.0f - total_foam) * water_col + total_foam * COL_FOAM_WHITECAP;

                    float NdotV = std::max(0.0f, s.normal.dot(view_dir));
                    float fresnel = 0.03f + 0.97f * std::pow(1.0f - NdotV, 4.0f);
                    float NdotH = std::max(0.0f, s.normal.dot((view_dir + sun_dir).normalized()));
                    float specular = std::pow(NdotH, 28.0f) * 0.45f;

                    water_col.r += specular;
                    water_col.g += specular;
                    water_col.b += specular;

                    // Physical Beer-Lambert + Fresnel Transparency
                    float alpha_depth = 1.0f - std::exp(-0.38f * depth);
                    alpha_depth = std::max(0.20f, std::min(0.88f, alpha_depth));
                    float alpha_eff = alpha_depth + fresnel * (1.0f - alpha_depth) * 0.65f;
                    water_col.a = std::max(0.20f, std::min(0.96f, alpha_eff + total_foam * 0.70f));

                    colors[idx] = clampColour(water_col);
                }
            }
        }

        // Commit shared vertex data
        for(int j = 0; j <= grid_res; ++j) {
            for(int i = 0; i <= grid_res; ++i) {
                int idx = j * num_verts_x + i;
                oceanObj->position(positions[idx].x, positions[idx].y, positions[idx].z);
                oceanObj->normal(normals[idx].x, normals[idx].y, normals[idx].z);
                oceanObj->textureCoord(positions[idx].x * 0.08f, positions[idx].z * 0.08f);
                oceanObj->colour(colors[idx]);
            }
        }

        // Emit shared quad indices
        for(int j = 0; j < grid_res; ++j) {
            for(int i = 0; i < grid_res; ++i) {
                uint32_t idx00 = j * num_verts_x + i;
                uint32_t idx01 = (j + 1) * num_verts_x + i;
                uint32_t idx11 = (j + 1) * num_verts_x + (i + 1);
                uint32_t idx10 = j * num_verts_x + (i + 1);

                oceanObj->triangle(idx00, idx01, idx11);
                oceanObj->triangle(idx00, idx11, idx10);
            }
        }

        oceanObj->end();
    }
};

} // namespace SCR::Ocean

#endif // CAVE_OCEAN_SIMULATION_HPP
