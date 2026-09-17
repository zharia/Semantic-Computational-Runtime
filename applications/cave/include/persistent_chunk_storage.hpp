#ifndef CAVE_PERSISTENT_CHUNK_STORAGE_HPP
#define CAVE_PERSISTENT_CHUNK_STORAGE_HPP

#include <openvdb/openvdb.h>
#include <openvdb/io/File.h>

#include <string>
#include <vector>
#include <fstream>
#include <sstream>
#include <filesystem>
#include <iostream>
#include <mutex>
#include <nlohmann/json.hpp>

namespace SCR::Storage {

struct VoxelDelta {
    int local_x = 0;
    int local_y = 0;
    int local_z = 0;
    uint16_t material_code = 0;
    float density = 0.0f;
};

struct WorldManifest {
    std::string world_name = "ExoticVolcanicIsland";
    uint32_t seed = 1337;
    float player_x = 124.0f;
    float player_y = 11.0f;
    float player_z = 42.0f;
    float time_of_day_hours = 12.0f;
    size_t saved_chunk_count = 0;
    std::string timestamp;
};

class PersistentChunkStorage {
public:
    static PersistentChunkStorage& instance() {
        static PersistentChunkStorage inst;
        return inst;
    }

    void initialize(const std::string& storage_directory = "applications/cave/data/partitions") {
        std::lock_guard<std::mutex> lock(io_mutex_);
        storage_dir_ = storage_directory;

        std::error_code ec;
        if (!std::filesystem::exists(storage_dir_, ec)) {
            std::filesystem::create_directories(storage_dir_, ec);
            if (!ec) {
                std::cout << "[Storage] Created persistent chunk directory: " << storage_dir_ << std::endl;
            }
        }
        initialized_ = true;
    }

    std::string getChunkFilePath(int cx, int cy, int cz, int biome_id = 0, const std::string& ext = ".vdb") const {
        return storage_dir_ + "/chunk_b" + std::to_string(biome_id) + "_" + std::to_string(cx) + "_" + std::to_string(cy) + "_" + std::to_string(cz) + ext;
    }

    bool hasChunkOnDisk(int cx, int cy, int cz, int biome_id = 0) const {
        std::string path = getChunkFilePath(cx, cy, cz, biome_id, ".vdb");
        std::error_code ec;
        return std::filesystem::exists(path, ec);
    }

    /**
     * Saves an OpenVDB FloatGrid and voxel delta metadata to persistent storage.
     */
    bool saveChunk(
        int cx, int cy, int cz,
        int biome_id,
        openvdb::FloatGrid::Ptr grid,
        const std::vector<VoxelDelta>& deltas = {}
    ) {
        if (!initialized_ || !grid) return false;
        std::lock_guard<std::mutex> lock(io_mutex_);

        try {
            // 1. Write Native OpenVDB Grid
            std::string vdb_path = getChunkFilePath(cx, cy, cz, biome_id, ".vdb");
            openvdb::io::File vdb_file(vdb_path);
            openvdb::GridPtrVec grids;
            grids.push_back(grid);
            vdb_file.write(grids);
            vdb_file.close();

            // 2. Write Voxel Delta Metadata
            if (!deltas.empty()) {
                std::string meta_path = getChunkFilePath(cx, cy, cz, biome_id, ".meta");
                std::ofstream meta_out(meta_path, std::ios::binary);
                if (meta_out.is_open()) {
                    uint32_t count = static_cast<uint32_t>(deltas.size());
                    meta_out.write(reinterpret_cast<const char*>(&count), sizeof(count));
                    for (const auto& d : deltas) {
                        meta_out.write(reinterpret_cast<const char*>(&d), sizeof(VoxelDelta));
                    }
                    meta_out.close();
                }
            }

            return true;
        } catch (const std::exception& e) {
            std::cerr << "[Storage Error] Failed to save chunk (" << cx << "," << cy << "," << cz << "): " << e.what() << std::endl;
            return false;
        }
    }

