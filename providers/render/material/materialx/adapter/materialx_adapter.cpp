// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

#include "materialx_c_api.h"

#include <unordered_map>
#include <string>
#include <vector>
#include <memory>
#include <cmath>
#include <algorithm>

#if defined(__has_include)
#if __has_include(<MaterialXCore/Document.h>) && __has_include(<MaterialXCore/Node.h>)
#include <MaterialXCore/Document.h>
#include <MaterialXCore/Node.h>
#define SCR_HAS_NATIVE_MATERIALX 1
#else
#define SCR_HAS_NATIVE_MATERIALX 0
#endif
#else
#define SCR_HAS_NATIVE_MATERIALX 0
#endif

struct InternalNode {
    std::string category;
    std::string name;
    std::unordered_map<std::string, float> float_params;
    std::unordered_map<std::string, MatXColor3> color_params;
};

struct InternalDocument {
    std::unordered_map<std::string, std::shared_ptr<InternalNode>> nodes;
#if SCR_HAS_NATIVE_MATERIALX
    MaterialX::DocumentPtr native_doc;
#endif

    InternalDocument() {
#if SCR_HAS_NATIVE_MATERIALX
        native_doc = MaterialX::createDocument();
#endif
    }
};

extern "C" {

MatXDocumentHandle matx_document_create(void) {
    auto* doc = new (std::nothrow) InternalDocument();
    return static_cast<MatXDocumentHandle>(doc);
}

void matx_document_destroy(MatXDocumentHandle doc) {
    if (!doc) return;
    delete static_cast<InternalDocument*>(doc);
}

int matx_node_add(
    MatXDocumentHandle doc,
    const char* category,
    const char* name,
    MatXNodeHandle* out_node
) {
    if (!doc || !category || !name || !out_node) return MATX_ERR_NULL_POINTER;
    auto* document = static_cast<InternalDocument*>(doc);

    auto node = std::make_shared<InternalNode>();
    node->category = category;
    node->name = name;

    // Default standard surface parameters
    if (std::string(category) == "standard_surface" || std::string(category) == "open_pbr_surface") {
        node->color_params["base_color"] = { 0.8f, 0.8f, 0.8f };
        node->float_params["base"] = 1.0f;
        node->float_params["roughness"] = 0.2f;
        node->float_params["metalness"] = 0.0f;
        node->float_params["specular_ior"] = 1.5f;
        node->float_params["coat"] = 0.0f;
        node->float_params["coat_roughness"] = 0.05f;
        node->float_params["coat_ior"] = 1.5f;
    }

#if SCR_HAS_NATIVE_MATERIALX
    if (document->native_doc) {
        document->native_doc->addNode(category, name);
    }
#endif

    document->nodes[name] = node;
    *out_node = static_cast<MatXNodeHandle>(node.get());
    return MATX_SUCCESS;
}

int matx_node_set_float(
    MatXNodeHandle node,
    const char* param_name,
    float value
) {
    if (!node || !param_name) return MATX_ERR_NULL_POINTER;
    auto* n = static_cast<InternalNode*>(node);
    n->float_params[param_name] = value;
    return MATX_SUCCESS;
}

int matx_node_set_color3(
    MatXNodeHandle node,
    const char* param_name,
    float r, float g, float b
) {
    if (!node || !param_name) return MATX_ERR_NULL_POINTER;
    auto* n = static_cast<InternalNode*>(node);
    n->color_params[param_name] = { r, g, b };
    return MATX_SUCCESS;
}

float matx_fresnel_dielectric(float ior, float cos_theta) {
    if (ior < 1.0f) ior = 1.0f;
    float ct = std::clamp(cos_theta, 0.0f, 1.0f);
    float f0 = (ior - 1.0f) / (ior + 1.0f);
    f0 = f0 * f0;
    // Schlick's approximation
    return f0 + (1.0f - f0) * std::pow(1.0f - ct, 5.0f);
}

int matx_surface_evaluate_bsdf(
    MatXDocumentHandle doc,
    const char* node_name,
    float cos_theta,
    MatXColor3* out_reflectance
) {
    if (!doc || !node_name || !out_reflectance) return MATX_ERR_NULL_POINTER;
    auto* document = static_cast<InternalDocument*>(doc);

    auto it = document->nodes.find(node_name);
    if (it == document->nodes.end()) return MATX_ERR_NODE_NOT_FOUND;
    auto& node = it->second;

    float base_weight = node->float_params.count("base") ? node->float_params["base"] : 1.0f;
    MatXColor3 base_color = node->color_params.count("base_color") ? node->color_params["base_color"] : MatXColor3{0.8f, 0.8f, 0.8f};
    float metalness = node->float_params.count("metalness") ? node->float_params["metalness"] : 0.0f;
    float spec_ior = node->float_params.count("specular_ior") ? node->float_params["specular_ior"] : 1.5f;
    float coat = node->float_params.count("coat") ? node->float_params["coat"] : 0.0f;
    float coat_ior = node->float_params.count("coat_ior") ? node->float_params["coat_ior"] : 1.5f;

    float f_dielectric = matx_fresnel_dielectric(spec_ior, cos_theta);
    float f_coat = coat * matx_fresnel_dielectric(coat_ior, cos_theta);

    // Diffuse component (Lambertian with albedo conservation)
    float diff_r = (1.0f - metalness) * base_weight * base_color.r * (1.0f - f_dielectric);
    float diff_g = (1.0f - metalness) * base_weight * base_color.g * (1.0f - f_dielectric);
    float diff_b = (1.0f - metalness) * base_weight * base_color.b * (1.0f - f_dielectric);

    // Specular / Conductor component
    float spec_r = metalness * base_color.r + (1.0f - metalness) * f_dielectric;
    float spec_g = metalness * base_color.g + (1.0f - metalness) * f_dielectric;
    float spec_b = metalness * base_color.b + (1.0f - metalness) * f_dielectric;

    // Substrate total
    float sub_r = diff_r + spec_r;
    float sub_g = diff_g + spec_g;
    float sub_b = diff_b + spec_b;

    // Layer coat over substrate enforcing energy conservation: R_total = F_coat + (1 - F_coat) * R_sub
    out_reflectance->r = std::clamp(f_coat + (1.0f - f_coat) * sub_r, 0.0f, 1.0f);
    out_reflectance->g = std::clamp(f_coat + (1.0f - f_coat) * sub_g, 0.0f, 1.0f);
    out_reflectance->b = std::clamp(f_coat + (1.0f - f_coat) * sub_b, 0.0f, 1.0f);

    return MATX_SUCCESS;
}

} // extern "C"
