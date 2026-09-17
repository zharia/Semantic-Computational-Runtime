# Sprint 01: Optical Contract Semantic Mapping

## 1. Objectives
Map SCR normative optical contracts (albedo, roughness, metallic, refractive index, transmission, subsurface scattering, emission) into standard surface / OpenPBR material parameters.

## 2. Invariants
- Conductors ($m = 1.0$): `metalness` = 1.0, preserving complex/real conductor IOR.
- Dielectrics ($m = 0.0$): `metalness` = 0.0, requiring $n \ge 1.0$.
- Optical transmission: bounded $[0.0, 1.0]$.
- Subsurface scattering: bounded $[0.0, 1.0]$.
- Emission: non-negative RGB vector.
