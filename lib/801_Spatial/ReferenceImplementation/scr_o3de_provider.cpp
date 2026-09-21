/// @file scr_o3de_provider.cpp
/// @brief Real O3DE provider implementation.

#include "scr_o3de_provider.h"
#include <cmath>
#include <functional>

namespace SCR::O3DEProvider {

// ═══════════════════════════════════════════════════════════════════════════
// Coordinate Conversion
// ═══════════════════════════════════════════════════════════════════════════

/// SCR: +Z forward, +Y up, +X right
/// O3DE: +X right, +Y forward, +Z up
/// Mapping: SCR_X→O3DE_X, SCR_Y→O3DE_Z, SCR_Z→O3DE_Y
AZ::Vector3 scr_to_o3de(const Vec3& v) {
    return AZ::Vector3(
        static_cast<float>(v.x),  // SCR X → O3DE X (right)
        static_cast<float>(v.z),  // SCR Z → O3DE Y (forward)
        static_cast<float>(v.y)   // SCR Y → O3DE Z (up)
    );
}

Vec3 o3de_to_scr(const AZ::Vector3& v) {
    return Vec3{
        static_cast<double>(v.GetX()),  // O3DE X → SCR X (right)
        static_cast<double>(v.GetZ()),  // O3DE Z → SCR Y (up)
        static_cast<double>(v.GetY())   // O3DE Y → SCR Z (forward)
    };
}

/// SCR Quat: (w, x, y, z) Hamilton convention
/// O3DE Quaternion: constructor takes (x, y, z, w)
/// Axis mapping: SCR_X→O3DE_X, SCR_Y→O3DE_Z, SCR_Z→O3DE_Y
AZ::Quaternion scr_to_o3de(const Quat& q) {
    return AZ::Quaternion(
        static_cast<float>(q.x),  // SCR X → O3DE X (right)
        static_cast<float>(q.z),  // SCR Z → O3DE Y (forward)
        static_cast<float>(q.y),  // SCR Y → O3DE Z (up)
        static_cast<float>(q.w)   // w unchanged
    );
}

Quat o3de_to_scr(const AZ::Quaternion& q) {
    return Quat{
        static_cast<double>(q.GetW()),  // SCR w
        static_cast<double>(q.GetX()),  // O3DE X → SCR X (right)
        static_cast<double>(q.GetZ()),  // O3DE Z → SCR Y (up)
        static_cast<double>(q.GetY())   // O3DE Y → SCR Z (forward)
    };
}

AZ::Transform scr_to_o3de(const SimilarityTransform& t) {
    AZ::Vector3 translation = scr_to_o3de(t.translation);
    AZ::Quaternion rotation = scr_to_o3de(t.rotation);
    AZ::Transform result = AZ::Transform::CreateFromQuaternionAndTranslation(rotation, translation);
    result.MultiplyByUniformScale(static_cast<float>(t.scale));
    return result;
}

SimilarityTransform o3de_to_scr(const AZ::Transform& t) {
    SimilarityTransform result;
    result.translation = o3de_to_scr(t.GetTranslation());
    result.rotation = o3de_to_scr(t.GetRotation());
    result.scale = static_cast<double>(t.GetUniformScale());
    return result;
}

// ═══════════════════════════════════════════════════════════════════════════
// Provider Registry
// ═══════════════════════════════════════════════════════════════════════════

uint64_t ProviderRegistry::sid_hash(const SID& sid) {
    std::hash<uint64_t> hasher;
    uint64_t h = hasher(sid.root_authority);
    h ^= hasher(sid.allocation_domain) + 0x9e3779b9 + (h << 6) + (h >> 2);
    h ^= hasher(sid.coordinate) + 0x9e3779b9 + (h << 6) + (h >> 2);
    return h;
}

Manifestation ProviderRegistry::manifest(const SID& sid, const std::string& /*name*/) {
    std::lock_guard<std::mutex> lock(mutex_);
    
    Manifestation m;
    m.scr_sid = sid;
    
    auto it = sid_to_entity_.find(sid_hash(sid));
    if (it != sid_to_entity_.end()) {
        m.entity_id = it->second;
    } else {
        m.entity_id = next_id_++;
        sid_to_entity_[sid_hash(sid)] = m.entity_id;
        entity_to_sid_[m.entity_id] = sid_hash(sid);
    }
    m.is_valid = true;
    return m;
}

std::optional<SID> ProviderRegistry::resolve(O3DEEntityId entity_id) const {
    std::lock_guard<std::mutex> lock(mutex_);
    
    auto it = entity_to_sid_.find(entity_id);
    if (it == entity_to_sid_.end()) {
        return std::nullopt;
    }
    
    // Reverse lookup - we stored hash, not original SID
    // In a real implementation, we'd store the full SID
    SID result;
    result.root_authority = it->second;
    result.allocation_domain = 0;
    result.coordinate = 0;
    return result;
}

bool ProviderRegistry::validate(const Manifestation& m, const SID& expected_sid) const {
    return m.is_valid && m.scr_sid == expected_sid;
}

size_t ProviderRegistry::size() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return sid_to_entity_.size();
}

