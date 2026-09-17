# MaterialX Provider Contract

**Provider:** materialx  
**Domain:** render  
**Subdomain:** material  
**Version:** 0.1.0  
**Status:** Normative Contract  
**Governing Documents:** [`docs/architecture/103_provider_contracts.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/docs/architecture/103_provider_contracts.md), [`lib/A01_Render/Material/101_definition.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/lib/A01_Render/Material/101_definition.md)

---

## 1. Contract Overview

This document specifies the concrete Provider Contract implemented by the `materialx` provider for the `render/material` capability domain. It defines document lifecycle, node graph querying, standard physical surface evaluation, and BSDF closure composition.

---

## 2. Semantic Capabilities

* `[render, material, materialx, document_lifecycle]` — Creation, parsing, and destruction of MaterialX documents.
* `[render, material, materialx, nodegraph_traversal]` — Node graph declaration, parameter setting, and topological traversal.
* `[render, material, materialx, standard_surface_bsdf]` — Evaluation of physically based surface scattering (base color, roughness, metalness, specular transmission).
* `[render, material, materialx, closure_composition]` — Evaluation and composition of BSDF/EDF closures.
* `[render, material, materialx, fresnel_layering]` — Dielectric clearcoat vertical layering with Fresnel transmission conservation.

---

## 3. Operations & Signatures

* `matx_document_create() -> MatXDocumentHandle`
* `matx_document_destroy(doc) -> void`
* `matx_node_add(doc, category, name, out_node) -> int`
* `matx_node_set_float(node, param_name, value) -> int`
* `matx_node_set_color3(node, param_name, r, g, b) -> int`
* `matx_surface_evaluate_bsdf(doc, node_name, cos_theta, out_reflectance) -> int`
* `matx_fresnel_dielectric(ior, cos_theta) -> float`

---

## 4. Preconditions & Postconditions

1. **Precondition (Handle Validity):** All operations require non-null handles. Passing null returns `MATX_ERR_NULL_POINTER`.
2. **Precondition (Index of Refraction):** Physical IOR must be $\ge 1.0$.
3. **Postcondition (Energy Conservation):** Evaluated reflectance must satisfy $R(\theta) \in [0.0, 1.0]$.
4. **Postcondition (Fresnel Monotonicity):** Dielectric Fresnel reflectance strictly increases from normal incidence ($\theta = 0^\circ$) to grazing incidence ($\theta = 90^\circ$).

---

## 5. Failure Semantics & Error Codes

* `MATX_SUCCESS = 0`
* `MATX_ERR_NULL_POINTER = -1`
* `MATX_ERR_NODE_NOT_FOUND = -2`
* `MATX_ERR_INVALID_PARAM = -3`
* `MATX_ERR_OUT_OF_MEMORY = -4`

---

## 6. Conformance Test Suite

The provider is validated against the conformance suite in `tests/test_materialx_contract.cpp`.
