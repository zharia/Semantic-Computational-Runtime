#pragma once

/// @file scr_reference_implementation.h
/// @brief Minimal end-to-end SCR semantic execution path.
///
/// This file demonstrates:
/// 1. SCR semantic object creation
/// 2. SID assignment/resolution
/// 3. Semantic state and transformation establishment
/// 4. Provider representation mapping
/// 5. Bounded operation execution
/// 6. Provider observation obtaining
/// 7. SCR observation mapping
/// 8. Invariant verification

#include <string>
#include <vector>
#include <optional>
#include <cstdint>
#include <functional>

namespace SCR::ReferenceImplementation {

// ═══════════════════════════════════════════════════════════════════════════
// 1. Semantic Identity (SID)
// ═══════════════════════════════════════════════════════════════════════════

/// SCR Semantic Identity Coordinate.
/// Not a UUID or random token; a coordinate in an authority hierarchy.
struct SID {
    uint64_t root_authority;
    uint64_t allocation_domain;
    uint64_t coordinate;

    bool operator==(const SID& other) const noexcept {
        return root_authority == other.root_authority &&
               allocation_domain == other.allocation_domain &&
               coordinate == other.coordinate;
    }

    bool operator!=(const SID& other) const noexcept {
        return !(*this == other);
    }
};

/// Create a SID with explicit authority hierarchy.
SID create_sid(uint64_t root_authority, uint64_t allocation_domain, uint64_t coordinate);

/// Validate SID structure.
bool validate_sid(const SID& sid);

// ═══════════════════════════════════════════════════════════════════════════
// 2. Coordinate Systems
// ═══════════════════════════════════════════════════════════════════════════

/// SCR canonical coordinate system: +Z forward, +Y up, +X right (right-handed).
struct Vec3 {
    double x = 0.0;
    double y = 0.0;
    double z = 0.0;
};

/// Quaternion in Hamilton convention: scalar-first (w, x, y, z).
struct Quat {
    double w = 1.0;
    double x = 0.0;
    double y = 0.0;
    double z = 0.0;
};

/// Transform: similarity transform T = (s, R, t) where:
/// - s: uniform scale
/// - R: rotation (quaternion)
/// - t: translation (Vec3)
struct SimilarityTransform {
    double scale = 1.0;
    Quat rotation{};
    Vec3 translation{};
};

/// Apply similarity transform to a point: p' = s * R * p + t
Vec3 apply_transform(const SimilarityTransform& t, const Vec3& p);

/// Compose two similarity transforms: T2 ∘ T1
SimilarityTransform compose_transforms(const SimilarityTransform& t1, const SimilarityTransform& t2);

/// Invert a similarity transform: T⁻¹ = (1/s, Rᵀ, -(1/s) * Rᵀ * t)
SimilarityTransform invert_transform(const SimilarityTransform& t);

// ═══════════════════════════════════════════════════════════════════════════
// 3. Semantic Entity
// ═══════════════════════════════════════════════════════════════════════════

/// Semantic entity state.
enum class EntityState {
    Created,
    Active,
    Suspended,
    Destroyed
};

/// SCR semantic entity with identity, state, and transformation.
struct SemanticEntity {
    SID sid;
    EntityState state = EntityState::Created;
    SimilarityTransform transform;
    std::string name;
};

/// Create a semantic entity with canonical SID.
SemanticEntity create_entity(const std::string& name, const SID& sid);

/// Validate entity invariants.
bool validate_entity(const SemanticEntity& entity);

/// Transition entity state.
bool transition_state(SemanticEntity& entity, EntityState new_state);

// ═══════════════════════════════════════════════════════════════════════════
// 4. Provider Manifestation
// ═══════════════════════════════════════════════════════════════════════════

/// Provider-specific identifier (distinct from SID).
struct ProviderID {
    uint64_t handle;
    std::string provider_name;
};

/// Manifestation: the provider-side representation of an SCR entity.
struct Manifestation {
    SID scr_sid;
    ProviderID provider_id;
    bool is_valid = false;
};

/// Manifest an SCR entity into a provider representation.
Manifestation manifest_entity(const SemanticEntity& entity);

/// Reverse-map a provider ID to SID.
std::optional<SID> resolve_manifestation(const ProviderID& provider_id);

/// Validate manifestation preserves SID.
bool validate_manifestation(const Manifestation& m, const SID& expected_sid);

// ═══════════════════════════════════════════════════════════════════════════
// 5. Provider Execution
// ═══════════════════════════════════════════════════════════════════════════

/// Provider observation result.
struct Observation {
    Vec3 position;
    Quat orientation;
    double scale;
    bool is_valid;
    std::string error;
};

/// Execute a bounded operation: transform the entity in the provider.
Observation execute_transform(const Manifestation& m, const SimilarityTransform& op);

/// Obtain a provider observation.
Observation observe_entity(const Manifestation& m);

/// Map observation back to SCR semantics.
SimilarityTransform observation_to_transform(const Observation& obs);

// ═══════════════════════════════════════════════════════════════════════════
// 6. Conformance Verification
// ═══════════════════════════════════════════════════════════════════════════

/// Verify SID-to-provider mapping is bidirectional.
bool verify_identity_mapping(const SemanticEntity& entity, const Manifestation& m);

/// Verify transformation round-trip within tolerance.
bool verify_transform_roundtrip(const SimilarityTransform& original,
                                const SimilarityTransform& observed,
                                double tolerance = 1e-9);

/// Verify entity state is preserved across manifestation.
bool verify_state_preservation(const SemanticEntity& entity, const Observation& obs);

/// Run full conformance check.
bool run_conformance_check(const SemanticEntity& entity,
                           const Manifestation& m,
                           const Observation& obs);

// ═══════════════════════════════════════════════════════════════════════════
// 7. Error Handling
// ═══════════════════════════════════════════════════════════════════════════

enum class ErrorCode {
    Success,
    InvalidSID,
    InvalidTransform,
    ManifestationFailed,
    ExecutionFailed,
    ObservationFailed,
    ConformanceViolation,
    UnsupportedOperation
};

/// Get human-readable error string.
const char* error_string(ErrorCode code);

} // namespace SCR::ReferenceImplementation
