# MaterialX Provider

**Provider ID:** `materialx`  
**Domain:** `render`  
**Subdomain:** `material`  
**Status:** Operational  
**Parent Specification:** [`lib/A01_Render/Material`](file:///home/kobus/Projects/Semantic-Computational-Runtime/lib/A01_Render/Material)

---

## 1. Purpose

This directory defines the SCR integration of the **AcademySoftwareFoundation MaterialX** standard and runtime library as a concrete Provider for the `render/material` capability domain.

## 2. Provider Role

The MaterialX Provider supplies:
1. Serialization and deserialization of MaterialX XML (`.mtlx`) documents.
2. In-memory dataflow node graph traversal and parameter introspection.
3. Shading closure synthesis (BSDF, EDF, VDF) for physically based materials (OpenPBR, Autodesk Standard Surface, USD Preview Surface).
4. Shader generation target compilation bridging to OSL, GLSL, and Vulkan/SPIR-V.

## 3. Provider Semantic Isolation (Rule 6 & Rule 18)

* The MaterialX Provider is an implementation mechanism; it is **not** the semantic authority of SCR materials.
* The normative definition of materials, closures, and shading graphs resides in [`lib/A01_Render/Material`](file:///home/kobus/Projects/Semantic-Computational-Runtime/lib/A01_Render/Material).
* MaterialX-specific types and syntax are converted to SCR semantic hypergraph elements at the adapter boundary.

## 4. Contract Governance

The MaterialX Provider implements and conforms to the Normative Provider Contract defined in:

`providers/render/material/materialx/104_contract.md`
