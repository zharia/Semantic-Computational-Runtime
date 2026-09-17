/**
 * SCR Render / Volcanic Effects — Dynamic Magma River & Caldera Smoke Plume
 * ─────────────────────────────────────────────────────────────────────────────
 * Implements SCR-LIB-RENDER-VOLCANO (lib/A01_Render/Volcano/101_definition.md).
 *
 * Provides:
 *   - VolcanicLavaFlow: Dynamic cascading molten magma river with incandescent
 *     core, cooled crust drift, pulsating thermal radiation, and ocean steam.
 *   - VolcanicSmokePlume: High-volume convective ash and smoke chimney rising
 *     from the caldera crater with turbulent entrainment and wind dispersion.
 */

#ifndef CAVE_VOLCANIC_EFFECTS_HPP
#define CAVE_VOLCANIC_EFFECTS_HPP

#include <Ogre.h>
#include "spatial_semantics.hpp"
#include "multi_scale_noise.hpp"
#include "procedural_island.hpp"
#include "fluid_dynamics_solver.hpp"

#include <vector>
#include <cmath>
#include <algorithm>
#include <random>

namespace SCR::Volcano {

// ─── Flowing Molten Lava River System ────────────────────────────────────────
class VolcanicLavaFlow {
public:
    float flow_speed = 0.85f;      // Downhill advection velocity (m/s)
    float simulation_time = 0.0f;
    SCR::Noise::GradientNoise3D noise_crust;
    SCR::Noise::GradientNoise3D noise_heat;
    SCR::Fluid::FluidDynamicsSolver fluid_solver;

    struct RiverSplineNode {
        Spatial::Point3D pos;
        float width;
    };

    std::vector<RiverSplineNode> spline_nodes;

    VolcanicLavaFlow() : noise_crust(5555), noise_heat(8888) {}

    /**
     * Initializes the lava river path cascading down the South face of the volcano
     * from the caldera crater (48, 28, 48) down to the ocean surf (48, 9, 16).
     */
    void initRiverPath(const Island::VoxelIsland& island) {
        spline_nodes.clear();
        fluid_solver.initVolcanicChannel(island);

        const int NUM_WAYPOINTS = 28;
        float start_x = island.center_x;
        float start_z = island.center_z - 3.0f;
        float end_x = island.center_x + 3.0f;
        float end_z = island.center_z - island.island_radius * 0.75f;

        for (int i = 0; i <= NUM_WAYPOINTS; ++i) {
            float t = float(i) / float(NUM_WAYPOINTS);
            // Sinuous meandering curve down the mountainside
            float wx = (1.0f - t) * start_x + t * end_x + std::sin(t * 7.0f) * 5.2f + std::cos(t * 3.5f) * 2.8f;
            float wz = (1.0f - t) * start_z + t * end_z;
            float wy = island.getIslandHeight(wx, wz) + 0.16f; // Ride just above bedrock isosurface

            // River starts wide at caldera lake, narrows in rapids, widens at delta (Scaled by 1/2)
            float w = ((t < 0.15f) ? 10.5f : (t > 0.85f) ? 9.0f : 5.2f + std::sin(t * 12.0f) * 1.4f) * 0.50f;
            spline_nodes.push_back({Spatial::Point3D(wx, wy, wz), w});
        }
    }

