# SCR Render Representation — 101 Specification

## Purpose
Define provider-neutral, derived representations for presentation clients.

## Representations
- Surface;
- Volume;
- ParticleField;
- HeightField;
- InstanceSet;
- TransformSet;
- MotionVectorField.

Additional representations may be introduced through versioned schemas.

## Provenance and identity
Each representation identifies semantic source SID, source World version/generation, representation schema/version, content ID where applicable, and resource generation.

## Semantics
Representations are derived and disposable. They may be regenerated without modifying World.

## Resource model
A representation may be inline metadata, shared-memory payload, file/OS handle, or provider-specific GPU resource. Its descriptor must define format, dimensions/layout, ownership, lifetime and synchronization.

## Provider neutrality
OGRE/Vulkan object handles are local implementation details, not semantic identifiers. Unsupported formats require negotiation or explicit fallback.
