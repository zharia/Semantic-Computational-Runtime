# Sprint 011-004: Provider Adapter Specification

## 1. Adapter Identity

- **Name:** ReferenceProviderAdapter
- **Version:** 0.1.0
- **Purpose:** Minimal provider adapter demonstrating SCR semantic-to-provider mapping

## 2. Adapter Contract

### 2.1 Inputs

| Input | Type | Description |
|-------|------|-------------|
| Semantic Entity | `SemanticEntity` | SCR entity with SID, state, transform |
| Transform Operation | `SimilarityTransform` | Scale, rotation, translation |

### 2.2 Outputs

| Output | Type | Description |
|--------|------|-------------|
| Manifestation | `Manifestation` | Provider-side representation |
| Observation | `Observation` | Provider execution result |

### 2.3 Preconditions

| Precondition | Description |
|--------------|-------------|
| Valid SID | SID must have non-zero coordinate |
| Valid Entity | Entity must be in Created or Active state |
| Valid Transform | Scale must be positive |

### 2.4 Postconditions

| Postcondition | Description |
|---------------|-------------|
| Manifestation Valid | Manifestation.is_valid = true |
| SID Preserved | Manifestation.scr_sid == Entity.sid |
| Observation Valid | Observation.is_valid = true (on success) |

## 3. Capability Scope

### 3.1 Supported Capabilities

| Capability | Scope | Evidence |
|------------|-------|----------|
| Entity Manifestation | SID → ProviderID | Tested (test_manifestation) |
| Reverse Mapping | ProviderID → SID | Tested (test_reverse_mapping) |
| Transform Execution | SimilarityTransform → Observation | Tested (test_execute_transform) |
| Entity Observation | Provider → SCR | Tested (test_observe_entity) |
| State Validation | Entity state checks | Tested (test_entity_state_transitions) |

### 3.2 Unsupported Capabilities

| Capability | Reason |
|------------|--------|
| Multi-entity composition | Not in vertical slice |
| Physics simulation | Not in vertical slice |
| GPU execution | Not in vertical slice |
| Distributed state | Not in vertical slice |

## 4. Identity Mapping

### 4.1 SID → ProviderID

```
SID { root_authority, allocation_domain, coordinate }
    ↓
ProviderID { handle = coordinate, provider_name = "ReferenceProvider" }
```

**Properties:**
- Direct coordinate mapping (simplified)
- Provider name is constant
- Bidirectional verification tested

### 4.2 ProviderID → SID

```
ProviderID { handle, provider_name }
    ↓
Registry lookup: find Manifestation where provider_id matches
    ↓
SID = Manifestation.scr_sid
```

**Properties:**
- Registry-based lookup
- Returns nullopt if not found
- Tested (test_reverse_mapping_invalid)

## 5. Transformation Mapping

### 5.1 SCR → Provider

```
SimilarityTransform { scale, rotation, translation }
    ↓
Provider executes: position = scale * rotation * origin + translation
    ↓
Observation { position, orientation, scale, is_valid }
```

### 5.2 Provider → SCR

```
Observation { position, orientation, scale, is_valid }
    ↓
SimilarityTransform { scale = obs.scale, rotation = obs.orientation, translation = obs.position }
```

**Properties:**
- Round-trip verified (test_transform_roundtrip)
- Tolerance: 1e-9

## 6. Observation Mapping

### 6.1 Observation Semantics

| Field | SCR Meaning | Provider Meaning |
|-------|-------------|------------------|
| position | Translation in SCR frame | Provider execution result |
| orientation | Rotation quaternion | Provider rotation state |
| scale | Uniform scale factor | Provider scale state |
| is_valid | Observation succeeded | Provider operation succeeded |
| error | Error description | Provider error message |

### 6.2 Approximation

- **Reference Provider:** Exact (no approximation)
- **Real Provider:** May have floating-point precision differences
- **Tolerance:** Documented per provider

## 7. Failure Behavior

### 7.1 Error Codes

| Code | Condition | Response |
|------|-----------|----------|
| InvalidSID | SID.coordinate == 0 | Validation failure |
| InvalidTransform | scale <= 0 | Validation failure |
| ManifestationFailed | Provider error | Invalid manifestation |
| ExecutionFailed | Provider error | Invalid observation |
| ConformanceViolation | Check failure | False return |

### 7.2 Failure Invariants

| Invariant | Guarantee |
|-----------|-----------|
| SID not corrupted | Manifestation preserves SID |
| Operation not falsely successful | Error returned on failure |
| Observation not fabricated | Invalid observation on failure |
| Provenance preserved | Provider identity recorded |
| No unrelated mutation | Only target entity affected |

## 8. Provenance

| Property | Value |
|----------|-------|
| Adapter Version | 0.1.0 |
| Provider Name | ReferenceProvider |
| Provider Version | 0.1.0 |
| Mapping Version | 0.1.0 |
| SCR Specification | lib/101_Core/Identity/101_definition.md |
| Transform Specification | lib/905_Transforms/ |

## 9. Test Coverage

| Contract | Tests | Status |
|----------|-------|--------|
| SID Creation | test_sid_creation | PASS |
| SID Validation | test_sid_invalid | PASS |
| SID Equality | test_sid_equality | PASS |
| Transform Identity | test_identity_transform | PASS |
| Transform Scale | test_scale_transform | PASS |
| Transform Translation | test_translation_transform | PASS |
| Transform Composition | test_transform_composition | PASS |
| Transform Inversion | test_transform_inversion | PASS |
| Entity Creation | test_entity_creation | PASS |
| Entity State | test_entity_state_transitions | PASS |
| Invalid Transitions | test_entity_invalid_transitions | PASS |
| Manifestation | test_manifestation | PASS |
| Reverse Mapping | test_reverse_mapping | PASS |
| Invalid Mapping | test_reverse_mapping_invalid | PASS |
| Execution | test_execute_transform | PASS |
| Observation | test_observe_entity | PASS |
| Observation Mapping | test_observation_mapping | PASS |
| Conformance | test_conformance_check | PASS |
| Roundtrip | test_transform_roundtrip | PASS |
| Identity Verify | test_identity_mapping_verification | PASS |
| Invalid Execution | test_invalid_manifestation_execution | PASS |
| Error Strings | test_error_strings | PASS |
