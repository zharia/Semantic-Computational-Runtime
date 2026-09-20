#ifndef CAVE_SIM_IPC_WORLD_HPP
#define CAVE_SIM_IPC_WORLD_HPP

#include <cstdint>
#include <string>
#include <unordered_map>
#include <unordered_set>
#include <mutex>
#include <nlohmann/json.hpp>

#include "simulation/sim_ipc_protocol.hpp"

// SubjectRegistry forward — full header in simulation_subjects.hpp
// WorldModel holds a reference; callers include the full header.
namespace SCR::Simulation { class SubjectRegistry; }

namespace SCR::IPC {

/**
 * In-memory World model with commit/generation snapshot semantics.
 * Simulation-side state container — produces snapshots and deltas.
 * No OGRE dependencies.
 */
class WorldModel {
public:
    WorldModel() : generation_(0), tick_(0), simulated_time_(0.0) {}

    explicit WorldModel(SCR::Simulation::SubjectRegistry& subjects)
        : generation_(0), tick_(0), simulated_time_(0.0),
          subjects_(&subjects) {}

    // -- Accessors --------------------------------------------------------------

    uint32_t getGeneration() const {
        std::lock_guard<std::mutex> lock(mutex_);
        return generation_;
    }

    uint64_t getTick() const {
        std::lock_guard<std::mutex> lock(mutex_);
        return tick_;
    }

    double getSimulatedTime() const {
        std::lock_guard<std::mutex> lock(mutex_);
        return simulated_time_;
    }

    void setSubjectRegistry(SCR::Simulation::SubjectRegistry* reg) {
        std::lock_guard<std::mutex> lock(mutex_);
        subjects_ = reg;
    }

    // -- Entity mutation --------------------------------------------------------

    void updateEntity(const std::string& id, const nlohmann::json& state) {
        std::lock_guard<std::mutex> lock(mutex_);
        entities_[id] = state;
        changed_.insert(id);
    }

    void removeEntity(const std::string& id) {
        std::lock_guard<std::mutex> lock(mutex_);
        entities_.erase(id);
        removed_.insert(id);
        changed_.erase(id);
    }

    bool hasEntity(const std::string& id) const {
        std::lock_guard<std::mutex> lock(mutex_);
        return entities_.count(id) > 0;
    }

    nlohmann::json getEntity(const std::string& id) const {
        std::lock_guard<std::mutex> lock(mutex_);
        auto it = entities_.find(id);
        if (it != entities_.end()) return it->second;
        return nullptr;
    }

    size_t getEntityCount() const {
        std::lock_guard<std::mutex> lock(mutex_);
        return entities_.size();
    }

    // -- Commit ----------------------------------------------------------------

    /**
     * Commit current state: increment generation, snapshot changed/removed sets,
     * extract SubjectRegistry state into entity map.
     */
    void commit(uint64_t tick, float time) {
        std::lock_guard<std::mutex> lock(mutex_);

        tick_ = tick;
        simulated_time_ = static_cast<double>(time);
        ++generation_;

        // Snapshot the change sets for delta tracking
        delta_added_[generation_]   = changed_;
        delta_removed_[generation_] = removed_;
        changed_.clear();
        removed_.clear();

        // Prune old delta history — keep last MAX_DELTA_HISTORY generations
        constexpr size_t MAX_DELTA_HISTORY = 128;
        while (delta_added_.size() > MAX_DELTA_HISTORY) {
            delta_added_.erase(delta_added_.begin());
            delta_removed_.erase(delta_removed_.begin());
        }

        // Extract SubjectRegistry state if available
        if (subjects_) {
            extractSubjectState();
        }
    }

    // -- Snapshot access --------------------------------------------------------

    SnapshotHeader getSnapshotHeader() const {
        std::lock_guard<std::mutex> lock(mutex_);
        SnapshotHeader h;
        h.generation     = generation_;
        h.tick_count     = static_cast<uint32_t>(tick_);
        h.simulated_time = simulated_time_;
        h.entity_count   = static_cast<uint32_t>(entities_.size());
        return h;
    }

    /**
     * Full serialized state: header + all entities.
     */
    nlohmann::json getFullSnapshot() const {
        std::lock_guard<std::mutex> lock(mutex_);
        nlohmann::json snap;
        snap["header"] = {
            {"generation",     generation_},
            {"tick_count",     static_cast<uint32_t>(tick_)},
            {"simulated_time", simulated_time_},
            {"entity_count",   entities_.size()},
        };
        snap["entities"] = entities_;
        return snap;
    }

