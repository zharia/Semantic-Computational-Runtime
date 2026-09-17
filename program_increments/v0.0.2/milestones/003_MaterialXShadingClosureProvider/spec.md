# Milestone 003 Specification: MaterialX Shading Closure Provider

## 1. Scope & Objective
Bridge SCR normative optical contracts (albedo, roughness, metallic, refractive index, transmission, subsurface scattering, emission) into standard MaterialX shading networks.

## 2. Optical Contract Mapping Rules
1. **Conductors ($m = 1.0$)**:
   - `metalness` = 1.0
   - `base_color` = material albedo
   - `specular_roughness` = material roughness
   - `specular_IOR` = conductor real refractive index (e.g., Gold 0.18, Copper 0.27, Silver 0.14)
2. **Dielectrics ($m = 0.0$)**:
   - `metalness` = 0.0
   - `base_color` = material albedo
   - `specular_roughness` = material roughness
   - `specular_IOR` = dielectric refractive index ($n \ge 1.0$)
3. **Transmissive & Fluids**:
   - `transmission` = optical transmission scalar $[0.0, 1.0]$
   - `transmission_color` = transmission tint
   - `transmission_scatter` = scattering coefficient
4. **Emissive & Volatiles**:
   - `emission_color` = emission luminance vector $[r, g, b]$

## 3. Normative Interface
- `MaterialXGenerator(catalog_path: str)`
- `generate_mtlx_document() -> str`
- `export_mtlx_file(output_path: str) -> None`
