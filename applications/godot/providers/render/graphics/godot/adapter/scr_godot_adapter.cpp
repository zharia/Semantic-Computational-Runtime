/* scr_godot_adapter.cpp — GDExtension adapter of the SCR Godot render
 * provider (providers/render/graphics/godot).
 *
 * Normative sources:
 *   - providers/render/graphics/godot/104_contract.md  (byte schema 3, C ABI)
 *   - providers/render/graphics/godot/101_definition.md (invariants)
 *   - applications/godot/program_increments/v0.0.1/
 *       milestone_0002_scene-initiation/spec.md §2 (AP-1..AP-10)
 *   - applications/godot/program_increments/v0.0.1/
 *       milestone_0003_volcano/spec.md §2.1 (AP-11..AP-14), §3.4 (groups)
 *   - applications/godot/program_increments/v0.0.1/
 *       milestone_0004_atmosphere-weather/spec.md §2.1 (AP-15..AP-18),
 *       §3.2 (SKY 64 B), §3.4 (scene binding table)
 *   - applications/godot/program_increments/v0.0.1/
 *       milestone_0005_shoreline-fidelity/spec.md §1.1 (decisions (a)/(b)),
 *       §2.1 (AP-19..AP-22), §3.2/§3.5 (schema 4, SHORE_FOAM, blend tuples)
 *   - applications/godot/program_increments/v0.0.1/
 *       milestone_0006_ecology/spec.md §1.1 (schema 5, FLORA/FAUNA),
 *       §2.1 (0006 AP-11..AP-14), §5 (scene scripts own node construction),
 *       §3.4 (groups)
 *   - applications/godot/docs/05_provider_boundary.md
 *
 * SCOPE: representation conversion ONLY. Decode snapshot bytes -> Godot nodes;
 * capture raw input intent -> scr_input_batch. No semantic/gameplay decisions,
 * no world mutation, no file/network I/O in _physics_process (AP-8/AP-9).
 * Contract errors are reported loudly (ERR_PRINT) and the frame is skipped —
 * never coerced (104_contract §8).
 *
 * ---------------------------------------------------------------------------
 * Sim library resolution (AP-4: zero hardcoded absolute paths)
 * ---------------------------------------------------------------------------
 *   1. ProjectSettings::globalize_path("res://../build/libscr_sim.so")
 *      (res:// = <repo>/applications/godot/godot/, so ../build/ = the dev
 *      build output applications/godot/build/libscr_sim.so)
 *   2. if that file does not exist: environment variable SCR_SIM_LIB
 *      (explicit override for tests/CI)
 *   3. otherwise: refuse loudly (ERR_PRINT) and stay inert.
 * dlopen happens once in _ready(); _exit_tree() shuts down + dlcloses.
 *
 * ---------------------------------------------------------------------------
 * Scene interface (contract for the Sprint-04 scene; discovery by GROUP)
 * ---------------------------------------------------------------------------
 *   "scr_terrain"  Node3D            one  -> children Chunk_i (MeshInstance3D)
 *   "scr_meta"     any Node          one  -> meta: sea_level, peak_height,
 *                                            spawn_position (Vector3)
 *   "scr_ocean"    MeshInstance3D    one  -> ShaderMaterial params:
 *                                            sea_level, amplitude, frequency,
 *                                            steepness, dir_x, dir_z, speed,
 *                                            phase
 *   "scr_sun"      DirectionalLight3D one -> rotation/energy/color from
 *                                            SKY (elevation, azimuth,
 *                                            sun_intensity, sun_color_*)
 *   "scr_env"      WorldEnvironment  one  -> ProceduralSkyMaterial dome
 *                                            gradient (derived, contract
 *                                            §4.3 note) + energy; fog
 *                                            enabled/density/light color
 *                                            from the derived SKY values
 *   "scr_clouds"   MeshInstance3D    one  -> ShaderMaterial uniform
 *                                            cloud_cover (0..1)
 *   "scr_rain"     GPUParticles3D    one  -> emitting = precipitation > 0,
 *                                            amount_ratio = precipitation,
 *                                            wetness darkens the cached
 *                                            terrain albedos
 *   "scr_camera"   Camera3D | Node3D one  -> player camera rig
 *   "scr_hud"      Label             one  -> "tick %d | gen %d | seed %d"
 *   "scr_materials" Node            one  -> meta "materials":
 *                                            Dictionary id -> {albedo,
 *                                            roughness, emissive, opacity}
 *   "scr_crater_lava" MeshInstance3D one  -> ShaderMaterial lava.gdshader
 *                                            params emissive_intensity,
 *                                            crust_fraction, radius; node
 *                                            transform = §7 geometry
 *                                            (position (center_x, lake_level,
 *                                            center_z), scale (radius,1,
 *                                            radius) over a unit disc)
 *   "scr_plume"    GPUParticles3D    one  -> position = PLUME.origin,
 *                                            emitting = rate > 0,
 *                                            amount = round(rate·lifetime)
 *                                            (Godot emits `amount` per
 *                                            `lifetime` ⇒ amount/lifetime
 *                                            == contract rate), lifetime,
 *                                            process material: spread,
 *                                            initial velocity (min = max = w0),
 *                                            turbulence enabled + influence
 *   "scr_crater_glow" OmniLight3D    one  -> position (center_x, lake_level +
 *                                            GLOW display lift, center_z),
 *                                            light_energy = glow_intensity
 *                                            (sim-computed; adapter must NOT
 *                                            re-derive "night", AP-11)
 *   "scr_flora"    Node3D            one  -> method apply_flora(bytes,
 *                                            materials) rebuilds one
 *                                            MultiMeshInstance3D per species
 *                                            from the validated §10 FLORA
 *                                            records (called ONLY when the
 *                                            emission-gated section is
 *                                            present — invariant 5 keeps the
 *                                            cached instances otherwise);
 *                                            method set_wetness_gain(k) when
 *                                            the wet-surface gain changes.
 *                                            materials: Dictionary species ->
 *                                            {albedo: Color, roughness: float}
 *   "scr_fauna"    Node3D            one  -> method apply_fauna(bytes) —
 *                                            repositions the bird pool from
 *                                            the validated §11 FAUNA records
 *                                            (every snapshot)
 * Missing groups are tolerated (presentation simply absent); present-but-
 * mistyped nodes are reported with ERR_PRINT and skipped.
 *
 * Adapter decisions recorded here (representation only — no semantics):
 *   - LAVA MESH: the scene ships a unit CylinderMesh disc (radius 1, height
 *     0.2); the adapter scales it non-uniformly to (radius, 1, radius) so the
 *     y thickness stays 0.2 u, and ALSO mirrors `radius` into the shader
 *     uniform (the shader currently reads UVs only — the transform is the
 *     authoritative geometry path, the uniform is carried per 104_contract
 *     §3.4 wording).
 *   - GLOW NODE: position comes from the VOLCANO section so the light tracks
 *     the sim's caldera geometry; +1 u above `lake_level` is a scene-side
 *     DISPLAY lift constant (documented in docs/04 §5), not a tunable.
 *
 * ---------------------------------------------------------------------------
 * Milestone 0004 — schema 3 SKY (64 B, 16xf32) adapter decisions
 * ---------------------------------------------------------------------------
 * All of the following are REPRESENTATION ONLY: every value applied below is
 * a pure function of the 16 SKY fields plus the named adapter-display
 * constants (documented here and mirrored in docs/04 §6.6, same precedent as
 * GLOW_DISPLAY_LIFT_U). The sim stays the sole semantic authority (AP-11);
 * there is exactly one solar arc in the system and it lives in
 * src/mojo/sim/subjects.mojo (AP-16) — the adapter never re-derives it.
 *
 *   - SUN ROTATION: `set_rotation(Vector3(-sun_elevation, sun_azimuth, 0))`
 *     (unchanged 0002 mapping, verified against the scene's initial
 *     rotation) — +Z of the light node points AT the sun, -Z emits.
 *     `light_energy = sun_intensity`, `light_color = sun_color_*`.
 *   - SKY GRADIENT DERIVATION (104_contract §4.3 note): zenith/horizon are
 *     NOT wire fields. The adapter derives the ProceduralSkyMaterial dome:
 *         horizon = lerp(fog_color, sun_color, SKY_HORIZON_SUN_MIX)
 *         zenith  = horizon * (SKY_ZENITH_SCALE_R/G/B)
 *         ground_horizon = horizon        (no seam at the horizon)
 *         ground_bottom  = zenith * SKY_GROUND_DARKEN
 *     Rationale: the horizon band is the haze the fog actually paints, so
 *     fog_color_* is the physically consistent base; a fixed fraction of the
 *     sim sun palette keeps the low sun warming the horizon, and the
 *     per-channel zenith scale recovers the blue-up / warm-down gradient of
 *     A01_Render/Sky §2 from those two wire colors alone.
 *   - SKY ENERGY: `sky_energy_multiplier = SKY_ENERGY_MIN +
 *     (1 - SKY_ENERGY_MIN) * clamp(sun_intensity, 0, 1)` — day tracks the
 *     sim intensity, night keeps a dim but non-zero sky so the 0003 crater
 *     glow still has an ambient floor (night_factor stays sim-owned, AP-11).
 *   - FOG: `fog_enabled = true`, `fog_density`, `fog_light_color` ← SKY
 *     fields directly (no scene-side literal, AP-17). `fog_sky_affect` is a
 *     scene display value and is left alone.
 *   - CLOUDS: `cloud_cover` is written verbatim into the `cloud_cover`
 *     uniform of `scr_clouds`' ShaderMaterial (clouds.gdshader). The pattern
 *     inside the shader is display-only spatial noise (AP-17: no sim
 *     feedback, no TIME-driven semantics).
 *   - RAIN AMOUNT MAPPING: `emitting = (precipitation > 0)` and
 *     `amount_ratio = precipitation` (clamped to [0,1]). Godot scales the
 *     live particle count AND the emission rate by `amount_ratio`, so the
 *     scene's fixed `amount` is the full-intensity budget and precipitation
 *     (0..1) becomes a continuous intensity dial. This avoids `set_amount`
 *     (which restarts the GPU system) on every intensity change.
 *   - WETNESS: deterministic representation conversion from the catalog
 *     albedo — for every cached StandardMaterial3D the surface darkens by
 *     `(1 - WETNESS_TINT * wetness)`. Since schema 4 (0005) the wetness gain
 *     lives in `albedo_color` and MULTIPLIES the vertex-colour albedo (the
 *     catalog value itself is baked into ARRAY_COLOR); rewritten every frame
 *     from the latched SKY wetness (16 dry => gain 1, AP-3).
 *
 * ---------------------------------------------------------------------------
 * Milestone 0005 — schema 4 adapter decisions (SHORE_FOAM + blend tuples)
 * ---------------------------------------------------------------------------
 * Schema gate: SCR_SIM_SCHEMA_VER == 4 (scr_godot_abi.h); sections 1..9,
 * SHORE_FOAM required in every snapshot (104_contract §4.2/§4.3).
 *
 *   - TERRAIN BLEND TUPLES: the per-vertex 4-byte slot is the schema-4 tuple
 *     (u8 dominant, u8 blend partner, u8 weight 0..255, u8 pad = 0) — same
 *     stride as the schema-3 u32 id, new meaning (AP-21). Decode rejects a
 *     nonzero pad, `weight == 0 && blend_id != material_id`, and any blend
 *     partner id absent from MATERIALS (loud ERR_PRINT, frame skipped —
 *     never coerced, 104_contract §8). A dominant id absent from MATERIALS
 *     keeps the schema-3 behaviour (neutral fallback + one warning).
 *   - VERTEX-COLOUR ALBEDO (locked, spec §1.1 (b)): surfaces still group by
 *     dominant id; every emitted vertex carries
 *         COLOR = mix(albedo[dominant], albedo[blend], w/255)
 *     from the MATERIALS catalog (representation conversion only — AP-20:
 *     no material is ever assigned here, only mixed) and the material sets
 *     the BaseMaterial3D flag `FLAG_ALBEDO_FROM_VERTEX_COLOR` (godot-cpp 4.7
 *     binding name for `vertex_color_use_as_albedo`) PLUS
 *     `FLAG_SRGB_VERTEX_COLOR` — probe-measured: the catalog ships
 *     `base_color_srgb`, and only the sRGB flag reproduces the schema-3
 *     albedo path pixel-exactly (albedo 0.4 -> 0.4; vertex without the flag
 *     -> 0.667, washed out). Measured Godot 4.7 semantics (rendered probe):
 *     the vertex colour MULTIPLIES `albedo_color`
 *     (ALBEDO = albedo_color.rgb * COLOR.rgb), so the composition is:
 *         final albedo = blended_albedo × (1 − WETNESS_TINT·wetness)
 *     implemented as `albedo_color = (gain, gain, gain, opacity)` — the 0004
 *     wetness gain COMBINES with the vertex colour instead of overwriting it,
 *     and wetness keeps updating every frame without re-uploading meshes
 *     (albedo_color is per-material, COLOR is baked per-vertex).
 *     Roughness / emission / opacity stay the grouped surface's dominant
 *     material (recorded limitation, spec §1.1). Catalog albedo values live
 *     in the `scr_materials` meta dictionary unchanged (AP-3).
 *   - SHORE FOAM TEXTURE (locked, spec §1.1 (a)): section 9 is uploaded as
 *     an ImageTexture (FORMAT_RF, grid_n × grid_n) and refreshed EVERY
 *     snapshot (the field evolves with wave phase). Row mapping: image row r
 *     = contract row `iz` (row-major iz·grid_n + ix, cell centers); Godot
 *     samples texture v = 0 at image row 0 (rendered probe, Godot 4.7), and
 *     the shader maps world z → v = (z − z0)/(grid_n·cell_size) with
 *     z0 = −0.5·grid_n·cell_size, so v = (iz + 0.5)/grid_n lands on row iz
 *     — NO flip. The shader only shades the field: it never re-derives
 *     y_water − y_terrain (AP-19). Crest whitecaps stay the disjoint 0002
 *     display path (AP-22).
 *
 * ---------------------------------------------------------------------------
 * Milestone 0006 — schema 5 adapter decisions (FLORA/FAUNA)
 * ---------------------------------------------------------------------------
 * Schema gate: SCR_SIM_SCHEMA_VER == 5 (scr_godot_abi.h); sections 1..11,
 * FAUNA required in every snapshot, FLORA emission-gated (first snapshot
 * after init + world_version bump — 104_contract §4.2/§4.3, invariant 5).
 *
 *   - DECODE ONLY IN C++: section 10 (4 + 24·count, count ≤ 4096, species_id
 *     1..7, finite pose, scale > 0) and section 11 (4 + 20·count, count ≤ 64,
 *     u8 species_id, 3 pad bytes MUST be 0, finite pose) are fully validated
 *     here; a violation skips the frame loudly (104_contract §8).
 *   - VIEW CONSTRUCTION STAYS IN GDSCRIPT (spec §5): the adapter hands the
 *     validated byte spans to the host scripts — `apply_flora(bytes,
 *     materials)` ONLY while §10 is present (absence never clears the cached
 *     instances, invariant 5) and `apply_fauna(bytes)` every snapshot. The
 *     scripts own MultiMesh build, pooling and node lifecycle (presentation
 *     only); a present host without the method warns once and is skipped.
 *   - SPECIES COLORS (0006 AP-14): MATERIALS never carries botanical ids
 *     (encode.mojo::_encode_materials = terrain vocabulary ∪ water), so each
 *     species resolves its catalog albedo via a MIRROR of
 *     materials/catalog.mojo::species_catalog_id_string() keyed by the
 *     materials_catalog.json array index (foliage 34 / bamboo 33 / moss 81) —
 *     a MATERIALS record with that id wins if it ever appears. Colors are
 *     catalog values, never invented; species semantics stay sim-side
 *     (0006 AP-11) and no flap/sway phase is read from the wire (0006 AP-12).
 *   - WETNESS: flora materials get `set_wetness_gain(k)` (same k as terrain,
 *     wetness_gain()) only when it changes; the script multiplies its base
 *     albedo. Birds are not wetness-tinted (thin-film display choice).
 *   - DISPLAY-ONLY MOTION: sway/flap run on shader TIME inside
 *     flora_wing.gdshader (docs/04 §6) — representation only.
 *
 * Conventions (normative for Sprint-04 scene work): *   - YAW:    rotation.y = +yaw.  The sim's horizontal forward is
 *             (-sin yaw, -cos yaw) (src/mojo/sim/subjects.mojo), which equals
 *             Godot's -Z axis rotated by +yaw. No sign flip.
 *   - PITCH:  rotation.x = +pitch. Godot: +rotation.x looks UP; the sim does
 *             pitch -= look_dy (mouse down => pitch down), matching Godot.
 *   - CAMERA position = player.position + (0, eye_height, 0), applied as a
 *     GLOBAL position (sim world frame == Godot world frame).
 *             Gated by the `camera_follow` property (default true, so the
 *             main scene behaves exactly as before): when false the adapter
 *     leaves the scr_camera node transform alone. This is a DEBUG-ONLY
 *     escape hatch for diagnostics that need to drive the camera themselves
 *     (the adapter otherwise overwrites it every physics frame) — it is not
 *     used by scenes/island.tscn and carries no semantics.
 *   - SUN:    set_rotation(Vector3(-sun_elevation, sun_azimuth, 0)) with
 *             Godot's default YXZ euler order: the light node's +Z axis
 *             points AT the sun, so its -Z emission direction (Godot light
 *             convention) points from the sun into the scene. azimuth is
 *             measured from +Z toward +X; elevation from the horizon up.
 *     energy: Light3D::set_param(PARAM_ENERGY, sun_intensity)
 *             (== the `light_energy` property).
 *   - TERRAIN material strategy: TERRAIN chunk vertices are WORLD-space
 *             (encode.mojo writes global x/z; chunk `origin` is provenance
 *             only and is stored as node meta, not as a transform).
 *             Material choice: one ArrayMesh SURFACE per distinct
 *             material_id in the chunk (triangle assigned by its first
 *             vertex's material_id); each surface gets a StandardMaterial3D
 *             derived from the MATERIALS section (albedo, roughness,
 *             emission, opacity). This preserves per-vertex material ids
 *             without a custom ARRAY_CUSTOM0 shader. Materials are cached per
 *             id and updated in place when MATERIALS changes.
 *   - TRIANGLE WINDING: 104_contract §4.3 ships indices as CCW front faces
 *             (right-hand-rule normal = the vertex normal, pointing out of
 *             the surface). Godot's front face is the OPPOSITE convention —
 *             clockwise (Godot procedural-geometry convention), so the
 *             renderer's default CULL_BACK discards every sim-front face.
 *             The adapter therefore REVERSES each triangle's index order
 *             while building the ArrayMesh. This is representation
 *             conversion (provider-side), not a semantic change: the byte
 *             schema, the vertex positions, the normals and the contract's
 *             "CCW front faces" wording are untouched. Without it the whole
 *             island is back-face culled — "half the island looks missing"
 *             (docs/04_simulation_engine.md §8.2).
 *
 * Input uplink (submit_input): movement clamped to the unit circle; look
 * deltas accumulate across frames and RESET each _physics_process after being
 * placed in the batch; booleans are level-triggered per frame (submitted
 * value is carried by the next batch and then cleared — the scene should call
 * submit_input every frame with current device state); the movement vector is
 * held (last submitted value) until overwritten.
 */

