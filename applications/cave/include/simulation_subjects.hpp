#ifndef CAVE_SIMULATION_SUBJECTS_HPP
#define CAVE_SIMULATION_SUBJECTS_HPP

#include <string>
#include <vector>
#include <memory>
#include <unordered_map>
#include <mutex>
#include <atomic>
#include <any>
#include <cmath>
#include <algorithm>

#include "simulation/spatial_semantics.hpp"
#include "simulation/island_biome_types.hpp"
#include "procedural_island.hpp"

namespace SCR::Simulation {

using SubjectId = uint64_t;

enum class SubjectType : uint32_t {
    UNKNOWN = 0,
    PLAYER,
    ISLAND,
    OCEAN,
    ATMOSPHERE,
    VOLCANO,
    ECOLOGY,
    WAYLAND_DISPLAY,
    CELESTIAL_BODY
};

inline const char* subjectTypeToString(SubjectType type) {
    switch (type) {
        case SubjectType::PLAYER: return "PLAYER";
        case SubjectType::ISLAND: return "ISLAND";
        case SubjectType::OCEAN: return "OCEAN";
        case SubjectType::ATMOSPHERE: return "ATMOSPHERE";
        case SubjectType::VOLCANO: return "VOLCANO";
        case SubjectType::ECOLOGY: return "ECOLOGY";
        case SubjectType::WAYLAND_DISPLAY: return "WAYLAND_DISPLAY";
        case SubjectType::CELESTIAL_BODY: return "CELESTIAL_BODY";
        default: return "UNKNOWN";
    }
}

/**
 * Abstract Base Interface for all Domain Subject Objects in the SCR runtime.
 * Provides strong identity, semantic categorization, spatial bounds, and dynamic properties.
 */
class ISubjectObject {
public:
    virtual ~ISubjectObject() = default;

    virtual SubjectId getSubjectId() const = 0;
    virtual SubjectType getSubjectType() const = 0;
    virtual std::string getSemanticName() const = 0;

    virtual Spatial::Point3D getPosition() const { return Spatial::Point3D(0, 0, 0); }
    virtual void setPosition(const Spatial::Point3D& pos) { (void)pos; }

    virtual bool isActive() const { return active_.load(std::memory_order_relaxed); }
    virtual void setActive(bool active) { active_.store(active, std::memory_order_relaxed); }

    // Dynamic property bag for extensibility
    void setProperty(const std::string& key, std::any value) {
        std::lock_guard<std::mutex> lock(prop_mutex_);
        properties_[key] = std::move(value);
    }

    template<typename T>
    T getProperty(const std::string& key, T default_value = T()) const {
        std::lock_guard<std::mutex> lock(prop_mutex_);
        auto it = properties_.find(key);
        if (it != properties_.end()) {
            try {
                return std::any_cast<T>(it->second);
            } catch (...) {
                return default_value;
            }
        }
        return default_value;
    }

    bool hasProperty(const std::string& key) const {
        std::lock_guard<std::mutex> lock(prop_mutex_);
        return properties_.find(key) != properties_.end();
    }

    template<typename Derived>
    Derived* as() {
        return dynamic_cast<Derived*>(this);
    }

    template<typename Derived>
    const Derived* as() const {
        return dynamic_cast<const Derived*>(this);
    }

private:
    std::atomic<bool> active_{true};
    mutable std::mutex prop_mutex_;
    std::unordered_map<std::string, std::any> properties_;
};

// ─── Concrete Subject: Player ────────────────────────────────────────────────
class PlayerSubject : public ISubjectObject {
public:
    SubjectId id = 1001;
    Spatial::Point3D position{48.0f, 15.0f, 20.0f};
    Spatial::Vector3D velocity{0.0f, 0.0f, 0.0f};
    float yaw = 0.0f;
    float pitch = 0.14f;
    float eye_height = 0.80f;
    float smooth_eye_y = 15.80f;
    bool on_ground = false;
    bool in_water = false;
    int jump_count = 0;
    int max_jumps = 2;
    float coyote_timer = 0.0f;
    float jump_buffer = 0.0f;
    int selected_hotbar_slot = 1;
    float health = 100.0f;
    float stamina = 100.0f;