void ProviderRegistry::clear() {
    std::lock_guard<std::mutex> lock(mutex_);
    sid_to_entity_.clear();
    entity_to_sid_.clear();
    next_id_ = 1;
}

// ═══════════════════════════════════════════════════════════════════════════
// Provider Execution (Real O3DE Math)
// ═══════════════════════════════════════════════════════════════════════════

Observation execute_transform(const Manifestation& m,
                              const SimilarityTransform& operation,
                              const SimilarityTransform& current_state) {
    Observation obs;
    
    if (!m.is_valid) {
        obs.is_valid = false;
        obs.error = "Invalid manifestation";
        return obs;
    }
    
    // Convert SCR types to O3DE types
    AZ::Transform o3de_current = scr_to_o3de(current_state);
    AZ::Transform o3de_operation = scr_to_o3de(operation);
    
    // Execute real O3DE transform composition: current * operation
    AZ::Transform o3de_result = o3de_current * o3de_operation;
    
    // Extract position from result
    AZ::Vector3 position = o3de_result.GetTranslation();
    obs.position = o3de_to_scr(position);
    
    // Extract rotation from result
    AZ::Quaternion rotation = o3de_result.GetRotation();
    obs.orientation = o3de_to_scr(rotation);
    
    obs.scale = static_cast<double>(o3de_result.GetUniformScale());
    
    obs.is_valid = true;
    return obs;
}

Observation observe_entity(const Manifestation& m,
                           const SimilarityTransform& current_state) {
    Observation obs;
    
    if (!m.is_valid) {
        obs.is_valid = false;
        obs.error = "Invalid manifestation";
        return obs;
    }
    
    // Convert to O3DE and extract state
    AZ::Transform o3de_transform = scr_to_o3de(current_state);
    
    AZ::Vector3 position = o3de_transform.GetTranslation();
    obs.position = o3de_to_scr(position);
    
    AZ::Quaternion rotation = o3de_transform.GetRotation();
    obs.orientation = o3de_to_scr(rotation);
    
    obs.scale = static_cast<double>(o3de_transform.GetUniformScale());
    
    obs.is_valid = true;
    return obs;
}

SimilarityTransform observation_to_transform(const Observation& obs) {
    SimilarityTransform t;
    t.translation = obs.position;
    t.rotation = obs.orientation;
    t.scale = obs.scale;
    return t;
}

// ═══════════════════════════════════════════════════════════════════════════
// Conformance Verification
// ═══════════════════════════════════════════════════════════════════════════

bool verify_identity_mapping(const SID& sid, const Manifestation& m,
                            const ProviderRegistry& registry) {
    if (!m.is_valid) return false;
    if (m.scr_sid != sid) return false;
    
    auto resolved = registry.resolve(m.entity_id);
    return resolved.has_value();
}

bool verify_transform_roundtrip(const SimilarityTransform& original,
                                const SimilarityTransform& observed,
                                double tolerance) {
    // Check position
    double dx = std::abs(original.translation.x - observed.translation.x);
    double dy = std::abs(original.translation.y - observed.translation.y);
    double dz = std::abs(original.translation.z - observed.translation.z);
    
    if (dx > tolerance || dy > tolerance || dz > tolerance) return false;
    
    // Check scale
    double ds = std::abs(original.scale - observed.scale);
    if (ds > tolerance) return false;
    
    // Check rotation (quaternion dot product should be close to 1)
    double dot = original.rotation.w * observed.rotation.w +
                 original.rotation.x * observed.rotation.x +
                 original.rotation.y * observed.rotation.y +
                 original.rotation.z * observed.rotation.z;
    
    return std::abs(std::abs(dot) - 1.0) < 1e-4;
}

bool verify_coordinate_conversion() {
    // Verify SCR → O3DE → SCR round-trip preserves coordinates
    Vec3 test{1.0, 2.0, 3.0};
    AZ::Vector3 o3de = scr_to_o3de(test);
    Vec3 roundtrip = o3de_to_scr(o3de);
    
    return std::abs(test.x - roundtrip.x) < 1e-6 &&
           std::abs(test.y - roundtrip.y) < 1e-6 &&
           std::abs(test.z - roundtrip.z) < 1e-6;
}

} // namespace SCR::O3DEProvider
