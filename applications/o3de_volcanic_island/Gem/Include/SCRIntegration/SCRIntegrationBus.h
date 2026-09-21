#pragma once

/// @file SCRIntegrationBus.h
/// @brief SCR Integration component for O3DE
/// @version 0.0.4
/// @date 2026-09-21
///
/// Maps SCR semantic contracts to O3DE ECS:
/// - SCR SID → O3DE EntityId
/// - SCR SimilarityTransform → AZ::Transform
/// - SCR lifecycle → AZ::Component lifecycle

#include <AzCore/Component/Component.h>
#include <AzCore/Math/Transform.h>
#include <AzCore/Math/Vector3.h>
#include <AzCore/Math/Quaternion.h>
#include <cstdint>
#include <string>

namespace SCR::Integration {

/// @brief SCR Semantic Identity (simplified for O3DE)
struct SCR_SID {
    uint64_t root_authority = 0;
    uint64_t allocation_domain = 0;
    uint64_t coordinate = 0;

    bool IsValid() const {
        return root_authority != 0 && allocation_domain != 0 && coordinate != 0;
    }

    bool operator==(const SCR_SID& other) const {
        return root_authority == other.root_authority &&
               allocation_domain == other.allocation_domain &&
               coordinate == other.coordinate;
    }
};

/// @brief SCR Position in canonical coordinates
///   SCR: +Z forward, +Y up, +X right
struct SCR_Position {
    double x = 0.0;  ///< +X right
    double y = 0.0;  ///< +Y up
    double z = 0.0;  ///< +Z forward
};

/// @brief SCR Quaternion (Hamilton, scalar-first)
struct SCR_Quaternion {
    double w = 1.0;  ///< Scalar part
    double x = 0.0;  ///< i
    double y = 0.0;  ///< j
    double z = 0.0;  ///< k
};

/// @brief SCR Similarity Transform (scale + rotation + translation)
struct SCR_SimTransform {
    SCR_Position position;
    SCR_Quaternion rotation;
    double scale = 1.0;
};

/// @brief Convert SCR position to O3DE AZ::Vector3
/// @param scr SCR canonical position
/// @return O3DE vector (X right, Y forward, Z up)
inline AZ::Vector3 scrToO3DE(const SCR_Position& scr) {
    return AZ::Vector3(
        static_cast<float>(scr.x),   // SCR X → O3DE X (right)
        static_cast<float>(scr.z),   // SCR Z → O3DE Y (forward)
        static_cast<float>(scr.y)    // SCR Y → O3DE Z (up)
    );
}

/// @brief Convert O3DE AZ::Vector3 to SCR position
/// @param o3de O3DE vector
/// @return SCR canonical position
inline SCR_Position o3deToSCR(const AZ::Vector3& o3de) {
    return {
        static_cast<double>(o3de.GetX()),  // O3DE X → SCR X (right)
        static_cast<double>(o3de.GetZ()),  // O3DE Z → SCR Y (up)
        static_cast<double>(o3de.GetY())   // O3DE Y → SCR Z (forward)
    };
}

/// @brief Convert SCR quaternion to O3DE AZ::Quaternion
/// @param scr SCR quaternion (w, x, y, z)
/// @return O3DE quaternion (x, y, z, w)
inline AZ::Quaternion scrToO3DE(const SCR_Quaternion& scr) {
    return AZ::Quaternion(
        static_cast<float>(scr.x),  // i
        static_cast<float>(scr.y),  // j
        static_cast<float>(scr.z),  // k
        static_cast<float>(scr.w)   // scalar
    );
}

/// @brief Convert O3DE AZ::Quaternion to SCR quaternion
/// @param o3de O3DE quaternion (x, y, z, w)
/// @return SCR quaternion (w, x, y, z)
inline SCR_Quaternion o3deToSCR(const AZ::Quaternion& o3de) {
    return {
        static_cast<double>(o3de.GetW()),  // scalar
        static_cast<double>(o3de.GetX()),  // i
        static_cast<double>(o3de.GetY()),  // j
        static_cast<double>(o3de.GetZ())   // k
    };
}

/// @brief Convert SCR transform to O3DE transform
/// @param scr SCR similarity transform
/// @return O3DE transform
inline AZ::Transform scrToO3DE(const SCR_SimTransform& scr) {
    AZ::Vector3 position = scrToO3DE(scr.position);
    AZ::Quaternion rotation = scrToO3DE(scr.rotation);
    AZ::Vector3 scale = AZ::Vector3(static_cast<float>(scr.scale));
    
    return AZ::Transform::CreateFromQuaternionAndTranslation(rotation, position);
}

/// @brief SCR Integration Component
/// @details Attaches to an O3DE entity and manages its SCR semantic state.
/// Provides bidirectional mapping between SCR SID and O3DE EntityId.
class SCRIntegrationComponent
    : public AZ::Component
{
public:
    AZ_RTTI(SCRIntegrationComponent, "{SCR-INTEGRATION-COMPONENT-ID}", AZ::Component);
    AZ_CLASS_ALLOCATOR(SCRIntegrationComponent, AZ::SystemAllocator);

    SCRIntegrationComponent() = default;
    ~SCRIntegrationComponent() override = default;

    /// @brief Get the SCR SID for this entity
    /// @return SCR SID
    const SCR_SID& GetSID() const { return m_sid; }

    /// @brief Set the SCR SID for this entity
    /// @param sid SCR SID to set
    void SetSID(const SCR_SID& sid) { m_sid = sid; }

    /// @brief Get the SCR transform for this entity
    /// @return SCR similarity transform
    const SCR_SimTransform& GetSCRTransform() const { return m_scrTransform; }

    /// @brief Set the SCR transform for this entity
    /// @param transform SCR similarity transform
    void SetSCRTransform(const SCR_SimTransform& transform);

    /// @brief Apply SCR transform to O3DE transform
    void ApplyToO3DE();

    /// @brief Read O3DE transform into SCR
    void ReadFromO3DE();

    /// @brief Get the entity activation state
    /// @return true if entity is active
    bool IsActive() const { return m_isActive; }

    static void Reflect(AZ::ReflectContext* context);

protected:
    void Activate() override;
    void Deactivate() override;

private:
    SCR_SID m_sid;
    SCR_SimTransform m_scrTransform;
    bool m_isActive = false;
};

} // namespace SCR::Integration
