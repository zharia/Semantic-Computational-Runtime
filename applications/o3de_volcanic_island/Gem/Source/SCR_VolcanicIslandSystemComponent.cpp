#include <AzCore/Serialization/SerializeContext.h>
#include "SCR_VolcanicIslandSystemComponent.h"

namespace SCR_VolcanicIsland {
    AZ_COMPONENT_IMPL(SCR_VolcanicIslandSystemComponent, "SCR_VolcanicIslandSystemComponent",
        "{E5C9A000-0010-4000-8000-000000000010}");

    void SCR_VolcanicIslandSystemComponent::Reflect(AZ::ReflectContext* context)
    {
        if (auto serializeContext = azrtti_cast<AZ::SerializeContext*>(context))
        {
            serializeContext->Class<SCR_VolcanicIslandSystemComponent, AZ::Component>()
                ->Version(0);
        }
    }

    void SCR_VolcanicIslandSystemComponent::GetProvidedServices(AZ::ComponentDescriptor::DependencyArrayType& provided)
    {
        provided.push_back(AZ_CRC_CE("SCR_VolcanicIslandService"));
    }

    void SCR_VolcanicIslandSystemComponent::GetIncompatibleServices(AZ::ComponentDescriptor::DependencyArrayType& incompatible)
    {
        incompatible.push_back(AZ_CRC_CE("SCR_VolcanicIslandService"));
    }

    void SCR_VolcanicIslandSystemComponent::GetRequiredServices([[maybe_unused]] AZ::ComponentDescriptor::DependencyArrayType& required) {}
    void SCR_VolcanicIslandSystemComponent::GetDependentServices([[maybe_unused]] AZ::ComponentDescriptor::DependencyArrayType& dependent) {}
}
