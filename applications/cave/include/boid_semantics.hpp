/**
 * SCR Application / Multi-Dimensional Semantic Boids System
 * ─────────────────────────────────────────────────────────────────────────────
 * Normative multi-agent flocking engine operating across 2D, 3D, and 4D spatial
 * manifolds. Implements species specialization, generalized Reynolds force fields,
 * dynamic behavioral modes, and real-time GPU mesh synthesis.
 */

#ifndef CAVE_BOID_SEMANTICS_HPP
#define CAVE_BOID_SEMANTICS_HPP

#include <Ogre.h>
#include "simulation/spatial_semantics.hpp"
#include "procedural_island.hpp"

#include <vector>
#include <array>
#include <string>
#include <cmath>
#include <random>
#include <algorithm>
#include <iostream>

namespace SCR::Boids {

// ─── 1. Generic Dimension-Agnostic Vector (R^N, N in {2, 3, 4}) ───────────────
template<typename T, size_t N>
class VectorND {
public:
    std::array<T, N> data;

    VectorND() { data.fill(T(0)); }

    VectorND(std::initializer_list<T> list) {
        size_t idx = 0;
        for (auto val : list) {
            if (idx < N) data[idx++] = val;
        }
        for (; idx < N; ++idx) data[idx] = T(0);
    }

    T& operator[](size_t i) { return data[i]; }
    const T& operator[](size_t i) const { return data[i]; }

    T x() const { return data[0]; }
    T y() const { return (N > 1) ? data[1] : T(0); }
    T z() const { return (N > 2) ? data[2] : T(0); }
    T w() const { return (N > 3) ? data[3] : T(0); }

    void setX(T v) { if (N > 0) data[0] = v; }
    void setY(T v) { if (N > 1) data[1] = v; }
    void setZ(T v) { if (N > 2) data[2] = v; }
    void setW(T v) { if (N > 3) data[3] = v; }

    VectorND operator+(const VectorND& o) const {
        VectorND r;
        for (size_t i = 0; i < N; ++i) r[i] = data[i] + o[i];
        return r;
    }

    VectorND operator-(const VectorND& o) const {
        VectorND r;
        for (size_t i = 0; i < N; ++i) r[i] = data[i] - o[i];
        return r;
    }

    VectorND operator*(T s) const {
        VectorND r;
        for (size_t i = 0; i < N; ++i) r[i] = data[i] * s;
        return r;
    }

    VectorND operator/(T s) const {
        VectorND r;
        T inv = T(1) / (std::abs(s) > T(1e-6) ? s : T(1e-6));
        for (size_t i = 0; i < N; ++i) r[i] = data[i] * inv;
        return r;
    }

    VectorND& operator+=(const VectorND& o) {
        for (size_t i = 0; i < N; ++i) data[i] += o[i];
        return *this;
    }

    VectorND& operator-=(const VectorND& o) {
        for (size_t i = 0; i < N; ++i) data[i] -= o[i];
        return *this;
    }

    VectorND& operator*=(T s) {
        for (size_t i = 0; i < N; ++i) data[i] *= s;
        return *this;
    }

    T dot(const VectorND& o) const {
        T sum(0);
        for (size_t i = 0; i < N; ++i) sum += data[i] * o[i];
        return sum;
    }

    T lengthSq() const { return dot(*this); }
    T length() const { return std::sqrt(lengthSq()); }

    VectorND normalized() const {
        T len = length();
        if (len < T(1e-6)) return *this;
        return *this * (T(1) / len);
    }

    T distanceSq(const VectorND& o) const { return (*this - o).lengthSq(); }
    T distance(const VectorND& o) const { return (*this - o).length(); }

    VectorND clampedLength(T max_len) const {
        T len = length();
        if (len > max_len && len > T(1e-6)) {
            return *this * (max_len / len);
        }
        return *this;
    }

    // Projection to physical 3D space
    Ogre::Vector3 to3D(float w_phase = 0.0f) const {
        if constexpr (N == 2) {
            return Ogre::Vector3(data[0], 0.0f, data[1]);
        } else if constexpr (N == 3) {
            return Ogre::Vector3(data[0], data[1], data[2]);
        } else if constexpr (N == 4) {
            // 4D -> 3D slice projection with hyperspatial offset
            float pw = data[3] - w_phase;
            float scale_proj = 1.0f / (1.0f + 0.15f * pw * pw);
            return Ogre::Vector3(data[0] * scale_proj, data[1] * scale_proj, data[2] * scale_proj);
        }
        return Ogre::Vector3::ZERO;
    }
};

using Vector2D = VectorND<float, 2>;
using Vector3D = VectorND<float, 3>;
using Vector4D = VectorND<float, 4>;

// ─── 2. Species Archetypes & Behavior Modes ───────────────────────────────────
enum class BoidClass {
    AVIAN_AERIAL,        // 3D Airspace flocking
    AQUATIC_PELAGIC,     // 3D Underwater schooling
    VOLCANIC_ENTOMOLOGY, // 3D Thermal chimney swarming
    TERRESTRIAL_SURFACE, // 2D/2.5D Coastal dune herd
    HYPERSPATIAL_ETHREAL // 4D Hyperspace manifold probes
};

enum class BehaviorMode {
    CRUISING,
    FORAGING,
    SWARMING,
    PANIC_SCATTER,
    HYPER_SLICING
};

template<size_t N>
struct BoidSpeciesConfig {
    std::string name;
    BoidClass boid_class;
    size_t dimension = N;

    // Perceptual Radii (Hyper-spherical metrics in R^N)
    float sep_radius;
    float ali_radius;
    float coh_radius;

    // Steering Weights
    float w_sep;
    float w_ali;
    float w_coh;
    float w_env;      // Habitat center attractor
    float w_wander;   // Organic exploration noise
    float w_obs;      // Obstacle & boundary repulsion
    float w_dive;     // Special attack/foraging dive force

    // Kinematic Bounds
    float min_speed;
    float max_speed;
    float max_force;

    // Ecological Habitat Envelope in R^N
    VectorND<float, N> habitat_center;
    float habitat_radius;
    VectorND<float, N> bounds_min;
    VectorND<float, N> bounds_max;

    // Visual & Morphological Attributes
    float scale;
    float wing_speed;
    Ogre::ColourValue color_primary;
    Ogre::ColourValue color_secondary;
    Ogre::ColourValue glow_color;
    bool is_luminescent;
};

// ─── 3. Autonomous Boid Agent in R^N ──────────────────────────────────────────
template<size_t N>
struct BoidAgent {
    VectorND<float, N> position;
    VectorND<float, N> velocity;
    VectorND<float, N> acceleration;

