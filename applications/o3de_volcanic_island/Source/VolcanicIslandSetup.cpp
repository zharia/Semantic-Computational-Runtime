/// @file VolcanicIslandSetup.cpp
/// @brief Volcanic island entity setup using SCR framework
/// @version 0.0.4
/// @date 2026-09-21
///
/// Creates volcanic island entities with SCR semantic contracts:
/// - Terrain entity (ground)
/// - Volcano entity (mountain)
/// - Lava entity (flowing lava)
/// - Water entity (ocean)
/// - Camera entity (viewer)

#include <AzCore/Component/ComponentApplication.h>
#include <AzCore/Component/Entity.h>
#include <AzCore/Component/TransformBus.h>
#include <AzCore/Math/Transform.h>
#include <AzCore/Math/Vector3.h>
#include <AzCore/Math/Quaternion.h>
#include <AzCore/Console/IConsole.h>
#include <AzCore/Serialization/SerializeContext.h>

// SCR Integration
#include "SCRIntegrationBus.h"

namespace SCR::VolcanicIsland {

/// @brief Create a terrain entity
AZ::EntityId createTerrain(AZ::ComponentApplication* app)
{
    auto* entity = aznew AZ::Entity("Terrain");
    
    // SCR SID: Terrain
    SCR::Integration::SCR_SID terrainSid;
    terrainSid.root_authority = 1;
    terrainSid.allocation_domain = 1;
    terrainSid.coordinate = 1001;
    
    // SCR Transform: Ground at origin
    SCR::Integration::SCR_SimTransform terrainTransform;
    terrainTransform.position = {0.0, 0.0, 0.0};
    terrainTransform.rotation = {1.0, 0.0, 0.0, 0.0};
    terrainTransform.scale = 1.0;
    
    // Create SCR component
    auto* scrComponent = aznew SCR::Integration::SCRIntegrationComponent();
    scrComponent->SetSID(terrainSid);
    scrComponent->SetSCRTransform(terrainTransform);
    entity->AddComponent(scrComponent);
    
    // Create transform component
    auto* transformComponent = aznew AZ::TransformComponent();
    entity->AddComponent(transformComponent);
    
    entity->Init();
    entity->Activate();
    
    AZ_Printf("VolcanicIsland", "Created terrain entity [%llu, %llu, %llu]",
        terrainSid.root_authority, terrainSid.allocation_domain, terrainSid.coordinate);
    
    return entity->GetId();
}

/// @brief Create a volcano entity
AZ::EntityId createVolcano(AZ::ComponentApplication* app)
{
    auto* entity = aznew AZ::Entity("Volcano");
    
    // SCR SID: Volcano
    SCR::Integration::SCR_SID volcanoSid;
    volcanoSid.root_authority = 1;
    volcanoSid.allocation_domain = 1;
    volcanoSid.coordinate = 2001;
    
    // SCR Transform: Center of island, elevated
    SCR::Integration::SCR_SimTransform volcanoTransform;
    volcanoTransform.position = {0.0, 50.0, 0.0};  // 50m up
    volcanoTransform.rotation = {1.0, 0.0, 0.0, 0.0};
    volcanoTransform.scale = 1.0;
    
    // Create SCR component
    auto* scrComponent = aznew SCR::Integration::SCRIntegrationComponent();
    scrComponent->SetSID(volcanoSid);
    scrComponent->SetSCRTransform(volcanoTransform);
    entity->AddComponent(scrComponent);
    
    // Create transform component
    auto* transformComponent = aznew AZ::TransformComponent();
    entity->AddComponent(transformComponent);
    
    entity->Init();
    entity->Activate();
    
    AZ_Printf("VolcanicIsland", "Created volcano entity [%llu, %llu, %llu]",
        volcanoSid.root_authority, volcanoSid.allocation_domain, volcanoSid.coordinate);
    
    return entity->GetId();
}

/// @brief Create a lava flow entity
AZ::EntityId createLavaFlow(AZ::ComponentApplication* app, float offsetX, float offsetZ)
{
    auto* entity = aznew AZ::Entity("LavaFlow");
    
    // SCR SID: Lava
    SCR::Integration::SCR_SID lavaSid;
    lavaSid.root_authority = 1;
    lavaSid.allocation_domain = 1;
    lavaSid.coordinate = 3001;
    
    // SCR Transform: Flowing down from volcano
    SCR::Integration::SCR_SimTransform lavaTransform;
    lavaTransform.position = {offsetX, 45.0, offsetZ};
    lavaTransform.rotation = {1.0, 0.0, 0.0, 0.0};
    lavaTransform.scale = 1.0;
    
    // Create SCR component
    auto* scrComponent = aznew SCR::Integration::SCRIntegrationComponent();
    scrComponent->SetSID(lavaSid);
    scrComponent->SetSCRTransform(lavaTransform);
    entity->AddComponent(scrComponent);
    
    // Create transform component
    auto* transformComponent = aznew AZ::TransformComponent();
    entity->AddComponent(transformComponent);
    
    entity->Init();
    entity->Activate();
    
    AZ_Printf("VolcanicIsland", "Created lava flow entity [%llu, %llu, %llu]",
        lavaSid.root_authority, lavaSid.allocation_domain, lavaSid.coordinate);
    
    return entity->GetId();
}

/// @brief Create water entity
AZ::EntityId createWater(AZ::ComponentApplication* app)
{
    auto* entity = aznew AZ::Entity("Water");
    
    // SCR SID: Water
    SCR::Integration::SCR_SID waterSid;
    waterSid.root_authority = 1;
    waterSid.allocation_domain = 1;
    waterSid.coordinate = 4001;
    
    // SCR Transform: Sea level
    SCR::Integration::SCR_SimTransform waterTransform;
    waterTransform.position = {0.0, 0.0, 0.0};
    waterTransform.rotation = {1.0, 0.0, 0.0, 0.0};
    waterTransform.scale = 100.0;  // Large water plane
    
    // Create SCR component
    auto* scrComponent = aznew SCR::Integration::SCRIntegrationComponent();
    scrComponent->SetSID(waterSid);
    scrComponent->SetSCRTransform(waterTransform);
    entity->AddComponent(scrComponent);
    
    // Create transform component
    auto* transformComponent = aznew AZ::TransformComponent();
    entity->AddComponent(transformComponent);
    
    entity->Init();
    entity->Activate();
    
    AZ_Printf("VolcanicIsland", "Created water entity [%llu, %llu, %llu]",
        waterSid.root_authority, waterSid.allocation_domain, waterSid.coordinate);
    
    return entity->GetId();
}

/// @brief Create camera entity
AZ::EntityId createCamera(AZ::ComponentApplication* app)
{
    auto* entity = aznew AZ::Entity("Camera");
    
    // SCR SID: Camera
    SCR::Integration::SCR_SID cameraSid;
    cameraSid.root_authority = 1;
    cameraSid.allocation_domain = 1;
    cameraSid.coordinate = 5001;
    
    // SCR Transform: Looking at island from distance
    SCR::Integration::SCR_SimTransform cameraTransform;
    cameraTransform.position = {100.0, 80.0, 100.0};
    cameraTransform.rotation = {0.924, 0.0, -0.383, 0.0};  // Look at origin
    cameraTransform.scale = 1.0;
    
    // Create SCR component
    auto* scrComponent = aznew SCR::Integration::SCRIntegrationComponent();
    scrComponent->SetSID(cameraSid);
    scrComponent->SetSCRTransform(cameraTransform);
    entity->AddComponent(scrComponent);
    
    // Create transform component
    auto* transformComponent = aznew AZ::TransformComponent();
    entity->AddComponent(transformComponent);
    
    entity->Init();
    entity->Activate();
    
    AZ_Printf("VolcanicIsland", "Created camera entity [%llu, %llu, %llu]",
        cameraSid.root_authority, cameraSid.allocation_domain, cameraSid.coordinate);
    
    return entity->GetId();
}

/// @brief Setup volcanic island scene
void setupVolcanicIsland(AZ::ComponentApplication* app)
{
    AZ_Printf("VolcanicIsland", "Setting up volcanic island scene...");
    
    // Create entities
    AZ::EntityId terrainId = createTerrain(app);
    AZ::EntityId volcanoId = createVolcano(app);
    AZ::EntityId lavaId1 = createLavaFlow(app, 10.0f, 5.0f);
    AZ::EntityId lavaId2 = createLavaFlow(app, -8.0f, 7.0f);
    AZ::EntityId waterId = createWater(app);
    AZ::EntityId cameraId = createCamera(app);
    
    AZ_Printf("VolcanicIsland", "Volcanic island scene created successfully!");
    AZ_Printf("VolcanicIsland", "  Terrain: [%llu, %llu, %llu]", 
        terrainId.m_storage, 0ULL, 0ULL);
    AZ_Printf("VolcanicIsland", "  Volcano: [%llu, %llu, %llu]",
        volcanoId.m_storage, 0ULL, 0ULL);
    AZ_Printf("VolcanicIsland", "  Lava 1: [%llu, %llu, %llu]",
        lavaId1.m_storage, 0ULL, 0ULL);
    AZ_Printf("VolcanicIsland", "  Lava 2: [%llu, %llu, %llu]",
        lavaId2.m_storage, 0ULL, 0ULL);
    AZ_Printf("VolcanicIsland", "  Water: [%llu, %llu, %llu]",
        waterId.m_storage, 0ULL, 0ULL);
    AZ_Printf("VolcanicIsland", "  Camera: [%llu, %llu, %llu]",
        cameraId.m_storage, 0ULL, 0ULL);
}

} // namespace SCR::VolcanicIsland

// ═══════════════════════════════════════════════════════════════════════════
// Entry point
// ═══════════════════════════════════════════════════════════════════════════

int main(int argc, char** argv)
{
    AZ::ComponentApplication app;
    
    // Initialize O3DE
    AZ::ComponentApplication::Descriptor appDesc;
    appDesc.m_consoleCommandsEnabled = true;
    
    app.Create(appDesc);
    
    // Setup volcanic island
    SCR::VolcanicIsland::setupVolcanicIsland(&app);
    
    AZ_Printf("VolcanicIsland", "Press Ctrl+C to exit...");
    
    // Run main loop
    app.Run();
    
    return 0;
}
