# Sprint 006-003 Report: Semantic Reconciliation

## Status: COMPLETE

## Reconciliation Decisions

### C-01: O3DE Handedness
- **Canonical:** O3DE = +Y forward, +Z up, +X right, right-handed
- **Correction:** Remove "left-handed" and "Z-up" claims from sprint records
- **Action:** Update O3DE provider spec

### C-02: Three Conflicting Lifecycles
- **Canonical:** No universal entity lifecycle. Application lifecycle in `lib/804_Application/Lifecycle/` is canonical for applications.
- **Correction:** O3DE lifecycle is a provider-specific profile. CAVE lifecycle is application-specific.
- **Action:** Mark O3DE lifecycle as profile, not universal

### C-03: Transform Composition
- **Canonical:** SCR supports similarity transforms (uniform scale + rotation + translation)
- **Correction:** Non-uniform scale + rotation does not compose cleanly. Document as limitation.
- **Action:** Update Transformations definition

### C-04: SID Uniqueness
- **Canonical:** SID is globally unique. EntityId is scope-bounded (provider handle).
- **Correction:** These are different concepts. SID ≠ EntityId.
- **Action:** Clarify in Identity definitions

### C-05: Replication Consistency
- **Canonical:** SCR defines consistency contracts; specific models must be specified.
- **Correction:** Consistency is NOT automatic. Each replication scenario must declare its model.
- **Action:** Update Distributed State definitions

### C-06: Energy Conservation
- **Canonical:** Conservation is model-specific, not universal.
- **Correction:** SCR Physics defines conservation as a semantic property that models may declare.
- **Action:** Update Physics definitions

### C-07: Component Identity
- **Canonical:** Components MAY have identity (addressable). O3DE components lack independent identity (O3DE-specific).
- **Correction:** SCR does not impose O3DE's restriction.
- **Action:** Clarify in Entity/Component definitions

### C-08: Physics Body Definitions
- **Canonical:** Static/kinematic/dynamic are behavioral profiles, not lifecycle states.
- **Correction:** Static does not mean permanent. It means immobility constraint.
- **Action:** Update Physics definitions
