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
    O3deMeshHandle mesh_handle;

    float sea_level = 9.0f;
    float center_x = 160.0f, center_z = 160.0f;
    float island_radius = 128.0f;

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

        if (mesh_handle.valid) {
            auto* fp = scene->GetFeatureProcessor<AZ::Render::MeshFeatureProcessorInterface>();
            if (fp) fp->ReleaseMesh(mesh_handle.handle);
            mesh_handle.valid = false;
        }

        AZStd::shared_ptr<AZ::RPI::Scene> scenePtr(scene, [](AZ::RPI::Scene*){});
        MeshData mesh;
        buildTerrainMesh(mesh);
        mesh_handle = submitMeshData(scenePtr, mesh, MaterialCache::instance().terrain,
            AZ::Transform::CreateIdentity(), AZ::Vector3(1.0f, 1.0f, 1.0f), "terrain");
        if (mesh_handle.valid) mesh_dirty = false;
    }

    void cleanup(Simulation::RenderContext& renderCtx) override {
        auto* scene = renderCtx.getSceneManager<AZ::RPI::Scene>();
        if (scene && mesh_handle.valid) {
            auto* fp = scene->GetFeatureProcessor<AZ::Render::MeshFeatureProcessorInterface>();
            if (fp) fp->ReleaseMesh(mesh_handle.handle);
            mesh_handle.valid = false;
        }
    }

    void handleEvent(const Simulation::ISimulationEvent& event, Simulation::SimContext& ctx) override {
        if (event.getEventType() == Simulation::EventType::ISLAND_VOYAGE) {
            mesh_dirty = true;
        }
    }

private:
    void buildTerrainMesh(MeshData& mesh) {
        const int grid_size = 96;
        const float cell_size = 4.0f;
        const float sea_level = this->sea_level;

        // SCR: +Y up, island center (160,160). O3DE: +Z up, origin at island center.
        for (int sx = 0; sx < grid_size; ++sx) {
            for (int sz = 0; sz < grid_size; ++sz) {
                float x0 = sx * cell_size;
                float z0 = sz * cell_size;
                float x1 = (sx + 1) * cell_size;
                float z1 = (sz + 1) * cell_size;

                float h00 = terrainHeight(x0, z0);
                float h10 = terrainHeight(x1, z0);
                float h01 = terrainHeight(x0, z1);
                float h11 = terrainHeight(x1, z1);

                // Skip fully submerged ocean floor; keep water as separate mesh
                float avg_h = (h00 + h10 + h01 + h11) * 0.25f;
                if (avg_h < sea_level - 0.5f) continue;

                // O3DE coords: o3x = scr_x - 160, o3y = scr_z - 160, o3z = scr_y
                float ox0 = x0 - 160.0f, oy0 = z0 - 160.0f;
                float ox1 = x1 - 160.0f, oy1 = z1 - 160.0f;

                // Normal from finite differences (SCR up = +Y → O3DE +Z)
                float nx = (h10 - h00 + h11 - h01) * 0.5f;
                float ny = (h01 - h00 + h11 - h10) * 0.5f;
                float nz = cell_size;
                float inv_len = 1.0f / sqrtf(nx * nx + ny * ny + nz * nz);
                nx *= inv_len; ny *= inv_len; nz *= inv_len;

                // Map: (SCR x, SCR y=height, SCR z) -> (o3 x, o3 y, o3 z)
                uint32_t base = mesh.vertex_count();
                mesh.vertices.push_back(MeshData::vert(ox0, oy0, h00, nx, ny, nz, 0, 0));
                mesh.vertices.push_back(MeshData::vert(ox1, oy0, h10, nx, ny, nz, 1, 0));
                mesh.vertices.push_back(MeshData::vert(ox1, oy1, h11, nx, ny, nz, 1, 1));
                mesh.vertices.push_back(MeshData::vert(ox0, oy1, h01, nx, ny, nz, 0, 1));
                mesh.addQuad(base, base + 1, base + 2, base + 3);
            }
        }
    }

    float terrainHeight(float x, float z) {
        if (getTerrainHeight) return getTerrainHeight(x, z);

        float dx = x - center_x;
        float dz = z - center_z;
        float dist = sqrtf(dx * dx + dz * dz);
        float cone = std::max(0.0f, island_radius * 0.39f - dist * 0.3f);
        float noise = sinf(x * 0.1f) * cosf(z * 0.1f) * 5.0f;
        return sea_level + cone + noise;
    }
};

