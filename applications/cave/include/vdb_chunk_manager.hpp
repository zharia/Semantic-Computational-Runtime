#ifndef CAVE_VDB_CHUNK_MANAGER_HPP
#define CAVE_VDB_CHUNK_MANAGER_HPP

#include <openvdb/openvdb.h>
#include <openvdb/tools/VolumeToMesh.h>

#include <Ogre.h>

#include "spatial_semantics.hpp"
#include "semantic_materials.hpp"
#include "procedural_island.hpp"
#include "spatial_partitions.hpp"
#include "persistent_chunk_storage.hpp"

#include <vector>
#include <unordered_map>
#include <queue>
#include <thread>
#include <mutex>
#include <condition_variable>
#include <atomic>
#include <memory>
#include <algorithm>
#include <cmath>
#include <iostream>

namespace SCR::VDB {

/**
 * 3D Integer Chunk Coordinates for Paged Volumetric OpenVDB Grid.
 */
struct ChunkCoord {
    int cx = 0;
    int cy = 0;
    int cz = 0;

    ChunkCoord() = default;
    ChunkCoord(int x, int y, int z) : cx(x), cy(y), cz(z) {}

    bool operator==(const ChunkCoord& o) const {
        return cx == o.cx && cy == o.cy && cz == o.cz;
    }

    bool operator!=(const ChunkCoord& o) const {
        return !(*this == o);
    }

    float distanceTo(const ChunkCoord& o) const {
        float dx = float(cx - o.cx);
        float dy = float(cy - o.cy);
        float dz = float(cz - o.cz);
        return std::sqrt(dx * dx + dy * dy + dz * dz);
    }
};

struct ChunkCoordHash {
    std::size_t operator()(const ChunkCoord& c) const noexcept {
        std::size_t h1 = std::hash<int>{}(c.cx);
        std::size_t h2 = std::hash<int>{}(c.cy);
        std::size_t h3 = std::hash<int>{}(c.cz);
        return h1 ^ (h2 << 1) ^ (h3 << 2);
    }
};

/**
 * Extracted Geometry Payload ready for GPU hardware buffer upload.
 */
struct ChunkMeshPayload {
    ChunkCoord coord;
    uint64_t generation = 0;
    std::vector<Ogre::Vector3> positions;
    std::vector<Ogre::Vector3> normals;
    std::vector<Ogre::Vector2> uvs;
    std::vector<Ogre::ColourValue> colors;
    std::vector<uint32_t> indices;
    float adaptivity = 0.02f;
    bool has_geometry = false;
};

/**
 * In-World Volumetric Chunk Container.
 */
class VdbChunk {
public:
    enum State {
        UNLOADED,
        QUEUED,
        GENERATING,
        READY_TO_COMMIT,
        ACTIVE,
        EVICTED
    };

    ChunkCoord coord;
    uint64_t generation = 0;
    std::atomic<State> state{UNLOADED};
    Ogre::SceneNode* scene_node = nullptr;
    Ogre::ManualObject* manual_obj = nullptr;
    ChunkMeshPayload payload;
    float last_access_time = 0.0f;
    float current_adaptivity = 0.02f;

    VdbChunk(const ChunkCoord& c) : coord(c) {}

    ~VdbChunk() {
        // Scene node and manual object are destroyed by SceneManager on main thread
    }
};

/**
 * Multi-Threaded Paged OpenVDB Volumetric Chunk Manager.
 * Streams chunks dynamically based on player position, executes background
 * polygonization with 1-voxel overlap skirt seam-stitching, and uploads
 * directly to Ogre3D GPU vertex buffers without main-thread stutter.
 */
class VdbChunkManager {
public:
    static constexpr int CHUNK_SIZE = 48; // Voxels per chunk dimension (48m x 48m x 48m)
    static constexpr int LOAD_RADIUS_XZ = 4; // Chunks horizontal radius (9x9 area = 432m x 432m)
    static constexpr int LOAD_RADIUS_Y = 2;  // Chunks vertical radius (5 chunks = 240m vertical span)
    static constexpr int EVICT_RADIUS_XZ = LOAD_RADIUS_XZ + 1;
    static constexpr int EVICT_RADIUS_Y = LOAD_RADIUS_Y + 1;

    struct QueuedCandidate {
        ChunkCoord coord;
        float dist_sq;
        float adaptivity;
    };

