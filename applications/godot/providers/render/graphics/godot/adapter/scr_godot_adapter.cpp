/* scr_godot_adapter.cpp — GDExtension adapter of the SCR Godot render
 * provider (providers/render/graphics/godot).
 *
 * Normative sources:
 *   - providers/render/graphics/godot/104_contract.md  (byte schema v1, C ABI)
 *   - providers/render/graphics/godot/101_definition.md (invariants)
 *   - applications/godot/program_increments/v0.0.1/
 *       milestone_0002_scene-initiation/spec.md §2 (AP-1..AP-10), §5 Sprint 03
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
 *   "scr_sun"      DirectionalLight3D one -> rotation/energy (see below)
 *   "scr_env"      WorldEnvironment  one  -> fog_density, fog_light_color
 *   "scr_camera"   Camera3D | Node3D one  -> player camera rig
 *   "scr_hud"      Label             one  -> "tick %d | gen %d | seed %d"
 *   "scr_materials" Node            one  -> meta "materials":
 *                                            Dictionary id -> {albedo,
 *                                            roughness, emissive, opacity}
 * Missing groups are tolerated (presentation simply absent); present-but-
 * mistyped nodes are reported with ERR_PRINT and skipped.
 *
 * Conventions (normative for Sprint-04 scene work):
 *   - YAW:    rotation.y = +yaw.  The sim's horizontal forward is
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
#include <godot_cpp/classes/label.hpp>
#include <godot_cpp/classes/mesh_instance3d.hpp>
#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/classes/node3d.hpp>
#include <godot_cpp/classes/project_settings.hpp>
#include <godot_cpp/classes/scene_tree.hpp>
#include <godot_cpp/classes/shader_material.hpp>
#include <godot_cpp/classes/standard_material3d.hpp>
#include <godot_cpp/classes/world_environment.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/error_macros.hpp>
#include <godot_cpp/core/property_info.hpp>
#include <godot_cpp/godot.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/dictionary.hpp>
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
constexpr uint32_t kSkyBytes = 32;

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

struct ChunkView {
    float origin[3] = { 0, 0, 0 };
    uint32_t vcount = 0;
    uint32_t icount = 0;
    const float *verts = nullptr;   // 3 * vcount
    const float *norms = nullptr;   // 3 * vcount
    const uint32_t *mats = nullptr; // vcount
    const uint32_t *idx = nullptr;  // icount
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
    const uint8_t *sky = nullptr;    // 32 bytes
    std::vector<MatRecord> materials;
    std::vector<ChunkView> chunks;
};

inline bool fail(String &err, const char *msg) {
    err = String(msg);
    return false;
}

/* Full framing + section validation. Returns false (with err) on ANY
 * violation: bad magic, size, schema, framing, section size, index bounds,
 * required-section absence, unknown section id, or meta/terrain disagreement. */