    float flap_phase = 0.0f;
    BehaviorMode mode = BehaviorMode::CRUISING;
    float mode_timer = 0.0f;
    float energy = 1.0f;
    unsigned id = 0;
};

// ─── 4. Specialized Species Catalog Presets ───────────────────────────────────
class SpeciesCatalog {
public:
    // 1. Coastal Tropic Tern (3D Aerial Soaring & Diving)
    static BoidSpeciesConfig<3> getCoastalTropicTern(const Island::VoxelIsland& island) {
        BoidSpeciesConfig<3> c;
        c.name = "Coastal Tropic Tern (Phaethon aethereus)";
        c.boid_class = BoidClass::AVIAN_AERIAL;
        c.sep_radius = 1.75f;
        c.ali_radius = 6.0f;
        c.coh_radius = 9.0f;

        c.w_sep = 2.2f;
        c.w_ali = 1.6f;
        c.w_coh = 1.1f;
        c.w_env = 0.8f;
        c.w_wander = 0.45f;
        c.w_obs = 3.5f;
        c.w_dive = 1.8f;

        c.min_speed = 3.5f;
        c.max_speed = 9.0f;
        c.max_force = 11.0f;

        c.habitat_center = {island.center_x - 50.0f, 36.0f, island.center_z - 70.0f};
        c.habitat_radius = 90.0f;
        c.bounds_min = {12.0f, island.sea_level + 1.5f, 12.0f};
        c.bounds_max = {island.dim_x - 12.0f, 85.0f, island.dim_z - 12.0f};

        c.scale = 0.325f;
        c.wing_speed = 7.5f;
        c.color_primary   = Ogre::ColourValue(0.96f, 0.98f, 1.00f); // Bright white plumage
        c.color_secondary = Ogre::ColourValue(0.15f, 0.20f, 0.25f); // Black wingtips
        c.glow_color      = Ogre::ColourValue(0.0f, 0.0f, 0.0f);
        c.is_luminescent  = false;
        return c;
    }

    // 2. Coral Reef Tang (3D Aquatic Pelagic Lagoon Schooling)
    static BoidSpeciesConfig<3> getCoralReefTang(const Island::VoxelIsland& island) {
        BoidSpeciesConfig<3> c;
        c.name = "Pacific Blue Tang (Paracanthurus hepatus)";
        c.boid_class = BoidClass::AQUATIC_PELAGIC;
        c.sep_radius = 0.9f;
        c.ali_radius = 2.75f;
        c.coh_radius = 4.5f;

        c.w_sep = 2.6f;
        c.w_ali = 1.9f;
        c.w_coh = 1.4f;
        c.w_env = 1.2f;
        c.w_wander = 0.35f;
        c.w_obs = 4.0f;
        c.w_dive = 0.0f;

        c.min_speed = 1.5f;
        c.max_speed = 4.25f;
        c.max_force = 7.0f;

        c.habitat_center = {island.center_x - 80.0f, island.sea_level - 2.5f, island.center_z - 80.0f};
        c.habitat_radius = 55.0f;
        c.bounds_min = {15.0f, island.sea_level - 7.0f, 15.0f};
        c.bounds_max = {island.dim_x - 15.0f, island.sea_level - 0.2f, island.dim_z - 15.0f};

        c.scale = 0.225f;
        c.wing_speed = 5.0f;
        c.color_primary   = Ogre::ColourValue(0.08f, 0.42f, 0.95f); // Vibrant ocean royal blue
        c.color_secondary = Ogre::ColourValue(0.98f, 0.85f, 0.12f); // Bright yellow caudal fin
        c.glow_color      = Ogre::ColourValue(0.0f, 0.0f, 0.0f);
        c.is_luminescent  = false;
        return c;
    }

    // 3. Volcanic Ember Moth (3D Caldera Swarming Vortex)
    static BoidSpeciesConfig<3> getVolcanicEmberMoth(const Island::VoxelIsland& island) {
        BoidSpeciesConfig<3> c;
        c.name = "Volcanic Ash Moth (Pyralis vulcanus)";
        c.boid_class = BoidClass::VOLCANIC_ENTOMOLOGY;
        c.sep_radius = 0.8f;
        c.ali_radius = 2.4f;
        c.coh_radius = 4.75f;

        c.w_sep = 1.8f;
        c.w_ali = 1.2f;
        c.w_coh = 1.6f;
        c.w_env = 2.5f; // Strong attraction to hot caldera chimney
        c.w_wander = 0.85f;
        c.w_obs = 2.0f;
        c.w_dive = 0.0f;

        c.min_speed = 1.75f;
        c.max_speed = 5.25f;
        c.max_force = 9.0f;

        c.habitat_center = {island.center_x, island.peak_height + 6.0f, island.center_z};
        c.habitat_radius = 36.0f;
        c.bounds_min = {island.center_x - 45.0f, island.peak_height - 3.0f, island.center_z - 45.0f};
        c.bounds_max = {island.center_x + 45.0f, island.peak_height + 48.0f, island.center_z + 45.0f};

        c.scale = 0.20f;
        c.wing_speed = 14.0f;
        c.color_primary   = Ogre::ColourValue(1.00f, 0.45f, 0.05f); // Molten amber glowing wings
        c.color_secondary = Ogre::ColourValue(0.25f, 0.18f, 0.15f); // Basalt charcoal body
        c.glow_color      = Ogre::ColourValue(1.00f, 0.60f, 0.15f);
        c.is_luminescent  = true;
        return c;
    }

    // 4. Shoreline Sandpiper (2D/2.5D Beach Surface Herd)
    static BoidSpeciesConfig<2> getShorelineSandpiper(const Island::VoxelIsland& island) {
        BoidSpeciesConfig<2> c;
        c.name = "Shoreline Sandpiper (Calidris alba)";
        c.boid_class = BoidClass::TERRESTRIAL_SURFACE;
        c.sep_radius = 0.8f;
        c.ali_radius = 2.4f;
        c.coh_radius = 3.75f;

        c.w_sep = 2.4f;
        c.w_ali = 1.5f;
        c.w_coh = 1.3f;
        c.w_env = 1.0f;
        c.w_wander = 0.50f;
        c.w_obs = 3.0f;
        c.w_dive = 0.0f;

        c.min_speed = 1.25f;
        c.max_speed = 3.25f;
        c.max_force = 6.0f;

        c.habitat_center = {island.center_x - 60.0f, island.center_z - 90.0f};
        c.habitat_radius = 48.0f;
        c.bounds_min = {18.0f, 18.0f};
        c.bounds_max = {island.dim_x - 18.0f, island.dim_z - 18.0f};

        c.scale = 0.21f;
        c.wing_speed = 4.0f;
        c.color_primary   = Ogre::ColourValue(0.82f, 0.74f, 0.62f); // Sand dune plumage
        c.color_secondary = Ogre::ColourValue(0.35f, 0.28f, 0.20f); // Dark mottled back
        c.glow_color      = Ogre::ColourValue(0.0f, 0.0f, 0.0f);
        c.is_luminescent  = false;
        return c;
    }