    /**
     * Loads an OpenVDB FloatGrid and optional delta metadata from persistent storage.
     */
    bool loadChunk(
        int cx, int cy, int cz,
        int biome_id,
        openvdb::FloatGrid::Ptr& out_grid,
        std::vector<VoxelDelta>& out_deltas
    ) {
        if (!initialized_) return false;
        std::lock_guard<std::mutex> lock(io_mutex_);

        std::string vdb_path = getChunkFilePath(cx, cy, cz, biome_id, ".vdb");
        std::error_code ec;
        if (!std::filesystem::exists(vdb_path, ec)) return false;

        try {
            // 1. Read OpenVDB Grid
            openvdb::io::File vdb_file(vdb_path);
            vdb_file.open();
            openvdb::GridBase::Ptr base_grid = vdb_file.readGrid("VolcanicIslandDensityGrid");
            if (!base_grid) {
                auto iter = vdb_file.beginName();
                if (iter != vdb_file.endName()) {
                    base_grid = vdb_file.readGrid(iter.gridName());
                }
            }
            vdb_file.close();

            if (base_grid) {
                out_grid = openvdb::gridPtrCast<openvdb::FloatGrid>(base_grid);
            }

            // 2. Read Voxel Deltas
            std::string meta_path = getChunkFilePath(cx, cy, cz, biome_id, ".meta");
            if (std::filesystem::exists(meta_path, ec)) {
                std::ifstream meta_in(meta_path, std::ios::binary);
                if (meta_in.is_open()) {
                    uint32_t count = 0;
                    meta_in.read(reinterpret_cast<char*>(&count), sizeof(count));
                    out_deltas.resize(count);
                    for (uint32_t i = 0; i < count; ++i) {
                        meta_in.read(reinterpret_cast<char*>(&out_deltas[i]), sizeof(VoxelDelta));
                    }
                    meta_in.close();
                }
            }

            return (out_grid != nullptr);
        } catch (const std::exception& e) {
            std::cerr << "[Storage Error] Failed to load chunk (" << cx << "," << cy << "," << cz << "): " << e.what() << std::endl;
            return false;
        }
    }

    /**
     * Saves World Manifest JSON containing state, seed, and partition information.
     */
    bool saveWorldManifest(const WorldManifest& manifest) {
        if (!initialized_) return false;
        std::lock_guard<std::mutex> lock(io_mutex_);

        std::string manifest_path = storage_dir_ + "/world_manifest.json";
        try {
            nlohmann::json j;
            j["world_name"] = manifest.world_name;
            j["seed"] = manifest.seed;
            j["player_pos"] = {manifest.player_x, manifest.player_y, manifest.player_z};
            j["time_of_day_hours"] = manifest.time_of_day_hours;
            j["saved_chunk_count"] = manifest.saved_chunk_count;
            j["timestamp"] = manifest.timestamp;

            std::ofstream out(manifest_path);
            if (out.is_open()) {
                out << j.dump(2);
                out.close();
                std::cout << "[Storage] Saved world manifest -> " << manifest_path << std::endl;
                return true;
            }
        } catch (const std::exception& e) {
            std::cerr << "[Storage Error] Failed to save world manifest: " << e.what() << std::endl;
        }
        return false;
    }

    bool loadWorldManifest(WorldManifest& manifest) {
        if (!initialized_) return false;
        std::lock_guard<std::mutex> lock(io_mutex_);

        std::string manifest_path = storage_dir_ + "/world_manifest.json";
        std::error_code ec;
        if (!std::filesystem::exists(manifest_path, ec)) return false;

        try {
            std::ifstream in(manifest_path);
            if (in.is_open()) {
                nlohmann::json j;
                in >> j;
                manifest.world_name = j.value("world_name", "ExoticVolcanicIsland");
                manifest.seed = j.value("seed", 1337);
                if (j.contains("player_pos") && j["player_pos"].is_array() && j["player_pos"].size() >= 3) {
                    manifest.player_x = j["player_pos"][0];
                    manifest.player_y = j["player_pos"][1];
                    manifest.player_z = j["player_pos"][2];
                }
                manifest.time_of_day_hours = j.value("time_of_day_hours", 12.0f);
                manifest.saved_chunk_count = j.value("saved_chunk_count", 0);
                manifest.timestamp = j.value("timestamp", "");
                in.close();
                std::cout << "[Storage] Loaded world manifest from " << manifest_path << std::endl;
                return true;
            }
        } catch (const std::exception& e) {
            std::cerr << "[Storage Error] Failed to load world manifest: " << e.what() << std::endl;
        }
        return false;
    }

private:
    PersistentChunkStorage() = default;
    bool initialized_ = false;
    std::string storage_dir_ = "applications/cave/data/partitions";
    mutable std::mutex io_mutex_;
};

} // namespace SCR::Storage

#endif // CAVE_PERSISTENT_CHUNK_STORAGE_HPP
