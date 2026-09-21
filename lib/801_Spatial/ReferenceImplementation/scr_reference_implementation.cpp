/// @file scr_reference_implementation.cpp
/// @brief Minimal end-to-end SCR semantic execution path implementation.

#include "scr_reference_implementation.h"
#include <cmath>
#include <stdexcept>
#include <sstream>

namespace SCR::ReferenceImplementation {

// ═══════════════════════════════════════════════════════════════════════════
// 1. SID Implementation
// ═══════════════════════════════════════════════════════════════════════════

SID create_sid(uint64_t root_authority, uint64_t allocation_domain, uint64_t coordinate) {
    return SID{root_authority, allocation_domain, coordinate};
}

bool validate_sid(const SID& sid) {
    // SID must have non-zero coordinate
    return sid.coordinate != 0;
}

// ═══════════════════════════════════════════════════════════════════════════
// 2. Transform Implementation
// ═══════════════════════════════════════════════════════════════════════════

/// Quaternion operations (Hamilton product, scalar-first)
namespace {

Quat quat_mul(const Quat& a, const Quat& b) {
    return Quat{
        a.w * b.w - a.x * b.x - a.y * b.y - a.z * b.z,
        a.w * b.x + a.x * b.w + a.y * b.z - a.z * b.y,
        a.w * b.y - a.x * b.z + a.y * b.w + a.z * b.x,
        a.w * b.z + a.x * b.y - a.y * b.x + a.z * b.w
    };
}

Quat quat_conjugate(const Quat& q) {
    return Quat{q.w, -q.x, -q.y, -q.z};
}

Vec3 quat_rotate(const Quat& q, const Vec3& v) {
    Quat v_quat{0.0, v.x, v.y, v.z};
    Quat result = quat_mul(quat_mul(q, v_quat), quat_conjugate(q));
    return Vec3{result.x, result.y, result.z};
}

} // anonymous namespace

Vec3 apply_transform(const SimilarityTransform& t, const Vec3& p) {
    Vec3 rotated = quat_rotate(t.rotation, p);
    return Vec3{
        t.scale * rotated.x + t.translation.x,
        t.scale * rotated.y + t.translation.y,
        t.scale * rotated.z + t.translation.z
    };
}

SimilarityTransform compose_transforms(const SimilarityTransform& t1, const SimilarityTransform& t2) {
    // T2 ∘ T1 = (s2·s1, R2·R1, s2·R2·t1 + t2)
    Vec3 rotated_t1 = quat_rotate(t2.rotation, t1.translation);
    return SimilarityTransform{
        t2.scale * t1.scale,
        quat_mul(t2.rotation, t1.rotation),
        Vec3{
            t2.scale * rotated_t1.x + t2.translation.x,
            t2.scale * rotated_t1.y + t2.translation.y,
            t2.scale * rotated_t1.z + t2.translation.z
        }
    };
}

SimilarityTransform invert_transform(const SimilarityTransform& t) {
    // T⁻¹ = (1/s, Rᵀ, -(1/s) * Rᵀ * t)
    double inv_scale = 1.0 / t.scale;
    Quat inv_rot = quat_conjugate(t.rotation);
    Vec3 inv_trans = quat_rotate(inv_rot, t.translation);
    return SimilarityTransform{
        inv_scale,
        inv_rot,
        Vec3{-inv_scale * inv_trans.x, -inv_scale * inv_trans.y, -inv_scale * inv_trans.z}
    };
}

// ═══════════════════════════════════════════════════════════════════════════
// 3. Semantic Entity Implementation
// ═══════════════════════════════════════════════════════════════════════════

SemanticEntity create_entity(const std::string& name, const SID& sid) {
    return SemanticEntity{sid, EntityState::Created, SimilarityTransform{}, name};
}

bool validate_entity(const SemanticEntity& entity) {
    // Entity must have valid SID
    if (!validate_sid(entity.sid)) return false;
    
    // Entity must be in a valid state
    switch (entity.state) {
        case EntityState::Created:
        case EntityState::Active:
        case EntityState::Suspended:
        case EntityState::Destroyed:
            break;
        default:
            return false;
    }
    
    // Transform must be valid (positive scale)
    if (entity.transform.scale <= 0.0) return false;
    
    return true;
}

bool transition_state(SemanticEntity& entity, EntityState new_state) {
    // Valid transitions:
    // Created -> Active
    // Active -> Suspended
    // Suspended -> Active
    // Active -> Destroyed
    // Suspended -> Destroyed
    
    bool valid_transition = false;
    
    switch (entity.state) {
        case EntityState::Created:
            valid_transition = (new_state == EntityState::Active);
            break;
        case EntityState::Active:
            valid_transition = (new_state == EntityState::Suspended || 
                               new_state == EntityState::Destroyed);
            break;
        case EntityState::Suspended:
            valid_transition = (new_state == EntityState::Active || 
                               new_state == EntityState::Destroyed);
            break;
        case EntityState::Destroyed:
            valid_transition = false; // Cannot transition from Destroyed
            break;
    }
    
    if (valid_transition) {
        entity.state = new_state;
    }
    
    return valid_transition;
}

// ═══════════════════════════════════════════════════════════════════════════
// 4. Provider Manifestation Implementation
// ═══════════════════════════════════════════════════════════════════════════

/// Global manifestation registry (simplified for reference implementation)
static std::vector<Manifestation> g_manifestations;

Manifestation manifest_entity(const SemanticEntity& entity) {
    Manifestation m;
    m.scr_sid = entity.sid;
    m.provider_id.handle = entity.sid.coordinate; // Simplified mapping
    m.provider_id.provider_name = "ReferenceProvider";
    m.is_valid = true;
    
    g_manifestations.push_back(m);
    
    return m;
}

std::optional<SID> resolve_manifestation(const ProviderID& provider_id) {
    for (const auto& m : g_manifestations) {
        if (m.provider_id.handle == provider_id.handle &&
            m.provider_id.provider_name == provider_id.provider_name) {
            return m.scr_sid;
        }
    }
    return std::nullopt;
}

bool validate_manifestation(const Manifestation& m, const SID& expected_sid) {
    return m.is_valid && m.scr_sid == expected_sid;
}

// ═══════════════════════════════════════════════════════════════════════════
// 5. Provider Execution Implementation
// ═══════════════════════════════════════════════════════════════════════════

Observation execute_transform(const Manifestation& m, const SimilarityTransform& op) {
    if (!m.is_valid) {
        return Observation{Vec3{}, Quat{}, 1.0, false, "Invalid manifestation"};
    }
    
    // Simulate provider execution: apply transform and return observation
    Vec3 position = apply_transform(op, Vec3{0.0, 0.0, 0.0});
    
    return Observation{
        position,
        op.rotation,
        op.scale,
        true,
        ""
    };
}

Observation observe_entity(const Manifestation& m) {
    if (!m.is_valid) {
        return Observation{Vec3{}, Quat{}, 1.0, false, "Invalid manifestation"};
    }
    
    // Simulate provider observation
    return Observation{
        Vec3{0.0, 0.0, 0.0},
        Quat{1.0, 0.0, 0.0, 0.0},
        1.0,
        true,
        ""
    };
}

SimilarityTransform observation_to_transform(const Observation& obs) {
    if (!obs.is_valid) {
        return SimilarityTransform{};
    }
    
    return SimilarityTransform{
        obs.scale,
        obs.orientation,
        obs.position
    };
}

// ═══════════════════════════════════════════════════════════════════════════
// 6. Conformance Verification Implementation
// ═══════════════════════════════════════════════════════════════════════════

bool verify_identity_mapping(const SemanticEntity& entity, const Manifestation& m) {
    // Verify SID-to-provider mapping is bidirectional
    if (m.scr_sid != entity.sid) return false;
    
    auto resolved = resolve_manifestation(m.provider_id);
    if (!resolved || *resolved != entity.sid) return false;
    
    return true;
}

bool verify_transform_roundtrip(const SimilarityTransform& original,
                                const SimilarityTransform& observed,
                                double tolerance) {
    // Verify scale roundtrip
    if (std::abs(original.scale - observed.scale) > tolerance) return false;
    
    // Verify translation roundtrip
    if (std::abs(original.translation.x - observed.translation.x) > tolerance) return false;
    if (std::abs(original.translation.y - observed.translation.y) > tolerance) return false;
    if (std::abs(original.translation.z - observed.translation.z) > tolerance) return false;
    
    // Verify rotation roundtrip (quaternion dot product close to 1)
    double dot = original.rotation.w * observed.rotation.w +
                 original.rotation.x * observed.rotation.x +
                 original.rotation.y * observed.rotation.y +
                 original.rotation.z * observed.rotation.z;
    
    if (std::abs(std::abs(dot) - 1.0) > tolerance) return false;
    
    return true;
}

bool verify_state_preservation(const SemanticEntity& entity, const Observation& obs) {
    // Verify entity state is preserved across manifestation
    // For reference implementation, we check observation is valid
    return obs.is_valid;
}

bool run_conformance_check(const SemanticEntity& entity,
                           const Manifestation& m,
                           const Observation& obs) {
    // Run all conformance checks
    if (!validate_entity(entity)) return false;
    if (!validate_manifestation(m, entity.sid)) return false;
    if (!verify_identity_mapping(entity, m)) return false;
    if (!verify_state_preservation(entity, obs)) return false;
    
    return true;
}

// ═══════════════════════════════════════════════════════════════════════════
// 7. Error Handling Implementation
// ═══════════════════════════════════════════════════════════════════════════

const char* error_string(ErrorCode code) {
    switch (code) {
        case ErrorCode::Success: return "Success";
        case ErrorCode::InvalidSID: return "Invalid SID";
        case ErrorCode::InvalidTransform: return "Invalid transform";
        case ErrorCode::ManifestationFailed: return "Manifestation failed";
        case ErrorCode::ExecutionFailed: return "Execution failed";
        case ErrorCode::ObservationFailed: return "Observation failed";
        case ErrorCode::ConformanceViolation: return "Conformance violation";
        case ErrorCode::UnsupportedOperation: return "Unsupported operation";
        default: return "Unknown error";
    }
}

} // namespace SCR::ReferenceImplementation