// ═══════════════════════════════════════════════════════════════════════════════
// O3DE VOLCANO SUBSYSTEM — Lava flow + smoke plume
// ═══════════════════════════════════════════════════════════════════════════════

class O3deVolcanoSubSystem : public Simulation::ISimulationSubSystem {
public:
    float lava_flow_time = 0.0f;
    float smoke_plume_time = 0.0f;
    O3deMeshHandle lava_handle;
    O3deMeshHandle smoke_handle;

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
        if (lava_handle.valid && smoke_handle.valid) return;
        auto* scene = renderCtx.getSceneManager<AZ::RPI::Scene>();
        if (!scene) return;

        AZStd::shared_ptr<AZ::RPI::Scene> scenePtr(scene, [](AZ::RPI::Scene*){});

        if (!lava_handle.valid) {
            MeshData mesh;
            buildLavaFlowMesh(mesh);
            if (!mesh.vertices.empty()) {
                lava_handle = submitMeshData(scenePtr, mesh, MaterialCache::instance().lava,
                    AZ::Transform::CreateIdentity(), AZ::Vector3(1.0f, 1.0f, 1.0f), "lava_flow");
            }
        }

        if (!smoke_handle.valid) {
            MeshData mesh;
            buildSmokePlumeMesh(mesh);
            if (!mesh.vertices.empty()) {
                smoke_handle = submitMeshData(scenePtr, mesh, MaterialCache::instance().smoke,
                    AZ::Transform::CreateIdentity(), AZ::Vector3(1.0f, 1.0f, 1.0f), "smoke_plume");
            }
        }
    }

    void cleanup(Simulation::RenderContext& renderCtx) override {
        auto* scene = renderCtx.getSceneManager<AZ::RPI::Scene>();
        if (!scene) return;
        auto* fp = scene->GetFeatureProcessor<AZ::Render::MeshFeatureProcessorInterface>();
        if (!fp) return;
        if (lava_handle.valid) { fp->ReleaseMesh(lava_handle.handle); lava_handle.valid = false; }
        if (smoke_handle.valid) { fp->ReleaseMesh(smoke_handle.handle); smoke_handle.valid = false; }
    }

private:
    void buildLavaFlowMesh(MeshData& mesh) {
        // Lava river down the flank from caldera rim toward the sea
        const int segments = 60;
        const float width = 4.5f;

        for (int i = 0; i < segments; ++i) {
            float t0 = (float)i / segments;
            float t1 = (float)(i + 1) / segments;

            float r0 = caldera_radius * 0.95f + t0 * (island_radius * 0.78f - caldera_radius * 0.95f);
            float r1 = caldera_radius * 0.95f + t1 * (island_radius * 0.78f - caldera_radius * 0.95f);

            // Meander the flow centerline
            float me0 = sinf(t0 * 9.0f) * (2.2f + t0 * 3.0f);
            float me1 = sinf(t1 * 9.0f) * (2.2f + t1 * 3.0f);
            float b0 = river_angle + cosf(t0 * 5.0f) * 0.06f;
            float b1 = river_angle + cosf(t1 * 5.0f) * 0.06f;

            float c0x = (center_x - 160.0f) + cosf(b0) * (r0 + me0);
            float c0y = (center_z - 160.0f) + sinf(b0) * (r0 + me0);
            float c1x = (center_x - 160.0f) + cosf(b1) * (r1 + me1);
            float c1y = (center_z - 160.0f) + sinf(b1) * (r1 + me1);

            float px = -sinf(b0), py = cosf(b0);
            float h0 = peak_height - 8.0f - t0 * (peak_height - 8.0f - (sea_level + 2.0f));
            float h1 = peak_height - 8.0f - t1 * (peak_height - 8.0f - (sea_level + 2.0f));

            uint32_t base = mesh.vertex_count();
            mesh.vertices.push_back(MeshData::vert(c0x - px * width, c0y - py * width, h0, 0, 0, 1, 0, t0));
            mesh.vertices.push_back(MeshData::vert(c0x + px * width, c0y + py * width, h0, 0, 0, 1, 1, t0));
            mesh.vertices.push_back(MeshData::vert(c1x + px * width, c1y + py * width, h1, 0, 0, 1, 1, t1));
            mesh.vertices.push_back(MeshData::vert(c1x - px * width, c1y - py * width, h1, 0, 0, 1, 0, t1));
            mesh.addQuad(base, base + 1, base + 2, base + 3);
        }
    }

