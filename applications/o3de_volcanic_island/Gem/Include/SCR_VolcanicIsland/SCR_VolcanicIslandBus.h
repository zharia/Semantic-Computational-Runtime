#pragma once

/// @file SCR_VolcanicIslandBus.h
/// @brief SCR Integration component for O3DE volcanic island
/// @version 0.0.4

#include <AzCore/Component/Component.h>
#include <AzCore/Math/Transform.h>
#include <AzCore/Math/Vector3.h>
#include <AzCore/Math/Quaternion.h>
#include <cstdint>

namespace SCR_VolcanicIsland {

struct SCR_SID {
    AZ_TYPE_INFO(SCR_SID, "{E5C9A000-0001-4000-8000-000000000001}");
    uint64_t root_authority = 0;
    uint64_t allocation_domain = 0;
    uint64_t coordinate = 0;
    bool IsValid() const { return root_authority != 0 && allocation_domain != 0 && coordinate != 0; }
};

struct SCR_Position {
    AZ_TYPE_INFO(SCR_Position, "{E5C9A000-0002-4000-8000-000000000002}");
    double x = 0.0;
    double y = 0.0;
    double z = 0.0;
};

struct SCR_Quaternion {
    AZ_TYPE_INFO(SCR_Quaternion, "{E5C9A000-0003-4000-8000-000000000003}");
    double w = 1.0;
    double x = 0.0;
    double y = 0.0;
    double z = 0.0;
};

struct SCR_SimTransform {
    AZ_TYPE_INFO(SCR_SimTransform, "{E5C9A000-0004-4000-8000-000000000004}");
    SCR_Position position;
    SCR_Quaternion rotation;
    double scale = 1.0;
};

inline AZ::Vector3 scrToO3DE(const SCR_Position& scr) {
    return AZ::Vector3(
        static_cast<float>(scr.x),
        static_cast<float>(scr.z),
        static_cast<float>(scr.y)
    );
}

inline SCR_Position o3deToSCR(const AZ::Vector3& o3de) {
    return {
        static_cast<double>(o3de.GetX()),
        static_cast<double>(o3de.GetZ()),
        static_cast<double>(o3de.GetY())
    };
}

inline AZ::Quaternion scrToO3DE(const SCR_Quaternion& scr) {
    return AZ::Quaternion(
        static_cast<float>(scr.x),
        static_cast<float>(scr.y),
        static_cast<float>(scr.z),
        static_cast<float>(scr.w)
    );
}

inline SCR_Quaternion o3deToSCR(const AZ::Quaternion& o3de) {
    return {
        static_cast<double>(o3de.GetW()),
        static_cast<double>(o3de.GetX()),
        static_cast<double>(o3de.GetY()),
        static_cast<double>(o3de.GetZ())
    };
}

inline AZ::Transform scrToO3DE(const SCR_SimTransform& scr) {
    AZ::Vector3 position = scrToO3DE(scr.position);
    AZ::Quaternion rotation = scrToO3DE(scr.rotation);
    return AZ::Transform::CreateFromQuaternionAndTranslation(rotation, position);
}

class SCR_IntegrationComponent
    : public AZ::Component
{
public:
    AZ_COMPONENT(SCR_IntegrationComponent, "{E5C9A000-0005-4000-8000-000000000005}", AZ::Component);

    static void Reflect(AZ::ReflectContext* context);

    const SCR_SID& GetSID() const { return m_sid; }
    void SetSID(const SCR_SID& sid) { m_sid = sid; }
    const SCR_SimTransform& GetSCRTransform() const { return m_scrTransform; }
    void SetSCRTransform(const SCR_SimTransform& transform);
    void ApplyToO3DE();
    void ReadFromO3DE();

protected:
    void Activate() override;
    void Deactivate() override;

private:
    SCR_SID m_sid;
    SCR_SimTransform m_scrTransform;
    bool m_isActive = false;
};

} // namespace SCR_VolcanicIsland
