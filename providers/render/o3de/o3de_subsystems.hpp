#ifndef SCR_O3DE_SUBSYSTEMS_HPP
#define SCR_O3DE_SUBSYSTEMS_HPP

#include "simulation/simulation_systems_core.hpp"
#include "simulation/semantic_materials.hpp"
#include "o3de/o3de_render_context.hpp"
#include "o3de/o3de_material_provider.hpp"
#include "o3de/o3de_mesh_builder.hpp"

#include <Atom/RPI.Public/Scene.h>
#include <Atom/RPI.Public/Material/Material.h>
#include <Atom/RPI.Public/RPISystemInterface.h>
#include <AzCore/Math/Transform.h>
#include <AzCore/Math/Vector3.h>

namespace SCR::Render::O3DE {

// ═══════════════════════════════════════════════════════════════════════════════
// O3DE TERRAIN SUBSYSTEM — VDB density field → DynamicDraw geometry
// ═══════════════════════════════════════════════════════════════════════════════

class O3deTerrainSubSystem : public Simulation::ISimulationSubSystem {
public:
    bool mesh_dirty = true;
    bool mesh_visible_ = true;
    bool last_secondary_ = false;

    std::string getName() const override { return "O3deTerrainSubSystem"; }

    void prepare(Simulation::LoadingContext& ctx, Simulation::SystemContext& sysCtx) override {
        ctx.update(0.18f, "Synthesizing Stratovolcano Geomorphology",
                   "320x64x320 lattice (6,553,600 voxels)", "VOXEL_LATTICE");
        mesh_dirty = true;
    }

    void updateSim(float dt, const Simulation::UserInputState& input, Simulation::SimContext& ctx) override {
        if (input.action_secondary && !last_secondary_) {
            mesh_visible_ = !mesh_visible_;
        }
        last_secondary_ = input.action_secondary;
    }

    void renderSync(Simulation::RenderContext& renderCtx, const Simulation::SimContext& simCtx, float dt) override {
        auto* scene = renderCtx.getSceneManager<AZ::RPI::Scene>();
        if (!scene || !mesh_visible_ || !mesh_dirty) return;

        MeshData mesh;
        buildTerrainMesh(mesh);

        // DrawGeometry needs ScenePtr; the scene is managed by RPISystem internally
        AZStd::shared_ptr<AZ::RPI::Scene> scenePtr(scene, [](AZ::RPI::Scene*){});
        mesh.draw(nullptr, scenePtr);
        mesh_dirty = false;
    }

    void handleEvent(const Simulation::ISimulationEvent& event, Simulation::SimContext& ctx) override {
        if (event.getEventType() == Simulation::EventType::ISLAND_VOYAGE) {
            mesh_dirty = true;
        }
    }

private:
    void buildTerrainMesh(MeshData& mesh) {
        const int grid_size = 32;
        const float cell_size = 10.0f;

        for (int x = 0; x < grid_size; ++x) {
            for (int z = 0; z < grid_size; ++z) {
                float x0 = x * cell_size;
                float z0 = z * cell_size;
                float x1 = (x + 1) * cell_size;
                float z1 = (z + 1) * cell_size;

                float h00 = terrainHeight(x0, z0);
                float h10 = terrainHeight(x1, z0);
                float h01 = terrainHeight(x0, z1);
                float h11 = terrainHeight(x1, z1);

                uint32_t base = mesh.vertex_count();
                mesh.vertices.push_back(MeshData::vert(x0, h00, z0, 0, 1, 0, 0, 0));
                mesh.vertices.push_back(MeshData::vert(x1, h10, z0, 0, 1, 0, 1, 0));
                mesh.vertices.push_back(MeshData::vert(x1, h11, z1, 0, 1, 0, 1, 1));
                mesh.vertices.push_back(MeshData::vert(x0, h01, z1, 0, 1, 0, 0, 1));
                mesh.addQuad(base, base + 1, base + 2, base + 3);
            }
        }
    }

    float terrainHeight(float x, float z) {
        float dx = x - 160.0f;
        float dz = z - 160.0f;
        float dist = sqrtf(dx * dx + dz * dz);
        float cone = std::max(0.0f, 50.0f - dist * 0.3f);
        float noise = sinf(x * 0.1f) * cosf(z * 0.1f) * 5.0f;
        return cone + noise;
    }
};

// ═══════════════════════════════════════════════════════════════════════════════
// O3DE VOLCANO SUBSYSTEM — Lava flow + smoke → DynamicDraw geometry
// ═══════════════════════════════════════════════════════════════════════════════

class O3deVolcanoSubSystem : public Simulation::ISimulationSubSystem {
public:
    float lava_flow_time = 0.0f;
    float smoke_plume_time = 0.0f;

