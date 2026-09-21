
#include <AzCore/Memory/SystemAllocator.h>
#include <AzCore/Module/Module.h>

#include "SCR_VolcanicIslandSystemComponent.h"
#include <SCR_VolcanicIsland/SCR_VolcanicIslandBus.h>

#include <SCR_VolcanicIsland/SCR_VolcanicIslandTypeIds.h>

namespace SCR_VolcanicIsland
{
    class SCR_VolcanicIslandModule
        : public AZ::Module
    {
    public:
        AZ_RTTI(SCR_VolcanicIslandModule, SCR_VolcanicIslandModuleTypeId, AZ::Module);
        AZ_CLASS_ALLOCATOR(SCR_VolcanicIslandModule, AZ::SystemAllocator);

        SCR_VolcanicIslandModule()
            : AZ::Module()
        {
            // Push results of [MyComponent]::CreateDescriptor() into m_descriptors here.
            m_descriptors.insert(m_descriptors.end(), {
                SCR_VolcanicIslandSystemComponent::CreateDescriptor(),
                SCR_IntegrationComponent::CreateDescriptor(),
            });
        }

        /**
         * Add required SystemComponents to the SystemEntity.
         */
        AZ::ComponentTypeList GetRequiredSystemComponents() const override
        {
            return AZ::ComponentTypeList{
                azrtti_typeid<SCR_VolcanicIslandSystemComponent>(),
            };
        }
    };
}// namespace SCR_VolcanicIsland

#if defined(O3DE_GEM_NAME)
AZ_DECLARE_MODULE_CLASS(AZ_JOIN(Gem_, O3DE_GEM_NAME), SCR_VolcanicIsland::SCR_VolcanicIslandModule)
#else
AZ_DECLARE_MODULE_CLASS(Gem_SCR_VolcanicIsland, SCR_VolcanicIsland::SCR_VolcanicIslandModule)
#endif