#include "scr_sim_loader.h"

#include <godot_cpp/classes/array_mesh.hpp>
#include <godot_cpp/classes/camera3d.hpp>
#include <godot_cpp/classes/directional_light3d.hpp>
#include <godot_cpp/classes/environment.hpp>
#include <godot_cpp/classes/file_access.hpp>
#include <godot_cpp/classes/gpu_particles3d.hpp>
#include <godot_cpp/classes/image.hpp>
#include <godot_cpp/classes/image_texture.hpp>
#include <godot_cpp/classes/label.hpp>
#include <godot_cpp/classes/mesh_instance3d.hpp>
#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/classes/node3d.hpp>
#include <godot_cpp/classes/omni_light3d.hpp>
#include <godot_cpp/classes/particle_process_material.hpp>
#include <godot_cpp/classes/procedural_sky_material.hpp>
#include <godot_cpp/classes/project_settings.hpp>
#include <godot_cpp/classes/scene_tree.hpp>
#include <godot_cpp/classes/shader.hpp>
#include <godot_cpp/classes/shader_material.hpp>
#include <godot_cpp/classes/sky.hpp>
#include <godot_cpp/classes/standard_material3d.hpp>
#include <godot_cpp/classes/world_environment.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/error_macros.hpp>
#include <godot_cpp/core/property_info.hpp>
#include <godot_cpp/godot.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/packed_byte_array.hpp>
#include <godot_cpp/variant/packed_color_array.hpp>
#include <godot_cpp/variant/packed_int32_array.hpp>
#include <godot_cpp/variant/packed_vector3_array.hpp>
#include <godot_cpp/variant/utility_functions.hpp>
#include <godot_cpp/variant/variant.hpp>

#include <cmath>
#include <cstdlib>
#include <cstring>
#include <unordered_map>
#include <unordered_set>
#include <vector>

using namespace godot;

namespace scr {

// ---------------------------------------------------------------------------
// Snapshot decode (104_contract.md §4) — validation only, no coercion
// ---------------------------------------------------------------------------

constexpr uint64_t kEnvelopeBytes = 48;
constexpr uint64_t kSectionHeaderBytes = 8;
constexpr uint32_t kPlayerBytes = 44;
constexpr uint32_t kMetaBytes = 32;
constexpr uint32_t kOceanBytes = 32;
/* Schema 3 (milestone_0004 §3.2 / §3.5): 5 SKY grows 32 -> 64 bytes
 * (16xf32). Sections 1-4 and 6-8 are byte-identical to schema 2. */
constexpr uint32_t kSkyBytes = 64;
/* Schema 2 (milestone_0003 §3.2): 7 VOLCANO = 7xf32 + u8 + 3 pad,
 * 8 PLUME = 8xf32 — both exactly 32 bytes (104_contract §4.3). */
constexpr uint32_t kVolcanoBytes = 32;
constexpr uint32_t kPlumeBytes = 32;
/* Schema 4 (milestone_0005 §3.3): 9 SHORE_FOAM = 12-byte header
 * (u32 grid_n, f32 cell_size, f32 sea_level) + grid_n² f32 foam values;
 * 16396 bytes at grid_n = 64 (12 + 4096·4). Size is derived, never hard
 * coded: sbytes MUST equal 12 + 4·grid_n² (104_contract §4.3 §9). */
constexpr uint32_t kShoreFoamHeaderBytes = 12;
constexpr uint32_t kShoreFoamGridMax = 1024;
/* Schema 5 (milestone_0006 §1.1, 104_contract §4.3 §10/§11):
 *   10 FLORA = u32 count + count·24 B (f32 x/y/z, f32 yaw, f32 scale,
 *              u32 species_id) — emission-gated, count ≤ FLORA_N_MAX (4096).
 *   11 FAUNA = u32 count + count·20 B (f32 x/y/z, f32 yaw, u8 species_id,
 *              u8×3 pad = 0) — every snapshot, count ≤ FLOCK_N_MAX (64). */
constexpr uint32_t kFloraHeaderBytes = 4;
constexpr uint32_t kFloraRecordBytes = 24;
constexpr uint32_t kFloraNMax = 4096;
constexpr uint32_t kFaunaHeaderBytes = 4;
constexpr uint32_t kFaunaRecordBytes = 20;
constexpr uint32_t kFaunaNMax = 64;
/* SPECIES_NONE = 0 is never emitted (mojo invariant); valid species 1..7. */
constexpr uint32_t kFloraSpeciesMax = 7;
/* Highest section id defined by SCR_SIM_SCHEMA_VER (used for range checks).
 * Schema 5: sections 1..11 (10 = FLORA, 11 = FAUNA). */
constexpr uint32_t kMaxSectionId = 11;

inline uint32_t rd_u32(const uint8_t *p) {
    uint32_t v;
    memcpy(&v, p, sizeof(v));
    return v;
}

inline float rd_f32(const uint8_t *p) {
    float v;
    memcpy(&v, p, sizeof(v));
    return v;
}

inline double rd_f64(const uint8_t *p) {
    double v;
    memcpy(&v, p, sizeof(v));
    return v;
}

struct MatRecord {
    uint32_t id = 0;
    float albedo[3] = { 0, 0, 0 };
    float roughness = 1.0f;
    float emissive[3] = { 0, 0, 0 };
    float opacity = 1.0f;
};

/* --- 0006 AP-14: species -> materials_catalog.json display mirror --------
 * The wire never carries a botanical color: MATERIALS only holds the terrain
 * vocabulary ∪ water (encode.mojo::_encode_materials), and FLORA/FAUNA ship
 * species_id only. This table MIRRORS materials/catalog.mojo::
 * species_catalog_id_string() — the single source, conformance-tested in
 * test_catalog.mojo against lib/A01_Render/Material/materials_catalog.json —
 * with the catalog array index as provenance (verified values: 33
 * botanical.bamboo, 34 botanical.foliage, 81 botanical.moss). Resolution in
 * ScrSimDriver::flora_materials(): a MATERIALS record whose material_id ==
 * catalog_index wins (future-proof); otherwise this table (0006 AP-14: no
 * color is ever invented). Roughness is the catalog's display_roughness. */
struct SpeciesDisplay {
    uint32_t catalog_index; // materials_catalog.json array index (0 = none)
    float albedo[3];
    float roughness;
};
constexpr SpeciesDisplay kSpeciesDisplay[kFloraSpeciesMax + 1] = {
    { 0, { 0.5f, 0.5f, 0.5f }, 1.0f }, // 0 SPECIES_NONE — never emitted
    { 34, { 0.24f, 0.52f, 0.18f }, 0.55f }, // 1 SPECIES_PALM_CLUSTER
    { 34, { 0.24f, 0.52f, 0.18f }, 0.55f }, // 2 SPECIES_PALM_SOLO
    { 33, { 0.38f, 0.62f, 0.22f }, 0.40f }, // 3 SPECIES_BAMBOO_GROVE
    { 34, { 0.24f, 0.52f, 0.18f }, 0.55f }, // 4 SPECIES_CANOPY_TREE
    { 34, { 0.24f, 0.52f, 0.18f }, 0.55f }, // 5 SPECIES_CANOPY_CLUSTER
    { 34, { 0.24f, 0.52f, 0.18f }, 0.55f }, // 6 SPECIES_SHRUB
    { 81, { 0.28f, 0.48f, 0.18f }, 0.92f }, // 7 SPECIES_FERN_CARPET
};

struct ChunkView {
    float origin[3] = { 0, 0, 0 };
    uint32_t vcount = 0;
    uint32_t icount = 0;
    const float *verts = nullptr;   // 3 * vcount
    const float *norms = nullptr;   // 3 * vcount
    /* Schema 4 blend tuples: 4 bytes per vertex (104_contract §4.3 §3) —
     * (u8 dominant, u8 blend partner, u8 weight, u8 pad). Same 4·vcount
     * byte span as the schema-3 u32 id slot. */
    const uint8_t *mats = nullptr;  // 4 * vcount
    const uint32_t *idx = nullptr;  // icount

