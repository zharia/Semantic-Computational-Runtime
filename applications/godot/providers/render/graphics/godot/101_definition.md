# 101 — Definition: Godot Render Provider

**ID:** `SCR-PROVIDER-RENDER-GODOT`
**Status:** Normative definition (implementation follows [104_contract.md](104_contract.md))
**Parent:** `SCR-LIB-RENDER` (`lib/A01_Render/101_definition.md`)

## 1. Meaning

The **Godot render provider** realizes SCR renderable semantic state as a Godot-engine presentation. It is a *provider*: it implements a contract; it does not own or define scene semantics.

## 2. Concept

```text
Renderable semantic state (Mojo sim, projected to RenderSnapshot)
        │ contract: 104_contract.md (byte schema v6, C ABI v2)
        ▼
Godot render provider adapter (GDExtension, godot-cpp)
        │ representation conversion only
        ▼
Godot scene graph / shaders / lights  (manifestation)
```

## 3. Invariants

1. Provider ≠ Semantic Authority (`AGENTS.md` not-equals; `applications/godot/docs/05_provider_boundary.md`).
2. The snapshot byte contract is the **only** state channel downlink; `scr_input_batch` (motion intent) and `scr_edit_batch`/`scr_edit_submit` (edit intent — op + hotbar slot only, never cells or materials) are the only uplinks.
3. Adapter performs representation conversion, error translation, and provenance recording — never gameplay/semantic decisions (`lib/804_Application` Port→Adapter→Provider).
4. Replacing Godot with another engine must not change any semantic definition (provider independence).

## 4. Capabilities

| Capability | Status |
|---|---|
| `RenderSnapshotDecode` (byte schema v6; v1→v2→v3→v4→v5→v6) | Implemented — milestones 0002–0007 |
| `TerrainMeshManifestation` (chunked ArrayMesh; chunk-local rebuild on edit) | Implemented — milestones 0002, 0007 |
| `OceanSurfaceManifestation` (Gerstner shader) | Implemented — milestone 0002 |
| `SkyManifestation` (time-of-day sun, derived dome gradient, atmosphere-derived fog) | Implemented — milestones 0002, 0004 |
| `CloudDeckManifestation` (cloud_cover → `scr_clouds`) | Implemented — milestone 0004 |
| `PrecipitationManifestation` (precipitation → `scr_rain`, wetness tint) | Implemented — milestone 0004 |
| `ShoreFoamManifestation` (SHORE_FOAM field → `foam_shore` texture on `scr_ocean`) | Implemented — milestone 0005 |
| `TerrainMaterialBlend` (per-vertex dominant/blend/weight tuples → blended vertex albedo) | Implemented — milestone 0005 |
| `FloraManifestation` (10 FLORA → `scr_flora` MultiMeshInstance3D, species colors from catalog) | Implemented — milestone 0006 |
| `FlockManifestation` (11 FAUNA → `scr_fauna` pooled MeshInstance3D birds, flap display) | Implemented — milestone 0006 |
| `EditUplink` (scr_edit_batch → scr_edit_submit; dig/place/select intent) | Implemented — milestone 0007 |
| `HotbarManifestation` (12 HOTBAR → `scr_hotbar` 9-slot HUD, catalog names/colors from the mirror) | Implemented — milestone 0007 |
| `TargetManifestation` (13 TARGET → `scr_target` readout; miss ⇒ "SKY / AIR") | Implemented — milestone 0007 |
| `RigidPropManifestation` (14 RIGID_BODIES → `scr_props` pooled ≤ 16 meshes) | Implemented — milestone 0007 |
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
| `consumes` | `SCR-LIB-PHYSICS` (rigid props manifestation + edit physics — sim authoritative, 0007) |
| `consumes` | `SCR-LIB-RENDER-MATERIAL` (hotbar/placed material vocabulary from the catalog — sim-side list authoritative, 0007 AP-13) |
| `consumes` | `SCR-LIB-RENDER-HUD` (hotbar/target readout projections — display-only, 0007 invariant 10) |
| `subordinate-to` | SCR semantic library, Mojo simulation core |

Derived relationships recorded in [103_provider.graph.json](103_provider.graph.json).
