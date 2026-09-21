/// @file SCRIntegrationModule.cpp
/// @brief SCR Integration gem module entry point
/// @version 0.0.4

#include <AzCore/Memory/SystemAllocator.h>
#include <AzCore/Module/Module.h>

#include "SCRIntegrationBus.h"

namespace SCR::Integration {

    class SCRIntegrationModule
        : public AZ::Module
    {
    public:
        AZ_RTTI(SCRIntegrationModule, "{SCR-VOLCANIC-ISLAND-004-MODULE}", AZ::Module);
        AZ_CLASS_ALLOCATOR(SCRIntegrationModule, AZ::SystemAllocator);

        SCRIntegrationModule()
            : AZ::Module()
        {
            m_descriptors.insert(m_descriptors.end(), {
                SCRIntegrationComponent::CreateDescriptor(),
            });
        }

        AZ::ComponentTypeList GetRequiredSystemComponents() const override
        {
            AZ::ComponentTypeList requiredComponents;
            requiredComponents.push_back(AZUuid(typeid(SCRIntegrationComponent).name()));
            return requiredComponents;
        }
    };

} // namespace SCR::Integration

#if defined(O3DE_GEM_NAME)
AZ_DECLARE_MODULE_CLASS(GEM_NAME, SCR::Integration::SCRIntegrationModule)
#else
AZ_DECLARE_MODULE_CLASS(SCRIntegration, SCR::Integration::SCRIntegrationModule)
#endif