    /**
     * Rebuilds and animates the dynamic flowing lava mesh each frame.
     */
    void updateLavaMesh(
        Ogre::ManualObject* lavaObj,
        float dt,
        const Island::VoxelIsland& island
    ) {
        if (!lavaObj || spline_nodes.empty()) return;
        simulation_time += dt;

        // Step non-Newtonian Bingham fluid solver
        fluid_solver.step(dt, island);
        flow_speed = fluid_solver.getLavaFlowSpeed();

        lavaObj->clear();
        lavaObj->begin("SCR/VolcanicLavaMaterial", Ogre::RenderOperation::OT_TRIANGLE_LIST);

        const int LENGTH_SEGMENTS = 48;
        const int WIDTH_SEGMENTS = 10;

        std::vector<Ogre::Vector3> positions;
        std::vector<Ogre::ColourValue> colors;
        std::vector<Ogre::Vector3> normals;

        // Sample along spline
        for (int l = 0; l <= LENGTH_SEGMENTS; ++l) {
            float t = float(l) / float(LENGTH_SEGMENTS);
            float spline_idx_f = t * float(spline_nodes.size() - 1);
            int idx0 = std::min((int)spline_nodes.size() - 2, (int)std::floor(spline_idx_f));
            int idx1 = idx0 + 1;
            float frac = spline_idx_f - float(idx0);

            // Interpolated centerline position and width
            Spatial::Point3D p0 = spline_nodes[idx0].pos;
            Spatial::Point3D p1 = spline_nodes[idx1].pos;
            float w0 = spline_nodes[idx0].width;
            float w1 = spline_nodes[idx1].width;

            Spatial::Point3D center = p0 + (p1 - p0) * frac;
            float width = w0 + (w1 - w0) * frac;

            // Compute tangent and cross-stream normal
            Spatial::Vector3D tangent = (p1 - p0).normalized();
            Spatial::Vector3D right(tangent.z, 0.0f, -tangent.x);
            right = right.normalized();

            for (int w = 0; w <= WIDTH_SEGMENTS; ++w) {
                float s = float(w) / float(WIDTH_SEGMENTS); // 0 (left bank) to 1 (right bank)
                float lat_offset = (s - 0.5f) * width;

                // Vertex World Position with slight surface bulging in center of channel
                float center_bulge = (1.0f - std::pow((s - 0.5f) * 2.0f, 2.0f)) * 0.22f;
                float px = center.x + right.x * lat_offset;
                float pz = center.z + right.z * lat_offset;
                float py = island.getIslandHeight(px, pz) + 0.15f + center_bulge;

                // ── Animated Incandescent Magma Color Synthesis & Physical Rheology ───
                // Query physical fluid sample at this point
                auto fluid_sample = fluid_solver.samplePoint(px, pz);

                // Downstream advection coordinates driven by physical fluid speed
                float physical_speed = std::max(0.4f, fluid_sample.speed > 0.0f ? fluid_sample.speed : flow_speed);
                float flow_u = (t * 18.0f) - simulation_time * physical_speed * 1.8f;
                float flow_v = (s - 0.5f) * 3.5f;

                // Shear stress is highest near banks (faster cooling + Bingham yield resistance)
                float bank_cooling = std::pow(std::abs(s - 0.5f) * 2.0f, 1.8f);

                // Multi-octave crust tearing noise
                float crust_n = noise_crust.fbm(flow_u * 0.45f, flow_v * 0.6f, simulation_time * 0.1f, 4, 2.1f, 0.55f);
                float heat_pulsation = std::sin(simulation_time * 2.5f + t * 8.0f) * 0.05f;

                // Combined crust factor combining physical crust thickness, thermal cooling, and bank stress
                float thermal_cool_factor = std::max(0.0f, std::min(1.0f, (1450.0f - fluid_sample.temperature_k) / 450.0f));
                float crust_factor = std::max(0.0f, std::min(1.0f, (crust_n * 0.55f + bank_cooling * 0.45f + thermal_cool_factor * 0.35f + fluid_sample.crust_thickness * 0.4f)));

                // Magma Core: Glowing yellow-white incandescent (1450K)
                Ogre::ColourValue core_color(1.0f, 0.88f + heat_pulsation, 0.25f, 1.0f);
                // Fiery fissures: Bright radiant orange-red (1100K)
                Ogre::ColourValue fissure_color(1.0f, 0.42f, 0.04f, 1.0f);
                // Cooled Obsidian Crust: Dark charcoal basalt (600K)
                Ogre::ColourValue crust_color(0.12f, 0.10f, 0.09f, 1.0f);

                Ogre::ColourValue vert_col;
                if (crust_factor < 0.32f) {
                    float k = crust_factor / 0.32f;
                    vert_col = (1.0f - k) * core_color + k * fissure_color;
                } else {
                    float k = (crust_factor - 0.32f) / 0.68f;
                    vert_col = (1.0f - k) * fissure_color + k * crust_color;
                }

                // Delta cooling when entering sea level (9m) -> turns to steamy black basalt
                if (py <= island.sea_level + 0.45f) {
                    float ocean_cool = std::min(1.0f, (island.sea_level + 0.45f - py) * 2.5f);
                    vert_col = (1.0f - ocean_cool) * vert_col + ocean_cool * Ogre::ColourValue(0.15f, 0.15f, 0.18f, 1.0f);
                }

                // Ensure strictly clamped in [0, 1]
                vert_col.r = std::max(0.0f, std::min(1.0f, vert_col.r));
                vert_col.g = std::max(0.0f, std::min(1.0f, vert_col.g));
                vert_col.b = std::max(0.0f, std::min(1.0f, vert_col.b));
                vert_col.a = 1.0f;

                positions.push_back(Ogre::Vector3(px, py, pz));
                colors.push_back(vert_col);
                normals.push_back(Ogre::Vector3(0.0f, 1.0f, 0.0f));
            }
        }

        // Build lava river triangle strips
        for (int l = 0; l < LENGTH_SEGMENTS; ++l) {
            for (int w = 0; w < WIDTH_SEGMENTS; ++w) {
                int row1 = l * (WIDTH_SEGMENTS + 1);
                int row2 = (l + 1) * (WIDTH_SEGMENTS + 1);

                int i0 = row1 + w;
                int i1 = row1 + w + 1;
                int i2 = row2 + w + 1;
                int i3 = row2 + w;

                lavaObj->position(positions[i0]); lavaObj->colour(colors[i0]); lavaObj->normal(normals[i0]);
                lavaObj->position(positions[i1]); lavaObj->colour(colors[i1]); lavaObj->normal(normals[i1]);
                lavaObj->position(positions[i2]); lavaObj->colour(colors[i2]); lavaObj->normal(normals[i2]);

                lavaObj->position(positions[i0]); lavaObj->colour(colors[i0]); lavaObj->normal(normals[i0]);
                lavaObj->position(positions[i2]); lavaObj->colour(colors[i2]); lavaObj->normal(normals[i2]);
                lavaObj->position(positions[i3]); lavaObj->colour(colors[i3]); lavaObj->normal(normals[i3]);
            }
        }

        lavaObj->end();
    }
};

// ─── Convective Volcanic Smoke & Ash Plume System ────────────────────────────
class VolcanicSmokePlume {
public:
    struct SmokePuff {
        Spatial::Point3D position;
        Spatial::Vector3D velocity;
        float radius;
        float density;
        float age;
        float max_age;
        float phase_seed;
    };

