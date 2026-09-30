# Spec test — Seabird flock (milestone_0006 §1.1 / §5 / §7, AP-13):
# over ≥600 ticks: count ≤ cap, all birds inside the ocean/beach bound,
# separation floor holds, speed/altitude clamps hold; run-twice determinism;
# the respawn rule fires without exceeding the cap. Headless (no Godot).
#
# NOTE on `assert`: this Mojo 1.0.0 toolchain compiles `assert` to a no-op.
# Every check below uses `_check`, which raises Error ⇒ TestSuite FAIL.

from std.collections import List
from std.testing import TestSuite
from std.math import sqrt

from sim.island import build_island
from sim.flock import (
    flock_from_island,
    flock_tick,
    flock_wire,
    flock_speed,
    flock_horizontal_r,
    FlockSubject,
)
from sim.parameters import (
    SEA_LEVEL,
    FLOCK_N_MAX,
    FLOCK_N_INIT,
    FLOCK_BOUND_RADIUS,
    FLOCK_SPEED_MIN,
    FLOCK_SPEED_MAX,
    FLOCK_MAX_ALTITUDE,
    FLOCK_SEPARATION_MIN,
    FLOCK_SEABIRD_SPECIES,
)
from snapshot.types import FlockBird

comptime BOUNDED_TICKS: Int = 600
comptime DETERMINISM_TICKS: Int = 120


def _check(cond: Bool, msg: String) raises:
    """Raise-based check (see header note: `assert` is a no-op here)."""
    if not cond:
        raise Error(msg)


def check_invariants(flock: FlockSubject, label: String) raises:
    """Per-tick oracle: cap, bound, altitude window, speed clamp, floor."""
    _check(flock.count == FLOCK_N_INIT, label + ": count == FLOCK_N_INIT")
    _check(flock.count <= FLOCK_N_MAX, label + ": count ≤ FLOCK_N_MAX")
    var n = 0
    for s in range(FLOCK_N_MAX):
        if not flock.birds[s].active:
            continue
        n += 1
        var b = flock.birds[s]
        var r = flock_horizontal_r(b)
        _check(r <= FLOCK_BOUND_RADIUS, label + ": inside ocean/beach bound")
        _check(
            b.y >= SEA_LEVEL + 1.0 and b.y <= FLOCK_MAX_ALTITUDE,
            label + ": altitude window",
        )
        var sp = flock_speed(b)
        _check(
            sp >= FLOCK_SPEED_MIN - 1.0e-9 and sp <= FLOCK_SPEED_MAX + 1.0e-9,
            label + ": speed clamp",
        )
    _check(n == flock.count, label + ": active slots == count")
    # Pairwise separation floor (0006 §7 / FLOCK_SEPARATION_MIN oracle).
    for i in range(FLOCK_N_MAX):
        if not flock.birds[i].active:
            continue
        for j in range(i + 1, FLOCK_N_MAX):
            if not flock.birds[j].active:
                continue
            var a = flock.birds[i]
            var c = flock.birds[j]
            var d = sqrt(
                (a.x - c.x) ** 2 + (a.y - c.y) ** 2 + (a.z - c.z) ** 2
            )
            _check(
                d >= FLOCK_SEPARATION_MIN - 1.0e-9,
                label + ": pairwise separation ≥ floor",
            )


def test_bounded_over_600_ticks() raises:
    """0006 §7: over ≥600 ticks count ≤ 64, birds within bound, separation
    floor holds (also exercises the speed/altitude clamps)."""
    var island = build_island(1)
    var flock = flock_from_island(island, 1)
    check_invariants(flock, "init")
    for tick in range(BOUNDED_TICKS):
        flock_tick(flock, island, UInt32(tick))
        check_invariants(flock, "tick " + String(tick + 1))


