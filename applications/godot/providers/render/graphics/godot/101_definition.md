# 101 — Definition: Godot Render Provider

**ID:** `SCR-PROVIDER-RENDER-GODOT`
**Status:** Normative definition (implementation follows [104_contract.md](104_contract.md))
**Parent:** `SCR-LIB-RENDER` (`lib/A01_Render/101_definition.md`)

## 1. Meaning

The **Godot render provider** realizes SCR renderable semantic state as a Godot-engine presentation. It is a *provider*: it implements a contract; it does not own or define scene semantics.

## 2. Concept

```text
Renderable semantic state (Mojo sim, projected to RenderSnapshot)
        │ contract: 104_contract.md (byte schema v5, C ABI v1)
        ▼
Godot render provider adapter (GDExtension, godot-cpp)
        │ representation conversion only
        ▼
Godot scene graph / shaders / lights  (manifestation)
```

## 3. Invariants

1. Provider ≠ Semantic Authority (`AGENTS.md` not-equals; `applications/godot/docs/05_provider_boundary.md`).
2. The snapshot byte contract is the **only** state channel downlink; `scr_input_batch` the only uplink.
3. Adapter performs representation conversion, error translation, and provenance recording — never gameplay/semantic decisions (`lib/804_Application` Port→Adapter→Provider).
4. Replacing Godot with another engine must not change any semantic definition (provider independence).

## 4. Capabilities

| Capability | Status |
|---|---|
| `RenderSnapshotDecode` (byte schema v5; v1→v2→v3→v4→v5) | Implemented — milestones 0002–0006 |
| `TerrainMeshManifestation` (chunked ArrayMesh) | Implemented — milestone 0002 |
| `OceanSurfaceManifestation` (Gerstner shader) | Implemented — milestone 0002 |
| `SkyManifestation` (time-of-day sun, derived dome gradient, atmosphere-derived fog) | Implemented — milestones 0002, 0004 |
| `CloudDeckManifestation` (cloud_cover → `scr_clouds`) | Implemented — milestone 0004 |
| `PrecipitationManifestation` (precipitation → `scr_rain`, wetness tint) | Implemented — milestone 0004 |
| `ShoreFoamManifestation` (SHORE_FOAM field → `foam_shore` texture on `scr_ocean`) | Implemented — milestone 0005 |
| `TerrainMaterialBlend` (per-vertex dominant/blend/weight tuples → blended vertex albedo) | Implemented — milestone 0005 |
| `FloraManifestation` (10 FLORA → `scr_flora` MultiMeshInstance3D, species colors from catalog) | Implemented — milestone 0006 |
| `FlockManifestation` (11 FAUNA → `scr_fauna` pooled MeshInstance3D birds, flap display) | Implemented — milestone 0006 |
| `PlayerCameraManifestation` | Implemented — milestone 0002 |
| `InputUplink` (scr_input_batch) | Implemented — milestone 0002 |

## 5. Relationships

| Relation | Target |
|---|---|
| `realizes` | `SCR-LIB-RENDER` |
| `consumes` | `SCR-APP-GODOT-0001` snapshot contract (104_contract.md) |
| `implements` | `SCR-LIB-MATH-GERSTNER` manifestation (display only) |
| `consumes` | `SCR-LIB-MATH-ATMOSPHERE` (solar arc, fog derivation — sim bytes authoritative) |
| `consumes` | `SCR-LIB-RENDER-SKY` (cloud deck manifestation) |
| `consumes` | `SCR-LIB-SIMULATION-WEATHER` (precipitation/wind manifestation — sim state authoritative) |
| `consumes` | `SCR-LIB-RENDER-WATER` (shore-foam field manifestation — sim computes the field, shader only shades it, AP-19) |
| `subordinate-to` | SCR semantic library, Mojo simulation core |

Derived relationships recorded in [103_provider.graph.json](103_provider.graph.json).