    SubjectId getSubjectId() const override { return id; }
    SubjectType getSubjectType() const override { return SubjectType::PLAYER; }
    std::string getSemanticName() const override { return "PlayerAvatar"; }

    Spatial::Point3D getPosition() const override { return position; }
    void setPosition(const Spatial::Point3D& pos) override { position = pos; }
};

// ─── Concrete Subject: Island Geomorphology ───────────────────────────────────
class IslandSubject : public ISubjectObject {
public:
    SubjectId id = 2001;
    std::shared_ptr<Island::VoxelIsland> voxel_island;
    Island::IslandBiomeType active_biome = Island::IslandBiomeType::VOLCANO;
    uint32_t seed = 1337;
    float peak_height = 64.0f;
    float sea_level = 6.0f;
    float island_radius = 120.0f;

    SubjectId getSubjectId() const override { return id; }
    SubjectType getSubjectType() const override { return SubjectType::ISLAND; }
    std::string getSemanticName() const override {
        const auto& desc = Island::ArchipelagoRegistry::getDescriptor(active_biome);
        return desc.name;
    }

    Spatial::Point3D getPosition() const override {
        if (voxel_island) {
            return Spatial::Point3D(voxel_island->center_x, 0.0f, voxel_island->center_z);
        }
        return Spatial::Point3D(160.0f, 0.0f, 160.0f);
    }
};

// ─── Concrete Subject: Atmosphere & Celestial Dome ───────────────────────────
class AtmosphereSubject : public ISubjectObject {
public:
    SubjectId id = 3001;
    float time_of_day_hours = 12.0f;
    float time_flow_multiplier = 0.05f;
    float cloud_coverage = 0.55f;
    float cloud_density_multiplier = 1.0f;
    float wind_direction_radians = 0.45f;
    float wind_speed = 4.5f;
    float rain_intensity = 0.0f;
    float fog_density = 0.0015f;

    // Advanced Weather State
    std::string weather_condition = "Clear Tropical";
    float barometric_pressure_hpa = 1018.0f;
    float ambient_temperature_c = 28.5f;
    float relative_humidity = 0.65f;
    float precipitation_rate_mm_h = 0.0f;
    float aerosol_density = 0.05f;
    float volcanic_ash_fraction = 0.0f;
    float lightning_intensity = 0.0f;

    SubjectId getSubjectId() const override { return id; }
    SubjectType getSubjectType() const override { return SubjectType::ATMOSPHERE; }
    std::string getSemanticName() const override { return "AtmosphereCelestialDome"; }
};

// ─── Concrete Subject: Hydrology & Ocean ──────────────────────────────────────
class HydrologySubject : public ISubjectObject {
public:
    SubjectId id = 4001;
    float sea_level = 6.0f;
    float wave_height = 0.85f;
    float wave_frequency = 0.35f;
    float water_transparency = 0.72f;
    float foam_coverage = 0.28f;
    float ocean_current_x = 0.2f;
    float ocean_current_z = 0.1f;

    SubjectId getSubjectId() const override { return id; }
    SubjectType getSubjectType() const override { return SubjectType::OCEAN; }
    std::string getSemanticName() const override { return "SeaOfThievesHydrology"; }
};

// ─── Concrete Subject: Volcano & Geothermal Magma ─────────────────────────────
class VolcanoSubject : public ISubjectObject {
public:
    SubjectId id = 5001;
    bool is_active = true;
    float lava_viscosity = 120.0f; // Bingham plastic yield stress
    float caldera_temperature_kelvin = 1473.15f; // ~1200°C
    float plume_emission_rate = 1.0f;
    float magma_river_velocity = 2.4f;
    Spatial::Point3D summit_vent_pos{160.0f, 58.0f, 160.0f};

