// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

#ifndef SCR_MATERIALX_C_API_H
#define SCR_MATERIALX_C_API_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#define MATX_SUCCESS 0
#define MATX_ERR_NULL_POINTER -1
#define MATX_ERR_NODE_NOT_FOUND -2
#define MATX_ERR_INVALID_PARAM -3
#define MATX_ERR_OUT_OF_MEMORY -4

typedef void* MatXDocumentHandle;
typedef void* MatXNodeHandle;

typedef struct {
    float r;
    float g;
    float b;
} MatXColor3;

/**
 * Creates an empty MaterialX document.
 */
MatXDocumentHandle matx_document_create(void);

/**
 * Destroys a MaterialX document and all child elements.
 */
void matx_document_destroy(MatXDocumentHandle doc);

/**
 * Adds a node (e.g. "standard_surface", "open_pbr_surface", "image") to the document.
 */
int matx_node_add(
    MatXDocumentHandle doc,
    const char* category,
    const char* name,
    MatXNodeHandle* out_node
);

/**
 * Sets a float parameter on a node.
 */
int matx_node_set_float(
    MatXNodeHandle node,
    const char* param_name,
    float value
);

/**
 * Sets a color3 parameter on a node.
 */
int matx_node_set_color3(
    MatXNodeHandle node,
    const char* param_name,
    float r, float g, float b
);

/**
 * Calculates dielectric Fresnel reflectance using Schlick's approximation.
 * @param ior Index of refraction (>= 1.0)
 * @param cos_theta Cosine of incident angle [0.0, 1.0]
 */
float matx_fresnel_dielectric(float ior, float cos_theta);

/**
 * Evaluates the total directional-hemispherical reflectance of a standard surface shader
 * for an incident direction cosine.
 */
int matx_surface_evaluate_bsdf(
    MatXDocumentHandle doc,
    const char* node_name,
    float cos_theta,
    MatXColor3* out_reflectance
);

#ifdef __cplusplus
}
#endif

#endif // SCR_MATERIALX_C_API_H
