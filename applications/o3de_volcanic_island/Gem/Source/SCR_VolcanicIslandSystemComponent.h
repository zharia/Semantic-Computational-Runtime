#pragma once

#include <AzCore/Component/Component.h>
#include <AzCore/Component/TickBus.h>

namespace SCR::Render::O3DE { class O3deVolcanicIslandScene; }

namespace SCR_VolcanicIsland {
    class SCR_VolcanicIslandSystemComponent
        : public AZ::Component
        , public AZ::TickBus::Handler
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
        void Init() override;
        void Activate() override;
        void Deactivate() override;
        void OnTick(float deltaTime, AZ::ScriptTimePoint time) override;
    private:
        std::unique_ptr<SCR::Render::O3DE::O3deVolcanicIslandScene> m_scene;
        bool m_scenePrepared = false;
        bool m_rendererAttached = false;
        float m_accumulatedTime = 0.0f;
    };
}
