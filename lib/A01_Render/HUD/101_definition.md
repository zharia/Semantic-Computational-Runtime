---

document: 101_definition
document_type: normative_semantic_definition
schema_version: 1.0.0

id: SCR-LIB-RENDER-HUD
name: Head-Up Display — Immediate-Mode Spatial Information Overlay

version: 0.1.0
status: operational

created: 2026-09-16
updated: 2026-09-16

parent: SCR-LIB-RENDER
authority: SCR
domain: semantic-library
---

# SCR Render: Head-Up Display (HUD)

## Summary

A HUD is a semantically-bound, read-only information projection layer rendered
in screen-space over the primary 3D viewport. It exposes derived spatial state
(player position, material identity, biome context) without altering the
underlying semantic world state.

---

## 1. Semantic Definition

A **HUD** is a pure *projection* of semantic state onto screen-space. It is:

- **Read-only**: HUD elements display state; they do not modify it.
- **Derived**: every value displayed must be computable from the current world
  semantic state without additional persistent state.
- **Referentially transparent**: the same world state always produces the same
  HUD output.
- **Non-authoritative**: the HUD representation never defines semantic meaning —
  it reflects it. A material's name and properties originate from the
  `MaterialRegistry`, not from the HUD.

A HUD is **NOT**:
- a menu or interactive editor (no world-state mutation)
- a data store (all displayed values are derived on demand)
- a replacement for the semantic model (the label "Basalt — 2900 kg/m³" is
  a projection of `MaterialEntry`, not the definition of basalt)

---

## 2. HUD Components

### 2.1 Spatial MiniMap

Projects the 2D top-down occupancy of the environment onto a fixed screen-space
panel. The minimap is a **lossy spatial summary** — it does not preserve full
3D structure.

**Semantic inputs:**
- `WFC::BiomeTile[x,z]` — biome colour coding
- `FPSController::position` — player world coordinates (projected to map space)
- `FPSController::yaw` — player facing direction (direction indicator)

**Semantic contract:**
- Map north (+Z world) aligns with map top
- Player dot position is computed from world coordinates, not from rendered pixels
- Colour coding reflects the normative biome vocabulary (from SCR-LIB-TOPOLOGY-WFC)

### 2.2 Material Inspector

Displays the identity and physical properties of the voxel the player is
currently targeting (raycasting forward from the eye position).

**Semantic inputs:**
- `RayHit::material_code` — the material under the crosshair
- `MaterialRegistry::get(material_code)` — the authoritative material entry

**Displayed fields (normative):**
| Field | Source |
|---|---|
| Material name | `MaterialEntry::name` |
| Semantic domain | `MaterialEntry::semantic_domain` |
| Category | `MaterialEntry::category` |
| Density | `MaterialEntry::density` (kg/m³) |
| Tensile strength | `MaterialEntry::tensile_strength` (MPa) |
| Young's modulus | `MaterialEntry::young_modulus` (GPa) |
| Thermal conductivity | `MaterialEntry::thermal_conductivity` (W/m·K) |
| Melting point | `MaterialEntry::melting_point` (°C) |
| Phase | `is_solid / is_fluid / is_gas / is_organic` |
| Albedo colour swatch | `MaterialEntry::albedo` |

**Semantic contract:**
- Values shown are drawn verbatim from `MaterialRegistry` — no rounding or
  approximation is introduced by the HUD layer.
- If no surface is targeted (`RayHit::hit == false`), the panel shows "SKY / AIR".

---

## 3. Implementation Provider

The normative GUI provider for this SCR runtime environment is
**Dear ImGui** (immediate-mode GUI) integrated via `Ogre::ImGuiOverlay`
(component: `OGRE-Overlay`).

This is the **subordinate provider** (Rule 18 — external technologies remain
subordinate to SCR contracts). The semantic contracts in §2 hold regardless of
which GUI framework renders them.

The provider MUST:
- Render each HUD component in a separate, titled, non-modal window
- Apply a consistent visual theme (volcanic dark theme — see §4)
- Not expose interactive controls that mutate semantic world state
- Update every rendered frame

---

## 4. Visual Theme Contract (Normative)

The volcanic dark theme is the normative visual identity for this application's
HUD. It uses:

| Token | Value | Usage |
|---|---|---|
| `bg_dark` | RGBA(12, 12, 20, 224) | Window backgrounds |
| `accent_lava` | RGBA(220, 80, 20, 180) | Borders, active headers |
| `accent_hot` | RGBA(255, 160, 50, 255) | Hot values (lava, temperature) |
| `text_primary` | RGBA(230, 220, 200, 255) | Main text |
| `text_muted` | RGBA(140, 130, 110, 200) | Property labels |
| `biome_ocean` | RGBA(18, 52, 100, 255) | Minimap deep ocean |
| `biome_jungle` | RGBA(28, 98, 28, 255) | Minimap dense rainforest |
| `biome_caldera` | RGBA(255, 80, 10, 255) | Minimap caldera lake |

Window rounding: 8px. Frame rounding: 4px. Scroll rounding: 4px.

---

## 5. Relationships

| Relation | Target | Kind |
|---|---|---|
| depends-on | SCR-LIB-RENDER-MATERIAL | material registry queries |
| depends-on | SCR-LIB-TOPOLOGY-WFC | biome map for minimap |
| depends-on | SCR-LIB-SPATIAL | player position / raycast |
| provider | Dear ImGui via OGRE-Overlay | rendering substrate |
| consumed-by | SCR-APP-CAVE-ISLAND | volcanic island explorer |