    // 5. Hyperspatial Luminary (4D Manifold Ethereal Probes)
    static BoidSpeciesConfig<4> getHyperspatialLuminary(const Island::VoxelIsland& island) {
        BoidSpeciesConfig<4> c;
        c.name = "Hyperspatial Luminary (Anomalocaris 4D)";
        c.boid_class = BoidClass::HYPERSPATIAL_ETHREAL;
        c.sep_radius = 2.25f;
        c.ali_radius = 7.0f;
        c.coh_radius = 11.0f;

        c.w_sep = 1.9f;
        c.w_ali = 1.7f;
        c.w_coh = 1.2f;
        c.w_env = 1.0f;
        c.w_wander = 0.60f;
        c.w_obs = 2.5f;
        c.w_dive = 0.0f;

        c.min_speed = 2.5f;
        c.max_speed = 6.5f;
        c.max_force = 9.0f;

        c.habitat_center = {island.center_x + 30.0f, 42.0f, island.center_z + 30.0f, 0.0f};
        c.habitat_radius = 70.0f;
        c.bounds_min = {20.0f, 15.0f, 20.0f, -12.0f};
        c.bounds_max = {island.dim_x - 20.0f, 75.0f, island.dim_z - 20.0f, 12.0f};

        c.scale = 0.425f;
        c.wing_speed = 3.2f;
        c.color_primary   = Ogre::ColourValue(0.75f, 0.25f, 0.95f); // Iridescent violet
        c.color_secondary = Ogre::ColourValue(0.20f, 0.92f, 0.85f); // Luminescent teal core
        c.glow_color      = Ogre::ColourValue(0.85f, 0.40f, 1.00f);
        c.is_luminescent  = true;
        return c;
    }

    // 6. Nocturnal Bioluminescent Fireflies (3D Rainforest Canopy & Beach Swarm)
    static BoidSpeciesConfig<3> getNocturnalFirefly(const Island::VoxelIsland& island) {
        BoidSpeciesConfig<3> c;
        c.name = "Tropical Bioluminescent Firefly (Noctiluca pyralis)";
        c.boid_class = BoidClass::VOLCANIC_ENTOMOLOGY;
        c.sep_radius = 1.2f;
        c.ali_radius = 3.25f;
        c.coh_radius = 7.0f;

        c.w_sep = 2.2f;
        c.w_ali = 1.3f;
        c.w_coh = 1.2f;
        c.w_env = 1.4f; // Rainforest & coastal groves
        c.w_wander = 0.95f;
        c.w_obs = 3.0f;
        c.w_dive = 0.0f;

        c.min_speed = 0.9f;
        c.max_speed = 2.75f;
        c.max_force = 6.0f;

        c.habitat_center = {island.center_x - 30.0f, island.sea_level + 7.5f, island.center_z - 35.0f};
        c.habitat_radius = 80.0f;
        c.bounds_min = {15.0f, island.sea_level + 0.5f, 15.0f};
        c.bounds_max = {island.dim_x - 15.0f, island.peak_height + 15.0f, island.dim_z - 15.0f};

        c.scale = 0.16f;
        c.wing_speed = 16.0f;
        c.color_primary   = Ogre::ColourValue(0.25f, 1.00f, 0.40f); // Radiant emerald bioluminescence
        c.color_secondary = Ogre::ColourValue(1.00f, 0.94f, 0.30f); // Phosphorescent golden abdomen
        c.glow_color      = Ogre::ColourValue(0.35f, 1.00f, 0.50f);
        c.is_luminescent  = true;
        return c;
    }
};

// ─── 4b. 32-Byte Aligned Structure-of-Arrays (SoA) SIMD Buffer ────────────────
template<size_t N>
struct alignas(32) BoidSoABuffer {
    static constexpr size_t MAX_BOIDS = 512;
    alignas(32) float pos[N][MAX_BOIDS];
    alignas(32) float vel[N][MAX_BOIDS];
    alignas(32) float flap_phase[MAX_BOIDS];
    size_t count = 0;

    void syncFromAgents(const std::vector<BoidAgent<N>>& agents) {
        count = std::min(agents.size(), MAX_BOIDS);
        for (size_t i = 0; i < count; ++i) {
            for (size_t d = 0; d < N; ++d) {
                pos[d][i] = agents[i].position[d];
                vel[d][i] = agents[i].velocity[d];
            }
            flap_phase[i] = agents[i].flap_phase;
        }
    }

    void syncToAgents(std::vector<BoidAgent<N>>& agents) {
        for (size_t i = 0; i < count; ++i) {
            for (size_t d = 0; d < N; ++d) {
                agents[i].position[d] = pos[d][i];
                agents[i].velocity[d] = vel[d][i];
            }
            agents[i].flap_phase = flap_phase[i];
        }
    }
};

// ─── 5. Dimension-Agnostic Flocking Solver ────────────────────────────────────
template<size_t N>
class BoidFlock {
public:
    BoidSpeciesConfig<N> config;
    std::vector<BoidAgent<N>> agents;
    BoidSoABuffer<N> soa_buffer;
    float global_time = 0.0f;
    float w_slice_phase = 0.0f;
    VectorND<float, N> dynamic_waypoint;
    float waypoint_timer = 0.0f;
    std::mt19937 flock_rng;

    void initialize(const BoidSpeciesConfig<N>& cfg, size_t count, unsigned base_seed) {
        config = cfg;
        agents.clear();
        agents.resize(count);
        flock_rng.seed(base_seed);
        dynamic_waypoint = config.habitat_center;
        waypoint_timer = 2.0f;

        std::uniform_real_distribution<float> rand_unit(-1.0f, 1.0f);
        std::uniform_real_distribution<float> rand_01(0.0f, 1.0f);

        for (size_t i = 0; i < count; ++i) {
            agents[i].id = static_cast<unsigned>(i);
            VectorND<float, N> offset;
            for (size_t d = 0; d < N; ++d) {
                offset[d] = rand_unit(flock_rng) * (config.habitat_radius * 0.45f);
            }
            agents[i].position = config.habitat_center + offset;

            VectorND<float, N> vel;
            for (size_t d = 0; d < N; ++d) vel[d] = rand_unit(flock_rng);
            agents[i].velocity = vel.normalized() * (config.min_speed + rand_01(flock_rng) * (config.max_speed - config.min_speed));
            agents[i].flap_phase = rand_01(flock_rng) * 6.2831853f;
            agents[i].mode = BehaviorMode::CRUISING;
            agents[i].mode_timer = 3.0f + rand_01(flock_rng) * 5.0f;
        }
        soa_buffer.syncFromAgents(agents);
    }