    VdbChunkManager() {
        openvdb::initialize();
        candidates_.reserve(512);
        ready_payloads_.reserve(64);
        to_evict_.reserve(64);
        startWorkerThreads(2);
    }

    ~VdbChunkManager() {
        stopWorkerThreads();
        clearAllChunks();
    }

    void startWorkerThreads(size_t num_threads = 2) {
        stop_workers_ = false;
        for (size_t i = 0; i < num_threads; ++i) {
            workers_.emplace_back(&VdbChunkManager::workerLoop, this);
        }
    }

    void stopWorkerThreads() {
        stop_workers_ = true;
        queue_cv_.notify_all();
        for (auto& t : workers_) {
            if (t.joinable()) {
                t.join();
            }
        }
        workers_.clear();
    }

    void clearAllChunks(Ogre::SceneManager* scnMgr = nullptr) {
        current_generation_.fetch_add(1, std::memory_order_seq_cst);

        // 1. Drain pending worker jobs
        {
            std::lock_guard<std::mutex> lock_q(queue_mutex_);
            std::queue<MeshingJob> empty_q;
            std::swap(job_queue_, empty_q);
        }

        // 2. Drain completed mesh payloads
        {
            std::lock_guard<std::mutex> lock_comp(completed_mutex_);
            std::queue<ChunkMeshPayload> empty_comp;
            std::swap(completed_queue_, empty_comp);
        }

        // 3. Destroy all Ogre ManualObjects and SceneNodes attached to scene
        {
            std::lock_guard<std::mutex> lock(chunks_mutex_);
            if (scnMgr) {
                for (auto& pair : active_chunks_) {
                    auto& chunk = pair.second;
                    if (chunk->manual_obj) {
                        try {
                            if (scnMgr->hasManualObject(chunk->manual_obj->getName())) {
                                scnMgr->destroyManualObject(chunk->manual_obj);
                            }
                        } catch (...) {}
                        chunk->manual_obj = nullptr;
                    }
                    if (chunk->scene_node) {
                        try {
                            if (scnMgr->hasSceneNode(chunk->scene_node->getName())) {
                                scnMgr->destroySceneNode(chunk->scene_node);
                            }
                        } catch (...) {}
                        chunk->scene_node = nullptr;
                    }
                }
            }
            active_chunks_.clear();
        }
    }

    /**
     * Main update called every frame on the main render thread.
     * Computes active chunk visibility, queues missing chunks, evicts out-of-range chunks,
     * and uploads finished background mesh payloads to GPU buffers.
     */
    void update(
        const Ogre::Vector3& player_pos,
        const Island::VoxelIsland& island,
        Ogre::SceneManager* scnMgr,
        float dt
    ) {
        simulation_time_ += dt;

        // 1. Calculate Player Chunk Coordinates
        int pcx = (int)std::floor(player_pos.x / float(CHUNK_SIZE));
        int pcy = (int)std::floor(player_pos.y / float(CHUNK_SIZE));
        int pcz = (int)std::floor(player_pos.z / float(CHUNK_SIZE));
        ChunkCoord player_chunk(pcx, pcy, pcz);

        // 2. Commit Completed Background Meshes to Ogre GPU Buffers
        commitFinishedChunks(scnMgr);

        // 3. Queue Chunks within View Horizon (sorted closest first)
        candidates_.clear();

        for (int dy = -LOAD_RADIUS_Y; dy <= LOAD_RADIUS_Y; ++dy) {
            for (int dz = -LOAD_RADIUS_XZ; dz <= LOAD_RADIUS_XZ; ++dz) {
                for (int dx = -LOAD_RADIUS_XZ; dx <= LOAD_RADIUS_XZ; ++dx) {
                    ChunkCoord c(pcx + dx, pcy + dy, pcz + dz);

                    // Check bounds against island terrain height
                    float world_x = (c.cx + 0.5f) * CHUNK_SIZE;
                    float world_z = (c.cz + 0.5f) * CHUNK_SIZE;
                    float world_y_min = c.cy * CHUNK_SIZE;
                    float world_y_max = (c.cy + 1) * CHUNK_SIZE;

                    // If chunk is completely above island peak or deep below bedrock, skip
                    if (world_y_min > island.peak_height + 16.0f || world_y_max < -8.0f) {
                        continue;
                    }

                    float dist_chunks = std::sqrt(float(dx * dx + dy * dy + dz * dz));
                    if (dist_chunks > float(LOAD_RADIUS_XZ) + 0.5f) continue;

                    // Distance-based adaptive Level of Detail (LOD)
                    float adaptivity = 0.015f; // Near (high detail)
                    if (dist_chunks > 3.0f) adaptivity = 0.15f; // Far horizon (low poly)
                    else if (dist_chunks > 1.8f) adaptivity = 0.06f; // Mid-range

                    candidates_.push_back({c, float(dx * dx + dy * dy + dz * dz), adaptivity});
                }
            }
        }

        // Sort candidates: closest to player first
        std::sort(candidates_.begin(), candidates_.end(), [](const QueuedCandidate& a, const QueuedCandidate& b) {
            return a.dist_sq < b.dist_sq;
        });

        {
            std::lock_guard<std::mutex> lock(chunks_mutex_);
            for (const auto& cand : candidates_) {
                auto it = active_chunks_.find(cand.coord);
                if (it == active_chunks_.end()) {
                    auto chunk = std::make_shared<VdbChunk>(cand.coord);
                    chunk->state = VdbChunk::QUEUED;
                    chunk->current_adaptivity = cand.adaptivity;
                    chunk->last_access_time = simulation_time_;
                    active_chunks_[cand.coord] = chunk;

                    // Enqueue for background worker meshing
                    enqueueJob(cand.coord, cand.adaptivity, island);
                } else {
                    it->second->last_access_time = simulation_time_;
                }
            }
        }

        // 4. Evict Distant Chunks
        evictDistantChunks(player_chunk, scnMgr);
    }

