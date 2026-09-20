# Implementation Plan — Simulation/Presentation Boundary

**Status:** Proposed program increment outline. No implementation is implied.

## PI objective
Demonstrate two independent processes communicating through a provider-neutral semantic protocol, with a reference executor and test suite independent of OGRE/CUDA.

## Phase 0 — Resolve protocol decisions
- Define canonical schema/encoding and maximum frame/resource descriptor sizes.
- Define generation scope, wraparound and restart epoch rules.
- Define snapshot/delta atomic cut and ordering scope.
- Define command authorization and local socket security.
- Define resource ownership, leases and failure cleanup.
- Decide Hyrx integration boundary and whether control/state share a connection.

**Gate:** reviewed protocol schema and decision log; no unresolved ambiguity in snapshot recovery or resource lifetime.

## Phase 1 — Reference semantic executor
- Implement in-memory World, commit/generation model and deterministic test fixtures.
- Implement projection interfaces and synthetic RenderWorld.
- Implement session, subscriptions, snapshot/delta flow and resync.
- Implement a fake renderer client and fake simulation server.

**Gate:** all protocol invariants tested without OGRE, CUDA, Vulkan or Bullet.

## Phase 2 — AF_UNIX/Hyrx provider
- Implement connection lifecycle, peer credentials, framing, bounded queues and disconnect handling.
- Verify renderer crash/reconnect while simulation continues.
- Test multiple clients and malformed input.

**Gate:** integration tests and resource cleanup pass under forced disconnects.

## Phase 3 — Shared-memory resource path
- Implement memfd/shared-memory resource descriptors and FD passing.
- Define mapping rights, size limits, lifetime/lease and release acknowledgement.
- Test stale handles, invalid descriptors and process death.

**Gate:** no leaked descriptors/mappings in lifecycle tests; generation checks enforced.

## Phase 4 — OGRE presentation client
- Build RenderWorld from synthetic semantic representations.
- Add spatial subscription and camera/observer updates.
- Add a small end-to-end scene and verify no simulation-side OGRE dependency.

**Gate:** renderer restart reconstructs state; simulation cadence is independent of frame cadence.

## Phase 5 — GPU interop experiment
- Separately investigate CUDA/Vulkan external-resource compatibility on target hardware.
- Implement capability detection and explicit import failure/fallback.
- Compare zero-copy path with staging path; measure synchronization and latency.

**Gate:** correctness and performance evidence on named hardware/driver versions. Do not assume availability from API names alone.

## Phase 6 — Fluid projection
- Project one bounded fluid domain to surface/volume/particle representations.
- Keep solver state simulation-side.
- Measure transfer volume, CPU copies, latency and frame freshness.

**Gate:** simulation state remains authoritative; renderer consumes versioned representations and recovers after disconnect.

## Acceptance criteria
- Simulation continues if renderer is killed.
- Renderer reconstructs after reconnect from consistent snapshot plus deltas.
- Generation gaps are detected and repaired.
- Queue limits and overflow behavior are tested.
- Large resource transfer uses an explicit lifetime/synchronization contract.
- Reference protocol tests run without production providers.
- Architecture remains transport- and renderer-provider-neutral.