    SubjectId getSubjectId() const override { return id; }
    SubjectType getSubjectType() const override { return SubjectType::VOLCANO; }
    std::string getSemanticName() const override { return "StratovolcanoMagmaSystem"; }

    Spatial::Point3D getPosition() const override { return summit_vent_pos; }
};

// ─── Concrete Subject: Ecology (Fauna & Flora) ────────────────────────────────
class EcologySubject : public ISubjectObject {
public:
    SubjectId id = 6001;
    size_t palm_count = 0;
    size_t tree_count = 0;
    size_t bush_count = 0;
    size_t total_vegetation_instances = 0;
    size_t boid_count = 0;
    size_t firefly_count = 6;
    float ecosystem_health = 1.0f;

    SubjectId getSubjectId() const override { return id; }
    SubjectType getSubjectType() const override { return SubjectType::ECOLOGY; }
    std::string getSemanticName() const override { return "IslandEcosystem"; }
};

// ─── Concrete Subject: Wayland Display & Terminal ─────────────────────────────
class WaylandDisplaySubject : public ISubjectObject {
public:
    SubjectId id = 7001;
    bool is_focused = false;
    bool is_compositor_running = false;
    float cursor_u = 0.5f;
    float cursor_v = 0.5f;
    int client_count = 0;
    std::string active_app_title = "None";

    SubjectId getSubjectId() const override { return id; }
    SubjectType getSubjectType() const override { return SubjectType::WAYLAND_DISPLAY; }
    std::string getSemanticName() const override { return "InWorldWaylandDisplay"; }
};

// ─── Subject Object Registry ──────────────────────────────────────────────────
class SubjectRegistry {
public:
    static SubjectRegistry& instance() {
        static SubjectRegistry inst;
        return inst;
    }

    void registerSubject(std::shared_ptr<ISubjectObject> subject) {
        if (!subject) return;
        std::lock_guard<std::mutex> lock(mutex_);
        subjects_[subject->getSubjectId()] = subject;
        by_type_[subject->getSubjectType()].push_back(subject);
    }

    void unregisterSubject(SubjectId id) {
        std::lock_guard<std::mutex> lock(mutex_);
        auto it = subjects_.find(id);
        if (it != subjects_.end()) {
            auto type = it->second->getSubjectType();
            subjects_.erase(it);
            auto& list = by_type_[type];
            list.erase(
                std::remove_if(list.begin(), list.end(), [id](const auto& s) { return s->getSubjectId() == id; }),
                list.end()
            );
        }
    }

    std::shared_ptr<ISubjectObject> getSubject(SubjectId id) const {
        std::lock_guard<std::mutex> lock(mutex_);
        auto it = subjects_.find(id);
        return it != subjects_.end() ? it->second : nullptr;
    }

    template<typename T>
    std::shared_ptr<T> getSubjectAs(SubjectId id) const {
        auto s = getSubject(id);
        return std::dynamic_pointer_cast<T>(s);
    }

    std::vector<std::shared_ptr<ISubjectObject>> getSubjectsByType(SubjectType type) const {
        std::lock_guard<std::mutex> lock(mutex_);
        auto it = by_type_.find(type);
        return it != by_type_.end() ? it->second : std::vector<std::shared_ptr<ISubjectObject>>{};
    }

    template<typename T>
    std::shared_ptr<T> getFirstSubjectOfType(SubjectType type) const {
        auto list = getSubjectsByType(type);
        if (!list.empty()) {
            return std::dynamic_pointer_cast<T>(list[0]);
        }
        return nullptr;
    }

    void clear() {
        std::lock_guard<std::mutex> lock(mutex_);
        subjects_.clear();
        by_type_.clear();
    }

private:
    mutable std::mutex mutex_;
    std::unordered_map<SubjectId, std::shared_ptr<ISubjectObject>> subjects_;
    std::unordered_map<SubjectType, std::vector<std::shared_ptr<ISubjectObject>>> by_type_;
};

} // namespace SCR::Simulation

#endif // CAVE_SIMULATION_SUBJECTS_HPP
