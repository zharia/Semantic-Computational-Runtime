#include "o3de/o3de_volcanic_island_scene.hpp"
#include "simulation_subjects.hpp"

namespace SCR::Render::O3DE {

O3deVolcanicIslandScene::O3deVolcanicIslandScene() {
    auto& reg = Simulation::SubjectRegistry::instance();
    coordinator = std::make_shared<Simulation::ConcurrentSystemCoordinator>(
        reg, Simulation::EventBus::instance());
}

Simulation::SceneMetadata O3deVolcanicIslandScene::getMetadata() const {
    Simulation::SceneMetadata meta;
    meta.id = "o3de_volcanic_island";
    meta.title = "SCR Volcanic Island (O3DE)";
    meta.subtitle = "Semantic Computational Runtime - O3DE Atom Renderer";
    meta.category = "simulation";
    meta.description = "Volcanic island simulation using SCR semantic fields "
                      "with O3DE Atom RPI rendering substrate";
    meta.semantic_contract = "SCR-LIB-SIMULATION";
    meta.author = "SCR";
    meta.version = "0.1.0";
    meta.feature_tags = {"terrain", "volcano", "ocean", "atmosphere",
                        "vegetation", "fields", "materials", "o3de"};
    return meta;
}

void O3deVolcanicIslandScene::prepare(Simulation::LoadingContext& ctx) {
    ctx.update(0.0f, "Initializing O3DE Volcanic Island", "Loading subsystems...", "CORE");

    auto& registry = Simulation::SubjectRegistry::instance();

    auto island = std::make_shared<Simulation::IslandSubject>();
    island->seed = 42;
    registry.registerSubject(island);

    auto player = std::make_shared<Simulation::PlayerSubject>();
    player->position = Spatial::Point3D(160.0f, 50.0f, 160.0f);
    registry.registerSubject(player);

    auto atmosphere = std::make_shared<Simulation::AtmosphereSubject>();
    registry.registerSubject(atmosphere);

    auto hydrology = std::make_shared<Simulation::HydrologySubject>();
    registry.registerSubject(hydrology);

    auto volcano = std::make_shared<Simulation::VolcanoSubject>();
    volcano->is_active = true;
    volcano->lava_viscosity = 1000.0f;
    volcano->caldera_temperature_kelvin = 1473.15f;
    registry.registerSubject(volcano);

    auto ecology = std::make_shared<Simulation::EcologySubject>();
    registry.registerSubject(ecology);

    struct NamedSystem : public Simulation::ISimulationSystem {
        std::string name;
        NamedSystem(std::string n) : name(std::move(n)) {}
        std::string getName() const override { return name; }
    };

    auto terrain = std::make_shared<O3deTerrainSubSystem>();
    auto volcano_sub = std::make_shared<O3deVolcanoSubSystem>();
    auto ocean = std::make_shared<O3deOceanSubSystem>();
    auto atmo = std::make_shared<O3deAtmosphereSubSystem>();
    auto veg = std::make_shared<O3deVegetationSubSystem>();

    auto geology = std::make_shared<NamedSystem>("Geology");
    geology->addSubSystem(terrain);
    geology->addSubSystem(volcano_sub);

    auto hydro = std::make_shared<NamedSystem>("Hydrology");
    hydro->addSubSystem(ocean);

    auto atmo_sys = std::make_shared<NamedSystem>("Atmosphere");
    atmo_sys->addSubSystem(atmo);

    auto eco_sys = std::make_shared<NamedSystem>("Ecology");
    eco_sys->addSubSystem(veg);

    coordinator->registerSystem(geology);
    coordinator->registerSystem(hydro);
    coordinator->registerSystem(atmo_sys);
    coordinator->registerSystem(eco_sys);

    coordinator->prepare(ctx);

    ctx.update(1.0f, "O3DE Volcanic Island Ready", "All subsystems initialized", "CORE");
}

void O3deVolcanicIslandScene::attachRenderer(Simulation::RenderContext& ctx) {
    coordinator->setRenderContext(ctx);
    coordinator->initialize();
}

void O3deVolcanicIslandScene::detachRenderer(Simulation::RenderContext& ctx) {
    coordinator->cleanup(ctx);
}

void O3deVolcanicIslandScene::update(float dt, const Simulation::UserInputState& input) {
    coordinator->stepSimulation(dt, input);
}

void O3deVolcanicIslandScene::renderPresentation(Simulation::RenderContext& ctx, float alpha) {
    coordinator->renderPipeline(1.0f / 60.0f);
}

bool O3deVolcanicIslandScene::handleKeyPress(int key, bool down, bool is_alt, bool is_ctrl) {
    return false;
}

} // namespace SCR::Render::O3DE