    void update(float dt, const Island::VoxelIsland& island) {
        global_time += dt;
        w_slice_phase = std::sin(global_time * 0.45f) * 4.5f;

        size_t count = agents.size();
        if (count == 0) return;

        // Sync contiguous SoA buffers before vectorized computation
        soa_buffer.syncFromAgents(agents);

        // ── 1. Dynamic Roaming Waypoint Progression (Emergent Biome Exploration) ──
        waypoint_timer -= dt;
        if (waypoint_timer <= 0.0f) {
            waypoint_timer = 5.0f + float(flock_rng() % 50) * 0.1f;
            std::uniform_real_distribution<float> rand_unit(-1.0f, 1.0f);

            // Select an organic exploratory goal within the species habitat envelope
            VectorND<float, N> new_target = config.habitat_center;
            for (size_t d = 0; d < N; ++d) {
                float span = (config.bounds_max[d] - config.bounds_min[d]) * 0.35f;
                new_target[d] += rand_unit(flock_rng) * std::min(config.habitat_radius * 0.85f, span);
                new_target[d] = std::max(config.bounds_min[d] + 2.0f, std::min(config.bounds_max[d] - 2.0f, new_target[d]));
            }

            // Ecological terrain snapping for terrestrial/pelagic/aerial
            if constexpr (N >= 3) {
                float gh = island.getIslandHeight(new_target[0], new_target[2]);
                if (config.boid_class == BoidClass::AQUATIC_PELAGIC) {
                    new_target[1] = std::max(island.sea_level - 6.0f, std::min(island.sea_level - 0.8f, gh - 1.5f));
                } else if (config.boid_class == BoidClass::AVIAN_AERIAL) {
                    new_target[1] = std::max(gh + 12.0f, 32.0f + float(flock_rng() % 35));
                } else if (config.boid_class == BoidClass::VOLCANIC_ENTOMOLOGY) {
                    new_target[1] = island.peak_height + 4.0f + float(flock_rng() % 25);
                }
            }
            dynamic_waypoint = new_target;
        }

        // ── 2. Kuramoto Phase Coupling for Bioluminescent Fireflies (Vectorized) ──
        if (config.is_luminescent && config.boid_class == BoidClass::VOLCANIC_ENTOMOLOGY) {
            const float kuramoto_k = 1.8f;
            float coh_r_sq = config.coh_radius * config.coh_radius;

            for (size_t i = 0; i < count; ++i) {
                float phase_diff_sum = 0.0f;
                int k_neighbors = 0;
                float px = soa_buffer.pos[0][i];
                float py = soa_buffer.pos[1][i];
                float pz = (N > 2) ? soa_buffer.pos[2][i] : 0.0f;
                float phi_i = soa_buffer.flap_phase[i];

                #pragma GCC ivdep
                for (size_t j = 0; j < count && k_neighbors < 8; ++j) {
                    if (i == j) continue;
                    float dx = px - soa_buffer.pos[0][j];
                    float dy = py - soa_buffer.pos[1][j];
                    float dz = (N > 2) ? (pz - soa_buffer.pos[2][j]) : 0.0f;
                    float d_sq = dx * dx + dy * dy + dz * dz;
                    if (d_sq < coh_r_sq) {
                        phase_diff_sum += std::sin(soa_buffer.flap_phase[j] - phi_i);
                        k_neighbors++;
                    }
                }
                if (k_neighbors > 0) {
                    agents[i].flap_phase += (kuramoto_k / float(k_neighbors)) * phase_diff_sum * dt;
                }
            }
        }

        // ── 3. Reynolds Flocking & Multi-Scale Force Accumulation (SoA Accelerated) ─
        float sep_r_sq = config.sep_radius * config.sep_radius;
        float ali_r_sq = config.ali_radius * config.ali_radius;
        float coh_r_sq = config.coh_radius * config.coh_radius;

        for (size_t i = 0; i < count; ++i) {
            auto& b = agents[i];
            b.mode_timer -= dt;
            b.flap_phase += dt * config.wing_speed;

            // State Machine transitions with individual temperament
            if (b.mode_timer <= 0.0f) {
                if (config.boid_class == BoidClass::AVIAN_AERIAL) {
                    b.mode = (b.mode == BehaviorMode::CRUISING) ? BehaviorMode::FORAGING : BehaviorMode::CRUISING;
                    b.mode_timer = (b.mode == BehaviorMode::FORAGING) ? 3.5f : (5.0f + float(b.id % 5));
                } else if (config.boid_class == BoidClass::VOLCANIC_ENTOMOLOGY) {
                    b.mode = (b.mode == BehaviorMode::SWARMING) ? BehaviorMode::CRUISING : BehaviorMode::SWARMING;
                    b.mode_timer = 4.0f + float(b.id % 4);
                } else {
                    b.mode = BehaviorMode::CRUISING;
                    b.mode_timer = 4.0f + float(b.id % 6);
                }
            }

            // ── A. Standard Reynolds Force Accumulation via Contiguous Arrays ──
            VectorND<float, N> f_sep;
            VectorND<float, N> f_ali;
            VectorND<float, N> f_coh;
            int n_sep = 0, n_ali = 0, n_coh = 0;

            float b_pos[N];
            for (size_t d = 0; d < N; ++d) b_pos[d] = soa_buffer.pos[d][i];

            #pragma GCC ivdep
            for (size_t j = 0; j < count; ++j) {
                if (i == j) continue;
                float d_sq = 0.0f;
                float diff[N];
                for (size_t d = 0; d < N; ++d) {
                    diff[d] = b_pos[d] - soa_buffer.pos[d][j];
                    d_sq += diff[d] * diff[d];
                }

                // Separation (inverse square push)
                if (d_sq < sep_r_sq && d_sq > 1e-4f) {
                    float inv_d_sq = 1.0f / d_sq;
                    for (size_t d = 0; d < N; ++d) {
                        f_sep[d] += diff[d] * inv_d_sq;
                    }
                    n_sep++;
                }
                // Alignment (heading match)
                if (d_sq < ali_r_sq) {
                    for (size_t d = 0; d < N; ++d) {
                        f_ali[d] += soa_buffer.vel[d][j];
                    }
                    n_ali++;
                }
                // Cohesion (center of mass)
                if (d_sq < coh_r_sq) {
                    for (size_t d = 0; d < N; ++d) {
                        f_coh[d] += soa_buffer.pos[d][j];
                    }
                    n_coh++;
                }
            }

            VectorND<float, N> steer;

            if (n_sep > 0) {
                f_sep = (f_sep / float(n_sep)).normalized() * config.max_speed - b.velocity;
                steer += f_sep.clampedLength(config.max_force) * config.w_sep;
            }
            if (n_ali > 0) {
                f_ali = (f_ali / float(n_ali)).normalized() * config.max_speed - b.velocity;
                steer += f_ali.clampedLength(config.max_force) * config.w_ali;
            }
            if (n_coh > 0) {
                VectorND<float, N> center = f_coh / float(n_coh);
                VectorND<float, N> desired = (center - b.position).normalized() * config.max_speed;
                f_coh = desired - b.velocity;
                steer += f_coh.clampedLength(config.max_force) * config.w_coh;
            }

            // ── B. Dynamic Roaming Waypoint Attraction ─────────────────────────
            VectorND<float, N> to_target = dynamic_waypoint - b.position;
            float dist_to_target = to_target.length();
            if (dist_to_target > 2.0f) {
                VectorND<float, N> f_roam = to_target.normalized() * config.max_speed - b.velocity;
                steer += f_roam.clampedLength(config.max_force) * (config.w_env * 0.90f);
            }

            // ── C. Multi-Frequency Organic Wander & Curl Noise (BREAKS LIMIT CYCLES) ─
            VectorND<float, N> f_wander;
            float seed_offset = float(b.id * 17 + 31);
            float t_wander = global_time * 0.45f + seed_offset * 0.13f;
            if constexpr (N == 2) {
                f_wander[0] = std::sin(b.position[0] * 0.04f + t_wander) + 0.5f * std::cos(b.position[1] * 0.09f + t_wander * 1.7f);
                f_wander[1] = std::cos(b.position[1] * 0.04f + t_wander * 0.8f) + 0.5f * std::sin(b.position[0] * 0.09f + t_wander * 2.1f);
            } else if constexpr (N >= 3) {
                f_wander[0] = std::sin(b.position[1] * 0.035f + t_wander) + 0.5f * std::cos(b.position[2] * 0.07f + t_wander * 1.6f);
                f_wander[1] = 0.5f * std::cos(b.position[0] * 0.035f + t_wander * 0.9f) + 0.3f * std::sin(b.position[2] * 0.07f + t_wander * 1.3f);
                f_wander[2] = std::sin(b.position[0] * 0.035f + t_wander * 1.2f) + 0.5f * std::cos(b.position[1] * 0.07f + t_wander * 1.9f);
                if constexpr (N == 4) {
                    f_wander[3] = std::sin(b.position[3] * 0.12f + t_wander * 0.7f);
                }
            }
            steer += f_wander.clampedLength(config.max_force) * (config.w_wander * 2.2f);

            // ── D. Biomechanical Undulation & Lateral Sway ────────────────────
            if constexpr (N >= 3) {
                float spd_cur = b.velocity.length();
                if (spd_cur > 0.1f) {
                    VectorND<float, N> f_sway;
                    float sway = std::sin(b.flap_phase) * 0.45f;
                    f_sway[0] = -b.velocity[2] * sway;
                    f_sway[2] =  b.velocity[0] * sway;
                    steer += f_sway.clampedLength(config.max_force) * 0.35f;
                }
            }

            // ── E. Mode-Specific Dynamics (Diving / Thermal Convection) ────────
            if (b.mode == BehaviorMode::FORAGING && config.boid_class == BoidClass::AVIAN_AERIAL) {
                if constexpr (N >= 3) {
                    VectorND<float, N> dive_force;
                    dive_force[1] = -10.0f; // Foraging swoop toward sea
                    steer += dive_force * config.w_dive;
                }
            } else if (b.mode == BehaviorMode::SWARMING && config.boid_class == BoidClass::VOLCANIC_ENTOMOLOGY) {
                if constexpr (N >= 3) {
                    float dx = b.position[0] - config.habitat_center[0];
                    float dz = b.position[2] - config.habitat_center[2];
                    float dist_center = std::sqrt(dx * dx + dz * dz) + 0.001f;
                    float thermal_t = global_time * 0.8f + float(b.id) * 0.5f;
                    VectorND<float, N> vortex_force;
                    float orbit_radius_desired = 18.0f + 8.0f * std::sin(thermal_t * 0.35f);
                    float radial_push = (orbit_radius_desired - dist_center) * 0.8f;
                    vortex_force[0] = (-dz / dist_center) * 4.2f + (dx / dist_center) * radial_push;
                    vortex_force[1] = 2.4f + 1.2f * std::sin(thermal_t * 0.6f);
                    vortex_force[2] = ( dx / dist_center) * 4.2f + (dz / dist_center) * radial_push;
                    steer += vortex_force.clampedLength(config.max_force) * 1.6f;
                }
            }

            // ── F. Boundary Soft Containment ──────────────────────────────────
            for (size_t d = 0; d < N; ++d) {
                float margin = (config.bounds_max[d] - config.bounds_min[d]) * 0.10f;
                if (b.position[d] < config.bounds_min[d] + margin) {
                    float pen = (config.bounds_min[d] + margin - b.position[d]) / (margin + 0.001f);
                    steer[d] += pen * pen * 9.0f;
                } else if (b.position[d] > config.bounds_max[d] - margin) {
                    float pen = (b.position[d] - (config.bounds_max[d] - margin)) / (margin + 0.001f);
                    steer[d] -= pen * pen * 9.0f;
                }
            }

            // ── G. Physical Island Terrain & Sea Avoidance ─────────────────────
            if constexpr (N >= 3) {
                float ground_h = island.getIslandHeight(b.position[0], b.position[2]);
                if (config.boid_class == BoidClass::AQUATIC_PELAGIC) {
                    float max_y = island.sea_level - 0.25f;
                    float min_y = ground_h + 0.40f;
                    if (b.position[1] > max_y) steer[1] -= (b.position[1] - max_y) * 16.0f;
                    if (b.position[1] < min_y) steer[1] += (min_y - b.position[1]) * 18.0f;
                } else {
                    float safe_y = ground_h + 1.8f;
                    if (b.position[1] < safe_y) {
                        steer[1] += (safe_y - b.position[1]) * 18.0f;
                    }
                }
            } else if constexpr (N == 2) {
                float ground_h = island.getIslandHeight(b.position[0], b.position[1]);
                if (ground_h > 12.5f) {
                    VectorND<float, 2> to_sea = {island.center_x - b.position[0], island.center_z - b.position[1]};
                    steer -= to_sea.normalized() * 5.0f;
                } else if (ground_h < 8.8f) {
                    VectorND<float, 2> to_land = {island.center_x - b.position[0], island.center_z - b.position[1]};
                    steer += to_land.normalized() * 5.0f;
                }
            }

            // ── H. Forward Urge & Kinetic Integration ────────────────────────
            float cur_spd = b.velocity.length();
            if (cur_spd > 1e-4f) {
                steer += (b.velocity / cur_spd) * 0.35f;
            }

            b.acceleration = steer.clampedLength(config.max_force);
            b.velocity = (b.velocity + b.acceleration * dt).clampedLength(config.max_speed);
            float spd = b.velocity.length();
            if (spd < config.min_speed && spd > 1e-5f) {
                b.velocity = b.velocity.normalized() * config.min_speed;
            }
            b.position += b.velocity * dt;
        }
    }
};

// ─── 6. Multi-Species Unified Flocking System ─────────────────────────────────
class MultiSpeciesBoidSystem {
public:
    BoidFlock<3> flock_terns;      // Coastal Tropic Terns (3D Airspace)
    BoidFlock<3> flock_tangs;      // Coral Reef Tangs (3D Pelagic Lagoon)
    BoidFlock<3> flock_moths;      // Volcanic Ember Moths (3D Caldera Chimney)
    BoidFlock<2> flock_sandpipers; // Shoreline Sandpipers (2D Beach Surface)
    BoidFlock<4> flock_luminaries; // Hyperspatial Luminaries (4D Manifold Probes)
    BoidFlock<3> flock_fireflies;  // Nocturnal Bioluminescent Fireflies (3D Canopy & Dunes)