    /**
     * Returns the total active chunk count, queued count, and total rendered vertices.
     */
    void getStatistics(size_t& out_active, size_t& out_queued, size_t& out_total_vertices) const {
        std::lock_guard<std::mutex> lock(chunks_mutex_);
        out_active = 0;
        out_queued = 0;
        out_total_vertices = 0;

        for (const auto& pair : active_chunks_) {
            if (pair.second->state == VdbChunk::ACTIVE) {
                out_active++;
                out_total_vertices += pair.second->payload.positions.size();
            } else if (pair.second->state == VdbChunk::QUEUED || pair.second->state == VdbChunk::GENERATING) {
                out_queued++;
            }
        }
    }

    void saveWorld(const Ogre::Vector3& player_pos, float time_of_day, uint32_t seed = 1337) {
        Storage::WorldManifest manifest;
        manifest.world_name = "ExoticVolcanicIsland";
        manifest.seed = seed;
        manifest.player_x = player_pos.x;
        manifest.player_y = player_pos.y;
        manifest.player_z = player_pos.z;
        manifest.time_of_day_hours = time_of_day;

        {
            std::lock_guard<std::mutex> lock(chunks_mutex_);
            manifest.saved_chunk_count = active_chunks_.size();
        }

        auto now = std::chrono::system_clock::now();
        std::time_t t = std::chrono::system_clock::to_time_t(now);
        manifest.timestamp = std::ctime(&t);
        if (!manifest.timestamp.empty() && manifest.timestamp.back() == '\n') {
            manifest.timestamp.pop_back();
        }

        Storage::PersistentChunkStorage::instance().saveWorldManifest(manifest);
        std::cout << "[Storage] World state & spatial partitions successfully saved to persistent storage." << std::endl;
    }

    void cleanup(Ogre::SceneManager* scnMgr) {
        stopWorkerThreads();
        clearAllChunks(scnMgr);
    }

private:
    struct MeshingJob {
        ChunkCoord coord;
        uint64_t generation = 0;
        float adaptivity = 0.02f;
        const Island::VoxelIsland* island = nullptr;
    };

    void enqueueJob(const ChunkCoord& coord, float adaptivity, const Island::VoxelIsland& island) {
        std::lock_guard<std::mutex> lock(queue_mutex_);
        job_queue_.push({coord, current_generation_.load(std::memory_order_relaxed), adaptivity, &island});
        queue_cv_.notify_one();
    }

