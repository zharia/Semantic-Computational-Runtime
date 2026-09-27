# Runtime — process-global simulation handle for the C ABI.
#
# No module-level mutable globals exist in Mojo, and the 7 ABI symbols are
# independent calls into one process, so the handle lives on the heap:
# `std.memory.alloc` once, address parked in the `SCR_SIM_HANDLE` env var,
# recovered per call through a mutable untracked pointer.
#
# Shutdown frees all handle CONTENTS (world grids, snapshot buffer) by
# move-replacing them; the fixed handle block itself is leaked deliberately
# (one small block per process — `dealloc` only accepts an `Allocation`, which
# cannot be reconstructed from a raw address). Recorded in the final report.
#
# TERRAIN emission rule (104_contract §4.3): TERRAIN section is included only
# when `world_version != last_terrain_emitted`; the tracker lives here, outside
# World (projection must not mutate world state).

from std.memory import Layout, alloc, Pointer
from std.ffi import external_call, c_int, c_char

from sim.world import World, world_init, step_world
from sim.input import InputBatch, idle_input
from snapshot.encode import encode_snapshot
from sim.parameters import SCR_ERR_NOT_INIT, SCR_ERR_BAD_STATE

comptime HANDLE_ENV: String = "SCR_SIM_HANDLE"

struct SimHandle(Movable, Deinitable):
    var initialized: Bool
    var stepped: Bool  # false until the first successful scr_sim_step
    var last_terrain_emitted: UInt32  # world_version of last TERRAIN send
    var world: World
    var snapshot: List[UInt8]  # bytes from the most recent successful step

    def __init__(out self):
        self.initialized = False
        self.stepped = False
        self.last_terrain_emitted = 0
        self.world = World(0)
        self.snapshot = List[UInt8]()

    def __deinit__(deinit self):
        pass


# --- Env-var address plumbing ----------------------------------------------

def _cstr_to_string(p: Pointer[mut=False, c_char, ImmUntrackedOrigin]) -> String:
    if Int(p) == 0:
        return ""
    var out = String()
    var i = 0
    while True:
        var b = p[unsafe_offset=i]
        var ib = Int(b)
        if ib == 0:
            break
        if ib < 0:
            ib += 256
        out = out + chr(ib)
        i += 1
        if i > 64:
            break
    return out^


def _parse_dec(s: String) -> UInt64:
    var acc: UInt64 = 0
    for b in s.bytes():
        var c = Int(b)
        if c < 48 or c > 57:
            return 0
        acc = acc * 10 + UInt64(c - 48)
    return acc


def _read_handle_addr() -> UInt64:
    var name = HANDLE_ENV
    var p = external_call["getenv", Pointer[mut=False, c_char, ImmUntrackedOrigin]](
        name.unsafe_ptr()
    )
    if Int(p) == 0:
        return 0
    return _parse_dec(_cstr_to_string(p))


def _write_handle_addr(addr: UInt64):
    var name = HANDLE_ENV
    var value = String(addr)
    _ = external_call["setenv", c_int](name.unsafe_ptr(), value.unsafe_ptr(), c_int(1))


def _clear_handle_addr():
    var name = HANDLE_ENV
    _ = external_call["unsetenv", c_int](name.unsafe_ptr())


# --- Handle lifecycle -------------------------------------------------------

def runtime_acquire() raises -> Pointer[mut=True, SimHandle, MutUntrackedOrigin]:
    """Fetch the process-global handle, allocating it on first use."""
    var addr = _read_handle_addr()
    if addr == 0:
        var al = alloc(Layout[SimHandle](count=1))
        var p = al^.unsafe_leak()
        addr = UInt64(Int(p))
        var q = Pointer[mut=True, SimHandle, MutUntrackedOrigin](
            unsafe_from_address=Int(addr)
        )
        q[] = SimHandle()
        _write_handle_addr(addr)
        return q
    return Pointer[mut=True, SimHandle, MutUntrackedOrigin](
        unsafe_from_address=Int(addr)
    )


