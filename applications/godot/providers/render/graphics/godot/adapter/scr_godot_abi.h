/* SCR Godot render provider — C ABI between Mojo simulation core and the
 * Godot GDExtension adapter.
 *
 * Normative source: 104_contract.md (same directory).
 * Language: C11. Endianness: little-endian. All structs packed (explicit
 * layout, no implicit padding beyond what is documented).
 *
 * Provider rule: this boundary carries representation only. Godot is a
 * provider; it never owns scene semantics (docs/05_provider_boundary.md).
 */
#ifndef SCR_GODOT_ABI_H
#define SCR_GODOT_ABI_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#define SCR_SIM_ABI_VERSION  1u  /* C ABI symbol-contract version (unchanged) */
/* Snapshot binary schema version. 4 -> 5 (milestone_0006): NEW section 10
 * FLORA (u32 count + count * 24 B records; emission-gated like TERRAIN) and
 * NEW section 11 FAUNA (u32 count + count * 20 B records, every snapshot);
 * sections 1-9 byte-identical to schema 4. Symbol set unchanged. Adapter
 * refuses any library whose scr_sim_schema_version() != this value. */
#define SCR_SIM_SCHEMA_VER   5u

/* Snapshot section identifiers (104_contract.md §4). */
#define SCR_SEC_PLAYER       1u
#define SCR_SEC_TERRAIN_META 2u
#define SCR_SEC_TERRAIN      3u
#define SCR_SEC_OCEAN        4u
#define SCR_SEC_SKY          5u
#define SCR_SEC_MATERIALS    6u
#define SCR_SEC_VOLCANO      7u  /* schema 2 (milestone_0003 §3.2) */
#define SCR_SEC_PLUME        8u
#define SCR_SEC_SHORE_FOAM   9u  /* schema 4 (milestone_0005 §3.3) */
#define SCR_SEC_FLORA        10u /* schema 5 (milestone_0006 §1.1) */
#define SCR_SEC_FAUNA        11u /* schema 5 (milestone_0006 §1.1) */

/* Snapshot magic: bytes 'S','C','R','S' read as little-endian u32. */
#define SCR_SNAPSHOT_MAGIC   0x53524353u

/* Error codes (negative returns). */
#define SCR_ERR_NOT_INIT     (-1)
#define SCR_ERR_ABI_MISMATCH (-2)
#define SCR_ERR_BUF_SMALL    (-3)
#define SCR_ERR_BAD_STATE    (-4)

/* Input uplink: raw player intent captured by Godot, integrated by the sim.
 * Size: 20 bytes, packed. Per fixed tick batch (104_contract.md §5). */
typedef struct scr_input_batch {
    float    move_x;           /* [-1,1] strafe  (right = +x) */
    float    move_y;           /* [-1,1] forward (forward = +y) */
    float    look_dx;          /* yaw delta (radians, accumulated per frame) */
    float    look_dy;          /* pitch delta (radians) */
    uint8_t  jump;
    uint8_t  sprint;
    uint8_t  action_primary;
    uint8_t  action_secondary;
} scr_input_batch;

/* --- Lifecycle ---------------------------------------------------------- */

/* Initialize the simulation runtime and create the world.
 * seed: world generation seed. MUST be the first call; it performs Mojo
 * runtime initialization (host is non-Mojo). Returns 0 on success. */
int32_t scr_sim_init(uint32_t seed);

/* Tear down the simulation. Safe to call once after init; no-op otherwise. */
void scr_sim_shutdown(void);

/* SCR_SIM_ABI_VERSION of the loaded library; adapter refuses mismatch. */
uint32_t scr_sim_abi_version(void);

/* SCR_SIM_SCHEMA_VER of snapshots produced; adapter refuses mismatch. */
uint32_t scr_sim_schema_version(void);

/* --- Stepping ----------------------------------------------------------- */

/* Advance simulation by frame_dt seconds of wall-clock presentation time.
 * Internally accumulates toward the fixed tick rate (60 Hz) and executes
 * zero or more fixed ticks, applying `in` (NULL = idle) to each executed
 * tick. Returns the number of fixed ticks executed (>= 0), or a negative
 * SCR_ERR_* code. Determinism contract: a sequence of calls with
 * dt == 1.666...ms yields exactly one tick each and a deterministic
 * snapshot sequence for a fixed seed + input sequence. */
int32_t scr_sim_step(double frame_dt, const scr_input_batch *in);

/* --- Snapshot downlink -------------------------------------------------- */

/* Byte size of the snapshot produced by the most recent successful step. */
uint32_t scr_sim_snapshot_size(void);

/* Serialize the most recent snapshot into buf (little-endian layout,
 * 104_contract.md §4). Returns bytes written (>= 0), or:
 *  SCR_ERR_BUF_SMALL (-3) when cap < required size,
 *  SCR_ERR_NOT_INIT / SCR_ERR_BAD_STATE otherwise. */
int32_t scr_sim_snapshot_write(uint8_t *buf, uint32_t cap);

#ifdef __cplusplus
} /* extern "C" */
#endif

#endif /* SCR_GODOT_ABI_H */
