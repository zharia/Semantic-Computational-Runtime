#pragma once

#include <AzCore/Component/Component.h>

namespace SCR_VolcanicIsland {
    class SCR_VolcanicIslandSystemComponent
        : public AZ::Component
    {
    public:
        AZ_COMPONENT_DECL(SCR_VolcanicIslandSystemComponent);
        static void Reflect(AZ::ReflectContext* context);
        static void GetProvidedServices(AZ::ComponentDescriptor::DependencyArrayType& provided);
        static void GetIncompatibleServices(AZ::ComponentDescriptor::DependencyArrayType& incompatible);
        static void GetRequiredServices(AZ::ComponentDescriptor::DependencyArrayType& required);
        static void GetDependentServices(AZ::ComponentDescriptor::DependencyArrayType& dependent);
        SCR_VolcanicIslandSystemComponent() = default;
        ~SCR_VolcanicIslandSystemComponent() override = default;
    protected:
        void Init() override {}
        void Activate() override {}
        void Deactivate() override {}
    };
}