bool decode_snapshot(const uint8_t *buf, uint64_t len, SnapshotView &out,
                     String &err) {
    bool seen[7] = { false, false, false, false, false, false, false };

    if (buf == nullptr || len < kEnvelopeBytes) {
        return fail(err, "snapshot: shorter than envelope (48 bytes)");
    }
    if (rd_u32(buf + 0) != SCR_SNAPSHOT_MAGIC) {
        return fail(err, "snapshot: bad magic (expected 'SCRS')");
    }
    if (rd_u32(buf + 4) != SCR_SIM_SCHEMA_VER) {
        return fail(err, "snapshot: schema_version != 1");
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
        if (sid < 1u || sid > 6u) {
            return fail(err, "section: unknown section_id (schema v1 defines 1..6)");
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
                    return fail(err, "SKY: section must be exactly 32 bytes");
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
            default:
                return fail(err, "section: unhandled section_id");
        }

        off += kSectionHeaderBytes + sbytes;
    }

    if (walked != out.section_count) {
        return fail(err, "snapshot: section_count disagrees with framed sections");
    }
    /* Sections emitted in EVERY snapshot (104_contract §4.3). TERRAIN is the
     * only optional one (present on first snapshot / world_version bump). */
    if (!seen[SCR_SEC_PLAYER] || !seen[SCR_SEC_TERRAIN_META] ||
        !seen[SCR_SEC_OCEAN] || !seen[SCR_SEC_SKY] || !seen[SCR_SEC_MATERIALS]) {
        return fail(err, "snapshot: required section missing (PLAYER/TERRAIN_META/OCEAN/SKY/MATERIALS)");
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
            cv.mats = reinterpret_cast<const uint32_t *>(cv.norms + 3ull * cv.vcount);
            cv.idx = cv.mats + cv.vcount;
            for (uint32_t i = 0; i < cv.icount; i++) {
                if (cv.idx[i] >= cv.vcount) {
                    return fail(err, "TERRAIN: index out of vertex range");
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

    // --- helpers ------------------------------------------------------------
    Node *first_in_group(const StringName &p_group);
    void decode_and_apply(uint32_t len);
    void update_materials(const scr::SnapshotView &sv);
    Ref<StandardMaterial3D> material_for(uint32_t id);
    void apply_player(const scr::SnapshotView &sv);
    void apply_terrain_meta(const scr::SnapshotView &sv);
    void apply_terrain(const scr::SnapshotView &sv);
    void apply_ocean(const scr::SnapshotView &sv);
    void apply_sky(const scr::SnapshotView &sv);
    void apply_materials_node(const scr::SnapshotView &sv);
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

    /* Decode completed without error -> apply representation conversion.
     * Order: materials first (terrain surfaces derive from them). */
    update_materials(sv);
    apply_materials_node(sv);
    apply_terrain(sv);
    apply_terrain_meta(sv);
    apply_ocean(sv);
    apply_sky(sv);
    apply_player(sv);
    apply_hud(sv);
}

void ScrSimDriver::update_materials(const scr::SnapshotView &sv) {
    for (const scr::MatRecord &r : sv.materials) {
        mat_records_[r.id] = r;
        auto it = mat_cache_.find(r.id);
        if (it != mat_cache_.end() && it->second.is_valid()) {
            scr::apply_mat_props(it->second.ptr(), r);
        }
    }
}

Ref<StandardMaterial3D> ScrSimDriver::material_for(uint32_t id) {
    auto it = mat_cache_.find(id);
    if (it != mat_cache_.end()) {
        return it->second;
    }
    Ref<StandardMaterial3D> m;
    m.instantiate();
    auto rec = mat_records_.find(id);
    if (rec != mat_records_.end()) {
        scr::apply_mat_props(m.ptr(), rec->second);
    } else if (mat_missing_warned_.insert(id).second) {
        ERR_PRINT(String("SCR: no MATERIALS record for id ") +
                  String::num_uint64(id) + " — using neutral fallback material");
        m->set_albedo(Color(0.5f, 0.5f, 0.5f));
    }
    mat_cache_[id] = m;
    return m;
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
}

void ScrSimDriver::apply_sky(const scr::SnapshotView &sv) {
    if (sv.sky == nullptr) {
        return;
    }
    const float hours = scr::rd_f32(sv.sky + 0);
    const float azimuth = scr::rd_f32(sv.sky + 4);
    const float elevation = scr::rd_f32(sv.sky + 8);
    const float fog_density = scr::rd_f32(sv.sky + 12);
    const float fr = scr::rd_f32(sv.sky + 16);
    const float fg = scr::rd_f32(sv.sky + 20);
    const float fb = scr::rd_f32(sv.sky + 24);
    const float intensity = scr::rd_f32(sv.sky + 28);
    (void)hours; /* informational; sun angles are authoritative */

    Node *sun_node = first_in_group("scr_sun");
    if (sun_node != nullptr) {
        DirectionalLight3D *sun = Object::cast_to<DirectionalLight3D>(sun_node);
        if (sun == nullptr) {
            ERR_PRINT("SCR: group scr_sun must contain a DirectionalLight3D — skipped");
        } else {
            /* File header convention: +Z points at the sun, -Z emits. */
            sun->set_rotation(Vector3(-elevation, azimuth, 0.0f));
            sun->set_param(Light3D::PARAM_ENERGY, intensity);
        }
    }

    Node *env_node = first_in_group("scr_env");
    if (env_node != nullptr) {
        WorldEnvironment *we = Object::cast_to<WorldEnvironment>(env_node);
        if (we == nullptr) {
            ERR_PRINT("SCR: group scr_env must contain a WorldEnvironment — skipped");
        } else {
            Ref<Environment> env = we->get_environment();
            if (env.is_null()) {
                env.instantiate(); /* presentation resource, scene omitted it */
                we->set_environment(env);
            }
            env->set_fog_enabled(true);
            env->set_fog_density(fog_density);
            env->set_fog_light_color(Color(fr, fg, fb));
        }
    }
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

        /* Group triangles by per-vertex material id (triangle -> first
         * vertex's id); one mesh surface per material. Vertices are
         * world-space; origin kept as provenance meta only. */
        struct Surf {
            PackedVector3Array verts;
            PackedVector3Array norms;
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
            const uint32_t mid = cv.mats[corner[0]];
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
