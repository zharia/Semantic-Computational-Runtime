#ifndef SCR_O3DE_DYNAMIC_SKY_HPP
#define SCR_O3DE_DYNAMIC_SKY_HPP

#include "simulation/simulation_systems_core.hpp"
#include "o3de/o3de_render_context.hpp"
#include "o3de/o3de_mesh_builder.hpp"
#include "multi_scale_noise.hpp"

#include <Atom/Feature/SkyBox/SkyBoxFeatureProcessorInterface.h>
#include <Atom/Feature/SkyBox/SkyBoxFogSettings.h>
#include <Atom/RHI.Reflect/Format.h>
#include <Atom/RHI.Reflect/ImageEnums.h>
#include <Atom/RHI.Reflect/Size.h>
#include <Atom/RPI.Public/Image/ImageSystemInterface.h>
#include <Atom/RPI.Public/Image/StreamingImage.h>
#include <Atom/RPI.Public/Image/StreamingImagePool.h>
#include <Atom/RPI.Public/Material/Material.h>
#include <Atom/RPI.Public/Scene.h>
#include <AzCore/Math/Color.h>
#include <AzCore/Math/Transform.h>
#include <AzCore/Math/Vector3.h>
#include <AzCore/std/containers/vector.h>
#include <cmath>

namespace SCR::Render::O3DE {

// SCR Weather spec (lib/503_Simulation/Environment/Weather): three cloud decks at
// 150-500m (stratus/cumulus), 500-1000m (allocumulus), 1000-2000m (cirrus),
// wind shear v(y) = v_surf * (y/y0)^α, aerosol → Rayleigh/Mie turbidity.
// Provider renders AtmosphereSubject state via skybox fog + per-deck procedural
// cloud field (SCR::Noise fbm + wind advection), not static image assets.
//
// The skybox itself stays the authored HDRi cubemap from the level prefab: its
// .exr streaming image is the scene's Image-Based-Light source. Flipping SkyBox
// mode to PhysicalSky makes the standard-PBR world flat (no IBL) and samples a
// null cubemap when the scene carries no PhysicalSky component — a black sky.
// So the provider drives AtmosphereSubject → fog band + cloud field only.

class O3deDynamicSky {
public:
    static constexpr int kDeckCount = 3;

    bool initialized = false;
    float time = 0.0f;
    float cloudFieldTime = 0.0f;
    float nextCloudRegen = 0.0f;
    AZ::Render::SkyBoxFeatureProcessorInterface* skyFp = nullptr;

    O3deMeshHandle decks[kDeckCount];
    AZ::Data::Instance<AZ::RPI::Material> deckMats[kDeckCount];
    AZ::Data::Instance<AZ::RPI::StreamingImage> deckFieldImages[kDeckCount];

    // Deck altitudes (midpoint of SCR Weather tiers), XY scale, cloud resolution
    float deck_altitude[kDeckCount] = { 320.0f, 720.0f, 1400.0f };
    float deck_scale[kDeckCount]    = { 1800.0f, 1500.0f, 2000.0f };
    float deck_opacity[kDeckCount]  = { 0.75f, 0.65f, 0.55f };
    int deck_cell[kDeckCount]       = { 5, 9, 14 };   // noise frequency per deck (coarser low, finer cirrus)
    int deck_octaves[kDeckCount]    = { 4, 4, 3 };
    int deck_res[kDeckCount]        = { 160, 160, 192 };

    // Wind shear exponent α and reference height y0 (Weather spec: v(y)=v_surf·(y/y0)^α)
    static constexpr float kWindShearAlpha = 0.75f;
    static constexpr float kWindShearY0 = 150.0f;

    // Sun: afternoon over island (azimuth deg, altitude deg)
    float sun_azimuth = 135.0f;
    float sun_altitude = 40.0f;

    // Cached property indices per deck material
    AZ::RPI::MaterialPropertyIndex idx_texture[kDeckCount];
    AZ::RPI::MaterialPropertyIndex idx_opacity[kDeckCount];

    void initialize(AZ::RPI::Scene* scene) {
        if (initialized || !scene) return;

        configureSky(scene);
        createCloudDecks(scene);
        initialized = true;
    }

    void update(float dt, Simulation::AtmosphereSubject* atmo) {
        if (!initialized) return;
        time += dt;
        if (atmo) {
            driveFog(atmo);
            updateCloudFields(atmo, dt);
        }
    }

