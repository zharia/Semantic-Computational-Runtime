# SCR Simulation State — 101 Specification

## Purpose
Define the committed authoritative state contract exposed to projection and recording consumers.

## Authority
Simulation owns authoritative state. Presentation may submit explicit commands through a separately authorized command interface, but may not directly mutate World.

## Commit
A state is externally visible only after a complete commit boundary. Partial solver buffers or partially applied multi-domain updates are not committed World state.

## Required identity
Each commit identifies:
- `world_version`;
- `state_generation`;
- `simulation_tick`;
- `simulation_time` and its unit/encoding;
- `determinism_epoch`.

The exact integer widths, overflow behavior, time representation and restart semantics are open protocol-schema decisions and must be settled before implementation.

## Snapshot
A snapshot is a self-consistent committed state. It declares its generation/version and establishes the base for subsequent deltas.

## Restart
A simulation restart must be detectable as a new session/epoch. Generation reuse across epochs must not cause stale state to be accepted.

## Replay
Snapshot playback is distinct from recomputing a simulation. Any claim of deterministic recomputation requires a defined determinism contract and verification.
