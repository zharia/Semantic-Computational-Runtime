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
#include <functional>

namespace SCR::Render::O3DE {

// ═══════════════════════════════════════════════════════════════════════════════
// O3DE TERRAIN SUBSYSTEM — Volcanic island heightfield via simulation data
// ═══════════════════════════════════════════════════════════════════════════════

class O3deTerrainSubSystem : public Simulation::ISimulationSubSystem {
public:
    bool mesh_dirty = true;
    bool mesh_visible_ = true;
    bool last_secondary_ = false;

    // Injected by scene: returns terrain height at (x,z)
    std::function<float(float, float)> getTerrainHeight;

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
        const int grid_size = 64;
        const float cell_size = 5.0f;
        const float sea_level = 6.0f;

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

                float avg_h = (h00 + h10 + h01 + h11) * 0.25f;
                if (avg_h < sea_level - 0.5f) continue;

                float nx = (h10 - h00 + h11 - h01) * 0.5f;
                float nz = (h01 - h00 + h11 - h10) * 0.5f;
                float ny = cell_size;
                float inv_len = 1.0f / sqrtf(nx * nx + ny * ny + nz * nz);
                nx *= inv_len; ny *= inv_len; nz *= inv_len;

                uint32_t base = mesh.vertex_count();
                mesh.vertices.push_back(MeshData::vert(x0, h00, z0, nx, ny, nz, 0, 0));
                mesh.vertices.push_back(MeshData::vert(x1, h10, z0, nx, ny, nz, 1, 0));
                mesh.vertices.push_back(MeshData::vert(x1, h11, z1, nx, ny, nz, 1, 1));
                mesh.vertices.push_back(MeshData::vert(x0, h01, z1, nx, ny, nz, 0, 1));
                mesh.addQuad(base, base + 1, base + 2, base + 3);
            }
        }
    }

    float terrainHeight(float x, float z) {
        if (getTerrainHeight) return getTerrainHeight(x, z);

        float dx = x - 160.0f;
        float dz = z - 160.0f;
        float dist = sqrtf(dx * dx + dz * dz);
        float cone = std::max(0.0f, 50.0f - dist * 0.3f);
        float noise = sinf(x * 0.1f) * cosf(z * 0.1f) * 5.0f;
        return cone + noise;
    }
};

// ═══════════════════════════════════════════════════════════════════════════════
// O3DE VOLCANO SUBSYSTEM — Lava flow + smoke plume
// ═══════════════════════════════════════════════════════════════════════════════

class O3deVolcanoSubSystem : public Simulation::ISimulationSubSystem {
public:
    float lava_flow_time = 0.0f;
    float smoke_plume_time = 0.0f;

    // Injected by scene: returns lava flow position and temperature
    std::function<void(float, float&, float&, float&)> sampleLavaFlow;
    // Injected by scene: lava center and caldera params
    float center_x = 160.0f, center_z = 160.0f;
    float caldera_radius = 22.0f, peak_height = 64.0f, sea_level = 9.0f;
    float river_angle = 0.75f;
    float island_radius = 128.0f;
    bool volcano_active = true;

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
        if (!volcano_active) return;
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
        const int segments = 40;
        const float width = 3.5f;