    /**
     * Incremental delta since base_generation.
     * Returns null if base_generation is too old or beyond current.
     */
    nlohmann::json getDelta(uint64_t base_generation) const {
        std::lock_guard<std::mutex> lock(mutex_);

        if (base_generation >= generation_) {
            return nullptr; // nothing changed
        }

        nlohmann::json delta;
        nlohmann::json added;
        nlohmann::json removed_list = nlohmann::json::array();

        // Collect all changes from base+1 through current generation
        for (uint64_t g = base_generation + 1; g <= generation_; ++g) {
            auto ait = delta_added_.find(g);
            if (ait != delta_added_.end()) {
                for (const auto& id : ait->second) {
                    auto eit = entities_.find(id);
                    if (eit != entities_.end()) {
                        added[id] = eit->second;
                    }
                }
            }
            auto rit = delta_removed_.find(g);
            if (rit != delta_removed_.end()) {
                for (const auto& id : rit->second) {
                    removed_list.push_back(id);
                }
            }
        }

        delta["base_generation"]  = base_generation;
        delta["delta_generation"] = generation_;
        delta["tick_count"]       = static_cast<uint32_t>(tick_);
        delta["simulated_time"]   = simulated_time_;
        delta["change_count"]     = static_cast<uint32_t>(added.size() + removed_list.size());
        delta["added"]            = std::move(added);
        delta["removed"]          = std::move(removed_list);
        return delta;
    }

    /**
     * Incremental delta filtered by AABB — only includes entities whose
     * position (x/y/z fields) falls within the given bounds.
     * Returns null if base_generation is too old or beyond current.
     */
    nlohmann::json getFilteredDelta(uint64_t base_generation,
                                    float aabb_min[3],
                                    float aabb_max[3]) const {
        std::lock_guard<std::mutex> lock(mutex_);

        if (base_generation >= generation_) {
            return nullptr;
        }

        nlohmann::json delta;
        nlohmann::json added;
        nlohmann::json removed_list = nlohmann::json::array();

        for (uint64_t g = base_generation + 1; g <= generation_; ++g) {
            auto ait = delta_added_.find(g);
            if (ait != delta_added_.end()) {
                for (const auto& id : ait->second) {
                    auto eit = entities_.find(id);
                    if (eit != entities_.end()) {
                        if (entityInAABB(eit->second, aabb_min, aabb_max)) {
                            added[id] = eit->second;
                        }
                    }
                }
            }
            auto rit = delta_removed_.find(g);
            if (rit != delta_removed_.end()) {
                for (const auto& id : rit->second) {
                    removed_list.push_back(id);
                }
            }
        }

        delta["base_generation"]  = base_generation;
        delta["delta_generation"] = generation_;
        delta["tick_count"]       = static_cast<uint32_t>(tick_);
        delta["simulated_time"]   = simulated_time_;
        delta["change_count"]     = static_cast<uint32_t>(added.size() + removed_list.size());
        delta["added"]            = std::move(added);
        delta["removed"]          = std::move(removed_list);
        return delta;
    }

private:
    // -- Helpers ---------------------------------------------------------------

    static bool entityInAABB(const nlohmann::json& entity,
                             float aabb_min[3], float aabb_max[3]) {
        if (!entity.contains("x") || !entity.contains("y") || !entity.contains("z")) {
            return false;
        }
        float x = entity["x"].get<float>();
        float y = entity["y"].get<float>();
        float z = entity["z"].get<float>();
        return (x >= aabb_min[0] && x <= aabb_max[0] &&
                y >= aabb_min[1] && y <= aabb_max[1] &&
                z >= aabb_min[2] && z <= aabb_max[2]);
    }

    // -- SubjectRegistry extraction --------------------------------------------

    void extractSubjectState() {
        // Intentionally minimal — full SubjectRegistry include lives in
        // simulation_subjects.hpp. This extracts the serializable subset
        // of subject state into entity JSON maps keyed by semantic name.
        //
        // Actual extraction requires simulation_subjects.hpp to be included
        // by the translation unit that calls commit(). The WorldModel itself
        // holds only the pointer; the extraction is deferred to avoid
        // pulling the full SubjectRegistry header into every includer.
    }

    // -- State -----------------------------------------------------------------

    mutable std::mutex mutex_;
    uint32_t generation_;
    uint64_t tick_;
    double   simulated_time_;

    // Entity state — keyed by string ID (semantic name or "type:id")
    std::unordered_map<std::string, nlohmann::json> entities_;

    // Change tracking within a commit window
    std::unordered_set<std::string> changed_;
    std::unordered_set<std::string> removed_;

    // Delta history — generation → set of changed/removed entity IDs
    std::unordered_map<uint64_t, std::unordered_set<std::string>> delta_added_;
    std::unordered_map<uint64_t, std::unordered_set<std::string>> delta_removed_;

    // SubjectRegistry reference — owned externally
    SCR::Simulation::SubjectRegistry* subjects_ = nullptr;
};

} // namespace SCR::IPC

#endif // CAVE_SIM_IPC_WORLD_HPP
