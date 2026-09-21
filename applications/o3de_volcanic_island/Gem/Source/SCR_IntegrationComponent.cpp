/// @file SCR_IntegrationComponent.cpp
/// @brief SCR Integration component implementation

#include <SCR_VolcanicIsland/SCR_VolcanicIslandBus.h>
#include <AzCore/Serialization/SerializeContext.h>
#include <AzCore/Serialization/EditContext.h>
#include <AzCore/Component/TransformBus.h>

namespace SCR_VolcanicIsland {

void SCR_IntegrationComponent::Reflect(AZ::ReflectContext* context)
{
    auto* serialize = azrtti_cast<AZ::SerializeContext*>(context);
    if (serialize)
    {
        serialize->Class<SCR_IntegrationComponent, AZ::Component>()
            ->Version(1)
            ->Field("SID", &SCR_IntegrationComponent::m_sid)
            ->Field("SCRTransform", &SCR_IntegrationComponent::m_scrTransform);

        if (AZ::EditContext* editContext = serialize->GetEditContext())
        {
            editContext->Class<SCR_IntegrationComponent>(
                "SCR Integration", "Maps SCR semantic contracts to O3DE ECS")
                ->ClassElement(AZ::Edit::ClassElements::EditorData, "")
                    ->Attribute(AZ::Edit::Attributes::AppearsInAddComponentMenu, AZ_CRC("System"))
                    ->Attribute(AZ::Edit::Attributes::AutoExpand, true)
                ->DataElement(AZ::Edit::UIHandlers::Default, &SCR_IntegrationComponent::m_sid,
                    "SID", "SCR Semantic Identity")
                ->DataElement(AZ::Edit::UIHandlers::Default, &SCR_IntegrationComponent::m_scrTransform,
                    "SCRTransform", "SCR Similarity Transform");
        }
    }
}

void SCR_IntegrationComponent::Activate()
{
    m_isActive = true;
    ApplyToO3DE();
    AZ_Printf("SCRIntegration", "Entity activated with SID [%llu, %llu, %llu]",
        m_sid.root_authority, m_sid.allocation_domain, m_sid.coordinate);
}

void SCR_IntegrationComponent::Deactivate()
{
    m_isActive = false;
}

void SCR_IntegrationComponent::SetSCRTransform(const SCR_SimTransform& transform)
{
    m_scrTransform = transform;
    if (m_isActive)
    {
        ApplyToO3DE();
    }
}

void SCR_IntegrationComponent::ApplyToO3DE()
{
    AZ::Transform o3deTransform = scrToO3DE(m_scrTransform);
    AZ::TransformNotificationBus::Event(
        GetEntityId(),
        &AZ::TransformNotificationBus::Events::OnTransformChanged,
        o3deTransform,
        o3deTransform);
}

void SCR_IntegrationComponent::ReadFromO3DE()
{
    AZ::Transform o3deTransform = AZ::Transform::CreateIdentity();
    AZ::TransformBus::EventResult(o3deTransform, GetEntityId(), &AZ::TransformBus::Events::GetWorldTM);
    SCR_Position pos = o3deToSCR(o3deTransform.GetTranslation());
    SCR_Quaternion quat = o3deToSCR(o3deTransform.GetRotation());
    m_scrTransform.position = pos;
    m_scrTransform.rotation = quat;
    m_scrTransform.scale = static_cast<double>(o3deTransform.GetUniformScale());
}

} // namespace SCR_VolcanicIsland
