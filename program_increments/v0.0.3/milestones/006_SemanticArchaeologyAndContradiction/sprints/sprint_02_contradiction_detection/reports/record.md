# Sprint 006-002 Report: Contradiction Detection

## Status: COMPLETE

## Contradictions Found

### C-01: O3DE Handedness (CRITICAL)
- **Claim A:** `combined-spec.md:908` — "O3DE uses right-handed, Z-up"
- **Claim B:** `combined-spec.md:7043` — "SCR canonical frame → O3DE left-handed Y-up"
- **Resolution:** O3DE documentation says Y-up, right-handed. The "Z-up" claim was an error.
- **Canonical:** O3DE = +Y forward, +Z up, +X right, right-handed

### C-02: Three Conflicting Lifecycles (CRITICAL)
- **Claim A:** `providers/o3de/101_spec.md` — Construct → Initialize → Activate → Deactivate → Destroy
- **Claim B:** `applications/cave/.../sprint_02_object_and_lifecycle.md` — CREATED → ATTACHED → ACTIVE → DETACHED → RETIRED
- **Claim C:** `lib/804_Application/Lifecycle/101_definition.md` — Created → Initialized → Configured → Active → Suspended → Draining → Terminated
- **Resolution:** Each is correct for its scope. C is canonical SCR Application lifecycle. A is O3DE-specific profile. B is CAVE application-specific profile. No universal entity lifecycle exists.

### C-03: Transform Composition Scope (HIGH)
- **Claim A:** `combined-spec.md:845` — "Uniform scale only"
- **Claim B:** Implementation uses `Matrix4::setScale(Vector3)` — non-uniform scale
- **Resolution:** SCR supports similarity transforms (uniform scale + rotation). Non-uniform scale + rotation does not compose cleanly (produces shear). Document as limitation.

### C-04: SID Uniqueness (HIGH)
- **Claim A:** `combined-spec.md:949` — "Entity ID uniqueness is scope-bounded"
- **Claim B:** `validation record` — "SCR SID is globally unique by construction"
- **Resolution:** SID is globally unique. EntityId is scope-bounded (provider handle). These are different concepts.

### C-05: Replication Consistency (HIGH)
- **Claim A:** `validation record` — "Consistency guaranteed by SCR semantics"
- **Claim B:** `002_semantic-correction-and-conformance.md:947` — "Do not state that SCR replication automatically guarantees consistency"
- **Resolution:** SCR defines the consistency contract; the specific model must be specified. Consistency is NOT automatic.

### C-06: Energy Conservation (HIGH)
- **Claim A:** `lib/501_Physics/Conservation/101_definition.md` — "Exact conservation: energy, momentum"
- **Claim B:** `providers/physics/bullet3/101_definition.md` — "Symplectic Euler guarantees energy bounding"
- **Claim C:** `002_semantic-correction-and-conformance.md:846` — "Do not assert universal energy conservation"
- **Resolution:** Conservation is model-specific, not universal. SCR Physics defines conservation as a semantic property that models may declare. Bullet3 uses symplectic integration (energy bounded, not conserved).

### C-07: Component Identity (MEDIUM)
- **Claim A:** `combined-spec.md:1719` — "Has no independent identity"
- **Claim B:** `lib/101_Core/Identity/101_definition.md` — identity as coordinate in address space
- **Resolution:** Components MAY have identity (addressable). O3DE components lack independent identity (O3DE-specific). SCR does not impose this restriction.

### C-08: Physics Body Definitions (MEDIUM)
- **Claim A:** `combined-spec.md:875` — "Static body: fixed, immovable"
- **Claim B:** Physics semantics: static means immobility constraint, not permanence
- **Resolution:** Static/kinematic/dynamic are behavioral profiles, not lifecycle states. Static does not mean permanent.