    /**
     * Background Worker Thread Loop: Executes OpenVDB LevelSet SDF extraction and volumeToMesh.
     */
    void workerLoop() {
        while (!stop_workers_) {
            MeshingJob job;
            {
                std::unique_lock<std::mutex> lock(queue_mutex_);
                queue_cv_.wait(lock, [this] {
                    return stop_workers_ || !job_queue_.empty();
                });

                if (stop_workers_) break;
                job = job_queue_.front();
                job_queue_.pop();
            }

            if (!job.island || job.generation != current_generation_.load(std::memory_order_relaxed)) continue;

            // Generate Volumetric Mesh with 1-Voxel Overlap Skirt for Seamless Stitching
            ChunkMeshPayload payload = generateChunkMesh(job.coord, job.adaptivity, *job.island);
            payload.generation = job.generation;

            if (job.generation != current_generation_.load(std::memory_order_relaxed)) continue;

            {
                std::lock_guard<std::mutex> lock(completed_mutex_);
                if (job.generation == current_generation_.load(std::memory_order_relaxed)) {
                    completed_queue_.push(std::move(payload));
                }
            }
        }
    }

    /**
     * Seamless Volumetric Isosurface Extraction with 1-voxel overlap skirt.
     */
    ChunkMeshPayload generateChunkMesh(
        const ChunkCoord& coord,
        float adaptivity,
        const Island::VoxelIsland& island
    ) {
        ChunkMeshPayload result;
        result.coord = coord;
        result.adaptivity = adaptivity;

        // Voxel domain with 1-voxel skirt: [-1, CHUNK_SIZE + 1]
        int min_vx = coord.cx * CHUNK_SIZE;
        int min_vy = coord.cy * CHUNK_SIZE;
        int min_vz = coord.cz * CHUNK_SIZE;

        // 1. Check if persistent chunk exists on disk for this specific biome
        openvdb::FloatGrid::Ptr grid = nullptr;
        std::vector<Storage::VoxelDelta> deltas;
        bool loaded_from_disk = Storage::PersistentChunkStorage::instance().loadChunk(
            coord.cx, coord.cy, coord.cz, (int)island.biome_type, grid, deltas
        );

        if (!loaded_from_disk || !grid) {
            grid = openvdb::FloatGrid::create(-1.0f);
            grid->setName("VolcanicIslandDensityGrid");
            grid->setGridClass(openvdb::GRID_LEVEL_SET);
            grid->setTransform(openvdb::math::Transform::createLinearTransform(island.voxel_size));
            auto accessor = grid->getAccessor();

            bool has_solid = false;
            bool has_air = false;

            // Populate OpenVDB FloatGrid over chunk bounds plus 1-voxel skirt
            for (int lz = -1; lz <= CHUNK_SIZE + 1; ++lz) {
                int gz = min_vz + lz;
                for (int ly = -1; ly <= CHUNK_SIZE + 1; ++ly) {
                    int gy = min_vy + ly;
                    for (int lx = -1; lx <= CHUNK_SIZE + 1; ++lx) {
                        int gx = min_vx + lx;

                        float density = island.sampleContinuousDensity(float(gx), float(gy), float(gz));
                        accessor.setValue(openvdb::Coord(gx, gy, gz), density);

                        if (density > 0.0f) has_solid = true;
                        else has_air = true;
                    }
                }
            }

            // If chunk is completely empty air or completely solid underground with no boundary, skip meshing
            if (!has_solid || !has_air) {
                result.has_geometry = false;
                return result;
            }

            // Save chunk to persistent storage
            Storage::PersistentChunkStorage::instance().saveChunk(
                coord.cx, coord.cy, coord.cz, (int)island.biome_type, grid, {}
            );
        }

        auto accessor = grid->getAccessor();

        // 2. OpenVDB Adaptive VolumeToMesh Polygonization
        std::vector<openvdb::Vec3s> vdb_points;
        std::vector<openvdb::Vec3I> vdb_triangles;
        std::vector<openvdb::Vec4I> vdb_quads;

        openvdb::tools::volumeToMesh(
            *grid, vdb_points, vdb_triangles, vdb_quads,
            0.0, double(adaptivity), true
        );

        if (vdb_points.empty() || (vdb_triangles.empty() && vdb_quads.empty())) {
            result.has_geometry = false;
            return result;
        }

        const auto& reg = Material::MaterialRegistry::instance();

        auto get_density = [&](float sx, float sy, float sz) -> float {
            openvdb::Coord c((int)std::floor(sx), (int)std::floor(sy), (int)std::floor(sz));
            return accessor.getValue(c);
        };

        // 3. Compute Outward Gradient Normals & Vertex Materials
        result.positions.reserve(vdb_points.size());
        result.normals.reserve(vdb_points.size());
        result.uvs.reserve(vdb_points.size());
        result.colors.reserve(vdb_points.size());

        for (size_t i = 0; i < vdb_points.size(); ++i) {
            const auto& p = vdb_points[i];
            Ogre::Vector3 pos(p.x(), p.y(), p.z());
            result.positions.push_back(pos);

            // Central Differences on the Density Field
            float eps = 0.5f;
            float dx_val = get_density(p.x() + eps, p.y(), p.z()) - get_density(p.x() - eps, p.y(), p.z());
            float dy_val = get_density(p.x(), p.y() + eps, p.z()) - get_density(p.x(), p.y() - eps, p.z());
            float dz_val = get_density(p.x(), p.y(), p.z() + eps) - get_density(p.x(), p.y(), p.z() - eps);

            Ogre::Vector3 norm(-dx_val, -dy_val, -dz_val);
            if (norm.squaredLength() > 1e-6f) norm.normalise();
            else norm = Ogre::Vector3::UNIT_Y;
            result.normals.push_back(norm);

            result.uvs.emplace_back(p.x() * 0.15f, p.z() * 0.15f);

            // Material Determination across all spatial partitions
            int vx = (int)std::floor(p.x());
            int vy = (int)std::floor(p.y());
            int vz = (int)std::floor(p.z());

            uint16_t mat_code = Material::MAT_AIR;
            if (island.inBounds(vx, vy, vz)) {
                mat_code = island.getVoxel(vx, vy, vz);
            }

            if (mat_code == Material::MAT_AIR || mat_code == Material::MAT_WATER ||
                mat_code == Material::MAT_DIRT || mat_code == Material::MAT_BASALT ||
                mat_code == Material::MAT_BEDROCK || mat_code == Material::MAT_SANDSTONE) {
                float slope = 1.0f - std::max(0.0f, norm.y);

                if (island.biome_type == Island::IslandBiomeType::DESERT) {
                    if (slope > 0.50f || p.y() > island.sea_level + 24.0f) mat_code = Material::MAT_SANDSTONE;
                    else mat_code = Material::MAT_SAND;
                } else if (island.biome_type == Island::IslandBiomeType::GLACIAL_ICE) {
                    if (p.y() > island.sea_level + 16.0f || slope < 0.40f) mat_code = Material::MAT_ICE;
                    else mat_code = Material::MAT_GRANITE;
                } else if (island.biome_type == Island::IslandBiomeType::JUNGLE) {
                    if (slope > 0.52f) mat_code = Material::MAT_DIRT;
                    else if (p.y() >= island.sea_level + 1.2f) mat_code = Material::MAT_MOSS;
                    else mat_code = Material::MAT_SAND;
                } else if (island.biome_type == Island::IslandBiomeType::CORAL_ARCHIPELAGO) {
                    if (p.y() <= island.sea_level + 2.5f) mat_code = Material::MAT_SAND;
                    else if (slope < 0.45f) mat_code = Material::MAT_MOSS;
                    else mat_code = Material::MAT_SANDSTONE;
                } else {
                    // VOLCANO BIOME
                    float d_cx = p.x() - island.center_x;
                    float d_cz = p.z() - island.center_z;
                    float r = std::sqrt(d_cx * d_cx + d_cz * d_cz);
                    float theta = std::atan2(d_cz, d_cx);

                    float ad = std::abs(theta - Island::VoxelIsland::RIVER_ANGLE);
                    if (ad > 3.14159f) ad = 6.28318f - ad;
                    float river_dist = r * ad;

                    if (r > island.caldera_radius * 0.55f && r < island.island_radius * 0.96f && river_dist < 4.2f) {
                        if (river_dist < 1.8f) mat_code = Material::MAT_LAVA;
                        else mat_code = Material::MAT_OBSIDIAN;
                    } else if (r < island.caldera_radius * 1.35f) {
                        float crater_floor_y = island.peak_height - island.caldera_depth;
                        if (r < island.caldera_radius * 0.65f && p.y() <= crater_floor_y + 4.5f) {
                            mat_code = (r < island.caldera_radius * 0.42f) ? Material::MAT_LAVA : Material::MAT_OBSIDIAN;
                        } else if (p.y() >= island.peak_height - 4.5f) {
                            float vent_noise = std::sin(p.x() * 0.4f) * std::cos(p.z() * 0.4f);
                            if (vent_noise > 0.25f) mat_code = Material::MAT_SULFUR;
                            else if (vent_noise < -0.30f) mat_code = Material::MAT_ASH;
                            else mat_code = Material::MAT_PUMICE;
                        } else if (slope > 0.45f) {
                            mat_code = Material::MAT_OBSIDIAN;
                        } else {
                            mat_code = Material::MAT_BASALT;
                        }
                    } else if (p.y() < island.sea_level + 28.0f && r > island.caldera_radius * 1.3f) {
                        if (p.y() <= island.sea_level + 1.8f) {
                            mat_code = Material::MAT_SAND;
                        } else if (slope < 0.48f) {
                            float veg_noise = std::sin(p.x() * 0.12f) + std::cos(p.z() * 0.12f);
                            if (veg_noise > 0.2f && p.y() < island.sea_level + 20.0f) mat_code = Material::MAT_FOLIAGE;
                            else if (p.y() < island.sea_level + 14.0f) mat_code = Material::MAT_MOSS;
                            else mat_code = Material::MAT_DIRT;
                        } else {
                            mat_code = (slope > 0.65f) ? Material::MAT_BASALT : Material::MAT_DIRT;
                        }
                    } else {
                        float strata = std::sin(p.y() * 0.65f + std::sin(p.x() * 0.1f) * 1.5f);
                        if (slope > 0.55f) {
                            mat_code = (strata > 0.35f) ? Material::MAT_BASALT : Material::MAT_OBSIDIAN;
                        } else if (strata > 0.50f) {
                            mat_code = Material::MAT_PUMICE;
                        } else if (strata < -0.40f) {
                            mat_code = Material::MAT_ASH;
                        } else {
                            mat_code = Material::MAT_BASALT;
                        }
                    }
                }
            }

            const auto& mat = reg.get(mat_code);
            float ao = std::max(0.70f, std::min(1.0f, 0.75f + norm.y * 0.25f));
            float grain = 0.92f + 0.16f * std::sin(p.x() * 0.8f + p.y() * 1.4f + p.z() * 0.8f);
            result.colors.emplace_back(std::min(1.0f, mat.albedo.r * ao * grain),
                                       std::min(1.0f, mat.albedo.g * ao * grain),
                                       std::min(1.0f, mat.albedo.b * ao * grain), 1.0f);
        }

        // Triangles and Quads into Indices
        result.indices.reserve(vdb_triangles.size() * 3 + vdb_quads.size() * 6);
        for (const auto& tri : vdb_triangles) {
            result.indices.push_back(tri[0]);
            result.indices.push_back(tri[1]);
            result.indices.push_back(tri[2]);
        }
        for (const auto& quad : vdb_quads) {
            result.indices.push_back(quad[0]);
            result.indices.push_back(quad[1]);
            result.indices.push_back(quad[2]);

            result.indices.push_back(quad[0]);
            result.indices.push_back(quad[2]);
            result.indices.push_back(quad[3]);
        }

        result.has_geometry = !result.positions.empty() && !result.indices.empty();
        return result;
    }

