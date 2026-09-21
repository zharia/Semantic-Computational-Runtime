#pragma once

/// @file scr_o3de_provider.h
/// @brief Real O3DE provider integration for SCR semantic kernel.
///
/// Maps SCR semantic contracts into actual O3DE/AzCore types:
/// - SCR SID → O3DE EntityId
/// - SCR SimilarityTransform → O3DE Transform
/// - SCR Vec3 → O3DE Vector3
/// - SCR Quat → O3DE Quaternion (with component reordering)
///
/// Coordinate system mapping:
/// - SCR: +Z forward, +Y up, +X right (right-handed)
/// - O3DE: +X right, +Y forward, +Z up (right-handed)
/// - Mapping: SCR_X→O3DE_X, SCR_Y→O3DE_Z, SCR_Z→O3DE_Y

#include <AzCore/Math/Transform.h>
#include <AzCore/Math/Quaternion.h>
#include <AzCore/Math/Vector3.h>
#include <cstdint>
#include <optional>
#include <string>
#include <unordered_map>
#include <mutex>

namespace SCR::O3DEProvider {

// ═══════════════════════════════════════════════════════════════════════════
// SCR Types (minimal, for provider boundary)
// ═══════════════════════════════════════════════════════════════════════════

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

struct Vec3 {
    double x = 0.0;
    double y = 0.0;
    double z = 0.0;
};

struct Quat {
    double w = 1.0;
    double x = 0.0;
    double y = 0.0;
    double z = 0.0;
};

struct SimilarityTransform {
    double scale = 1.0;
    Quat rotation{};
    Vec3 translation{};
};

struct Observation {
    Vec3 position;
    Quat orientation;
    double scale;
    bool is_valid;
    std::string error;
};

// ═══════════════════════════════════════════════════════════════════════════
// Coordinate Conversion
// ═══════════════════════════════════════════════════════════════════════════

/// Convert SCR Vec3 to O3DE Vector3.
/// SCR: +Z forward, +Y up, +X right
/// O3DE: +X right, +Y forward, +Z up
AZ::Vector3 scr_to_o3de(const Vec3& v);

/// Convert O3DE Vector3 to SCR Vec3.
Vec3 o3de_to_scr(const AZ::Vector3& v);

/// Convert SCR Quat to O3DE Quaternion.
/// SCR: (w, x, y, z) Hamilton convention
/// O3DE: (x, y, z, w) constructor order
AZ::Quaternion scr_to_o3de(const Quat& q);

/// Convert O3DE Quaternion to SCR Quat.
Quat o3de_to_scr(const AZ::Quaternion& q);

/// Convert SCR SimilarityTransform to O3DE Transform.
AZ::Transform scr_to_o3de(const SimilarityTransform& t);

/// Convert O3DE Transform to SCR SimilarityTransform.
SimilarityTransform o3de_to_scr(const AZ::Transform& t);

// ═══════════════════════════════════════════════════════════════════════════
// Provider Manifestation
// ═══════════════════════════════════════════════════════════════════════════

/// O3DE Entity ID type (matching O3DE's AzFramework::EntityId).
using O3DEEntityId = uint64_t;

/// Manifestation: maps SCR SID to O3DE entity.
struct Manifestation {
    SID scr_sid;
    O3DEEntityId entity_id;
    bool is_valid = false;
};

/// Registry: bidirectional SID ↔ EntityId mapping.
class ProviderRegistry {
public:
    /// Manifest an SCR entity into O3DE.
    Manifestation manifest(const SID& sid, const std::string& name);

    /// Resolve an O3DE entity ID back to SID.
    std::optional<SID> resolve(O3DEEntityId entity_id) const;

    /// Check if manifestation is valid.
    bool validate(const Manifestation& m, const SID& expected_sid) const;

    /// Get the number of registered entities.
    size_t size() const;

    /// Clear all registrations.
    void clear();

private:
    mutable std::mutex mutex_;
    std::unordered_map<uint64_t, O3DEEntityId> sid_to_entity_;
    std::unordered_map<O3DEEntityId, uint64_t> entity_to_sid_;
    O3DEEntityId next_id_ = 1;

    static uint64_t sid_hash(const SID& sid);
};

// ═══════════════════════════════════════════════════════════════════════════
// Provider Execution
// ═══════════════════════════════════════════════════════════════════════════

/// Execute a transform operation using real O3DE Transform.
/// This performs actual O3DE math, not in-memory simulation.
Observation execute_transform(const Manifestation& m,
                              const SimilarityTransform& operation,
                              const SimilarityTransform& current_state);

/// Obtain an observation from O3DE state.
Observation observe_entity(const Manifestation& m,
                           const SimilarityTransform& current_state);

/// Map O3DE observation back to SCR transform.
SimilarityTransform observation_to_transform(const Observation& obs);

// ═══════════════════════════════════════════════════════════════════════════
// Conformance Verification
// ═══════════════════════════════════════════════════════════════════════════

/// Verify SID-to-entity mapping is bidirectional.
bool verify_identity_mapping(const SID& sid, const Manifestation& m,
                            const ProviderRegistry& registry);

/// Verify transform round-trip within tolerance.
bool verify_transform_roundtrip(const SimilarityTransform& original,
                                const SimilarityTransform& observed,
                                double tolerance = 1e-6);

/// Verify O3DE coordinate conversion preserves handedness.
bool verify_coordinate_conversion();

} // namespace SCR::O3DEProvider