    uint8_t dominant_at(uint32_t v) const { return mats[4u * v + 0]; }
    uint8_t blend_at(uint32_t v) const { return mats[4u * v + 1]; }
    uint8_t weight_at(uint32_t v) const { return mats[4u * v + 2]; }
};

struct SnapshotView {
    uint32_t section_count = 0;
    uint32_t world_version = 0;
    uint32_t state_generation = 0;
    uint32_t simulation_tick = 0;
    uint32_t determinism_epoch = 0;
    uint32_t seed = 0;
    double simulation_time = 0.0;
    bool has_terrain = false;
    const uint8_t *player = nullptr; // 44 bytes
    const uint8_t *meta = nullptr;   // 32 bytes
    const uint8_t *ocean = nullptr;  // 32 bytes
    const uint8_t *sky = nullptr;    // 64 bytes (schema 3, 104_contract §4.3)
    const uint8_t *volcano = nullptr; // 32 bytes (schema 2, 104_contract §7)
    const uint8_t *plume = nullptr;   // 32 bytes (schema 2, 104_contract §8)
    /* 9 SHORE_FOAM (schema 4): 12 + 4·grid_n² bytes, every snapshot. */
    const uint8_t *shore_foam = nullptr;
    uint32_t foam_grid_n = 0;
    float foam_cell_size = 0.0f;
    float foam_sea_level = 0.0f;
    /* 10 FLORA (schema 5): 4 + 24·count bytes, emission-gated — null when
     * absent (absent must NOT clear the view cache, invariant 5). */
    bool has_flora = false;
    const uint8_t *flora = nullptr;
    uint32_t flora_count = 0;
    /* 11 FAUNA (schema 5): 4 + 20·count bytes, every snapshot (required). */
    const uint8_t *fauna = nullptr;
    uint32_t fauna_count = 0;
    std::vector<MatRecord> materials;
    std::vector<ChunkView> chunks;
};

inline bool fail(String &err, const char *msg) {
    err = String(msg);
    return false;
}

inline bool fail(String &err, const String &msg) {
    err = msg;
    return false;
}

/* Full framing + section validation. Returns false (with err) on ANY
 * violation: bad magic, size, schema, framing, section size, index bounds,
 * required-section absence, unknown section id, or meta/terrain disagreement. */
bool decode_snapshot(const uint8_t *buf, uint64_t len, SnapshotView &out,
                     String &err) {
    /* seen[0] unused; indices 1..kMaxSectionId (schema 5 = sections 1..11). */
    bool seen[kMaxSectionId + 1] = {};

    if (buf == nullptr || len < kEnvelopeBytes) {
        return fail(err, "snapshot: shorter than envelope (48 bytes)");
    }
    if (rd_u32(buf + 0) != SCR_SNAPSHOT_MAGIC) {
        return fail(err, "snapshot: bad magic (expected 'SCRS')");
    }
    if (rd_u32(buf + 4) != SCR_SIM_SCHEMA_VER) {
        return fail(err,
                    String("snapshot: schema_version != ") +
                        String::num_uint64(SCR_SIM_SCHEMA_VER));
    }
    out.section_count = rd_u32(buf + 8);
    out.world_version = rd_u32(buf + 12);
    out.state_generation = rd_u32(buf + 16);
    out.simulation_tick = rd_u32(buf + 20);
    out.determinism_epoch = rd_u32(buf + 24);
    out.seed = rd_u32(buf + 28);
    out.simulation_time = rd_f64(buf + 32);
    const uint32_t payload_bytes = rd_u32(buf + 40);
    if (rd_u32(buf + 44) != 0) {
        return fail(err, "snapshot: reserved field != 0");
    }
    if (kEnvelopeBytes + payload_bytes != len) {
        return fail(err, "snapshot: envelope payload_bytes disagrees with buffer length");
    }

    uint64_t off = kEnvelopeBytes;
    uint64_t end = kEnvelopeBytes + payload_bytes;
    uint32_t walked = 0;
    const uint8_t *meta_buf = nullptr;
    const uint8_t *terrain_buf = nullptr;
    uint32_t meta_chunk_count = 0;
    uint32_t terrain_chunk_count = 0;

    while (off < end) {
        if (off + kSectionHeaderBytes > end) {
            return fail(err, "section: truncated 8-byte header");
        }
        const uint32_t sid = rd_u32(buf + off);
        const uint32_t sbytes = rd_u32(buf + off + 4);
        const uint8_t *data = buf + off + kSectionHeaderBytes;
        if (off + kSectionHeaderBytes + sbytes > end) {
            return fail(err, "section: section_bytes exceeds envelope payload");
        }
        if (sid < 1u || sid > kMaxSectionId) {
            return fail(err,
                        "section: unknown section_id (schema 5 defines 1..11)");
        }
        if (seen[sid]) {
            return fail(err, "section: duplicate section_id");
        }
        seen[sid] = true;
        walked++;

        switch (sid) {
            case SCR_SEC_PLAYER: {
                if (sbytes != kPlayerBytes) {
                    return fail(err, "PLAYER: section must be exactly 44 bytes");
                }
                out.player = data;
                break;
            }
            case SCR_SEC_TERRAIN_META: {
                if (sbytes != kMetaBytes) {
                    return fail(err, "TERRAIN_META: section must be exactly 32 bytes");
                }
                meta_buf = data;
                meta_chunk_count = rd_u32(data + 28);
                break;
            }
            case SCR_SEC_TERRAIN: {
                if (sbytes < 4) {
                    return fail(err, "TERRAIN: section shorter than chunk_count");
                }
                terrain_buf = data;
                terrain_chunk_count = rd_u32(data);
                break;
            }
            case SCR_SEC_OCEAN: {
                if (sbytes != kOceanBytes) {
                    return fail(err, "OCEAN: section must be exactly 32 bytes");
                }
                out.ocean = data;
                break;
            }
            case SCR_SEC_SKY: {
                if (sbytes != kSkyBytes) {
                    return fail(err, "SKY: section must be exactly 64 bytes");
                }
                /* Strict field validation (104_contract §4.3, schema 3).
                 * Comparisons are written so NaN fails every range test
                 * (never coerced, §8). */
                const float hours = rd_f32(data + 0);
                const float elevation = rd_f32(data + 8);
                const float fog_density = rd_f32(data + 12);
                const float intensity = rd_f32(data + 28);
                if (!(hours >= 0.0f) || !(hours <= 24.0001f)) {
                    return fail(err, "SKY: time_of_day_hours outside [0,24]");
                }
                if (!(elevation >= -1.7f) || !(elevation <= 1.7f)) {
                    return fail(err, "SKY: sun_elevation not sane (±1.7 rad)");
                }
                if (!(fog_density >= 0.0f)) {
                    return fail(err, "SKY: fog_density < 0");
                }
                if (!(intensity >= 0.0f)) {
                    return fail(err, "SKY: sun_intensity < 0");
                }
                const float cover = rd_f32(data + 44);
                const float precip = rd_f32(data + 48);
                const float wetness = rd_f32(data + 60);
                if (!(cover >= 0.0f) || !(cover <= 1.0f)) {
                    return fail(err, "SKY: cloud_cover not in [0,1]");
                }
                if (!(precip >= 0.0f) || !(precip <= 1.0f)) {
                    return fail(err, "SKY: precipitation not in [0,1]");
                }
                if (!(wetness >= 0.0f) || !(wetness <= 1.0f)) {
                    return fail(err, "SKY: wetness not in [0,1]");
                }
                out.sky = data;
                break;
            }
            case SCR_SEC_MATERIALS: {
                if (sbytes < 4) {
                    return fail(err, "MATERIALS: section shorter than count");
                }
                const uint32_t count = rd_u32(data);
                if (sbytes != 4u + 36u * count) {
                    return fail(err, "MATERIALS: section_bytes != 4 + 36*count");
                }
                out.materials.resize(count);
                for (uint32_t i = 0; i < count; i++) {
                    const uint8_t *r = data + 4u + 36u * i;
                    MatRecord &m = out.materials[i];
                    m.id = rd_u32(r + 0);
                    m.albedo[0] = rd_f32(r + 4);
                    m.albedo[1] = rd_f32(r + 8);
                    m.albedo[2] = rd_f32(r + 12);
                    m.roughness = rd_f32(r + 16);
                    m.emissive[0] = rd_f32(r + 20);
                    m.emissive[1] = rd_f32(r + 24);
                    m.emissive[2] = rd_f32(r + 28);
                    m.opacity = rd_f32(r + 32);
                }
                break;
            }
            case SCR_SEC_VOLCANO: {
                if (sbytes != kVolcanoBytes) {
                    return fail(err, "VOLCANO: section must be exactly 32 bytes");
                }
                if (data[29] != 0 || data[30] != 0 || data[31] != 0) {
                    return fail(err, "VOLCANO: pad bytes must be zero");
                }
                if (data[28] > 1u) {
                    return fail(err, "VOLCANO: effusion_state > 1");
                }
                if (!(rd_f32(data + 8) > 0.0f)) {
                    return fail(err, "VOLCANO: radius <= 0");
                }
                if (!(rd_f32(data + 16) > 0.0f)) {
                    return fail(err, "VOLCANO: emissive_intensity <= 0");
                }
                const float crust = rd_f32(data + 20);
                if (!(crust >= 0.0f) || !(crust <= 1.0f)) {
                    return fail(err, "VOLCANO: crust_fraction not in [0,1]");
                }
                out.volcano = data;
                break;
            }
            case SCR_SEC_PLUME: {
                if (sbytes != kPlumeBytes) {
                    return fail(err, "PLUME: section must be exactly 32 bytes");
                }
                const float rate = rd_f32(data + 12);
                const float lifetime = rd_f32(data + 28);
                if (!(rate >= 0.0f)) {
                    return fail(err, "PLUME: rate < 0");
                }
                if (!(lifetime > 0.0f)) {
                    return fail(err, "PLUME: lifetime <= 0");
                }
                out.plume = data;
                break;
            }
            case SCR_SEC_SHORE_FOAM: {
                /* 9 SHORE_FOAM (schema 4, 104_contract §4.3 §9): 12-byte
                 * header + grid_n² f32. Size is DERIVED from grid_n — never
                 * hard coded (16396 B at grid_n = 64). Range checks written
                 * so NaN fails (never coerced, §8). */
                if (sbytes < kShoreFoamHeaderBytes) {
                    return fail(err, "SHORE_FOAM: section shorter than 12-byte header");
                }
                const uint32_t grid_n = rd_u32(data + 0);
                const float cell_size = rd_f32(data + 4);
                const float sea_level = rd_f32(data + 8);
                if (grid_n == 0 || grid_n > kShoreFoamGridMax) {
                    return fail(err, "SHORE_FOAM: grid_n outside [1,1024]");
                }
                const uint64_t want = (uint64_t)kShoreFoamHeaderBytes +
                                      4ull * (uint64_t)grid_n * (uint64_t)grid_n;
                if ((uint64_t)sbytes != want) {
                    return fail(err, "SHORE_FOAM: section_bytes != 12 + 4*grid_n^2");
                }
                if (!(cell_size > 0.0f)) {
                    return fail(err, "SHORE_FOAM: cell_size <= 0");
                }
                if (!(sea_level == sea_level)) {
                    return fail(err, "SHORE_FOAM: sea_level is NaN");
                }
                for (uint64_t i = 0; i < (uint64_t)grid_n * grid_n; i++) {
                    const float f = rd_f32(data + kShoreFoamHeaderBytes + 4 * i);
                    if (!(f >= 0.0f) || !(f <= 1.0f)) {
                        return fail(err, "SHORE_FOAM: foam value outside [0,1]");
                    }
                }
                out.shore_foam = data;
                out.foam_grid_n = grid_n;
                out.foam_cell_size = cell_size;
                out.foam_sea_level = sea_level;
                break;
            }
            case SCR_SEC_FLORA: {
                /* 10 FLORA (schema 5, 104_contract §4.3 §10): u32 count +
                 * count·24 B, emission-gated. Size is DERIVED from count.
                 * Range checks written so NaN fails (never coerced, §8). */
                if (sbytes < kFloraHeaderBytes) {
                    return fail(err, "FLORA: section shorter than count");
                }
                const uint32_t count = rd_u32(data);
                if (count > kFloraNMax) {
                    return fail(err, "FLORA: count > 4096 (FLORA_N_MAX)");
                }
                const uint64_t want = (uint64_t)kFloraHeaderBytes +
                                      (uint64_t)kFloraRecordBytes * count;
                if ((uint64_t)sbytes != want) {
                    return fail(err, "FLORA: section_bytes != 4 + 24*count");
                }
                for (uint32_t i = 0; i < count; i++) {
                    const uint8_t *rec = data + kFloraHeaderBytes +
                                         (uint64_t)kFloraRecordBytes * i;
                    const float x = rd_f32(rec + 0);
                    const float y = rd_f32(rec + 4);
                    const float z = rd_f32(rec + 8);
                    const float yaw = rd_f32(rec + 12);
                    const float scale = rd_f32(rec + 16);
                    const uint32_t species = rd_u32(rec + 20);
                    if (!(x == x) || !(y == y) || !(z == z)) {
                        return fail(err, "FLORA: position is NaN");
                    }
                    if (!(yaw == yaw)) {
                        return fail(err, "FLORA: yaw is NaN");
                    }
                    if (!(scale > 0.0f)) {
                        return fail(err, "FLORA: scale <= 0");
                    }
                    if (species < 1u || species > kFloraSpeciesMax) {
                        return fail(err,
                                    "FLORA: species_id outside [1,7] "
                                    "(SPECIES_NONE = 0 is never emitted)");
                    }
                }
                out.has_flora = true;
                out.flora = data;
                out.flora_count = count;
                break;
            }
            case SCR_SEC_FAUNA: {
                /* 11 FAUNA (schema 5, 104_contract §4.3 §11): u32 count +
                 * count·20 B, every snapshot (required below). Pad MUST be 0
                 * (loud failure, §8); count ≤ FLOCK_N_MAX (0006 AP-13). */
                if (sbytes < kFaunaHeaderBytes) {
                    return fail(err, "FAUNA: section shorter than count");
                }
                const uint32_t count = rd_u32(data);
                if (count > kFaunaNMax) {
                    return fail(err, "FAUNA: count > 64 (FLOCK_N_MAX)");
                }
                const uint64_t want = (uint64_t)kFaunaHeaderBytes +
                                      (uint64_t)kFaunaRecordBytes * count;
                if ((uint64_t)sbytes != want) {
                    return fail(err, "FAUNA: section_bytes != 4 + 20*count");
                }
                for (uint32_t i = 0; i < count; i++) {
                    const uint8_t *rec = data + kFaunaHeaderBytes +
                                         (uint64_t)kFaunaRecordBytes * i;
                    const float x = rd_f32(rec + 0);
                    const float y = rd_f32(rec + 4);
                    const float z = rd_f32(rec + 8);
                    const float yaw = rd_f32(rec + 12);
                    if (!(x == x) || !(y == y) || !(z == z)) {
                        return fail(err, "FAUNA: position is NaN");
                    }
                    if (!(yaw == yaw)) {
                        return fail(err, "FAUNA: yaw is NaN");
                    }
                    /* rec+16 u8 species_id (0 = seabird, reserved), rec+17..19
                     * pad — contract mandates rejection of nonzero pad. */
                    if (rec[17] != 0 || rec[18] != 0 || rec[19] != 0) {
                        return fail(err, "FAUNA: nonzero pad bytes");
                    }
                }
                out.fauna = data;
                out.fauna_count = count;
                break;
            }
            default:
                return fail(err, "section: unhandled section_id");
        }

        off += kSectionHeaderBytes + sbytes;
    }

    if (walked != out.section_count) {
        return fail(err, "snapshot: section_count disagrees with framed sections");
    }
    /* Sections emitted in EVERY snapshot (104_contract §4.3, schema 5).
     * TERRAIN and FLORA are the only optional ones (TERRAIN: first snapshot /
     * world_version bump; FLORA: emission-gated on the same rule). */
    if (!seen[SCR_SEC_PLAYER] || !seen[SCR_SEC_TERRAIN_META] ||
        !seen[SCR_SEC_OCEAN] || !seen[SCR_SEC_SKY] || !seen[SCR_SEC_MATERIALS] ||
        !seen[SCR_SEC_VOLCANO] || !seen[SCR_SEC_PLUME] ||
        !seen[SCR_SEC_SHORE_FOAM] || !seen[SCR_SEC_FAUNA]) {
        return fail(err, "snapshot: required section missing "
                         "(PLAYER/TERRAIN_META/OCEAN/SKY/MATERIALS/VOLCANO/PLUME/"
                         "SHORE_FOAM/FAUNA)");
    }
    out.meta = meta_buf;

    /* Terrain chunk records: bounds + index validation, views into buffer. */
    if (seen[SCR_SEC_TERRAIN]) {
        out.has_terrain = true;
        const uint64_t sec_bytes = kSectionHeaderBytes +
            (terrain_chunk_count > 0
                 ? (uint64_t)(end - (uintptr_t)(terrain_buf - buf) - kSectionHeaderBytes)
                 : 0);
        /* Recompute section length from framing (data starts after header). */
        const uint8_t *sec_start = terrain_buf - kSectionHeaderBytes;
        const uint32_t sec_len = rd_u32(sec_start + 4);
        (void)sec_bytes;
        if (sec_len < 4) {
            return fail(err, "TERRAIN: truncated section");
        }
        uint64_t toff = 4;
        out.chunks.reserve(terrain_chunk_count);
        for (uint32_t c = 0; c < terrain_chunk_count; c++) {
            if (toff + 20 > sec_len) {
                return fail(err, "TERRAIN: truncated chunk header");
            }
            const uint8_t *ch = terrain_buf + toff;
            ChunkView cv;
            cv.origin[0] = rd_f32(ch + 0);
            cv.origin[1] = rd_f32(ch + 4);
            cv.origin[2] = rd_f32(ch + 8);
            cv.vcount = rd_u32(ch + 12);
            cv.icount = rd_u32(ch + 16);
            if (cv.icount % 3u != 0u) {
                return fail(err, "TERRAIN: idx_count not a multiple of 3");
            }
            if (cv.icount > 0 && cv.vcount == 0) {
                return fail(err, "TERRAIN: indices present with zero vertices");
            }
            const uint64_t need = 20ull + 28ull * cv.vcount + 4ull * cv.icount;
            if (toff + need > sec_len) {
                return fail(err, "TERRAIN: chunk payload exceeds section_bytes");
            }
            cv.verts = reinterpret_cast<const float *>(ch + 20);
            cv.norms = cv.verts + 3ull * cv.vcount;
            /* Schema 4 (104_contract §4.3 §3): 4-byte blend tuple per vertex
             * — (u8 dominant, u8 blend partner, u8 weight, u8 pad) — at the
             * same byte span the schema-3 u32 id occupied (20 + 28·vcount
             * + 4·icount is unchanged). */
            cv.mats = reinterpret_cast<const uint8_t *>(cv.norms + 3ull * cv.vcount);
            cv.idx = reinterpret_cast<const uint32_t *>(cv.mats + 4ull * cv.vcount);
            for (uint32_t i = 0; i < cv.icount; i++) {
                if (cv.idx[i] >= cv.vcount) {
                    return fail(err, "TERRAIN: index out of vertex range");
                }
            }
            /* Blend-tuple validation (104_contract §4.3 §3, §8): reject the
             * pad byte, and reject weight == 0 carrying blend != dominant.
             * Never coerced — frame is skipped with an explicit reason. */
            for (uint32_t i = 0; i < cv.vcount; i++) {
                const uint8_t *t = cv.mats + 4ull * i;
                if (t[3] != 0u) {
                    return fail(err, "TERRAIN: blend tuple pad byte != 0");
                }
                if (t[2] == 0u && t[1] != t[0]) {
                    return fail(err,
                                "TERRAIN: weight 0 but blend_id != material_id");
                }
            }
            out.chunks.push_back(cv);
            toff += need;
        }
        if (toff != sec_len) {
            return fail(err, "TERRAIN: framed bytes != chunk payloads");
        }
        if (out.chunks.size() != meta_chunk_count) {
            return fail(err, "TERRAIN chunk_count != TERRAIN_META.chunk_count");
        }
        terrain_chunk_count = (uint32_t)out.chunks.size();
    } else {
        /* TERRAIN suppressed: keep existing meshes. TERRAIN_META.chunk_count
         * persists (describes the cached terrain) and must NOT be zero. */
        out.has_terrain = false;
    }
    (void)terrain_buf;

    /* Blend-partner closure (104_contract §4.3 §3): a vertex that actually
     * blends (weight > 0) must name a partner present in MATERIALS — the
     * segment can then resolve its albedo from the catalog. The dominant id
     * keeps the schema-3 neutral-fallback behaviour. Linear scan: MATERIALS
     * is small (<= ~96 records) and TERRAIN is optional. */
    if (out.has_terrain) {
        auto has_material = [&out](uint32_t id) -> bool {
            for (const MatRecord &m : out.materials) {
                if (m.id == id) {
                    return true;
                }
            }
            return false;
        };
        for (const ChunkView &cv : out.chunks) {
            for (uint32_t i = 0; i < cv.vcount; i++) {
                if (cv.weight_at(i) > 0u && !has_material(cv.blend_at(i))) {
                    return fail(err,
                                "TERRAIN: blend_id not present in MATERIALS");
                }
            }
        }
    }

    return true;
}

// ---------------------------------------------------------------------------
// Material derivation (MATERIALS section -> StandardMaterial3D)
// ---------------------------------------------------------------------------

void apply_mat_props(StandardMaterial3D *m, const MatRecord &r) {
    m->set_albedo(Color(r.albedo[0], r.albedo[1], r.albedo[2], r.opacity));
    m->set_roughness(r.roughness);
    m->set_emission(Color(r.emissive[0], r.emissive[1], r.emissive[2]));
    /* emission_enabled binds to set_feature(FEATURE_EMISSION, ·) in 4.7. */
    m->set_feature(BaseMaterial3D::FEATURE_EMISSION,
                   r.emissive[0] > 0.0f || r.emissive[1] > 0.0f ||
                       r.emissive[2] > 0.0f);
    m->set_transparency(r.opacity < 0.999f
                            ? BaseMaterial3D::TRANSPARENCY_ALPHA
                            : BaseMaterial3D::TRANSPARENCY_DISABLED);
}

} // namespace scr