    std::vector<SmokePuff> puffs;
    float simulation_time = 0.0f;
    float spawn_timer = 0.0f;
    SCR::Noise::GradientNoise3D noise_curl;

    VolcanicSmokePlume() : noise_curl(9999) {
        puffs.reserve(128);
    }

    /**
     * Pre-warms an established towering volcanic smoke column on startup.
     */
    void initPlume(const Island::VoxelIsland& island) {
        puffs.clear();
        Spatial::Point3D caldera_center(island.center_x, island.peak_height + 0.5f, island.center_z);

        const int PREWARM_PUFFS = 76;
        for (int i = 0; i < PREWARM_PUFFS; ++i) {
            float frac = float(i) / float(PREWARM_PUFFS); // 0 (crater) to 1 (high sky)
            SmokePuff p;
            float angle = ((float)rand() / (float)RAND_MAX) * 6.28318f;
            float dist = ((float)rand() / (float)RAND_MAX) * (5.0f + frac * 22.0f);

            float wind_drift_x = frac * 14.0f;
            float wind_drift_z = frac * -10.0f;
            float curl_x = noise_curl.sample(frac * 4.0f, frac * 4.0f, 1.0f) * 9.0f;

            p.position = Spatial::Point3D(
                caldera_center.x + std::cos(angle) * dist + wind_drift_x + curl_x,
                caldera_center.y + frac * 180.0f,
                caldera_center.z + std::sin(angle) * dist + wind_drift_z
            );
            p.velocity = Spatial::Vector3D(
                (std::cos(angle) * 0.45f),
                4.8f + ((float)rand() / (float)RAND_MAX) * 2.5f,
                (std::sin(angle) * 0.45f)
            );
            p.radius = (5.0f + frac * 28.0f) * 0.50f;
            float alpha_curve = (frac < 0.10f) ? (frac / 0.10f) : std::pow(1.0f - frac, 0.9f);
            p.density = alpha_curve * 0.82f;
            p.max_age = 22.0f;
            p.age = frac * p.max_age;
            p.phase_seed = ((float)rand() / (float)RAND_MAX) * 100.0f;
            puffs.push_back(p);
        }
    }