    bool initialized = false;
    float weather_storm_intensity = 0.0f;

    void setWeatherStormIntensity(float intensity) {
        weather_storm_intensity = std::max(0.0f, std::min(1.0f, intensity));
    }

    void initialize(const Island::VoxelIsland& island) {
        flock_terns.initialize(SpeciesCatalog::getCoastalTropicTern(island), 32, 101);
        flock_tangs.initialize(SpeciesCatalog::getCoralReefTang(island), 45, 202);
        flock_moths.initialize(SpeciesCatalog::getVolcanicEmberMoth(island), 50, 303);
        flock_sandpipers.initialize(SpeciesCatalog::getShorelineSandpiper(island), 30, 404);
        flock_luminaries.initialize(SpeciesCatalog::getHyperspatialLuminary(island), 20, 505);
        flock_fireflies.initialize(SpeciesCatalog::getNocturnalFirefly(island), 65, 606);

        initialized = true;
        std::cout << "[Boids] Semantic Multi-Species Flocking System active — 242 autonomous agents across 6 species (2D–4D)." << std::endl;
    }

    void update(float dt, const Island::VoxelIsland& island) {
        if (!initialized) initialize(island);
        flock_terns.update(dt, island);
        flock_tangs.update(dt, island);
        flock_moths.update(dt, island);
        flock_sandpipers.update(dt, island);
        flock_luminaries.update(dt, island);
        flock_fireflies.update(dt, island);
    }