// ---------------------------------------------------------------------------
// ScrSimDriver — the single registered node class
// ---------------------------------------------------------------------------

/* Godot-visible name must be exactly "ScrSim" (Sprint-04 scene instantiates
 * `ScrSim`). godot-cpp's GDCLASS registers under the literal token passed to
 * it (stringified unexpanded), so we pass the alias token `ScrSim` while every
 * other (non-`#`) use expands to the real C++ class name ScrSimDriver.
 * C++ references to the class may use either name (see `using` below). */
#define ScrSim ScrSimDriver

class ScrSimDriver : public Node3D {
    GDCLASS(ScrSim, Node3D)

#undef ScrSim

public:
    ScrSimDriver() = default;
    ~ScrSimDriver() override = default;

    /* Scene-side DISPLAY lift for the crater glow light (representation
     * only): light centre = lake_level + lift. Measurement chain (night
     * captures, spawn view): +1 u -> light buried in bowl, all visible
     * outer slopes NdotL < 0, warm px = 0. +30 u (y~40) -> clears rim but
     * still behind the visible slope normals (dot ~ -0.1), warm px = 0.
     * +60 u puts the light above the visible silhouette so outward-facing
     * slopes get dot > 0 and the spec §7 "glow spot above terrain
     * luminance background" appears in build/island.png. Measured warm
     * pixels (r>=70, r-b>=10, day-neutral threshold) on the spawn view:
     * lift 1 u -> 0, lift 30 u -> 0, lift 60 u -> 139 (glow hue evidence;
     * glow OFF baseline = 0). Projection of the light centre sits just
     * above the frame top (y=-8) but its lit pool lands on the dome.
     * Geometry is display-only; light_energy stays the sim glow_intensity
     * (AP-11). Documented docs/04 §5 with omni_range 90 (island.tscn). */
    static constexpr float GLOW_DISPLAY_LIFT_U = 60.0f;