def test_run_twice_deterministic() raises:
    """0006 §6 invariant 4: identical bird state sequences for the same
    seed across two runs (position, velocity, yaw, respawn_count, active)."""
    var island_a = build_island(1)
    var island_b = build_island(1)
    var fa = flock_from_island(island_a, 1)
    var fb = flock_from_island(island_b, 1)
    for tick in range(DETERMINISM_TICKS):
        flock_tick(fa, island_a, UInt32(tick))
        flock_tick(fb, island_b, UInt32(tick))
        for s in range(FLOCK_N_MAX):
            var a = fa.birds[s]
            var b = fb.birds[s]
            _check(a.active == b.active, "active mismatch at tick " + String(tick))
            _check(
                a.respawn_count == b.respawn_count,
                "respawn_count mismatch at tick " + String(tick),
            )
            _check(
                a.x == b.x and a.y == b.y and a.z == b.z,
                "position mismatch at tick " + String(tick),
            )
            _check(
                a.vx == b.vx and a.vy == b.vy and a.vz == b.vz,
                "velocity mismatch at tick " + String(tick),
            )
            _check(a.yaw == b.yaw, "yaw mismatch at tick " + String(tick))
    # Construction itself is deterministic too.
    var f2 = flock_from_island(build_island(1), 1)
    var f3 = flock_from_island(build_island(1), 1)
    for s in range(FLOCK_N_MAX):
        _check(
            f2.birds[s].x == f3.birds[s].x
            and f2.birds[s].z == f3.birds[s].z
            and f2.birds[s].active == f3.birds[s].active,
            "construction not deterministic",
        )


def test_forced_respawn_fires_and_respects_cap() raises:
    """0006 §1.1/§5: a bound violation despawns the slot and respawns it from
    (seed, slot, respawn_count); count never exceeds the cap."""
    var island = build_island(1)
    var flock = flock_from_island(island, 1)
    var before = flock.birds[0].respawn_count
    # Displace slot 0 well past the bound (forced violation).
    flock.birds[0].x = FLOCK_BOUND_RADIUS + 90.0
    flock.birds[0].z = 0.0
    flock.birds[0].y = 10.0
    flock_tick(flock, island, 0)
    _check(
        flock.birds[0].respawn_count == before + 1,
        "respawn_count advanced on bound violation",
    )
    _check(flock.birds[0].active, "slot stays active after respawn")
    _check(
        flock_horizontal_r(flock.birds[0]) <= FLOCK_BOUND_RADIUS,
        "respawned bird inside bound",
    )
    _check(flock.count <= FLOCK_N_MAX, "count ≤ cap after respawn")
    _check(flock.count == FLOCK_N_INIT, "count unchanged by respawn")
    # Second violation increments again.
    flock.birds[0].x = 0.0
    flock.birds[0].z = -(FLOCK_BOUND_RADIUS + 90.0)
    flock.birds[0].y = 10.0
    flock_tick(flock, island, 1)
    _check(
        flock.birds[0].respawn_count == before + 2,
        "second violation increments respawn_count",
    )
    _check(
        flock_horizontal_r(flock.birds[0]) <= FLOCK_BOUND_RADIUS,
        "second respawn inside bound",
    )
    _check(flock.count == FLOCK_N_INIT, "count still FLOCK_N_INIT")


def test_wire_projection_is_active_slots_in_order() raises:
    """§11 wire: ascending slot order, seabird species id, count matches."""
    var island = build_island(1)
    var flock = flock_from_island(island, 1)
    var wire = flock_wire(flock)
    _check(len(wire) == flock.count, "wire count == active count")
    var prev = -1
    for i in range(len(wire)):
        _check(
            Int(wire[i].species_id) == Int(FLOCK_SEABIRD_SPECIES),
            "seabird species id",
        )
        # Ascending slot order: find the slot of record i and require growth.
        var slot_i = -1
        for s in range(prev + 1, FLOCK_N_MAX):
            if flock.birds[s].active:
                slot_i = s
                break
        _check(slot_i > prev, "wire order follows ascending slots")
        prev = slot_i
        _check(
            wire[i].x == Float32(flock.birds[slot_i].x),
            "wire pose == sim state",
        )


def main() raises:
    TestSuite.discover_tests[
        (
            test_bounded_over_600_ticks,
            test_run_twice_deterministic,
            test_forced_respawn_fires_and_respects_cap,
            test_wire_projection_is_active_slots_in_order,
        )
    ]().run()