    std::vector<Ogre::Vector3> getFireflyLightPositions(size_t max_lights = 8) const {
        std::vector<Ogre::Vector3> pos;
        size_t count = std::min(max_lights, flock_fireflies.agents.size());
        for (size_t i = 0; i < count; ++i) {
            pos.push_back(flock_fireflies.agents[i].position.to3D());
        }
        return pos;
    }

    /**
     * Synthesizes real-time 3D GPU mesh geometry for all active boid species
     * with wing flapping, undulating caudal fins, glowing firefly halos, and ember highlights.
     * Generates explicit outward surface normals for crisp illumination and cel-shading.
     */
    void updateBoidMesh(Ogre::ManualObject* boidMesh, float dt, const Island::VoxelIsland& island) {
        if (!boidMesh) return;
        (void)dt;

        boidMesh->clear();
        boidMesh->begin("SCR/BoidSpeciesMaterial", Ogre::RenderOperation::OT_TRIANGLE_LIST);

        uint32_t vert_idx = 0;

        // 1. Render Coastal Tropic Terns (Avian Wings & Fuselage)
        for (const auto& b : flock_terns.agents) {
            Ogre::Vector3 p = b.position.to3D();
            Ogre::Vector3 fwd(b.velocity.x(), b.velocity.y(), b.velocity.z());
            fwd.normalise();
            Ogre::Vector3 up(0, 1, 0);
            Ogre::Vector3 right = fwd.crossProduct(up).normalisedCopy();
            up = right.crossProduct(fwd).normalisedCopy();

            float wing_flap = std::sin(b.flap_phase) * 0.75f;
            float scale = flock_terns.config.scale;

            Ogre::ColourValue c_white(0.96f, 0.98f, 1.00f);
            Ogre::ColourValue c_black(0.12f, 0.15f, 0.18f);
            Ogre::ColourValue c_beak(1.00f, 0.55f, 0.08f);

            // Fuselage keypoints
            Ogre::Vector3 beak    = p + fwd * (scale * 2.0f);
            Ogre::Vector3 head    = p + fwd * (scale * 1.3f) + up * (scale * 0.35f);
            Ogre::Vector3 breast  = p + fwd * (scale * 0.5f) - up * (scale * 0.35f);
            Ogre::Vector3 back    = p + up * (scale * 0.35f);
            Ogre::Vector3 belly   = p - up * (scale * 0.35f);
            Ogre::Vector3 tail_base = p - fwd * (scale * 1.2f);
            Ogre::Vector3 streamer_l = p - fwd * (scale * 2.4f) - right * (scale * 0.15f);
            Ogre::Vector3 streamer_r = p - fwd * (scale * 2.4f) + right * (scale * 0.15f);

            // Wing joints (articulated swept wings with flapping angle)
            Ogre::Vector3 wing_l_mid = p - fwd * (scale * 0.1f) - right * (scale * 1.4f) + up * (wing_flap * scale * 0.7f);
            Ogre::Vector3 wing_r_mid = p - fwd * (scale * 0.1f) + right * (scale * 1.4f) + up * (wing_flap * scale * 0.7f);
            Ogre::Vector3 wing_l_tip = p - fwd * (scale * 0.6f) - right * (scale * 2.8f) + up * (wing_flap * scale * 1.4f);
            Ogre::Vector3 wing_r_tip = p - fwd * (scale * 0.6f) + right * (scale * 2.8f) + up * (wing_flap * scale * 1.4f);

            // Head & Beak
            emitTriangle(beak, head, breast, c_beak, c_white, c_white, boidMesh, vert_idx);
            emitTriangle(beak, breast, head, c_beak, c_white, c_white, boidMesh, vert_idx);

            // Fuselage body facets
            emitTriangle(head, back, wing_l_mid, c_white, c_white, c_white, boidMesh, vert_idx);
            emitTriangle(head, wing_r_mid, back, c_white, c_white, c_white, boidMesh, vert_idx);
            emitTriangle(breast, wing_l_mid, belly, c_white, c_white, c_white, boidMesh, vert_idx);
            emitTriangle(breast, belly, wing_r_mid, c_white, c_white, c_white, boidMesh, vert_idx);
            emitTriangle(back, tail_base, wing_l_mid, c_white, c_white, c_white, boidMesh, vert_idx);
            emitTriangle(back, wing_r_mid, tail_base, c_white, c_white, c_white, boidMesh, vert_idx);
            emitTriangle(belly, wing_l_mid, tail_base, c_white, c_white, c_white, boidMesh, vert_idx);
            emitTriangle(belly, tail_base, wing_r_mid, c_white, c_white, c_white, boidMesh, vert_idx);

            // Swept wings (inner + outer primary feathers with black tips)
            emitTriangle(back, wing_l_tip, wing_l_mid, c_white, c_black, c_white, boidMesh, vert_idx);
            emitTriangle(back, wing_l_mid, wing_l_tip, c_white, c_white, c_black, boidMesh, vert_idx);
            emitTriangle(back, wing_r_mid, wing_r_tip, c_white, c_white, c_black, boidMesh, vert_idx);
            emitTriangle(back, wing_r_tip, wing_r_mid, c_white, c_black, c_white, boidMesh, vert_idx);

            // Long tail streamers
            emitTriangle(tail_base, streamer_l, back, c_white, c_white, c_white, boidMesh, vert_idx);
            emitTriangle(tail_base, back, streamer_r, c_white, c_white, c_white, boidMesh, vert_idx);
        }

        // 2. Render Coral Reef Tangs (Streamlined Laterally Compressed Fish & Caudal Fin)
        for (const auto& b : flock_tangs.agents) {
            Ogre::Vector3 p = b.position.to3D();
            Ogre::Vector3 fwd(b.velocity.x(), b.velocity.y(), b.velocity.z());
            fwd.normalise();
            Ogre::Vector3 up(0, 1, 0);
            Ogre::Vector3 right = fwd.crossProduct(up).normalisedCopy();
            up = right.crossProduct(fwd).normalisedCopy();

            float tail_wag = std::sin(b.flap_phase) * 0.75f;
            float scale = flock_tangs.config.scale;

            Ogre::ColourValue c_blue(0.08f, 0.45f, 0.98f);
            Ogre::ColourValue c_yellow(0.98f, 0.88f, 0.10f);
            Ogre::ColourValue c_dark(0.06f, 0.12f, 0.22f);

            // Lateral compression: taller than wide
            Ogre::Vector3 snout = p + fwd * (scale * 1.6f);
            Ogre::Vector3 crest = p + fwd * (scale * 0.2f) + up * (scale * 0.9f);
            Ogre::Vector3 belly = p + fwd * (scale * 0.2f) - up * (scale * 0.8f);
            Ogre::Vector3 side_l = p - right * (scale * 0.32f);
            Ogre::Vector3 side_r = p + right * (scale * 0.32f);
            Ogre::Vector3 peduncle = p - fwd * (scale * 1.2f) + right * (tail_wag * scale * 0.35f);

            // Caudal fin (bright yellow undulating tail)
            Ogre::Vector3 fin_t = peduncle - fwd * (scale * 0.9f) + right * (tail_wag * scale * 0.9f) + up * (scale * 0.75f);
            Ogre::Vector3 fin_b = peduncle - fwd * (scale * 0.9f) + right * (tail_wag * scale * 0.9f) - up * (scale * 0.75f);
            Ogre::Vector3 fin_m = peduncle - fwd * (scale * 0.6f) + right * (tail_wag * scale * 0.6f);

            // Head to torso
            emitTriangle(snout, crest, side_l, c_blue, c_dark, c_blue, boidMesh, vert_idx);
            emitTriangle(snout, side_r, crest, c_blue, c_blue, c_dark, boidMesh, vert_idx);
            emitTriangle(snout, side_l, belly, c_blue, c_blue, c_blue, boidMesh, vert_idx);
            emitTriangle(snout, belly, side_r, c_blue, c_blue, c_blue, boidMesh, vert_idx);

            // Torso to tail peduncle
            emitTriangle(crest, peduncle, side_l, c_dark, c_blue, c_blue, boidMesh, vert_idx);
            emitTriangle(crest, side_r, peduncle, c_dark, c_blue, c_blue, boidMesh, vert_idx);
            emitTriangle(belly, side_l, peduncle, c_blue, c_blue, c_blue, boidMesh, vert_idx);
            emitTriangle(belly, peduncle, side_r, c_blue, c_blue, c_blue, boidMesh, vert_idx);

            // Caudal fin fan
            emitTriangle(peduncle, fin_t, fin_m, c_yellow, c_yellow, c_yellow, boidMesh, vert_idx);
            emitTriangle(peduncle, fin_m, fin_t, c_yellow, c_yellow, c_yellow, boidMesh, vert_idx);
            emitTriangle(peduncle, fin_m, fin_b, c_yellow, c_yellow, c_yellow, boidMesh, vert_idx);
            emitTriangle(peduncle, fin_b, fin_m, c_yellow, c_yellow, c_yellow, boidMesh, vert_idx);
        }

        // 3. Render Volcanic Ember Moths (Luminescent Fluttering Wings)
        for (const auto& b : flock_moths.agents) {
            Ogre::Vector3 p = b.position.to3D();
            float flutter = std::sin(b.flap_phase) * 0.85f;
            float scale = flock_moths.config.scale;

            Ogre::ColourValue c_amber(1.00f, 0.55f, 0.08f);
            Ogre::ColourValue c_gold(1.00f, 0.85f, 0.25f);
            Ogre::ColourValue c_charcoal(0.22f, 0.16f, 0.12f);

            Ogre::Vector3 head   = p + Ogre::Vector3(0, 0,  scale * 0.7f);
            Ogre::Vector3 tail   = p + Ogre::Vector3(0, 0, -scale * 0.7f);
            Ogre::Vector3 body_t = p + Ogre::Vector3(0,  scale * 0.35f, 0);
            Ogre::Vector3 body_b = p - Ogre::Vector3(0,  scale * 0.35f, 0);

            // Large gossamer forewings & hindwings
            Ogre::Vector3 wing_fl = p + Ogre::Vector3(-scale * 2.2f, flutter * scale * 1.2f,  scale * 0.6f);
            Ogre::Vector3 wing_fr = p + Ogre::Vector3( scale * 2.2f, flutter * scale * 1.2f,  scale * 0.6f);
            Ogre::Vector3 wing_kl = p + Ogre::Vector3(-scale * 1.6f, flutter * scale * 0.7f, -scale * 0.8f);
            Ogre::Vector3 wing_kr = p + Ogre::Vector3( scale * 1.6f, flutter * scale * 0.7f, -scale * 0.8f);

            // Abdomen / Thorax
            emitTriangle(head, body_t, tail, c_charcoal, c_gold, c_charcoal, boidMesh, vert_idx);
            emitTriangle(head, tail, body_b, c_charcoal, c_charcoal, c_amber, boidMesh, vert_idx);

            // Forewings (double-sided)
            emitTriangle(body_t, wing_fl, head, c_gold, c_amber, c_charcoal, boidMesh, vert_idx);
            emitTriangle(body_t, head, wing_fl, c_gold, c_charcoal, c_amber, boidMesh, vert_idx);
            emitTriangle(body_t, head, wing_fr, c_gold, c_charcoal, c_amber, boidMesh, vert_idx);
            emitTriangle(body_t, wing_fr, head, c_gold, c_amber, c_charcoal, boidMesh, vert_idx);

            // Hindwings (double-sided)
            emitTriangle(body_t, tail, wing_kl, c_gold, c_charcoal, c_amber, boidMesh, vert_idx);
            emitTriangle(body_t, wing_kl, tail, c_gold, c_amber, c_charcoal, boidMesh, vert_idx);
            emitTriangle(body_t, wing_kr, tail, c_gold, c_amber, c_charcoal, boidMesh, vert_idx);
            emitTriangle(body_t, tail, wing_kr, c_gold, c_charcoal, c_amber, boidMesh, vert_idx);
        }

        // 4. Render Shoreline Sandpipers (2D Beach Surface Foragers)
        for (const auto& b : flock_sandpipers.agents) {
            float y = island.getIslandHeight(b.position.x(), b.position.y()) + 0.18f;
            Ogre::Vector3 p(b.position.x(), y, b.position.y());
            Ogre::Vector3 fwd(b.velocity.x(), 0.0f, b.velocity.y());
            fwd.normalise();
            Ogre::Vector3 right(-fwd.z, 0.0f, fwd.x);
            float scale = flock_sandpipers.config.scale;

            Ogre::ColourValue c_dune(0.85f, 0.78f, 0.65f);
            Ogre::ColourValue c_brown(0.42f, 0.32f, 0.22f);
            Ogre::ColourValue c_bill(0.20f, 0.18f, 0.15f);

            Ogre::Vector3 bill = p + fwd * (scale * 1.5f) + Ogre::Vector3(0, scale * 0.45f, 0);
            Ogre::Vector3 head = p + fwd * (scale * 0.9f) + Ogre::Vector3(0, scale * 0.75f, 0);
            Ogre::Vector3 back = p + Ogre::Vector3(0, scale * 0.85f, 0);
            Ogre::Vector3 breast = p + fwd * (scale * 0.5f) + Ogre::Vector3(0, scale * 0.25f, 0);
            Ogre::Vector3 belly  = p - Ogre::Vector3(0, scale * 0.05f, 0);
            Ogre::Vector3 tail   = p - fwd * (scale * 1.1f) + Ogre::Vector3(0, scale * 0.45f, 0);
            Ogre::Vector3 w_l    = p - right * (scale * 0.45f) + Ogre::Vector3(0, scale * 0.45f, 0);
            Ogre::Vector3 w_r    = p + right * (scale * 0.45f) + Ogre::Vector3(0, scale * 0.45f, 0);

            // Beak
            emitTriangle(bill, head, breast, c_bill, c_dune, c_dune, boidMesh, vert_idx);
            emitTriangle(bill, breast, head, c_bill, c_dune, c_dune, boidMesh, vert_idx);

            // Plump body facets
            emitTriangle(head, back, w_l, c_dune, c_brown, c_brown, boidMesh, vert_idx);
            emitTriangle(head, w_r, back, c_dune, c_brown, c_brown, boidMesh, vert_idx);
            emitTriangle(breast, w_l, belly, c_dune, c_brown, c_dune, boidMesh, vert_idx);
            emitTriangle(breast, belly, w_r, c_dune, c_dune, c_brown, boidMesh, vert_idx);
            emitTriangle(back, tail, w_l, c_brown, c_brown, c_brown, boidMesh, vert_idx);
            emitTriangle(back, w_r, tail, c_brown, c_brown, c_brown, boidMesh, vert_idx);
            emitTriangle(belly, w_l, tail, c_dune, c_brown, c_brown, boidMesh, vert_idx);
            emitTriangle(belly, tail, w_r, c_dune, c_brown, c_brown, boidMesh, vert_idx);
        }

        // 5. Render Hyperspatial Luminaries (4D Projective Octahedral Crystals)
        for (const auto& b : flock_luminaries.agents) {
            Ogre::Vector3 p = b.position.to3D(flock_luminaries.w_slice_phase);
            float pw = b.position.w() - flock_luminaries.w_slice_phase;
            float vis_alpha = std::exp(-0.18f * pw * pw);
            if (vis_alpha < 0.15f) continue;

            float scale = flock_luminaries.config.scale * (0.6f + 0.4f * vis_alpha);

            // Chromatic dispersion shimmer
            Ogre::ColourValue col_top(0.2f, 0.9f, 1.0f, vis_alpha);
            Ogre::ColourValue col_bot(1.0f, 0.3f, 0.9f, vis_alpha);
            Ogre::ColourValue col_mid(0.6f, 0.7f, 1.0f, vis_alpha);

            Ogre::Vector3 top = p + Ogre::Vector3(0, scale * 1.6f, 0);
            Ogre::Vector3 bot = p - Ogre::Vector3(0, scale * 1.6f, 0);
            Ogre::Vector3 pX1 = p + Ogre::Vector3( scale * 1.0f, 0, 0);
            Ogre::Vector3 pX2 = p - Ogre::Vector3( scale * 1.0f, 0, 0);
            Ogre::Vector3 pZ1 = p + Ogre::Vector3(0, 0,  scale * 1.0f);
            Ogre::Vector3 pZ2 = p - Ogre::Vector3(0, 0, -scale * 1.0f);

            // Upper 4 faces
            emitTriangle(top, pX1, pZ1, col_top, col_mid, col_mid, boidMesh, vert_idx);
            emitTriangle(top, pZ1, pX2, col_top, col_mid, col_mid, boidMesh, vert_idx);
            emitTriangle(top, pX2, pZ2, col_top, col_mid, col_mid, boidMesh, vert_idx);
            emitTriangle(top, pZ2, pX1, col_top, col_mid, col_mid, boidMesh, vert_idx);

            // Lower 4 faces
            emitTriangle(bot, pZ1, pX1, col_bot, col_mid, col_mid, boidMesh, vert_idx);
            emitTriangle(bot, pX2, pZ1, col_bot, col_mid, col_mid, boidMesh, vert_idx);
            emitTriangle(bot, pZ2, pX2, col_bot, col_mid, col_mid, boidMesh, vert_idx);
            emitTriangle(bot, pX1, pZ2, col_bot, col_mid, col_mid, boidMesh, vert_idx);
        }

        // 6. Render Nocturnal Bioluminescent Fireflies (Glowing Emerald & Gold Lanterns)
        for (const auto& b : flock_fireflies.agents) {
            Ogre::Vector3 p = b.position.to3D();
            float pulse = 0.70f + 0.30f * std::sin(b.flap_phase * 1.2f + float(b.id));
            float scale = flock_fireflies.config.scale * pulse;

            Ogre::ColourValue col_emerald = Ogre::ColourValue(0.40f, 1.00f, 0.35f) * pulse;
            Ogre::ColourValue col_gold    = Ogre::ColourValue(1.00f, 0.88f, 0.20f) * pulse;

            Ogre::Vector3 top = p + Ogre::Vector3(0, scale * 0.7f, 0);
            Ogre::Vector3 bot = p - Ogre::Vector3(0, scale * 0.7f, 0);
            Ogre::Vector3 p1  = p + Ogre::Vector3(-scale * 0.6f, 0,  scale * 0.6f);
            Ogre::Vector3 p2  = p + Ogre::Vector3( scale * 0.6f, 0,  scale * 0.6f);
            Ogre::Vector3 p3  = p + Ogre::Vector3(0, 0, -scale * 0.8f);

            // Dual tetrahedral lantern core with bright self-luminous vertex colors
            emitTriangle(top, p1, p2, col_emerald, col_gold, col_gold, boidMesh, vert_idx);
            emitTriangle(top, p2, p3, col_emerald, col_gold, col_emerald, boidMesh, vert_idx);
            emitTriangle(top, p3, p1, col_emerald, col_emerald, col_gold, boidMesh, vert_idx);
            emitTriangle(bot, p2, p1, col_gold, col_gold, col_gold, boidMesh, vert_idx);
            emitTriangle(bot, p3, p2, col_gold, col_emerald, col_gold, boidMesh, vert_idx);
            emitTriangle(bot, p1, p3, col_gold, col_gold, col_emerald, boidMesh, vert_idx);
        }

        boidMesh->end();
    }

private:
    static void emitTriangle(
        const Ogre::Vector3& v0,
        const Ogre::Vector3& v1,
        const Ogre::Vector3& v2,
        const Ogre::ColourValue& c0,
        const Ogre::ColourValue& c1,
        const Ogre::ColourValue& c2,
        Ogre::ManualObject* mesh,
        uint32_t& vert_idx
    ) {
        Ogre::Vector3 e1 = v1 - v0;
        Ogre::Vector3 e2 = v2 - v0;
        Ogre::Vector3 n = e1.crossProduct(e2).normalisedCopy();
        if (n.isNaN() || n.squaredLength() < 1e-4f) {
            n = Ogre::Vector3::UNIT_Y;
        }

        uint32_t base = vert_idx;
        mesh->position(v0); mesh->normal(n); mesh->colour(c0);
        mesh->position(v1); mesh->normal(n); mesh->colour(c1);
        mesh->position(v2); mesh->normal(n); mesh->colour(c2);

        mesh->triangle(base, base + 1, base + 2);
        vert_idx += 3;
    }
};

} // namespace SCR::Boids

#endif // CAVE_BOID_SEMANTICS_HPP