    /* --- milestone 0004 (schema 3) adapter-display constants --------------
     * Representation-only knobs for the SKY -> Godot mapping (file header
     * "0004 adapter decisions"; mirrored in docs/04 §6.6). Simulation
     * tunables stay in src/mojo/sim/parameters.mojo (AP-7/AP-17) — these
     * are NOT tunables of meaning, they pick how two wire colors become a
     * dome gradient and how wetness reads on screen. */
    /* horizon = lerp(fog_color, sun_color, SKY_HORIZON_SUN_MIX) */
    static constexpr float SKY_HORIZON_SUN_MIX = 0.25f;
    /* zenith = horizon * (SKY_ZENITH_SCALE_R/G/B) — recovers the blue-up
     * gradient of A01_Render/Sky §2 from fog_color alone. */
    static constexpr float SKY_ZENITH_SCALE_R = 0.40f;
    static constexpr float SKY_ZENITH_SCALE_G = 0.55f;
    static constexpr float SKY_ZENITH_SCALE_B = 0.90f;
    static constexpr float SKY_GROUND_DARKEN = 0.35f;
    /* Night sky floor: keeps a dim sky (and therefore ambient) at
     * sun_intensity = 0 so the 0003 crater glow keeps a background. */
    static constexpr float SKY_ENERGY_MIN = 0.50f;
    /* Wet-surface albedo tint: albedo *= (1 - WETNESS_TINT * wetness). */
    static constexpr float WETNESS_TINT = 0.35f;

    /* @export var world_seed: int = 1  (instance default; GDExtension cannot
     * register a property-default callback — see class comment). */
    void set_world_seed(int64_t p_seed) { world_seed = p_seed; }
    int64_t get_world_seed() const { return world_seed; }

    /* @export var camera_follow: bool = true — see file header. Debug aid
     * only: when false, apply_player() leaves the scr_camera transform alone
     * so a diagnostic script can drive the camera. */
    void set_camera_follow(bool p_follow) { camera_follow = p_follow; }
    bool get_camera_follow() const { return camera_follow; }

    /* GDScript input entry point (bound below). */
    void submit_input(float move_x, float move_y, float look_dx, float look_dy,
                      bool jump, bool sprint, bool action_primary,
                      bool action_secondary);

    void _ready() override;
    void _physics_process(double delta) override;
    void _exit_tree() override;

    static void _bind_methods();

protected:
    // --- sim lifecycle ------------------------------------------------------
    scr_sim_api api_ = {};
    bool loaded_ = false;        // symbols bound + versions accepted
    bool inited_ = false;        // scr_sim_init succeeded

    // --- input state --------------------------------------------------------
    int64_t world_seed = 1;
    bool camera_follow = true; // debug aid; default true (main scene unchanged)
    float in_move_x = 0.0f;
    float in_move_y = 0.0f;
    float in_look_dx = 0.0f;
    float in_look_dy = 0.0f;
    bool in_jump = false;
    bool in_sprint = false;
    bool in_action_primary = false;
    bool in_action_secondary = false;

    // --- snapshot buffer (reused; AP-9 O(snapshot)) -------------------------
    std::vector<uint8_t> snap_buf_;

    // --- material cache -----------------------------------------------------
    std::unordered_map<uint32_t, scr::MatRecord> mat_records_;
    std::unordered_map<uint32_t, Ref<StandardMaterial3D>> mat_cache_;
    std::unordered_set<uint32_t> mat_missing_warned_;

    // --- plume emitter cache (set_amount/set_emitting reset the GPU system;
    //     only touch on change) --------------------------------------------
    int plume_amount_cache_ = -1;
    int plume_emitting_cache_ = -1; // -1 unknown, 0 off, 1 on

    // --- weather display caches (0004: only touch GPU/materials on change) -
    int rain_emitting_cache_ = -1;  // -1 unknown, 0 off, 1 on
    float rain_ratio_cache_ = -1.0f;
    float wetness_ = -1.0f;   // latched SKY wetness; used by update_materials
    /* SHORE_FOAM upload cache (schema 4): FORMAT_RF grid_n × grid_n,
     * re-uploaded every snapshot (0005 §1.1 (a)). */
    Ref<ImageTexture> foam_tex_;
    float cloud_cover_cache_ = -1.0f;

    // --- ecology view caches (0006): warn-once + change-latched gain ----
    bool flora_method_warned_ = false; // present group, missing method
    bool fauna_method_warned_ = false;
    /* set_wetness_gain latch: wetness_gain() ∈ [0.65, 1], so -1 = unset. */
    float flora_wetness_cache_ = -1.0f;

    // --- helpers ------------------------------------------------------------
    Node *first_in_group(const StringName &p_group);
    void decode_and_apply(uint32_t len);
    void update_materials(const scr::SnapshotView &sv);
    Ref<StandardMaterial3D> material_for(uint32_t id);
    /* Wet-surface gain from the latched SKY wetness (0004); lives in
     * albedo_color so it composes with schema-4 vertex-colour albedo. */
    float wetness_gain() const;
    void apply_player(const scr::SnapshotView &sv);
    void apply_terrain_meta(const scr::SnapshotView &sv);
    void apply_terrain(const scr::SnapshotView &sv);
    void apply_ocean(const scr::SnapshotView &sv);
    /* Catalog albedo for ARRAY_COLOR (schema 4 blend tuples). Shared warning
     * set with material_for(): a missing id warns exactly once. */
    Color albedo_of(uint32_t id);
    void apply_sky(const scr::SnapshotView &sv);
    void apply_weather(const scr::SnapshotView &sv);
    void apply_materials_node(const scr::SnapshotView &sv);
    void apply_volcano(const scr::SnapshotView &sv);
    void apply_plume(const scr::SnapshotView &sv);
    /* 0006 ecology view dispatch (spec §5: view construction lives in the
     * host scripts; the adapter only validates + forwards). */
    void apply_flora(const scr::SnapshotView &sv);
    void apply_fauna(const scr::SnapshotView &sv);
    /* Dictionary species(int) -> {albedo: Color, roughness: float} resolved
     * through the catalog mirror table (0006 AP-14, scr::kSpeciesDisplay). */
    Dictionary flora_materials();
    void apply_hud(const scr::SnapshotView &sv);
};

using ScrSimDriverAlias = ScrSimDriver;

// ---------------------------------------------------------------------------
// Bindings
// ---------------------------------------------------------------------------

void ScrSimDriver::_bind_methods() {
    ClassDB::bind_method(D_METHOD("set_world_seed", "seed"),
                         &ScrSimDriver::set_world_seed);
    ClassDB::bind_method(D_METHOD("get_world_seed"),
                         &ScrSimDriver::get_world_seed);
    ADD_PROPERTY(PropertyInfo(Variant::INT, "world_seed"), "set_world_seed",
                 "get_world_seed");

    ClassDB::bind_method(D_METHOD("set_camera_follow", "follow"),
                         &ScrSimDriver::set_camera_follow);
    ClassDB::bind_method(D_METHOD("get_camera_follow"),
                         &ScrSimDriver::get_camera_follow);
    ADD_PROPERTY(PropertyInfo(Variant::BOOL, "camera_follow"),
                 "set_camera_follow", "get_camera_follow");

    ClassDB::bind_method(
        D_METHOD("submit_input", "move_x", "move_y", "look_dx", "look_dy",
                 "jump", "sprint", "action_primary", "action_secondary"),
        &ScrSimDriver::submit_input);
}

// ---------------------------------------------------------------------------
// Input uplink
// ---------------------------------------------------------------------------

void ScrSimDriver::submit_input(float move_x, float move_y, float look_dx,
                                float look_dy, bool jump, bool sprint,
                                bool action_primary, bool action_secondary) {
    /* Movement: clamp to the unit circle (diagonal never faster). */
    const float len2 = move_x * move_x + move_y * move_y;
    if (len2 > 1.0f) {
        const float inv = 1.0f / std::sqrt(len2);
        move_x *= inv;
        move_y *= inv;
    }
    in_move_x = move_x;
    in_move_y = move_y;

    /* Look deltas accumulate per rendered frame; reset after batching. */
    in_look_dx += look_dx;
    in_look_dy += look_dy;

    /* Booleans: level-triggered for the frame they are submitted in. */
    in_jump = jump;
    in_sprint = sprint;
    in_action_primary = action_primary;
    in_action_secondary = action_secondary;
}

// ---------------------------------------------------------------------------
// Lifecycle
// ---------------------------------------------------------------------------

void ScrSimDriver::_ready() {
    if (loaded_) {
        return;
    }

    /* 1) repo-relative dev path (AP-4: res:// + ProjectSettings only) */
    String path = ProjectSettings::get_singleton()->globalize_path(
        "res://../build/libscr_sim.so");
    bool have = FileAccess::file_exists(path);

    /* 2) explicit override for tests/CI */
    if (!have) {
        const char *env = std::getenv("SCR_SIM_LIB");
        if (env != nullptr && env[0] != '\0') {
            path = String(env);
            have = true;
        }
    }

    if (!have) {
        ERR_PRINT(
            "SCR: sim library not found (tried res://../build/libscr_sim.so, "
            "then $SCR_SIM_LIB) — ScrSim staying inert");
        return;
    }

    char err[512];
    CharString cs = path.utf8();
    const int rc = scr_sim_load(&api_, cs.get_data(), err, sizeof(err));
    if (rc != SCR_LOAD_OK) {
        ERR_PRINT(String("SCR: ") + String(err) + " [" + path + "]");
        return;
    }

    UtilityFunctions::print(
        String("SCR: sim loaded (abi ") +
        String::num_uint64(api_.abi_version()) + ", schema " +
        String::num_uint64(api_.schema_version()) + ")");

    const uint32_t seed = static_cast<uint32_t>(static_cast<uint64_t>(world_seed));
    const int32_t irc = api_.init(seed);
    if (irc != 0) {
        ERR_PRINT(String("SCR: scr_sim_init failed with code ") +
                  String::num_int64(irc));
        scr_sim_unload(&api_);
        return;
    }

    inited_ = true;
    loaded_ = true;
    set_physics_process(true);
}