    /**
     * Uploads completed background chunk meshes to GPU buffers on the main render thread.
     */
    void commitFinishedChunks(Ogre::SceneManager* scnMgr) {
        if (!scnMgr) return;
        ready_payloads_.clear();
        {
            std::lock_guard<std::mutex> lock(completed_mutex_);
            while (!completed_queue_.empty()) {
                ready_payloads_.push_back(std::move(completed_queue_.front()));
                completed_queue_.pop();
            }
        }

        if (ready_payloads_.empty()) return;

        uint64_t cur_gen = current_generation_.load(std::memory_order_relaxed);

        std::lock_guard<std::mutex> lock(chunks_mutex_);
        for (auto& payload : ready_payloads_) {
            if (payload.generation != cur_gen) continue;

            auto it = active_chunks_.find(payload.coord);
            if (it == active_chunks_.end()) continue;

            auto& chunk = it->second;
            chunk->payload = std::move(payload);

            if (!chunk->payload.has_geometry) {
                chunk->state = VdbChunk::ACTIVE;
                if (chunk->manual_obj) {
                    chunk->manual_obj->clear();
                }
                continue;
            }

            // Create or update Ogre ManualObject for this chunk
            std::string obj_name = "VdbChunkObj_" + std::to_string(chunk->coord.cx) + "_" +
                                   std::to_string(chunk->coord.cy) + "_" + std::to_string(chunk->coord.cz);
            std::string node_name = obj_name + "Node";

            if (!chunk->manual_obj) {
                if (scnMgr->hasManualObject(obj_name)) {
                    chunk->manual_obj = scnMgr->getManualObject(obj_name);
                } else {
                    chunk->manual_obj = scnMgr->createManualObject(obj_name);
                    chunk->manual_obj->setDynamic(false);
                }
            }

            if (!chunk->scene_node) {
                if (scnMgr->hasSceneNode(node_name)) {
                    chunk->scene_node = scnMgr->getSceneNode(node_name);
                } else {
                    chunk->scene_node = scnMgr->getRootSceneNode()->createChildSceneNode(node_name);
                    chunk->scene_node->attachObject(chunk->manual_obj);
                }
            }

            chunk->manual_obj->clear();
            chunk->manual_obj->begin("SCR/VolcanicIslandMaterial", Ogre::RenderOperation::OT_TRIANGLE_LIST);

            for (size_t i = 0; i < chunk->payload.positions.size(); ++i) {
                const auto& pos = chunk->payload.positions[i];
                const auto& norm = chunk->payload.normals[i];
                const auto& uv = chunk->payload.uvs[i];
                const auto& col = chunk->payload.colors[i];

                chunk->manual_obj->position(pos);
                chunk->manual_obj->normal(norm);
                chunk->manual_obj->textureCoord(uv);
                chunk->manual_obj->colour(col);
            }

            for (size_t i = 0; i < chunk->payload.indices.size(); i += 3) {
                chunk->manual_obj->triangle(
                    chunk->payload.indices[i],
                    chunk->payload.indices[i + 1],
                    chunk->payload.indices[i + 2]
                );
            }

            chunk->manual_obj->end();
            chunk->state = VdbChunk::ACTIVE;
        }
    }

