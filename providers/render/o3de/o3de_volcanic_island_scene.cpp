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
    meta.description = "Active stratovolcano with Bingham plastic lava river, "
                       "Gerstner wave ocean, volumetric smoke plume, "
                       "procedural vegetation via O3DE Atom RPI";
    meta.semantic_contract = "SCR-LIB-SIMULATION";
    meta.author = "SCR";
    meta.version = "1.0.0";
    meta.feature_tags = {"terrain", "volcano", "ocean", "atmosphere",
                        "vegetation", "fields", "materials", "o3de"};
    return meta;
}

void O3deVolcanicIslandScene::prepare(Simulation::LoadingContext& ctx) {
    ctx.update(0.05f, "Ingesting Semantic Material Registry", "101 materials registered", "MATERIAL_REGISTRY");
    (void)Material::MaterialRegistry::instance();

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

    auto terrain_sub = std::make_shared<O3deTerrainSubSystem>();
    auto volcano_sub = std::make_shared<O3deVolcanoSubSystem>();
    auto ocean_sub = std::make_shared<O3deOceanSubSystem>();
    auto atmo_sub = std::make_shared<O3deAtmosphereSubSystem>();
    auto veg_sub = std::make_shared<O3deVegetationSubSystem>();

    if (island->voxel_island) {
        auto vi = island->voxel_island;
        float cx = vi->center_x;
        float cz = vi->center_z;

        terrain_sub->getTerrainHeight = [vi](float x, float z) -> float {
            return vi->getIslandHeight(x, z);
        };

        volcano_sub->center_x = cx;
        volcano_sub->center_z = cz;
        volcano_sub->caldera_radius = vi->caldera_radius;
        volcano_sub->peak_height = vi->peak_height;
        volcano_sub->sea_level = vi->sea_level;
        volcano_sub->island_radius = vi->island_radius;
        volcano_sub->volcano_active = volcano->is_active;

        ocean_sub->center_x = cx;
        ocean_sub->center_z = cz;
        ocean_sub->island_radius = vi->island_radius;
        ocean_sub->sea_level = vi->sea_level;

        veg_sub->center_x = cx;
        veg_sub->center_z = cz;
        veg_sub->island_radius = vi->island_radius;
        veg_sub->sea_level = vi->sea_level;
        veg_sub->getTerrainHeight = [vi](float x, float z) -> float {
            return vi->getIslandHeight(x, z);
        };
        veg_sub->getVegetationDensity = [vi](float x, float z) -> float {
            float h = vi->getIslandHeight(x, z);
            if (h < vi->sea_level + 1.0f || h > 55.0f) return 0.0f;
            float dx = x - vi->center_x;
            float dz = z - vi->center_z;
            float r = sqrtf(dx * dx + dz * dz);
            if (r < vi->island_radius * 0.3f || r > vi->island_radius * 0.95f) return 0.0f;
            float edge = 1.0f - (r / vi->island_radius);
            return std::max(0.0f, edge * 1.5f);
        };
    }

    auto geology = std::make_shared<NamedSystem>("Geology");
    geology->addSubSystem(terrain_sub);
    geology->addSubSystem(volcano_sub);

    auto hydro = std::make_shared<NamedSystem>("Hydrology");
    hydro->addSubSystem(ocean_sub);

    auto atmo_sys = std::make_shared<NamedSystem>("Atmosphere");
    atmo_sys->addSubSystem(atmo_sub);

    auto eco_sys = std::make_shared<NamedSystem>("Ecology");
    eco_sys->addSubSystem(veg_sub);

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