void ScrSimDriver::_physics_process(double delta) {
    if (!loaded_ || !inited_) {
        return;
    }

    scr_input_batch batch;
    memset(&batch, 0, sizeof(batch));
    batch.move_x = in_move_x;
    batch.move_y = in_move_y;
    batch.look_dx = in_look_dx;
    batch.look_dy = in_look_dy;
    batch.jump = in_jump ? 1u : 0u;
    batch.sprint = in_sprint ? 1u : 0u;
    batch.action_primary = in_action_primary ? 1u : 0u;
    batch.action_secondary = in_action_secondary ? 1u : 0u;

    /* Look deltas are one-frame: consumed by this batch, then reset.
     * Booleans are level-triggered per frame: consumed, then cleared.
     * Movement is held until the scene submits a new vector. */
    in_look_dx = 0.0f;
    in_look_dy = 0.0f;
    in_jump = false;
    in_sprint = false;
    in_action_primary = false;
    in_action_secondary = false;

    /* delta passes through: the sim owns the frame-dt clamp (104_contract §6). */
    const int32_t ticks = api_.step(delta, &batch);
    if (ticks < 0) {
        ERR_PRINT(String("SCR: scr_sim_step failed with code ") +
                  String::num_int64(ticks));
        return;
    }

    const uint32_t need = api_.snapshot_size();
    if (need == 0) {
        return;
    }
    if (snap_buf_.size() < need) {
        snap_buf_.resize(need);
    }
    const int32_t got = api_.snapshot_write(snap_buf_.data(), need);
    if (got < 0) {
        ERR_PRINT(String("SCR: scr_sim_snapshot_write failed with code ") +
                  String::num_int64(got));
        return;
    }
    if (static_cast<uint32_t>(got) > need) {
        ERR_PRINT("SCR: snapshot_write reported more bytes than capacity");
        return;
    }
    decode_and_apply(static_cast<uint32_t>(got));
}

void ScrSimDriver::_exit_tree() {
    if (inited_) {
        api_.shutdown();
        inited_ = false;
    }
    if (loaded_) {
        scr_sim_unload(&api_);
        loaded_ = false;
    }
    set_physics_process(false);
}

// ---------------------------------------------------------------------------
// Group discovery + decode/apply
// ---------------------------------------------------------------------------

Node *ScrSimDriver::first_in_group(const StringName &p_group) {
    SceneTree *tree = get_tree();
    if (tree == nullptr) {
        return nullptr;
    }
    TypedArray<Node> nodes = tree->get_nodes_in_group(p_group);
    if (nodes.size() == 0) {
        return nullptr;
    }
    Object *obj = nodes[0];
    return Object::cast_to<Node>(obj);
}

void ScrSimDriver::decode_and_apply(uint32_t len) {
    scr::SnapshotView sv;
    String err;
    if (!scr::decode_snapshot(snap_buf_.data(), len, sv, err)) {
        ERR_PRINT(String("SCR: snapshot rejected, frame skipped — ") + err);
        return;
    }
    /* Latch SKY wetness BEFORE the per-frame material rewrite. */
    if (sv.sky != nullptr) {
        wetness_ = scr::rd_f32(sv.sky + 60);
    }

    /* Decode completed without error -> apply representation conversion.
     * Order: materials first (terrain surfaces derive from them). */
    update_materials(sv);
    apply_materials_node(sv);
    apply_terrain(sv);
    apply_terrain_meta(sv);
    apply_ocean(sv);
    apply_sky(sv);
    apply_weather(sv);
    apply_volcano(sv);
    apply_plume(sv);
    apply_flora(sv);
    apply_fauna(sv);
    apply_player(sv);
    apply_hud(sv);

    /* 0006 wetness: same gain as terrain (wetness_gain()), pushed to the
     * flora view only on change (the script multiplies its base albedo).
     * Runs regardless of FLORA presence — cached instances keep tracking the
     * latched SKY wetness while the section is absent. */
    const float gk = wetness_gain();
    if (gk != flora_wetness_cache_) {
        flora_wetness_cache_ = gk;
        Node *fn = first_in_group("scr_flora");
        if (fn != nullptr && fn->has_method("set_wetness_gain")) {
            Array args;
            args.append(gk);
            fn->callv("set_wetness_gain", args);
        }
    }
}

void ScrSimDriver::update_materials(const scr::SnapshotView &sv) {
    /* Wetness tint is applied HERE, immediately after the catalog write,
     * because every frame rewrites the material from the catalog (0004 AP-3:
     * 16.0 dry => catalog-exact). wetness_ is latched from the SKY bytes
     * in decode_and_apply() before this call.
     *
     * Schema 4 vertex-colour path (0005 §1.1 (b), probe-verified multiply):
     * the per-vertex COLOR already carries the blended catalog albedo, so the
     * material's albedo_color holds ONLY the wetness gain (+ dominant
     * opacity) and must NOT be overwritten with the catalog value. */
    const float k = wetness_gain();
    for (const scr::MatRecord &r : sv.materials) {
        mat_records_[r.id] = r;
        auto it = mat_cache_.find(r.id);
        if (it != mat_cache_.end() && it->second.is_valid()) {
            scr::apply_mat_props(it->second.ptr(), r);
            /* godot-cpp 4.7 exposes `vertex_color_use_as_albedo` as the
             * BaseMaterial3D flag (probe-verified: ALBEDO = albedo_color ×
             * vertex COLOR). SRGB flag is REQUIRED: catalog albedo is
             * base_color_srgb (materials/catalog.mojo), and a rendered probe
             * shows FLAG_SRGB_VERTEX_COLOR reproduces the schema-3 albedo
             * path pixel-exactly (0.4 -> 0.4; without it 0.4 -> 0.667,
             * washed out). */
            it->second->set_flag(BaseMaterial3D::FLAG_ALBEDO_FROM_VERTEX_COLOR,
                                 true);
            it->second->set_flag(BaseMaterial3D::FLAG_SRGB_VERTEX_COLOR, true);
            it->second->set_albedo(Color(k, k, k, r.opacity));
        }
    }
}

float ScrSimDriver::wetness_gain() const {
    /* 0004 wetness: final albedo = vertex_albedo * (1 - TINT * wetness). */
    return (wetness_ > 0.0f)
        ? (1.0f - WETNESS_TINT * (wetness_ > 1.0f ? 1.0f : wetness_))
        : 1.0f;
}

Ref<StandardMaterial3D> ScrSimDriver::material_for(uint32_t id) {
    auto it = mat_cache_.find(id);
    if (it != mat_cache_.end()) {
        return it->second;
    }
    Ref<StandardMaterial3D> m;
    m.instantiate();
    /* Schema 4: albedo arrives as ARRAY_COLOR (mixed dom/blend); this
     * material only contributes the wetness gain + dominant roughness /
     * emission / opacity. SRGB vertex flag = catalog is base_color_srgb
     * (probe: reproduces the schema-3 albedo path exactly). */
    m->set_flag(BaseMaterial3D::FLAG_ALBEDO_FROM_VERTEX_COLOR, true);
    m->set_flag(BaseMaterial3D::FLAG_SRGB_VERTEX_COLOR, true);
    const float k = wetness_gain();
    auto rec = mat_records_.find(id);
    if (rec != mat_records_.end()) {
        scr::apply_mat_props(m.ptr(), rec->second);
        m->set_albedo(Color(k, k, k, rec->second.opacity));
    } else if (mat_missing_warned_.insert(id).second) {
        ERR_PRINT(String("SCR: no MATERIALS record for id ") +
                  String::num_uint64(id) + " — using neutral fallback material");
        m->set_albedo(Color(0.5f * k, 0.5f * k, 0.5f * k));
    }
    mat_cache_[id] = m;
    return m;
}

Color ScrSimDriver::albedo_of(uint32_t id) {
    /* Catalog albedo for ARRAY_COLOR. Missing id: neutral fallback (same
     * 0.5 grey as material_for) + one shared warning — never invented. */
    auto rec = mat_records_.find(id);
    if (rec != mat_records_.end()) {
        return Color(rec->second.albedo[0], rec->second.albedo[1],
                     rec->second.albedo[2], 1.0f);
    }
    if (mat_missing_warned_.insert(id).second) {
        ERR_PRINT(String("SCR: no MATERIALS record for id ") +
                  String::num_uint64(id) + " — using neutral fallback material");
    }
    return Color(0.5f, 0.5f, 0.5f, 1.0f);
}

void ScrSimDriver::apply_hud(const scr::SnapshotView &sv) {
    Node *n = first_in_group("scr_hud");
    if (n == nullptr) {
        return;
    }
    Label *label = Object::cast_to<Label>(n);
    if (label == nullptr) {
        ERR_PRINT("SCR: group scr_hud must contain a Label — skipped");
        return;
    }
    label->set_text(vformat("tick %d | gen %d | seed %d",
                            (int64_t)sv.simulation_tick,
                            (int64_t)sv.state_generation, (int64_t)sv.seed));
}

void ScrSimDriver::apply_player(const scr::SnapshotView &sv) {
    if (!camera_follow) {
        return; /* debug aid (file header): diagnostic drives the camera */
    }
    if (sv.player == nullptr) {
        return;
    }
    Node *n = first_in_group("scr_camera");
    if (n == nullptr) {
        return;
    }
    Node3D *rig = Object::cast_to<Node3D>(n);
    if (rig == nullptr) {
        ERR_PRINT("SCR: group scr_camera must contain a Camera3D/Node3D — skipped");
        return;
    }
    const float px = scr::rd_f32(sv.player + 0);
    const float py = scr::rd_f32(sv.player + 4);
    const float pz = scr::rd_f32(sv.player + 8);
    const float yaw = scr::rd_f32(sv.player + 24);
    const float pitch = scr::rd_f32(sv.player + 28);
    const float eye = scr::rd_f32(sv.player + 32);

    rig->set_global_position(Vector3(px, py + eye, pz));
    /* Conventions documented in the file header: +yaw (no flip), +pitch. */
    rig->set_rotation(Vector3(pitch, yaw, 0.0f));
}

void ScrSimDriver::apply_terrain_meta(const scr::SnapshotView &sv) {
    if (sv.meta == nullptr) {
        return;
    }
    Node *n = first_in_group("scr_meta");
    if (n == nullptr) {
        return;
    }
    const float sea = scr::rd_f32(sv.meta + 0);
    const float peak = scr::rd_f32(sv.meta + 4);
    const float sx = scr::rd_f32(sv.meta + 8);
    const float sy = scr::rd_f32(sv.meta + 12);
    const float sz = scr::rd_f32(sv.meta + 16);
    n->set_meta("sea_level", Variant(sea));
    n->set_meta("peak_height", Variant(peak));
    n->set_meta("spawn_position", Variant(Vector3(sx, sy, sz)));
}

void ScrSimDriver::apply_ocean(const scr::SnapshotView &sv) {
    if (sv.ocean == nullptr) {
        return;
    }
    Node *n = first_in_group("scr_ocean");
    if (n == nullptr) {
        return;
    }
    MeshInstance3D *mi = Object::cast_to<MeshInstance3D>(n);
    if (mi == nullptr) {
        ERR_PRINT("SCR: group scr_ocean must contain a MeshInstance3D — skipped");
        return;
    }

    ShaderMaterial *sm = nullptr;
    Ref<Mesh> mesh = mi->get_mesh();
    if (mesh.is_valid() && mesh->get_surface_count() > 0) {
        sm = Object::cast_to<ShaderMaterial>(
            mi->get_surface_override_material(0).ptr());
    }
    if (sm == nullptr) {
        sm = Object::cast_to<ShaderMaterial>(mi->get_material_override().ptr());
    }
    if (sm == nullptr) {
        ERR_PRINT("SCR: scr_ocean mesh has no ShaderMaterial — skipped");
        return;
    }

    static const char *kNames[8] = { "sea_level", "amplitude", "frequency",
                                     "steepness", "dir_x",    "dir_z",
                                     "speed",     "phase" };
    for (int i = 0; i < 8; i++) {
        sm->set_shader_parameter(StringName(kNames[i]),
                                 Variant(scr::rd_f32(sv.ocean + 4u * i)));
    }

    /* 9 SHORE_FOAM (schema 4, 0005 §1.1 (a)): upload the raw grid as a
     * FORMAT_RF texture and refresh it EVERY snapshot — the field evolves
     * with wave phase, so a one-shot upload would freeze the shore band.
     * Row mapping (image row = contract iz, v=0 -> row 0) is documented in
     * the file header; the shader derives uv from world xz alone (AP-19: no
     * depth re-derivation). `sea_level` already reaches the shader from the
     * OCEAN section — both sections carry the same sim datum — so only the
     * grid geometry (grid_n, cell_size) is bound here. */
    if (sv.shore_foam != nullptr && sv.foam_grid_n > 0) {
        const uint32_t n = sv.foam_grid_n;
        const size_t nbytes = (size_t)n * n * 4u;
        PackedByteArray bytes;
        bytes.resize((int64_t)nbytes);
        std::memcpy(bytes.ptrw(), sv.shore_foam + scr::kShoreFoamHeaderBytes,
                    nbytes);
        Ref<Image> img;
        img.instantiate();
        img->create((int)n, (int)n, false, Image::FORMAT_RF);
        img->set_data((int)n, (int)n, false, Image::FORMAT_RF, bytes);
        if (foam_tex_.is_null() || foam_tex_->get_width() != (int)n ||
            foam_tex_->get_height() != (int)n) {
            foam_tex_ = ImageTexture::create_from_image(img);
        } else {
            foam_tex_->update(img);
        }
        sm->set_shader_parameter(StringName("foam_shore"), foam_tex_);
        sm->set_shader_parameter(StringName("foam_grid_n"), Variant((float)n));
        sm->set_shader_parameter(StringName("foam_cell_size"),
                                 Variant(sv.foam_cell_size));
    }
}