    /**
     * Evicts out-of-range chunks to maintain bounded memory and GPU buffer usage.
     */
    void evictDistantChunks(const ChunkCoord& player_chunk, Ogre::SceneManager* scnMgr) {
        if (!scnMgr) return;
        std::lock_guard<std::mutex> lock(chunks_mutex_);
        to_evict_.clear();

        for (auto& pair : active_chunks_) {
            const auto& coord = pair.first;
            int dx = std::abs(coord.cx - player_chunk.cx);
            int dy = std::abs(coord.cy - player_chunk.cy);
            int dz = std::abs(coord.cz - player_chunk.cz);

            if (dx > EVICT_RADIUS_XZ || dy > EVICT_RADIUS_Y || dz > EVICT_RADIUS_XZ) {
                to_evict_.push_back(coord);
            }
        }

        for (const auto& c : to_evict_) {
            auto it = active_chunks_.find(c);
            if (it != active_chunks_.end()) {
                auto& chunk = it->second;
                if (chunk->manual_obj) {
                    try {
                        if (scnMgr->hasManualObject(chunk->manual_obj->getName())) {
                            scnMgr->destroyManualObject(chunk->manual_obj);
                        }
                    } catch (...) {}
                    chunk->manual_obj = nullptr;
                }
                if (chunk->scene_node) {
                    try {
                        if (scnMgr->hasSceneNode(chunk->scene_node->getName())) {
                            scnMgr->destroySceneNode(chunk->scene_node);
                        }
                    } catch (...) {}
                    chunk->scene_node = nullptr;
                }
                active_chunks_.erase(it);
            }
        }
    }

    // Threading & Chunk State
    std::atomic<uint64_t> current_generation_{0};
    mutable std::mutex chunks_mutex_;
    std::unordered_map<ChunkCoord, std::shared_ptr<VdbChunk>, ChunkCoordHash> active_chunks_;

    std::mutex queue_mutex_;
    std::condition_variable queue_cv_;
    std::queue<MeshingJob> job_queue_;

    std::mutex completed_mutex_;
    std::queue<ChunkMeshPayload> completed_queue_;

    std::vector<QueuedCandidate> candidates_;
    std::vector<ChunkMeshPayload> ready_payloads_;
    std::vector<ChunkCoord> to_evict_;

    std::vector<std::thread> workers_;
    std::atomic<bool> stop_workers_{false};
    float simulation_time_ = 0.0f;
};

} // namespace SCR::VDB

#endif // CAVE_VDB_CHUNK_MANAGER_HPP