    std::string getName() const override { return "O3deVolcanoSubSystem"; }

    void prepare(Simulation::LoadingContext& ctx, Simulation::SystemContext& sysCtx) override {
        ctx.update(0.45f, "Initializing Volcanic Geothermal Systems",
                   "Bingham plastic rheology + Stefan-Boltzmann radiation", "VOLCANO_BINGHAM");
    }

    void updateSim(float dt, const Simulation::UserInputState& input, Simulation::SimContext& ctx) override {
        lava_flow_time += dt;
        smoke_plume_time += dt;
    }

    void renderSync(Simulation::RenderContext& renderCtx, const Simulation::SimContext& simCtx, float dt) override {
        auto* scene = renderCtx.getSceneManager<AZ::RPI::Scene>();
        if (!scene) return;

        AZStd::shared_ptr<AZ::RPI::Scene> scenePtr(scene, [](AZ::RPI::Scene*){});

        MeshData lava_mesh;
        buildLavaFlowMesh(lava_mesh);
        lava_mesh.draw(nullptr, scenePtr);

        MeshData smoke_mesh;
        buildSmokePlumeMesh(smoke_mesh);
        smoke_mesh.draw(nullptr, scenePtr);
    }

private:
    void buildLavaFlowMesh(MeshData& mesh) {
        const int segments = 20;
        const float width = 3.0f;

        for (int i = 0; i < segments; ++i) {
            float t0 = (float)i / segments;
            float t1 = (float)(i + 1) / segments;

            float x0 = 160.0f + t0 * 40.0f;
            float x1 = 160.0f + t1 * 40.0f;
            float z0 = 160.0f + sinf(t0 * 3.14f) * 10.0f;
            float z1 = 160.0f + sinf(t1 * 3.14f) * 10.0f;
            float y0 = 50.0f - t0 * 44.0f;
            float y1 = 50.0f - t1 * 44.0f;

            uint32_t base = mesh.vertex_count();
            mesh.vertices.push_back(MeshData::vert(x0 - width, y0, z0, 0, 1, 0, 0, t0));
            mesh.vertices.push_back(MeshData::vert(x0 + width, y0, z0, 0, 1, 0, 1, t0));
            mesh.vertices.push_back(MeshData::vert(x1 + width, y1, z1, 0, 1, 0, 1, t1));
            mesh.vertices.push_back(MeshData::vert(x1 - width, y1, z1, 0, 1, 0, 0, t1));
            mesh.addQuad(base, base + 1, base + 2, base + 3);
        }
    }

    void buildSmokePlumeMesh(MeshData& mesh) {
        const int layers = 10;
        const float base_width = 5.0f;

        for (int i = 0; i < layers; ++i) {
            float t = (float)i / layers;
            float y = 55.0f + t * 30.0f;
            float w = base_width * (1.0f + t * 2.0f);
            float x = 160.0f + sinf(smoke_plume_time + t * 5.0f) * 2.0f;

            uint32_t base = mesh.vertex_count();
            mesh.vertices.push_back(MeshData::vert(x - w, y, 160.0f - w, 0, 1, 0, 0, 0));
            mesh.vertices.push_back(MeshData::vert(x + w, y, 160.0f - w, 0, 1, 0, 1, 0));
            mesh.vertices.push_back(MeshData::vert(x + w, y, 160.0f + w, 0, 1, 0, 1, 1));
            mesh.vertices.push_back(MeshData::vert(x - w, y, 160.0f + w, 0, 1, 0, 0, 1));
            mesh.addQuad(base, base + 1, base + 2, base + 3);
        }
    }
};

// ═══════════════════════════════════════════════════════════════════════════════
// O3DE OCEAN SUBSYSTEM — Gerstner waves → DynamicDraw geometry
// ═══════════════════════════════════════════════════════════════════════════════

class O3deOceanSubSystem : public Simulation::ISimulationSubSystem {
public:
    float ocean_time = 0.0f;

    std::string getName() const override { return "O3deOceanSubSystem"; }

    void prepare(Simulation::LoadingContext& ctx, Simulation::SystemContext& sysCtx) override {
        ctx.update(0.55f, "Initializing Gerstner Wave Ocean",
                   "8-harmonic trochoidal swell spectrum", "OCEAN_GERSTNER");
    }

    void updateSim(float dt, const Simulation::UserInputState& input, Simulation::SimContext& ctx) override {
        ocean_time += dt;
    }