    void cleanup(Simulation::RenderContext& renderCtx) {
        auto* scene = renderCtx.getSceneManager<AZ::RPI::Scene>();
        if (scene) {
            auto* fp = scene->GetFeatureProcessor<AZ::Render::MeshFeatureProcessorInterface>();
            if (fp) {
                for (int i = 0; i < kDeckCount; ++i) {
                    if (decks[i].valid) {
                        fp->ReleaseMesh(decks[i].handle);
                        decks[i].valid = false;
                    }
                }
            }
        }
        for (int i = 0; i < kDeckCount; ++i) {
            deckMats[i].reset();
            deckFieldImages[i].reset();
        }
        initialized = false;
        time = 0.0f;
        cloudFieldTime = 0.0f;
        nextCloudRegen = 0.0f;
    }

    // Fog: skybox fog tints the direction-space gradient band. Enabled only for
    // meaningful density; ash colors it grey-brown.
    void driveFog(Simulation::AtmosphereSubject* atmo) {
        if (!skyFp) return;
        bool fogOn = atmo->fog_density > 0.01f;
        AZ::Render::SkyBoxFogSettings fog;
        fog.m_enable = fogOn;
        fog.m_color = AZ::Color(0.78f + 0.1f * atmo->volcanic_ash_fraction,
                                0.82f + 0.05f * atmo->volcanic_ash_fraction,
                                0.90f, 1.0f);
        fog.m_bottomHeight = 0.0f;
        fog.m_topHeight = 0.12f + std::clamp(atmo->fog_density * 30.0f, 0.0f, 0.5f);
        skyFp->SetFogSettings(fog);
    }

    // Regenerate procedural cloud field textures (RGBA8, alpha = cloud density).
    // Cloud density per deck from SCR Weather spec: alt strata → cell frequency,
    // wind shear guides advection. Full re-drive only on a short cadence so the
    // GPU sees a static field the rest of the frame (cheap), still sim-driven.
    void updateCloudFields(Simulation::AtmosphereSubject* atmo, float dt) {
        cloudFieldTime += dt;
        const float kRegenInterval = 1.0f / 6.0f;
        if (cloudFieldTime < nextCloudRegen) return;
        nextCloudRegen = cloudFieldTime + kRegenInterval;

        for (int i = 0; i < kDeckCount; ++i) {
            if (!deckMats[i]) continue;
            generateCloudFieldTexture(atmo, i);
        }
    }

