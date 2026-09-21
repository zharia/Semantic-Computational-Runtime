/// @file SCRIntegrationComponent.cpp
/// @brief SCR Integration component implementation
/// @version 0.0.4
/// @date 2026-09-21

#include <SCRIntegration/SCRIntegrationBus.h>
#include <AzCore/Serialization/SerializeContext.h>
#include <AzCore/Serialization/EditContext.h>
#include <AzCore/Component/TransformBus.h>

namespace SCR::Integration {

void SCRIntegrationComponent::Reflect(AZ::ReflectContext* context)
{
    auto* serialize = azrtti_cast<AZ::SerializeContext*>(context);
    if (serialize)
    {
        serialize->Class<SCRIntegrationComponent, AZ::Component>()
            ->Version(1)
            ->Field("SID", &SCRIntegrationComponent::m_sid)
            ->Field("SCRTransform", &SCRIntegrationComponent::m_scrTransform)
            ;

        if (AZ::EditContext* editContext = serialize->GetEditContext())
        {
            editContext->Class<SCRIntegrationComponent>(
                "SCR Integration", "Maps SCR semantic contracts to O3DE ECS")
                ->ClassElement(AZ::Edit::ClassElements::EditorData, "")
                    ->Attribute(AZ::Edit::Attributes::AppearsInAddComponentMenu, AZ_CRC("System"))
                    ->Attribute(AZ::Edit::Attributes::AutoExpand, true)
                ->DataElement(AZ::Edit::UIHandlers::Default, &SCRIntegrationComponent::m_sid,
                    "SID", "SCR Semantic Identity")
                    ->Attribute(AZ::Edit::Attributes::Min, 0)
                ->DataElement(AZ::Edit::UIHandlers::Default, &SCRIntegrationComponent::m_scrTransform,
                    "SCRTransform", "SCR Similarity Transform")
                ;
        }
    }
}

void SCRIntegrationComponent::Activate()
{
    m_isActive = true;
    
    // Apply initial SCR transform to O3DE
    ApplyToO3DE();
    
    AZ_Printf("SCRIntegration", "Entity activated with SID [%llu, %llu, %llu]",
        m_sid.root_authority, m_sid.allocation_domain, m_sid.coordinate);
}

void SCRIntegrationComponent::Deactivate()
{
    m_isActive = false;
    
    AZ_Printf("SCRIntegration", "Entity deactivated");
}

void SCRIntegrationComponent::SetSCRTransform(const SCR_SimTransform& transform)
{
    m_scrTransform = transform;
    
    if (m_isActive)
    {
        ApplyToO3DE();
    }
}

void SCRIntegrationComponent::ApplyToO3DE()
{
    AZ::Transform o3deTransform = scrToO3DE(m_scrTransform);
    
    // Apply to entity's transform component
    AZ::TransformNotificationBus::Event(
        GetEntityId(),
        &AZ::TransformNotificationBus::Events::OnTransformChanged,
        o3deTransform,
        o3deTransform);
}

void SCRIntegrationComponent::ReadFromO3DE()
{
    AZ::Transform o3deTransform = AZ::Transform::CreateIdentity();
    AZ::TransformBus::EventResult(o3deTransform, GetEntityId(), &AZ::TransformBus::Events::GetWorldTM);
    
    // Convert back to SCR
    SCR_Position pos = o3deToSCR(o3deTransform.GetTranslation());
    SCR_Quaternion quat = o3deToSCR(o3deTransform.GetRotation());
    
    m_scrTransform.position = pos;
    m_scrTransform.rotation = quat;
    m_scrTransform.scale = static_cast<double>(o3deTransform.GetUniformScale());
}

} // namespace SCR::Integration
