# C ABI exports — exact symbols of adapter/scr_godot_abi.h (104_contract §3).
#
# Build:  mojo build export/abi.mojo -I src/mojo --emit shared-lib -o libscr_sim.so
# Entry exports are `abi("C")` and never `raises`: every fallible path maps
# to a SCR_ERR_* code (header §Error codes).
#
# Threading: the contract is single-threaded for this milestone; the adapter
# serializes calls (milestone_0002 spec).

from std.ffi import c_int, c_char
from std.runtime import initialize_runtime

from sim.input import InputBatch, idle_input
from sim.parameters import (
    ABI_VERSION,
    SCHEMA_VERSION,
    SCR_ERR_NOT_INIT,
    SCR_ERR_BAD_STATE,
    SCR_ERR_QUEUE_FULL,
)
from sim.runtime import (
    runtime_init,
    runtime_shutdown,
    runtime_step,
    runtime_snapshot_size,
    runtime_snapshot_write,
    runtime_edit_submit,
)


struct EditBatch(Copyable, Movable, Deinitable, ImplicitlyCopyable):
    """Mirror of adapter/scr_edit_batch (0007 §3.2): u8 op, u8 select_slot,
    u16 reserved — 4 bytes packed, natural alignment 2 ⇒ size 4."""

    var op: UInt8
    var select_slot: UInt8
    var reserved: UInt16

    def __init__(out self):
        self.op = 0
        self.select_slot = 0
        self.reserved = 0

    def __deinit__(deinit self):
        pass


@export("scr_sim_init")
def scr_sim_init(seed: UInt32) abi("C") -> c_int:
    initialize_runtime()
    return c_int(Int(runtime_init(seed)))


@export("scr_sim_shutdown")
def scr_sim_shutdown() abi("C"):
    initialize_runtime()
    runtime_shutdown()


@export("scr_sim_abi_version")
def scr_sim_abi_version() abi("C") -> UInt32:
    initialize_runtime()
    return ABI_VERSION


@export("scr_sim_schema_version")
def scr_sim_schema_version() abi("C") -> UInt32:
    initialize_runtime()
    return SCHEMA_VERSION


@export("scr_sim_step")
def scr_sim_step(
    frame_dt: Float64, input: Pointer[mut=False, InputBatch, ImmUntrackedOrigin]
) abi("C") -> c_int:
    initialize_runtime()
    var batch = idle_input()
    if Int(input) != 0:
        # scr_input_batch and InputBatch have identical 20-byte layouts
        # (sim/input.mojo header): a copy is a representation transfer only.
        batch = input[]
    var ticks = runtime_step(frame_dt, batch)
    return c_int(Int(ticks))


@export("scr_sim_snapshot_size")
def scr_sim_snapshot_size() abi("C") -> UInt32:
    initialize_runtime()
    var n = runtime_snapshot_size()
    if n < 0:
        return 0
    return UInt32(n)


@export("scr_sim_snapshot_write")
def scr_sim_snapshot_write(
    buf: Pointer[mut=True, UInt8, MutUntrackedOrigin], cap: UInt32
) abi("C") -> c_int:
    initialize_runtime()
    if Int(buf) == 0:
        return c_int(-4)  # SCR_ERR_BAD_STATE (null destination)
    var written = runtime_snapshot_write(buf, Int(cap))
    return c_int(Int(written))


@export("scr_edit_submit")
def scr_edit_submit(
    batch: Pointer[mut=False, EditBatch, ImmUntrackedOrigin]
) abi("C") -> c_int:
    """Queue one scr_edit_batch (ABI 2, 0007 §3.2): select applies
    immediately, op is appended to the FIFO. Returns 0 / SCR_ERR_NOT_INIT /
    SCR_ERR_BAD_STATE (NULL or reserved != 0) / SCR_ERR_QUEUE_FULL."""
    initialize_runtime()
    if Int(batch) == 0:
        return c_int(Int(SCR_ERR_BAD_STATE))
    var b = batch[]
    if b.reserved != 0:
        return c_int(Int(SCR_ERR_BAD_STATE))
    return c_int(Int(runtime_edit_submit(b.op, b.select_slot)))