void ScrSimDriver::apply_sky(const scr::SnapshotView &sv) {
    if (sv.sky == nullptr) {
        return;
    }
    /* 104_contract §4.3 — schema 3 SKY, 16 x f32 (64 B). */
    const float hours = scr::rd_f32(sv.sky + 0);
    const float azimuth = scr::rd_f32(sv.sky + 4);
    const float elevation = scr::rd_f32(sv.sky + 8);
    const float fog_density = scr::rd_f32(sv.sky + 12);
    const float fr = scr::rd_f32(sv.sky + 16);
    const float fg = scr::rd_f32(sv.sky + 20);
    const float fb = scr::rd_f32(sv.sky + 24);
    const float intensity = scr::rd_f32(sv.sky + 28);
    const float sr = scr::rd_f32(sv.sky + 32);
    const float sg = scr::rd_f32(sv.sky + 36);
    const float sb = scr::rd_f32(sv.sky + 40);
    (void)hours; /* informational; sun angles are authoritative (AP-16) */

    Node *sun_node = first_in_group("scr_sun");
    if (sun_node != nullptr) {
        DirectionalLight3D *sun = Object::cast_to<DirectionalLight3D>(sun_node);
        if (sun == nullptr) {
            ERR_PRINT("SCR: group scr_sun must contain a DirectionalLight3D — skipped");
        } else {
            /* File header convention: +Z points at the sun, -Z emits. */
            sun->set_rotation(Vector3(-elevation, azimuth, 0.0f));
            sun->set_param(Light3D::PARAM_ENERGY, intensity);
            sun->set_color(Color(sr, sg, sb));
        }
    }

    /* SKY -> dome gradient derivation (contract §4.3 note, header "0004
     * adapter decisions"): zenith/horizon are not wire fields. */
    const float mix_h = SKY_HORIZON_SUN_MIX;
    const float hr = fr + (sr - fr) * mix_h;
    const float hg = fg + (sg - fg) * mix_h;
    const float hb = fb + (sb - fb) * mix_h;
    const float zr = hr * SKY_ZENITH_SCALE_R;
    const float zg = hg * SKY_ZENITH_SCALE_G;
    const float zb = hb * SKY_ZENITH_SCALE_B;
    const float sky_energy = SKY_ENERGY_MIN +
        (1.0f - SKY_ENERGY_MIN) * (intensity > 1.0f ? 1.0f : intensity);

    Node *env_node = first_in_group("scr_env");
    if (env_node != nullptr) {
        WorldEnvironment *we = Object::cast_to<WorldEnvironment>(env_node);
        if (we == nullptr) {
            ERR_PRINT("SCR: group scr_env must contain a WorldEnvironment — skipped");
            return;
        }
        Ref<Environment> env = we->get_environment();
        if (env.is_null()) {
            env.instantiate(); /* presentation resource, scene omitted it */
            we->set_environment(env);
        }
        /* Fog directly from SKY fields — no scene-side literal (AP-17). */
        env->set_fog_enabled(true);
        env->set_fog_density(fog_density);
        env->set_fog_light_color(Color(fr, fg, fb));

        /* Dome gradient (display derivation, AP-17). */
        Ref<Sky> sky_res = env->get_sky();
        if (sky_res.is_null()) {
            sky_res.instantiate();
            env->set_sky(sky_res);
        }
        if (sky_res.is_valid()) {
            Ref<Material> raw = sky_res->get_material();
            Ref<ProceduralSkyMaterial> mat = raw;
            if (mat.is_null()) {
                if (raw.is_valid()) {
                    ERR_PRINT("SCR: sky material is not a "
                              "ProceduralSkyMaterial — gradient skipped");
                } else {
                    mat.instantiate();
                    sky_res->set_material(mat);
                }
            }
            if (mat.is_valid()) {
                mat->set_sky_top_color(Color(zr, zg, zb));
                mat->set_sky_horizon_color(Color(hr, hg, hb));
                mat->set_ground_horizon_color(Color(hr, hg, hb));
                mat->set_ground_bottom_color(
                    Color(zr * SKY_GROUND_DARKEN, zg * SKY_GROUND_DARKEN,
                          zb * SKY_GROUND_DARKEN));
                mat->set_sky_energy_multiplier(sky_energy);
                mat->set_energy_multiplier(sky_energy);
            }
        }
    }
}

/* Milestone 0004 — clouds (cloud_cover), rain (precipitation), wetness.
 * Pure representation conversion of SKY bytes; constants documented in the
 * file header ("0004 adapter decisions") and docs/04 §6.6. */
void ScrSimDriver::apply_weather(const scr::SnapshotView &sv) {
    if (sv.sky == nullptr) {
        return;
    }
    const float cover = scr::rd_f32(sv.sky + 44);
    const float precip = scr::rd_f32(sv.sky + 48);

    /* --- clouds: cloud_cover uniform (AP-17: uniform only, noise display) */
    if (cover != cloud_cover_cache_) {
        cloud_cover_cache_ = cover;
        Node *n = first_in_group("scr_clouds");
        if (n != nullptr) {
            MeshInstance3D *mi = Object::cast_to<MeshInstance3D>(n);
            if (mi == nullptr) {
                ERR_PRINT("SCR: group scr_clouds must contain a MeshInstance3D — skipped");
            } else {
                Ref<Material> rm = mi->get_surface_override_material(0);
                if (rm.is_null()) {
                    rm = mi->get_material_override();
                }
                ShaderMaterial *sm = Object::cast_to<ShaderMaterial>(rm.ptr());
                if (sm == nullptr) {
                    ERR_PRINT("SCR: scr_clouds needs a ShaderMaterial — skipped");
                } else {
                    sm->set_shader_parameter("cloud_cover", cover);
                }
            }
        }
    }

    /* --- rain: amount_ratio drives count AND emission rate (no system
     * restart, unlike set_amount). precipitation = 0 => fully emitting-off. */
    const int emitting = (precip > 0.0f) ? 1 : 0;
    if (emitting != rain_emitting_cache_ ||
        precip != rain_ratio_cache_) {
        rain_emitting_cache_ = emitting;
        rain_ratio_cache_ = precip;
        Node *n = first_in_group("scr_rain");
        if (n != nullptr) {
            GPUParticles3D *p = Object::cast_to<GPUParticles3D>(n);
            if (p == nullptr) {
                ERR_PRINT("SCR: group scr_rain must contain a GPUParticles3D — skipped");
            } else {
                p->set_amount_ratio(precip);
                p->set_emitting(emitting != 0);
            }
        }
    }

    /* --- wetness: applied inside update_materials() (see there) so the
     * catalog rewrite each frame does not erase it. */
}

void ScrSimDriver::apply_materials_node(const scr::SnapshotView &sv) {
    Node *n = first_in_group("scr_materials");
    if (n == nullptr) {
        return;
    }
    Dictionary d;
    for (const scr::MatRecord &r : sv.materials) {
        Dictionary entry;
        entry["albedo"] =
            Color(r.albedo[0], r.albedo[1], r.albedo[2], r.opacity);
        entry["roughness"] = r.roughness;
        entry["emissive"] =
            Color(r.emissive[0], r.emissive[1], r.emissive[2]);
        entry["opacity"] = r.opacity;
        d[Variant((int64_t)r.id)] = entry;
    }
    n->set_meta("materials", Variant(d));
}

/* Schema 2 §7 VOLCANO: lava disc geometry + crust/emissive uniforms, plus the
 * sim-computed crater glow light (AP-11: glow comes from the section, the
 * adapter never re-derives "night"). Both groups are optional. */
void ScrSimDriver::apply_volcano(const scr::SnapshotView &sv) {
    if (sv.volcano == nullptr) {
        return;
    }
    const float center_x = scr::rd_f32(sv.volcano + 0);
    const float center_z = scr::rd_f32(sv.volcano + 4);
    const float radius = scr::rd_f32(sv.volcano + 8);
    const float lake_level = scr::rd_f32(sv.volcano + 12);
    const float emissive = scr::rd_f32(sv.volcano + 16);
    const float crust = scr::rd_f32(sv.volcano + 20);
    const float glow = scr::rd_f32(sv.volcano + 24);
    /* +28 u8 effusion_state (validated at decode), +29..31 pad — no display
     * state is derived from them: the sim already folded effusion into
     * emissive/crust/rate (AP-11). */

    Node *lava_node = first_in_group("scr_crater_lava");
    if (lava_node != nullptr) {
        MeshInstance3D *mi = Object::cast_to<MeshInstance3D>(lava_node);
        if (mi == nullptr) {
            ERR_PRINT("SCR: group scr_crater_lava must contain a MeshInstance3D — skipped");
        } else {
            /* Unit CylinderMesh disc (scene) scaled to the contract geometry:
             * position (center_x, lake_level, center_z), scale (radius,1,radius)
             * so the 0.2 u thickness stays display-constant (file header). */
            mi->set_global_position(Vector3(center_x, lake_level, center_z));
            mi->set_scale(Vector3(radius, 1.0f, radius));

            ShaderMaterial *sm = nullptr;
            Ref<Mesh> mesh = mi->get_mesh();
            if (mesh.is_valid() && mesh->get_surface_count() > 0) {
                sm = Object::cast_to<ShaderMaterial>(
                    mi->get_surface_override_material(0).ptr());
            }
            if (sm == nullptr) {
                sm = Object::cast_to<ShaderMaterial>(mi->get_material_override().ptr());
            }
            if (sm == nullptr) {
                ERR_PRINT("SCR: scr_crater_lava mesh has no ShaderMaterial — skipped");
            } else {
                sm->set_shader_parameter(StringName("emissive_intensity"),
                                         Variant(emissive));
                sm->set_shader_parameter(StringName("crust_fraction"),
                                         Variant(crust));
                sm->set_shader_parameter(StringName("radius"), Variant(radius));
            }
        }
    }

    Node *glow_node = first_in_group("scr_crater_glow");
    if (glow_node != nullptr) {
        OmniLight3D *light = Object::cast_to<OmniLight3D>(glow_node);
        if (light == nullptr) {
            ERR_PRINT("SCR: group scr_crater_glow must contain an OmniLight3D — skipped");
        } else {
            /* Display lift: light centre must clear the crater rim (rim
             * crest ~y38, lake_level ~y10.3 => need ~28 u) or every visible
             * outer slope has NdotL < 0 against a light sitting below it and
             * the night capture shows zero glow (measured: max r-b = -21 on
             * the spawn view, spec §7 wants a glow spot above background).
             * +1 u was not enough: light stayed buried inside the bowl.
             * Scene-side display constant only — light_energy stays the
             * sim-computed glow_intensity (AP-11). Documented docs/04 §5. */
            light->set_global_position(
                Vector3(center_x, lake_level + GLOW_DISPLAY_LIFT_U, center_z));
            light->set_param(Light3D::PARAM_ENERGY, glow);
        }
    }
}

/* Schema 2 §8 PLUME: emission parameters only; the GPU integrates (locked,
 * milestone_0003 §1.1). rate == 0 ⇒ idle emitter (contraction by 1 tick). */
