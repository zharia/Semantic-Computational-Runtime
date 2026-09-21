/// @file SCRIntegrationModule.cpp
/// @brief SCR Integration gem module entry point
/// @version 0.0.4

#include <AzCore/Memory/SystemAllocator.h>
#include <AzCore/Module/Module.h>

#include <SCRIntegration/SCRIntegrationBus.h>

namespace SCR::Integration {

    class SCRIntegrationModule
        : public AZ::Module
    {
    public:
        AZ_RTTI(SCRIntegrationModule, "{E5C9A000-0006-4000-8000-000000000006}", AZ::Module);
        AZ_CLASS_ALLOCATOR(SCRIntegrationModule, AZ::SystemAllocator);

        SCRIntegrationModule()
            : AZ::Module()
        {
            m_descriptors.insert(m_descriptors.end(), {
                SCRIntegrationComponent::CreateDescriptor(),
            });
        }
    };

} // namespace SCR::Integration

#if defined(O3DE_GEM_NAME)
AZ_DECLARE_MODULE_CLASS(AZ_JOIN(Gem_, O3DE_GEM_NAME), SCR::Integration::SCRIntegrationModule)
#else
AZ_DECLARE_MODULE_CLASS(Gem_SCRIntegration, SCR::Integration::SCRIntegrationModule)
#endif