def runtime_is_initialized() -> Bool:
    var addr = _read_handle_addr()
    if addr == 0:
        return False
    var q = Pointer[mut=True, SimHandle, MutUntrackedOrigin](
        unsafe_from_address=Int(addr)
    )
    return q[].initialized


def runtime_init(seed: UInt32) -> Int32:
    """Create world + empty snapshot state. Returns 0, or SCR_ERR_BAD_STATE."""
    try:
        var h = runtime_acquire()
        # Re-init: release previous contents first (deterministic fresh start).
        if h[].initialized:
            h[].world = World(seed)
            h[].snapshot = List[UInt8]()
            h[].stepped = False
            h[].last_terrain_emitted = 0
        h[].world = world_init(seed)
        h[].snapshot = List[UInt8]()
        h[].stepped = False
        h[].last_terrain_emitted = 0  # world_version == 1 ⇒ first snapshot emits
        h[].initialized = True
        return 0
    except e:
        return SCR_ERR_BAD_STATE


def runtime_shutdown():
    """Release handle contents; safe when never initialized (no-op)."""
    var addr = _read_handle_addr()
    if addr == 0:
        return
    var h = Pointer[mut=True, SimHandle, MutUntrackedOrigin](
        unsafe_from_address=Int(addr)
    )
    if h[].initialized:
        h[].world = World(0)  # move-assign frees the old world's grids
        h[].snapshot = List[UInt8]()
        h[].stepped = False
        h[].last_terrain_emitted = 0
        h[].initialized = False
    # Address stays in the env var: the (now empty) handle block is reused by
    # a later init. Block freed only by process exit — see file header.


def runtime_step(frame_dt: Float64, input: InputBatch) -> Int32:
    """Run 0..n fixed ticks, then (re)project the snapshot.
    Returns ticks executed, or SCR_ERR_NOT_INIT / SCR_ERR_BAD_STATE."""
    var addr = _read_handle_addr()
    if addr == 0:
        return SCR_ERR_NOT_INIT
    var h = Pointer[mut=True, SimHandle, MutUntrackedOrigin](
        unsafe_from_address=Int(addr)
    )
    if not h[].initialized:
        return SCR_ERR_NOT_INIT
    try:
        var ticks = step_world(h[].world, frame_dt, input)
        # TERRAIN only when (re)generation happened since last sent snapshot.
        var include_terrain = h[].world.world_version != h[].last_terrain_emitted
        h[].snapshot = encode_snapshot(h[].world, include_terrain)
        h[].last_terrain_emitted = h[].world.world_version
        h[].stepped = True
        return ticks
    except e:
        return SCR_ERR_BAD_STATE


def runtime_snapshot_size() -> Int32:
    """Bytes of the snapshot from the most recent successful step (0 before)."""
    var addr = _read_handle_addr()
    if addr == 0:
        return 0
    var h = Pointer[mut=True, SimHandle, MutUntrackedOrigin](
        unsafe_from_address=Int(addr)
    )
    if not h[].initialized or not h[].stepped:
        return 0
    return Int32(len(h[].snapshot))


def runtime_snapshot_write(buf: Pointer[mut=True, UInt8, MutUntrackedOrigin], cap: Int) -> Int32:
    """Copy the cached snapshot into buf. Returns bytes written or SCR_ERR_*:
    NOT_INIT before init, BAD_STATE before the first step, BUF_SMALL if cap
    cannot hold the snapshot (104_contract §3)."""
    var addr = _read_handle_addr()
    if addr == 0:
        return SCR_ERR_NOT_INIT
    var h = Pointer[mut=True, SimHandle, MutUntrackedOrigin](
        unsafe_from_address=Int(addr)
    )
    if not h[].initialized:
        return SCR_ERR_NOT_INIT
    if not h[].stepped:
        return SCR_ERR_BAD_STATE
    var need = len(h[].snapshot)
    if cap < need:
        return -3  # SCR_ERR_BUF_SMALL
    for i in range(need):
        buf[unsafe_offset=i] = h[].snapshot[i]
    return Int32(need)