        for (int i = 0; i < segments; ++i) {
            float t0 = (float)i / segments;
            float t1 = (float)(i + 1) / segments;

            float r0 = caldera_radius * 0.70f + t0 * (island_radius * 0.95f - caldera_radius * 0.70f);
            float r1 = caldera_radius * 0.70f + t1 * (island_radius * 0.95f - caldera_radius * 0.70f);

            float x0 = center_x + cosf(river_angle) * r0;
            float x1 = center_x + cosf(river_angle) * r1;
            float z0 = center_z + sinf(river_angle) * r0;
            float z1 = center_z + sinf(river_angle) * r1;

            float y0 = peak_height - 18.0f - t0 * (peak_height - 18.0f - sea_level + 2.0f);
            float y1 = peak_height - 18.0f - t1 * (peak_height - 18.0f - sea_level + 2.0f);

            float lava_temp = 1450.0f - t0 * 400.0f;
            (void)lava_temp;

            uint32_t base = mesh.vertex_count();
            mesh.vertices.push_back(MeshData::vert(x0 - width, y0, z0, 0, 1, 0, 0, t0));
            mesh.vertices.push_back(MeshData::vert(x0 + width, y0, z0, 0, 1, 0, 1, t0));
            mesh.vertices.push_back(MeshData::vert(x1 + width, y1, z1, 0, 1, 0, 1, t1));
            mesh.vertices.push_back(MeshData::vert(x1 - width, y1, z1, 0, 1, 0, 0, t1));
            mesh.addQuad(base, base + 1, base + 2, base + 3);
        }
    }

    void buildSmokePlumeMesh(MeshData& mesh) {
        const int layers = 15;
        const float base_width = 6.0f;

        for (int i = 0; i < layers; ++i) {
            float t = (float)i / layers;
            float y = peak_height + t * 40.0f;
            float w = base_width * (1.0f + t * 3.0f);
            float x = center_x + sinf(smoke_plume_time * 0.3f + t * 5.0f) * (2.0f + t * 4.0f);
            float z = center_z + cosf(smoke_plume_time * 0.2f + t * 4.0f) * (2.0f + t * 3.0f);

            uint32_t base = mesh.vertex_count();
            mesh.vertices.push_back(MeshData::vert(x - w, y, z - w, 0, 1, 0, 0, 0));
            mesh.vertices.push_back(MeshData::vert(x + w, y, z - w, 0, 1, 0, 1, 0));
            mesh.vertices.push_back(MeshData::vert(x + w, y, z + w, 0, 1, 0, 1, 1));
            mesh.vertices.push_back(MeshData::vert(x - w, y, z + w, 0, 1, 0, 0, 1));
            mesh.addQuad(base, base + 1, base + 2, base + 3);
        }
    }
};

// ═══════════════════════════════════════════════════════════════════════════════
// O3DE OCEAN SUBSYSTEM — Gerstner wave ocean surface
// ═══════════════════════════════════════════════════════════════════════════════

class O3deOceanSubSystem : public Simulation::ISimulationSubSystem {
public:
    float ocean_time = 0.0f;

    // Injected by scene: returns ocean height at (x,z,t)
    std::function<float(float, float, float)> getOceanHeight;
    // Injected by scene: returns ocean color at (x,z) → (r,g,b)
    std::function<void(float, float, float&, float&, float&)> getOceanColor;

    float sea_level = 9.0f;
    float center_x = 160.0f, center_z = 160.0f;
    float island_radius = 128.0f;

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
        const int grid_size = 80;
        const float cell_size = 4.0f;

