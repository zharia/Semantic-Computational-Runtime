# SCR Simulation Projection — 101 Specification

## Purpose
Define the read-only transformation from authoritative World state to consumer-specific RenderWorld.

## Contract
`Projection(WorldCommit, Observer, View, TemporalRequest, CapabilitySet, Subscription, Policy) -> RenderWorld`

For fixed inputs and a deterministic policy, projection should produce equivalent output. Any intentional nondeterminism must be explicit.

## Inputs
- committed World version/generation;
- observer/view state;
- requested time or generation;
- negotiated capabilities;
- spatial and semantic subscription;
- representation and resource budgets;
- temporal and LOD policies.

## Outputs
RenderWorld plus provenance: source world version, source generation/tick/time, projection version and representation/resource identities.

## Guarantees
- MUST NOT mutate authoritative World.
- MUST support spatial filtering.
- MUST select only negotiated representations.
- MUST expose source generation and stale/fresh status.
- MUST permit disposal and regeneration.
- MUST be testable without OGRE or CUDA.

## Temporal behavior
Support explicit policies such as exact committed state, latest available, compatible interpolation, or recorded-state reconstruction. Interpolation is not simulation advancement.

## Open requirements
Specify hierarchical spatial boundary rules, moving-observer subscription transitions, deterministic LOD tie-breaking, and atomicity of projection changes.