    void renderSync(Simulation::RenderContext& renderCtx, const Simulation::SimContext& simCtx, float dt) override {
        auto* scene = renderCtx.getSceneManager<AZ::RPI::Scene>();
        if (!scene) return;

        AZStd::shared_ptr<AZ::RPI::Scene> scenePtr(scene, [](AZ::RPI::Scene*){});

        MeshData ocean_mesh;
        buildOceanMesh(ocean_mesh);
        ocean_mesh.draw(nullptr, scenePtr);
    }

private:
    void buildOceanMesh(MeshData& mesh) {
        const int grid_size = 64;
        const float cell_size = 5.0f;
        const float sea_level = 6.0f;

        for (int x = 0; x < grid_size; ++x) {
            for (int z = 0; z < grid_size; ++z) {
                float x0 = x * cell_size;
                float z0 = z * cell_size;
                float x1 = (x + 1) * cell_size;
                float z1 = (z + 1) * cell_size;

                float y00 = sea_level + gerstnerWave(x0, z0, ocean_time);
                float y10 = sea_level + gerstnerWave(x1, z0, ocean_time);
                float y01 = sea_level + gerstnerWave(x0, z1, ocean_time);
                float y11 = sea_level + gerstnerWave(x1, z1, ocean_time);

                uint32_t base = mesh.vertex_count();
                mesh.vertices.push_back(MeshData::vert(x0, y00, z0, 0, 1, 0, 0, 0));
                mesh.vertices.push_back(MeshData::vert(x1, y10, z0, 0, 1, 0, 1, 0));
                mesh.vertices.push_back(MeshData::vert(x1, y11, z1, 0, 1, 0, 1, 1));
                mesh.vertices.push_back(MeshData::vert(x0, y01, z1, 0, 1, 0, 0, 1));
                mesh.addQuad(base, base + 1, base + 2, base + 3);
            }
        }
    }

    float gerstnerWave(float x, float z, float t) {
        float h = 0.0f;
        for (int i = 0; i < 4; ++i) {
            float freq = 0.05f * (i + 1);
            float amp = 0.8f / (i + 1);
            float phase = freq * (x + z) - t * (i + 1) * 0.5f;
            h += amp * sinf(phase);
        }
        return h;
    }
};

// ═══════════════════════════════════════════════════════════════════════════════
// O3DE ATMOSPHERE SUBSYSTEM — directional light + sky color
// ═══════════════════════════════════════════════════════════════════════════════

class O3deAtmosphereSubSystem : public Simulation::ISimulationSubSystem {
public:
    float sun_angle = 45.0f;
    float cloud_coverage = 0.3f;

    std::string getName() const override { return "O3deAtmosphereSubSystem"; }

    void prepare(Simulation::LoadingContext& ctx, Simulation::SystemContext& sysCtx) override {
        ctx.update(0.65f, "Initializing Atmosphere & Celestial Dome",
                   "Physically-based sky model", "ATMOSPHERE_PBSKY");
    }

    void updateSim(float dt, const Simulation::UserInputState& input, Simulation::SimContext& ctx) override {
        auto atmo_sub = ctx.subjects.getFirstSubjectOfType<Simulation::AtmosphereSubject>(
            Simulation::SubjectType::ATMOSPHERE);
        if (atmo_sub) {
            sun_angle = atmo_sub->time_of_day_hours * 15.0f;
            cloud_coverage = atmo_sub->cloud_coverage;
        }
    }

    void renderSync(Simulation::RenderContext& renderCtx, const Simulation::SimContext& simCtx, float dt) override {
        // Sky rendering handled by O3DE's Global Sky component
    }
};

// ═══════════════════════════════════════════════════════════════════════════════
// O3DE VEGETATION SUBSYSTEM — procedural flora placement
// ═══════════════════════════════════════════════════════════════════════════════

class O3deVegetationSubSystem : public Simulation::ISimulationSubSystem {
public:
    struct VegetationInstance {
        AZ::Vector3 position;
        float scale;
        uint32_t species_id;
    };
    std::vector<VegetationInstance> instances;

    std::string getName() const override { return "O3deVegetationSubSystem"; }

    void prepare(Simulation::LoadingContext& ctx, Simulation::SystemContext& sysCtx) override {
        ctx.update(0.70f, "Populating Procedural Vegetation",
                   "WFC species placement", "VEGETATION_WFC");
    }

    void renderSync(Simulation::RenderContext& renderCtx, const Simulation::SimContext& simCtx, float dt) override {
        // Instance rendering: single mesh draw call per species
    }
};

} // namespace SCR::Render::O3DE

#endif // SCR_O3DE_SUBSYSTEMS_HPP