    void generateCloudFieldTexture(Simulation::AtmosphereSubject* atmo, int idx) {
        int res = std::max(deck_res[idx], 64);

        // Wind shear per deck: v(y) = v_surf * (y/y0)^α
        float y = std::max(deck_altitude[idx], 10.0f);
        float shear = std::pow(y / kWindShearY0, kWindShearAlpha);
        float windMag = (atmo->wind_speed * shear) / (deck_scale[idx] * 0.5f);
        float windDir = atmo->wind_direction_radians;
        float windU = std::cos(windDir) * windMag;
        float windV = std::sin(windDir) * windMag;

        // Per-deck coverage split: low deck carries bulk (stratus), cirrus last
        float cover = std::clamp(atmo->cloud_coverage, 0.0f, 1.0f);
        float deckCov[3] = {
            std::clamp(cover * 1.05f, 0.0f, 1.0f),        // low
            std::clamp(cover, 0.0f, 1.0f),                // mid
            std::clamp((cover - 0.2f) * 1.15f, 0.0f, 1.0f) // high
        };
        float cov = deckCov[idx];

        // Dense coverage → lower density threshold so clouds connect
        float thresh = 0.5f + (1.0f - cov) * 0.4f;
        thresh = std::clamp(thresh, 0.20f, 0.85f);

        // Deterministic per-deck noise seeds keep the field stable across regens
        SCR::Noise::GradientNoise3D baseNoise(10791u + idx * 7919u);
        SCR::Noise::CellularNoise2D cellNoise(65537u + idx * 104729u);
        SCR::Noise::DomainWarp warp(3u + idx * 7u);

        AZStd::vector<uint8_t> data((size_t)res * res * 4);
        int cell = std::max(deck_cell[idx], 1);
        int oct = deck_octaves[idx];

        for (int pz = 0; pz < res; ++pz) {
            for (int px = 0; px < res; ++px) {
                // World-space sample point across the deck plane
                float nx = ((float)px / res - 0.5f) + windU * cloudFieldTime;
                float nz = ((float)pz / res - 0.5f) + windV * cloudFieldTime;

                auto [wx, wz] = warp.warp(nx * (float)cell, nz * (float)cell, 1.2f, 0.9f, 2);

                float fbm = baseNoise.fbm(wx, 0.0f, wz, oct, 2.0f, 0.5f);   // [-1,1]
                float cells = cellNoise.crack(nx * (float)cell, nz * (float)cell); // [0,~0.5]

                // Compose field signal ∈ roughly [-1, 1]
                float signal = fbm * 0.85f + (cells - 0.25f) * 0.6f;

                // Coverage threshold shaping → cloud mask [0,1]
                float t = (signal * 0.5f + 0.5f);
                float density = smoothstep01(thresh - 0.12f, thresh + 0.12f, t);

                // Cloud density multiplier scales optical depth (Weather spec τ)
                density = std::clamp(density * atmo->cloud_density_multiplier, 0.0f, 1.0f);

                // Lighting-term: bright tops from fbm, cooler shading in hollows
                float lit = 0.80f + fbm * 0.20f;
                uint8_t r = (uint8_t)(255 * lit);
                uint8_t g = (uint8_t)(255 * std::clamp(lit * 0.98f, 0.0f, 1.0f));
                uint8_t b = (uint8_t)(255 * std::clamp(lit + 0.05f, 0.0f, 1.0f));
                uint8_t a = (uint8_t)(255 * density);

                size_t o = ((size_t)pz * res + px) * 4;
                data[o + 0] = r;
                data[o + 1] = g;
                data[o + 2] = b;
                data[o + 3] = a;
            }
        }

        auto* imageSys = AZ::RPI::ImageSystemInterface::Get();
        if (!imageSys) return;
        auto& pool = imageSys->GetSystemStreamingPool();
        if (!pool) return;

        AZ::RHI::Size size;
        size.m_width = res;
        size.m_height = res;
        size.m_depth = 1;

        deckFieldImages[idx] = AZ::RPI::StreamingImage::CreateFromCpuData(
            *pool,
            AZ::RHI::ImageDimension::Image2D,
            size,
            AZ::RHI::Format::R8G8B8A8_UNORM,
            data.data(),
            data.size());

        if (!deckFieldImages[idx]) return;

        // Rebind as baseColor texture (Packed alpha reads baseColorMap.a)
        AZ::Data::Instance<AZ::RPI::Image> image = deckFieldImages[idx];
        if (idx_texture[idx].IsValid()) {
            deckMats[idx]->SetPropertyValue(idx_texture[idx], AZ::RPI::MaterialPropertyValue(image));
        }
        deckMats[idx]->Compile();
    }

    static float smoothstep01(float lo, float hi, float x) {
        float t = std::clamp((x - lo) / (hi - lo), 0.0f, 1.0f);
        return t * t * (3.0f - 2.0f * t);
    }

private:
    void configureSky(AZ::RPI::Scene* scene) {
        skyFp = scene->GetFeatureProcessor<AZ::Render::SkyBoxFeatureProcessorInterface>();
        if (!skyFp) return;

        // Avoid PhysicalSky mode (see class doc). Keep the prefab skybox path.
        skyFp->Enable(true);
    }

    void createCloudDecks(AZ::RPI::Scene* scene) {
        auto& mc = MaterialCache::instance();
        if (!mc.cloud) return;

        AZStd::shared_ptr<AZ::RPI::Scene> scenePtr(scene, [](AZ::RPI::Scene*){});

        for (int i = 0; i < kDeckCount; ++i) {
            // Independent instance so each deck scrolls separately
            deckMats[i] = mc.cloud_asset.Get()
                ? AZ::RPI::Material::Create(mc.cloud_asset)
                : mc.cloud;
            if (!deckMats[i]) continue;

            idx_texture[i] = deckMats[i]->FindPropertyIndex(AZ::Name("baseColor.textureMap"));
            idx_opacity[i] = deckMats[i]->FindPropertyIndex(AZ::Name("opacity.factor"));
            if (idx_opacity[i].IsValid()) {
                deckMats[i]->SetPropertyValue(idx_opacity[i], deck_opacity[i]);
            }
            deckMats[i]->Compile();

            AZ::Transform t = AZ::Transform::CreateTranslation(
                AZ::Vector3(0.0f, 0.0f, deck_altitude[i]));

            decks[i] = submitPlane(scenePtr, deckMats[i], t,
                AZ::Vector3(deck_scale[i], deck_scale[i], 1.0f), "cloud_deck");
        }
    }
};

} // namespace SCR::Render::O3DE

#endif // SCR_O3DE_DYNAMIC_SKY_HPP