void buildSmokePlumeMesh(MeshData& mesh) {
        const int layers = 16;
        const float base_width = 5.0f;
        const float max_h = peak_height + 45.0f;

        for (int i = 0; i < layers; ++i) {
            float t = (float)i / (layers - 1);
            float h = peak_height - 2.0f + t * (max_h - (peak_height - 2.0f));
            float w = base_width * (0.7f + t * 3.6f);
            float x = (center_x - 160.0f) + sinf(smoke_plume_time * 0.4f + t * 6.0f) * (1.5f + t * 5.0f);
            float y = (center_z - 160.0f) + cosf(smoke_plume_time * 0.3f + t * 5.0f) * (1.5f + t * 4.0f);

            uint32_t base = mesh.vertex_count();
            mesh.vertices.push_back(MeshData::vert(x - w, y - w, h, 0, 0, 1, 0, 0));
            mesh.vertices.push_back(MeshData::vert(x + w, y - w, h, 0, 0, 1, 1, 0));
            mesh.vertices.push_back(MeshData::vert(x + w, y + w, h, 0, 0, 1, 1, 1));
            mesh.vertices.push_back(MeshData::vert(x - w, y + w, h, 0, 0, 1, 0, 1));
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
    O3deMeshHandle ocean_handle;

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
        if (ocean_handle.valid) return;
        auto* scene = renderCtx.getSceneManager<AZ::RPI::Scene>();
        if (!scene) return;

        AZStd::shared_ptr<AZ::RPI::Scene> scenePtr(scene, [](AZ::RPI::Scene*){});
        MeshData mesh;
        buildOceanMesh(mesh);
        if (mesh.vertices.empty()) return;
        ocean_handle = submitMeshData(scenePtr, mesh, MaterialCache::instance().ocean,
            AZ::Transform::CreateIdentity(), AZ::Vector3(1.0f, 1.0f, 1.0f), "ocean");
    }

    void cleanup(Simulation::RenderContext& renderCtx) override {
        auto* scene = renderCtx.getSceneManager<AZ::RPI::Scene>();
        if (scene && ocean_handle.valid) {
            auto* fp = scene->GetFeatureProcessor<AZ::Render::MeshFeatureProcessorInterface>();
            if (fp) fp->ReleaseMesh(ocean_handle.handle);
            ocean_handle.valid = false;
        }
    }

private:
    void buildOceanMesh(MeshData& mesh) {
        const int grid_size = 120;
        const float cell_size = 4.0f;

        // Emit in O3DE space (origin at island center, +Z up), centered on the
        // island. Cover SCR [0,480] -> O3DE [-240,240] so the ocean ring also
        // fills the horizon beyond the island shelf.
        for (int x = 0; x < grid_size; ++x) {
            for (int z = 0; z < grid_size; ++z) {
                float scr_x0 = x * cell_size;
                float scr_z0 = z * cell_size;
                float scr_x1 = (x + 1) * cell_size;
                float scr_z1 = (z + 1) * cell_size;

                float cx = (scr_x0 + scr_x1) * 0.5f;
                float cz = (scr_z0 + scr_z1) * 0.5f;
                float dx = cx - center_x;
                float dz = cz - center_z;
                float dist = sqrtf(dx * dx + dz * dz);
                // Skip the island interior (terrain mesh owns it) and drop the
                // deep-sea floor beyond the coastal apron.
                if (dist < island_radius * 0.80f) continue;
                if (dist > island_radius * 2.2f) continue;

                float h00 = oceanHeight(scr_x0, scr_z0);
                float h10 = oceanHeight(scr_x1, scr_z0);
                float h01 = oceanHeight(scr_x0, scr_z1);
                float h11 = oceanHeight(scr_x1, scr_z1);

                // SCR (x, y=height, z) -> O3DE (x-center, z-center, y)
                float ox0 = scr_x0 - 160.0f, oy0 = scr_z0 - 160.0f;
                float ox1 = scr_x1 - 160.0f, oy1 = scr_z1 - 160.0f;

                uint32_t base = mesh.vertex_count();
                mesh.vertices.push_back(MeshData::vert(ox0, oy0, h00, 0, 0, 1, 0, 0));
                mesh.vertices.push_back(MeshData::vert(ox1, oy0, h10, 0, 0, 1, 1, 0));
                mesh.vertices.push_back(MeshData::vert(ox1, oy1, h11, 0, 0, 1, 1, 1));
                mesh.vertices.push_back(MeshData::vert(ox0, oy1, h01, 0, 0, 1, 0, 1));
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

    O3deMeshHandle veg_handle;

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
        if (instances.empty() || veg_handle.valid) return;

        auto* scene = renderCtx.getSceneManager<AZ::RPI::Scene>();
        if (!scene) return;

        AZStd::shared_ptr<AZ::RPI::Scene> scenePtr(scene, [](AZ::RPI::Scene*){});

        MeshData mesh;
        buildVegetationMesh(mesh);
        veg_handle = submitMeshData(scenePtr, mesh, MaterialCache::instance().vegetation,
            AZ::Transform::CreateIdentity(), AZ::Vector3(1.0f, 1.0f, 1.0f), "vegetation");
    }

    void cleanup(Simulation::RenderContext& renderCtx) override {
        auto* scene = renderCtx.getSceneManager<AZ::RPI::Scene>();
        if (scene && veg_handle.valid) {
            auto* fp = scene->GetFeatureProcessor<AZ::Render::MeshFeatureProcessorInterface>();
            if (fp) fp->ReleaseMesh(veg_handle.handle);
            veg_handle.valid = false;
        }
    }

private:
    void generateInstances() {
        std::mt19937 rng(1337);
        std::uniform_real_distribution<float> dist(0.0f, 1.0f);

        for (int i = 0; i < 600; ++i) {
            float x = dist(rng) * island_radius * 2.0f;
            float z = dist(rng) * island_radius * 2.0f;

            float dx = x - center_x;
            float dz = z - center_z;
            float r = sqrtf(dx * dx + dz * dz);
            if (r < island_radius * 0.32f || r > island_radius * 0.98f) continue;

            float h = getTerrainHeight ? getTerrainHeight(x, z) : 20.0f;
            if (h < sea_level + 1.5f || h > 52.0f) continue;

            float density = getVegetationDensity ? getVegetationDensity(x, z) : 0.5f;
            if (dist(rng) > density) continue;

            // O3DE coords: origin at island center, +Z up
            instances.push_back({
                AZ::Vector3(x - 160.0f, z - 160.0f, h),
                0.8f + dist(rng) * 1.2f,
                (uint32_t)(dist(rng) * 3.0f)
            });
        }
    }

    void buildVegetationMesh(MeshData& mesh) {
        for (auto& inst : instances) {
            float px = inst.position.GetX();
            float py = inst.position.GetY();
            float pz = inst.position.GetZ();
            float s = inst.scale;

            if (inst.species_id == 0) {
                // Low shrub: 5 crossed quads at ~0.4 height
                float h = 0.9f * s;
                float w = 0.5f * s;
                const float kFit = 0.70710678f;
                for (int q = 0; q < 4; ++q) {
                    float a = q * 1.5707963f;
                    float cx = cosf(a), cy = sinf(a);
                    float bx = cx * w, by = cy * w;
                    uint32_t base = mesh.vertex_count();
                    mesh.vertices.push_back(MeshData::vert(px - bx, py - by, pz, 0, 0, 1, 0, 0));
                    mesh.vertices.push_back(MeshData::vert(px + bx * kFit, py + by * kFit, pz + h, 0, 0, 1, 0, 1));
                    mesh.vertices.push_back(MeshData::vert(px + bx, py + by, pz, 0, 0, 1, 0, 0));
                    mesh.vertices.push_back(MeshData::vert(px - bx * kFit, py - by * kFit, pz + h, 0, 0, 1, 1, 1));
                    mesh.addQuad(base, base + 1, base + 2, base + 3);
                }
            } else {
                // Conifer/palm: 3 stacked triangular tops over a slanted trunk lean
                for (int seg = 0; seg < 3; ++seg) {
                    float th = 1.2f + seg * 1.6f;
                    for (int k = 0; k < 3; ++k) {
                        float ang = k * 2.0943951f + seg * 0.5f;
                        float lean = 0.18f;
                        uint32_t base = mesh.vertex_count();
                        float cx = cosf(ang), cy = sinf(ang);
                        float w = (0.55f - (float)seg * 0.08f) * s;
                        mesh.vertices.push_back(MeshData::vert(px, py, pz - (th - 0.4f), 0, 0, 1, 0, 0));
                        mesh.vertices.push_back(MeshData::vert(px + cx * w * lean, py + cy * w * lean, pz + th, 0, 0, 1, 1, 1));
                        mesh.vertices.push_back(MeshData::vert(px + cx * w, py + cy * w, pz - (th - 0.8f), 0, 0, 1, 0, 0));
                        mesh.addTriangle(base, base + 1, base + 2);
                    }
                }
            }
        }
    }
};

} // namespace SCR::Render::O3DE

#endif // SCR_O3DE_SUBSYSTEMS_HPP
