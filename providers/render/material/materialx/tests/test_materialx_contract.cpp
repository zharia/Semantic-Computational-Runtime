// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

#include "../adapter/materialx_c_api.h"

#include <iostream>
#include <cassert>
#include <cmath>

static void test_materialx_document_lifecycle() {
    std::cout << "[Test 1] MaterialX Document & Node Graph Setup... ";
    MatXDocumentHandle doc = matx_document_create();
    assert(doc != nullptr);

    MatXNodeHandle node = nullptr;
    int rc = matx_node_add(doc, "standard_surface", "SR_CarPaint", &node);
    assert(rc == MATX_SUCCESS);
    assert(node != nullptr);

    rc = matx_node_set_color3(node, "base_color", 0.9f, 0.1f, 0.1f); // Red
    assert(rc == MATX_SUCCESS);

    rc = matx_node_set_float(node, "roughness", 0.15f);
    assert(rc == MATX_SUCCESS);

    rc = matx_node_set_float(node, "coat", 1.0f); // Clearcoat
    assert(rc == MATX_SUCCESS);

    matx_document_destroy(doc);
    std::cout << "PASSED\n";
}

static void test_materialx_bsdf_and_fresnel() {
    std::cout << "[Test 2] MaterialX BSDF Evaluation & Fresnel Layering... ";
    MatXDocumentHandle doc = matx_document_create();
    assert(doc != nullptr);

    MatXNodeHandle node = nullptr;
    int rc = matx_node_add(doc, "standard_surface", "SR_Glass", &node);
    assert(rc == MATX_SUCCESS);

    // Pure dielectric: IOR = 1.5, base_color = white, coat = 0
    matx_node_set_float(node, "base", 1.0f);
    matx_node_set_color3(node, "base_color", 1.0f, 1.0f, 1.0f);
    matx_node_set_float(node, "metalness", 0.0f);
    matx_node_set_float(node, "specular_ior", 1.5f);
    matx_node_set_float(node, "coat", 0.0f);

    // At normal incidence: cos_theta = 1.0
    // F0 = ((1.5 - 1)/(1.5 + 1))^2 = (0.5/2.5)^2 = 0.2^2 = 0.04 (4% reflection)
    float f_normal = matx_fresnel_dielectric(1.5f, 1.0f);
    assert(std::abs(f_normal - 0.04f) < 1e-4f);

    // At grazing incidence: cos_theta = 0.0 -> F = 1.0 (100% reflection)
    float f_grazing = matx_fresnel_dielectric(1.5f, 0.0f);
    assert(std::abs(f_grazing - 1.0f) < 1e-4f);

    MatXColor3 refl_normal = { 0, 0, 0 };
    rc = matx_surface_evaluate_bsdf(doc, "SR_Glass", 1.0f, &refl_normal);
    assert(rc == MATX_SUCCESS);
    assert(refl_normal.r > 0.0f && refl_normal.r <= 1.0f);

    MatXColor3 refl_grazing = { 0, 0, 0 };
    rc = matx_surface_evaluate_bsdf(doc, "SR_Glass", 0.0f, &refl_grazing);
    assert(rc == MATX_SUCCESS);
    // Grazing reflection is higher than normal reflection (Fresnel law)
    assert(refl_grazing.r >= refl_normal.r);

    matx_document_destroy(doc);
    std::cout << "PASSED (F_normal: " << f_normal << ", F_grazing: " << f_grazing << ")\n";
}

static void test_materialx_error_handling() {
    std::cout << "[Test 3] MaterialX Precondition and Error Handling... ";
    MatXNodeHandle node = nullptr;
    int rc = matx_node_add(nullptr, "standard_surface", "test", &node);
    assert(rc == MATX_ERR_NULL_POINTER);

    MatXDocumentHandle doc = matx_document_create();
    MatXColor3 refl;
    rc = matx_surface_evaluate_bsdf(doc, "nonexistent_shader", 1.0f, &refl);
    assert(rc == MATX_ERR_NODE_NOT_FOUND);

    matx_document_destroy(doc);
    std::cout << "PASSED\n";
}

int main() {
    std::cout << "==========================================\n";
    std::cout << " Running MaterialX Provider Contract Tests\n";
    std::cout << "==========================================\n";
    test_materialx_document_lifecycle();
    test_materialx_bsdf_and_fresnel();
    test_materialx_error_handling();
    std::cout << "\nAll MaterialX Contract Tests PASSED successfully.\n\n";
    return 0;
}