void ScrSimDriver::apply_plume(const scr::SnapshotView &sv) {
    if (sv.plume == nullptr) {
        return;
    }
    const float ox = scr::rd_f32(sv.plume + 0);
    const float oy = scr::rd_f32(sv.plume + 4);
    const float oz = scr::rd_f32(sv.plume + 8);
    const float rate = scr::rd_f32(sv.plume + 12);
    const float velocity = scr::rd_f32(sv.plume + 16);
    const float spread = scr::rd_f32(sv.plume + 20);
    const float turbulence = scr::rd_f32(sv.plume + 24);
    const float lifetime = scr::rd_f32(sv.plume + 28);

    Node *n = first_in_group("scr_plume");
    if (n == nullptr) {
        return;
    }
    GPUParticles3D *p = Object::cast_to<GPUParticles3D>(n);
    if (p == nullptr) {
        ERR_PRINT("SCR: group scr_plume must contain a GPUParticles3D — skipped");
        return;
    }

    p->set_global_position(Vector3(ox, oy, oz));
    p->set_lifetime(lifetime);

    /* Godot emits `amount` particles per `lifetime` seconds, so the contract
     * rate (particles/s) needs amount = round(rate · lifetime). */
    int want_amount = (int)std::lround((double)rate * (double)lifetime);
    if (want_amount < 1) {
        want_amount = 1;
    }
    if (want_amount > 4096) {
        want_amount = 4096;
    }
    if (want_amount != plume_amount_cache_) {
        p->set_amount(want_amount);
        plume_amount_cache_ = want_amount;
    }

    const int want_emitting = rate > 0.0f ? 1 : 0;
    if (want_emitting != plume_emitting_cache_) {
        p->set_emitting(want_emitting != 0);
        plume_emitting_cache_ = want_emitting;
    }

    /* get_process_material() returns Ref<Material>; narrow to the concrete
     * particle material (the node keeps its own Ref, so this pointer stays
     * valid for the call). */
    ParticleProcessMaterial *pm =
        Object::cast_to<ParticleProcessMaterial>(p->get_process_material().ptr());
    if (pm == nullptr) {
        ERR_PRINT("SCR: scr_plume has no ParticleProcessMaterial — params skipped");
        return;
    }
    /* Contract params written as min == max (no randomization on a field the
     * sim already owns). Display-only spread/turbulence maps are recorded in
     * docs/04 §5. */
    pm->set_param_min(ParticleProcessMaterial::PARAM_INITIAL_LINEAR_VELOCITY,
                      velocity);
    pm->set_param_max(ParticleProcessMaterial::PARAM_INITIAL_LINEAR_VELOCITY,
                      velocity);
    pm->set_spread(spread);
    pm->set_turbulence_enabled(turbulence > 0.0f);
    /* Godot 4.7 velocity-influence turbulence relaxes each particle's
     * velocity toward the noise field, collapsing the buoyant column
     * (measured: influence 0.005 -> ~26 u plume vs 54 u ballistic, and the
     * stall height is independent of initial velocity at higher influence).
     * The contract still owns the turbulence amount: it gates the noise
     * field enable, while influence is held at 0 so buoyancy (locked by
     * 0003 spec §1.1) survives. Evidence + rejected alternatives recorded in
     * docs/04_simulation_engine.md §8. */
    pm->set_param_min(ParticleProcessMaterial::PARAM_TURB_VEL_INFLUENCE, 0.0f);
    pm->set_param_max(ParticleProcessMaterial::PARAM_TURB_VEL_INFLUENCE, 0.0f);
}

/* --- milestone 0006: ecology view dispatch (spec §5) ---------------------
 * The adapter owns DECODE (strict, above) and color resolution only; the
 * MultiMesh/pool construction lives in scripts/flora_view.gd +
 * scripts/fauna_view.gd (scene interface, file header). Missing groups are
 * tolerated; present hosts without the method warn once and are skipped. */
Dictionary ScrSimDriver::flora_materials() {
    /* Species -> {albedo, roughness}: MATERIALS record with id ==
     * catalog_index wins, else the scr::kSpeciesDisplay mirror (0006 AP-14). */
    Dictionary d;
    for (uint32_t s = 1; s <= scr::kFloraSpeciesMax; s++) {
        const scr::SpeciesDisplay &sd = scr::kSpeciesDisplay[s];
        Dictionary entry;
        auto rec = mat_records_.find(sd.catalog_index);
        if (rec != mat_records_.end()) {
            entry["albedo"] = Color(rec->second.albedo[0], rec->second.albedo[1],
                                    rec->second.albedo[2], 1.0f);
            entry["roughness"] = rec->second.roughness;
        } else {
            entry["albedo"] =
                Color(sd.albedo[0], sd.albedo[1], sd.albedo[2], 1.0f);
            entry["roughness"] = sd.roughness;
        }
        d[Variant((int64_t)s)] = entry;
    }
    return d;
}

void ScrSimDriver::apply_flora(const scr::SnapshotView &sv) {
    /* Emission-gated (0006 invariant 5): an absent §10 NEVER clears the
     * cached instances — simply do not touch the view. */
    if (!sv.has_flora || sv.flora == nullptr) {
        return;
    }
    Node *n = first_in_group("scr_flora");
    if (n == nullptr) {
        return;
    }
    if (!n->has_method("apply_flora")) {
        if (!flora_method_warned_) {
            ERR_PRINT("SCR: group scr_flora host lacks apply_flora "
                      "(scripts/flora_view.gd missing?) — FLORA skipped");
            flora_method_warned_ = true;
        }
        return;
    }
    const uint64_t nbytes = (uint64_t)scr::kFloraHeaderBytes +
                             (uint64_t)scr::kFloraRecordBytes * sv.flora_count;
    PackedByteArray bytes;
    bytes.resize((int64_t)nbytes);
    memcpy(bytes.ptrw(), sv.flora, (size_t)nbytes);
    Array args;
    args.append(bytes);
    args.append(flora_materials());
    n->callv("apply_flora", args);
}

void ScrSimDriver::apply_fauna(const scr::SnapshotView &sv) {
    /* FAUNA is REQUIRED every snapshot (decode enforces it). */
    if (sv.fauna == nullptr) {
        return;
    }
    Node *n = first_in_group("scr_fauna");
    if (n == nullptr) {
        return;
    }
    if (!n->has_method("apply_fauna")) {
        if (!fauna_method_warned_) {
            ERR_PRINT("SCR: group scr_fauna host lacks apply_fauna "
                      "(scripts/fauna_view.gd missing?) — FAUNA skipped");
            fauna_method_warned_ = true;
        }
        return;
    }
    const uint64_t nbytes = (uint64_t)scr::kFaunaHeaderBytes +
                             (uint64_t)scr::kFaunaRecordBytes * sv.fauna_count;
    PackedByteArray bytes;
    bytes.resize((int64_t)nbytes);
    memcpy(bytes.ptrw(), sv.fauna, (size_t)nbytes);
    Array args;
    args.append(bytes);
    n->callv("apply_fauna", args);
}

void ScrSimDriver::apply_terrain(const scr::SnapshotView &sv) {
    if (!sv.has_terrain) {
        return; /* 104_contract §4.3: keep existing meshes */
    }
    Node *n = first_in_group("scr_terrain");
    if (n == nullptr) {
        return; /* terrain group absent -> leave meshes alone */
    }
    Node3D *terrain = Object::cast_to<Node3D>(n);
    if (terrain == nullptr) {
        ERR_PRINT("SCR: group scr_terrain must contain a Node3D — skipped");
        return;
    }

    const int64_t chunk_count = (int64_t)sv.chunks.size();

    /* Drop stale chunks (world regeneration shrank the chunk list). */
    for (int32_t c = terrain->get_child_count() - 1; c >= 0; c--) {
        Node *child = terrain->get_child(c);
        if (child == nullptr) {
            continue;
        }
        const String nm = child->get_name();
        if (!nm.begins_with("Chunk_")) {
            continue;
        }
        if (nm.substr(6).to_int() >= chunk_count) {
            child->queue_free();
        }
    }

    for (int64_t i = 0; i < chunk_count; i++) {
        const scr::ChunkView &cv = sv.chunks[(size_t)i];
        const String cname = String("Chunk_") + String::num_int64(i);

        Node *existing = terrain->get_node_or_null(NodePath(cname));
        MeshInstance3D *mi = Object::cast_to<MeshInstance3D>(existing);
        if (mi == nullptr) {
            if (existing != nullptr) {
                ERR_PRINT(String("SCR: terrain child ") + cname +
                          " exists but is not a MeshInstance3D — skipped");
                continue;
            }
            mi = memnew(MeshInstance3D);
            mi->set_name(cname);
            terrain->add_child(mi);
        }

        /* Group triangles by the per-vertex DOMINANT material id (triangle
         * -> first vertex's id); one mesh surface per dominant material.
         * Vertices are world-space; origin kept as provenance meta only.
         *
         * Schema 4 (0005 §1.1 (b)): each emitted vertex carries its blended
         * catalog albedo as ARRAY_COLOR —
         *   COLOR = mix(albedo[dominant], albedo[blend], weight/255)
         * — which multiplies the material's albedo_color (wetness gain) at
         * shading time. This is representation conversion only: surfaces are
         * STILL grouped by dominant id, no material is assigned from data
         * beyond the existing dominant record (AP-20). */
        struct Surf {
            PackedVector3Array verts;
            PackedVector3Array norms;
            PackedColorArray cols;
            PackedInt32Array indices;
        };
        std::unordered_map<uint32_t, Surf> surfs;
        std::unordered_map<uint32_t, std::unordered_map<uint32_t, uint32_t>> remap;

        const uint32_t tris = cv.icount / 3u;
        for (uint32_t t = 0; t < tris; t++) {
            uint32_t corner[3];
            corner[0] = cv.idx[3u * t + 0];
            corner[1] = cv.idx[3u * t + 1];
            corner[2] = cv.idx[3u * t + 2];
            const uint32_t mid = cv.dominant_at(corner[0]);
            Surf &s = surfs[mid];
            std::unordered_map<uint32_t, uint32_t> &m = remap[mid];
            uint32_t out3[3];
            for (int k = 0; k < 3; k++) {
                const uint32_t old = corner[k];
                auto it = m.find(old);
                if (it == m.end()) {
                    const uint32_t fresh = (uint32_t)s.verts.size();
                    s.verts.append(Vector3(cv.verts[3u * old + 0],
                                           cv.verts[3u * old + 1],
                                           cv.verts[3u * old + 2]));
                    s.norms.append(Vector3(cv.norms[3u * old + 0],
                                           cv.norms[3u * old + 1],
                                           cv.norms[3u * old + 2]));
                    Color c = albedo_of(cv.dominant_at(old));
                    const uint8_t w = cv.weight_at(old);
                    if (w > 0u) {
                        c = c.lerp(albedo_of(cv.blend_at(old)), w / 255.0f);
                    }
                    s.cols.append(c);
                    m.emplace(old, fresh);
                    out3[k] = fresh;
                } else {
                    out3[k] = it->second;
                }
            }
            /* Godot front face = clockwise (file header "TRIANGLE WINDING"):
             * reverse the sim's CCW order so CULL_BACK keeps the outward
             * faces instead of discarding them. */
            s.indices.append((int32_t)out3[0]);
            s.indices.append((int32_t)out3[2]);
            s.indices.append((int32_t)out3[1]);
        }

        Ref<ArrayMesh> mesh;
        mesh.instantiate();
        int32_t surface = 0;
        for (auto &kv : surfs) {
            Array arrays;
            arrays.resize(Mesh::ARRAY_MAX);
            arrays[Mesh::ARRAY_VERTEX] = kv.second.verts;
            arrays[Mesh::ARRAY_NORMAL] = kv.second.norms;
            arrays[Mesh::ARRAY_COLOR] = kv.second.cols;
            arrays[Mesh::ARRAY_INDEX] = kv.second.indices;
            mesh->add_surface_from_arrays(Mesh::PRIMITIVE_TRIANGLES, arrays);
            mesh->surface_set_material(surface, material_for(kv.first));
            surface++;
        }

        mi->set_mesh(mesh);
        mi->set_meta("origin",
                     Variant(Vector3(cv.origin[0], cv.origin[1], cv.origin[2])));
    }
}

// ---------------------------------------------------------------------------
// GDExtension entry point
// ---------------------------------------------------------------------------

namespace {

void scr_initialize(ModuleInitializationLevel p_level) {
    if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
        return;
    }
    GDREGISTER_CLASS(ScrSimDriver);
    UtilityFunctions::print(
        "SCR GDExtension adapter registered (Godot class 'ScrSim')");
}

void scr_uninitialize(ModuleInitializationLevel p_level) {
    if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
        return;
    }
}

} // namespace

extern "C" {

GDExtensionBool gdextension_init(
    GDExtensionInterfaceGetProcAddress p_get_proc_address,
    GDExtensionClassLibraryPtr p_library,
    GDExtensionInitialization *r_initialization) {
    GDExtensionBinding::InitObject init_obj(p_get_proc_address, p_library,
                                            r_initialization);
    init_obj.register_initializer(scr_initialize);
    init_obj.register_terminator(scr_uninitialize);
    init_obj.set_minimum_library_initialization_level(
        MODULE_INITIALIZATION_LEVEL_SCENE);
    return init_obj.init();
}

} // extern "C"