    /**
     * Spawns, ascends, and animates convective smoke billows.
     */
    void updateSmokeMesh(
        Ogre::ManualObject* smokeObj,
        float dt,
        const Island::VoxelIsland& island
    ) {
        if (!smokeObj) return;
        if (puffs.empty()) {
            initPlume(island);
        }
        simulation_time += dt;
        spawn_timer += dt;

        Spatial::Point3D caldera_center(island.center_x, island.peak_height + 0.5f, island.center_z);

        // Spawn new billowing ash puffs from the active crater
        if (spawn_timer >= 0.14f && puffs.size() < 90) {
            spawn_timer = 0.0f;
            SmokePuff p;
            float angle = ((float)rand() / (float)RAND_MAX) * 6.28318f;
            float dist = ((float)rand() / (float)RAND_MAX) * 3.2f;
            p.position = Spatial::Point3D(
                caldera_center.x + std::cos(angle) * dist,
                caldera_center.y,
                caldera_center.z + std::sin(angle) * dist
            );
            p.velocity = Spatial::Vector3D(
                (std::cos(angle) * 0.35f),
                3.8f + ((float)rand() / (float)RAND_MAX) * 2.0f, // Thermal convective lift
                (std::sin(angle) * 0.35f)
            );
            p.radius = (2.4f + ((float)rand() / (float)RAND_MAX) * 1.2f) * 0.50f;
            p.density = 0.75f;
            p.age = 0.0f;
            p.max_age = 15.0f + ((float)rand() / (float)RAND_MAX) * 5.0f;
            p.phase_seed = ((float)rand() / (float)RAND_MAX) * 100.0f;
            puffs.push_back(p);
        }

        // Advance simulation of each active smoke puff
        for (auto it = puffs.begin(); it != puffs.end(); ) {
            it->age += dt;
            if (it->age >= it->max_age) {
                it = puffs.erase(it);
                continue;
            }

            float life = it->age / it->max_age;

            // Turbulent curl dispersion and high-altitude prevailing wind drift
            float wind_x = 2.0f + life * 2.8f;
            float wind_z = -1.2f + life * 1.8f;
            float curl_x = noise_curl.sample(it->position.x * 0.04f, it->position.y * 0.04f, simulation_time * 0.2f);
            float curl_z = noise_curl.sample(it->position.z * 0.04f, it->position.y * 0.04f, it->phase_seed);

            it->position.x += (it->velocity.x + wind_x + curl_x * 1.5f) * dt;
            it->position.y += it->velocity.y * dt;
            it->position.z += (it->velocity.z + wind_z + curl_z * 1.5f) * dt;

            // Thermal deceleration as plume expands and cools
            it->velocity.y = std::max(1.4f, it->velocity.y - 0.20f * dt);

            // Plume expansion with altitude
            it->radius += dt * 1.15f;

            // Smooth bell-shaped density curve (fade in, plateau, gentle fade out)
            float alpha_curve = (life < 0.15f) ? (life / 0.15f) : std::pow(1.0f - life, 1.2f);
            it->density = alpha_curve * 0.65f;

            ++it;
        }

        // Build 3D Soft Radial Octahedral Smoke Billows
        smokeObj->clear();
        smokeObj->begin("SCR/VolcanicSmokeMaterial", Ogre::RenderOperation::OT_TRIANGLE_LIST);

        uint32_t v_idx = 0;

        for (const auto& puff : puffs) {
            float r = puff.radius;

            // Base ash color with warm fiery glow near caldera vent
            Ogre::ColourValue core_col;
            if (puff.position.y < island.peak_height + 6.0f) {
                float magma_glow = std::max(0.0f, 1.0f - (puff.position.y - island.peak_height) / 6.0f);
                core_col = (1.0f - magma_glow) * Ogre::ColourValue(0.18f, 0.17f, 0.16f, puff.density) +
                           magma_glow * Ogre::ColourValue(0.95f, 0.45f, 0.08f, puff.density);
            } else {
                // High altitude plume is dark volumetric slate ash
                core_col = Ogre::ColourValue(0.20f, 0.19f, 0.18f, puff.density);
            }

            // Radial soft outer edge (alpha = 0 for seamless blending)
            Ogre::ColourValue edge_col = core_col;
            edge_col.a = 0.0f;

            // 3D Soft Octahedral Billow (Dense center vertex + 6 radial outer vertices)
            Ogre::Vector3 center(puff.position.x, puff.position.y, puff.position.z);
            Ogre::Vector3 top(center.x, center.y + r, center.z);
            Ogre::Vector3 btm(center.x, center.y - r, center.z);
            Ogre::Vector3 px(center.x + r, center.y, center.z);
            Ogre::Vector3 nx(center.x - r, center.y, center.z);
            Ogre::Vector3 pz(center.x, center.y, center.z + r);
            Ogre::Vector3 nz(center.x, center.y, center.z - r);

            // Connect center vertex (core_col) to pairs of outer edge vertices (edge_col)
            auto addSector = [&](const Ogre::Vector3& v1, const Ogre::Vector3& v2) {
                smokeObj->position(center); smokeObj->colour(core_col);
                smokeObj->position(v1);     smokeObj->colour(edge_col);
                smokeObj->position(v2);     smokeObj->colour(edge_col);
                smokeObj->triangle(v_idx, v_idx + 1, v_idx + 2);
                smokeObj->triangle(v_idx + 2, v_idx + 1, v_idx); // Double sided
                v_idx += 3;
            };

            // Top hemisphere sectors
            addSector(top, px);
            addSector(top, pz);
            addSector(top, nx);
            addSector(top, nz);

            // Equator sectors
            addSector(px, pz);
            addSector(pz, nx);
            addSector(nx, nz);
            addSector(nz, px);

            // Bottom hemisphere sectors
            addSector(btm, px);
            addSector(btm, pz);
            addSector(btm, nx);
            addSector(btm, nz);
        }

        smokeObj->end();
    }
};

} // namespace SCR::Volcano

#endif // CAVE_VOLCANIC_EFFECTS_HPP