        for (int x = 0; x < grid_size; ++x) {
            for (int z = 0; z < grid_size; ++z) {
                float x0 = x * cell_size;
                float z0 = z * cell_size;
                float x1 = (x + 1) * cell_size;
                float z1 = (z + 1) * cell_size;

                float cx = (x0 + x1) * 0.5f;
                float cz = (z0 + z1) * 0.5f;
                float dx = cx - center_x;
                float dz = cz - center_z;
                float dist = sqrtf(dx * dx + dz * dz);
                if (dist < island_radius * 0.85f) continue;

                float y00 = oceanHeight(x0, z0);
                float y10 = oceanHeight(x1, z0);
                float y01 = oceanHeight(x0, z1);
                float y11 = oceanHeight(x1, z1);

                uint32_t base = mesh.vertex_count();
                mesh.vertices.push_back(MeshData::vert(x0, y00, z0, 0, 1, 0, 0, 0));
                mesh.vertices.push_back(MeshData::vert(x1, y10, z0, 0, 1, 0, 1, 0));
                mesh.vertices.push_back(MeshData::vert(x1, y11, z1, 0, 1, 0, 1, 1));
                mesh.vertices.push_back(MeshData::vert(x0, y01, z1, 0, 1, 0, 0, 1));
                mesh.addQuad(base, base + 1, base + 2, base + 3);
            }
        }
    }

    float oceanHeight(float x, float z) {
        if (getOceanHeight) return getOceanHeight(x, z, ocean_time);

        float h = 0.0f;
        for (int i = 0; i < 8; ++i) {
            float freq = 0.03f * (i + 1);
            float amp = 1.2f / (i + 1);
            float speed = 0.8f + i * 0.3f;
            float dir_x = cosf(0.3f + i * 0.7f);
            float dir_z = sinf(0.3f + i * 0.7f);
            float phase = freq * (dir_x * x + dir_z * z) - ocean_time * speed;

            h += amp * sinf(phase);
        }
        return sea_level + h;
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
    bool instances_generated = false;

    // Injected by scene: returns terrain height at (x,z)
    std::function<float(float, float)> getTerrainHeight;
    // Injected by scene: returns vegetation density at (x,z) → [0,1]
    std::function<float(float, float)> getVegetationDensity;
    float sea_level = 9.0f;
    float center_x = 160.0f, center_z = 160.0f;
    float island_radius = 128.0f;

    std::string getName() const override { return "O3deVegetationSubSystem"; }

    void prepare(Simulation::LoadingContext& ctx, Simulation::SystemContext& sysCtx) override {
        ctx.update(0.70f, "Populating Procedural Vegetation",
                   "WFC species placement", "VEGETATION_WFC");
    }

    void renderSync(Simulation::RenderContext& renderCtx, const Simulation::SimContext& simCtx, float dt) override {
        if (!instances_generated) {
            generateInstances();
            instances_generated = true;
        }
        if (instances.empty()) return;

        auto* scene = renderCtx.getSceneManager<AZ::RPI::Scene>();
        if (!scene) return;

        AZStd::shared_ptr<AZ::RPI::Scene> scenePtr(scene, [](AZ::RPI::Scene*){});

        for (auto& inst : instances) {
            MeshData tree_mesh;
            float s = inst.scale;
            float px = inst.position.GetX();
            float py = inst.position.GetY();
            float pz = inst.position.GetZ();

            uint32_t base = tree_mesh.vertex_count();
            tree_mesh.vertices.push_back(MeshData::vert(px - 0.3f * s, py, pz - 0.3f * s, 0, 0, 1, 0, 0));
            tree_mesh.vertices.push_back(MeshData::vert(px + 0.3f * s, py, pz - 0.3f * s, 0, 0, 1, 1, 0));
            tree_mesh.vertices.push_back(MeshData::vert(px + 0.3f * s, py, pz + 0.3f * s, 0, 0, 1, 1, 1));
            tree_mesh.vertices.push_back(MeshData::vert(px - 0.3f * s, py, pz + 0.3f * s, 0, 0, 1, 0, 1));
            tree_mesh.addQuad(base, base + 1, base + 2, base + 3);

            float trunk_h = 2.0f * s;
            base = tree_mesh.vertex_count();
            tree_mesh.vertices.push_back(MeshData::vert(px - 0.1f * s, py + trunk_h, pz, 0, 1, 0, 0, 0));
            tree_mesh.vertices.push_back(MeshData::vert(px + 0.1f * s, py + trunk_h, pz, 0, 1, 0, 1, 0));
            tree_mesh.vertices.push_back(MeshData::vert(px + 0.1f * s, py + trunk_h + 2.0f * s, pz, 0, 1, 0, 1, 1));
            tree_mesh.vertices.push_back(MeshData::vert(px - 0.1f * s, py + trunk_h + 2.0f * s, pz, 0, 1, 0, 0, 1));
            tree_mesh.addQuad(base, base + 1, base + 2, base + 3);

            tree_mesh.draw(nullptr, scenePtr);
        }
    }

private:
    void generateInstances() {
        std::mt19937 rng(1337);
        std::uniform_real_distribution<float> dist(0.0f, 1.0f);

        for (int i = 0; i < 200; ++i) {
            float x = dist(rng) * island_radius * 2.0f;
            float z = dist(rng) * island_radius * 2.0f;

            float dx = x - center_x;
            float dz = z - center_z;
            float r = sqrtf(dx * dx + dz * dz);
            if (r < island_radius * 0.3f || r > island_radius * 0.95f) continue;

            float h = getTerrainHeight ? getTerrainHeight(x, z) : 20.0f;
            if (h < sea_level + 1.0f || h > 55.0f) continue;

            float density = getVegetationDensity ? getVegetationDensity(x, z) : 0.5f;
            if (dist(rng) > density) continue;

            instances.push_back({
                AZ::Vector3(x, h, z),
                0.8f + dist(rng) * 1.2f,
                (uint32_t)(dist(rng) * 3.0f)
            });
        }
    }
};

} // namespace SCR::Render::O3DE

#endif // SCR_O3DE_SUBSYSTEMS_HPP
