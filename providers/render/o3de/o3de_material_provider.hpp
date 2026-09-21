#ifndef SCR_O3DE_MATERIAL_PROVIDER_HPP
#define SCR_O3DE_MATERIAL_PROVIDER_HPP

#include "simulation/semantic_materials.hpp"
#include <AzCore/Math/Color.h>

namespace SCR::Render::O3DE {

struct O3deMaterialParams {
    AZ::Color albedo = AZ::Color(0.5f, 0.5f, 0.5f, 1.0f);
    AZ::Color emission = AZ::Color::CreateZero();
    float roughness = 0.5f;
    float metallic = 0.0f;
    float emission_intensity = 0.0f;
    bool is_transparent = false;
};

class O3deMaterialProvider {
public:
    static O3deMaterialParams fromContract(const SCR::Material::MaterialContract& mat) {
        O3deMaterialParams p;
        p.albedo = AZ::Color(mat.albedo.r, mat.albedo.g, mat.albedo.b, 1.0f);
        p.emission = AZ::Color(mat.emission.r, mat.emission.g, mat.emission.b, 1.0f);
        p.roughness = mat.roughness;
        p.metallic = mat.metallic;
        p.is_transparent = mat.is_transparent;
        p.emission_intensity = (mat.emission.r + mat.emission.g + mat.emission.b) / 3.0f;
        return p;
    }

    static AZ::Color getAlbedo(const SCR::Material::MaterialContract& mat) {
        return AZ::Color(mat.albedo.r, mat.albedo.g, mat.albedo.b, 1.0f);
    }

    static AZ::Color getEmission(const SCR::Material::MaterialContract& mat, float intensity_scale = 3.0f) {
        float avg = (mat.emission.r + mat.emission.g + mat.emission.b) / 3.0f;
        if (avg < 0.01f) return AZ::Color::CreateZero();
        return AZ::Color(mat.emission.r * intensity_scale,
                         mat.emission.g * intensity_scale,
                         mat.emission.b * intensity_scale, 1.0f);
    }
};

} // namespace SCR::Render::O3DE

#endif // SCR_O3DE_MATERIAL_PROVIDER_HPP
