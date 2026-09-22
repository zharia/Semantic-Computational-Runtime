#include <AzCore/Serialization/SerializeContext.h>
#include <AzCore/Component/TickBus.h>
#include "SCR_VolcanicIslandSystemComponent.h"
#include "render/o3de/o3de_volcanic_island_scene.hpp"
#include "render/o3de/o3de_render_context.hpp"

#include <Atom/RPI.Public/Scene.h>
#include <Atom/RPI.Public/RPISystemInterface.h>
#include <Atom/RPI.Public/RenderPipeline.h>
#include <Atom/RPI.Public/ViewportContext.h>
#include <Atom/RPI.Public/RPIUtils.h>
#include <AzCore/Math/Transform.h>

namespace SCR_VolcanicIsland {
    AZ_COMPONENT_IMPL(SCR_VolcanicIslandSystemComponent, "SCR_VolcanicIslandSystemComponent",
        "{E5C9A000-0010-4000-8000-000000000010}");

    void SCR_VolcanicIslandSystemComponent::Reflect(AZ::ReflectContext* context)
    {
        if (auto serializeContext = azrtti_cast<AZ::SerializeContext*>(context))
        {
            serializeContext->Class<SCR_VolcanicIslandSystemComponent, AZ::Component>()
                ->Version(1);
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

    void SCR_VolcanicIslandSystemComponent::Init() {}

    void SCR_VolcanicIslandSystemComponent::Activate()
    {
        AZ::TickBus::Handler::BusConnect();
    }

    void SCR_VolcanicIslandSystemComponent::Deactivate()
    {
        if (m_scene && m_rendererAttached) {
            auto defaultScene = AZ::RPI::RPISystemInterface::Get()->GetDefaultScene();
            if (defaultScene) {
                SCR::Simulation::RenderContext renderCtx;
                SCR::Render::O3DE::setScene(renderCtx, defaultScene.get());
                m_scene->detachRenderer(renderCtx);
            }
            m_rendererAttached = false;
        }
        m_scene.reset();
        AZ::TickBus::Handler::BusDisconnect();
    }

    void SCR_VolcanicIslandSystemComponent::OnTick(float deltaTime, [[maybe_unused]] AZ::ScriptTimePoint time)
    {
        if (!m_scene) {
            m_scene = std::make_unique<SCR::Render::O3DE::O3deVolcanicIslandScene>();
        }

        if (!m_scenePrepared) {
            SCR::Simulation::LoadingContext loadCtx;
            m_scene->prepare(loadCtx);
            m_scenePrepared = true;
        }

        if (!m_rendererAttached) {
            auto defaultScene = AZ::RPI::RPISystemInterface::Get()->GetDefaultScene();
            if (defaultScene) {
                SCR::Simulation::RenderContext renderCtx;
                SCR::Render::O3DE::setScene(renderCtx, defaultScene.get());
                m_scene->attachRenderer(renderCtx);
                m_rendererAttached = true;
            }
        }

        // Force camera every tick — EditorCameraComponent fights one-shot sets
        if (auto vpCtx = AZ::RPI::GetDefaultViewportContext()) {
            AZ::Transform camT = AZ::Transform::CreateLookAt(
                AZ::Vector3(180.0f, -220.0f, 90.0f),
                AZ::Vector3(0.0f, 0.0f, 30.0f));
            vpCtx->SetCameraTransform(camT);
        }

        SCR::Simulation::UserInputState input;
        m_scene->update(deltaTime, input);
        m_accumulatedTime += deltaTime;
    }
}
