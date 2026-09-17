#ifndef CAVE_SIMULATION_EVENTS_HPP
#define CAVE_SIMULATION_EVENTS_HPP

#include <string>
#include <vector>
#include <memory>
#include <functional>
#include <chrono>
#include <mutex>
#include <queue>
#include <unordered_map>
#include <typeindex>
#include <iostream>

#include "spatial_semantics.hpp"
#include "island_biome_types.hpp"
#include "simulation_subjects.hpp"

namespace SCR::Simulation {

enum class EventType : uint32_t {
    CUSTOM = 0,
    ISLAND_VOYAGE,
    TIME_OF_DAY_CHANGED,
    WEATHER_CONDITION_CHANGED,
    VOLCANIC_ERUPTION,
    PLAYER_MOVED,
    PLAYER_JUMPED,
    VOXEL_TERRAIN_MODIFIED,
    WAYLAND_SURFACE_UPDATED,
    HOTBAR_SELECTION_CHANGED
};

/**
 * Abstract Base Simulation Event.
 * Holds precise high-resolution timestamp, cancellation state, and references to source/target subject objects.
 */
class ISimulationEvent {
public:
    virtual ~ISimulationEvent() = default;

    virtual EventType getEventType() const = 0;
    virtual std::string getEventName() const = 0;

    std::chrono::high_resolution_clock::time_point getTimestamp() const { return timestamp_; }

    std::shared_ptr<ISubjectObject> getSourceSubject() const { return source_subject_; }
    void setSourceSubject(std::shared_ptr<ISubjectObject> src) { source_subject_ = src; }

    std::shared_ptr<ISubjectObject> getTargetSubject() const { return target_subject_; }
    void setTargetSubject(std::shared_ptr<ISubjectObject> tgt) { target_subject_ = tgt; }

    bool isCancelled() const { return cancelled_; }
    void setCancelled(bool cancel = true) { cancelled_ = cancel; }

private:
    std::chrono::high_resolution_clock::time_point timestamp_{std::chrono::high_resolution_clock::now()};
    std::shared_ptr<ISubjectObject> source_subject_;
    std::shared_ptr<ISubjectObject> target_subject_;
    bool cancelled_ = false;
};

// ─── Concrete Domain Events ──────────────────────────────────────────────────

/**
 * Fired when navigating or teleporting to an island biome.
 */
class IslandVoyageEvent : public ISimulationEvent {
public:
    Island::IslandBiomeType previous_biome;
    Island::IslandBiomeType new_biome;
    uint32_t world_seed = 1337;
    Spatial::Point3D target_spawn_pos;

    IslandVoyageEvent(Island::IslandBiomeType prev, Island::IslandBiomeType next, uint32_t seed, const Spatial::Point3D& spawn)
        : previous_biome(prev), new_biome(next), world_seed(seed), target_spawn_pos(spawn) {}

    EventType getEventType() const override { return EventType::ISLAND_VOYAGE; }
    std::string getEventName() const override { return "IslandVoyageEvent"; }
};

/**
 * Fired when simulation celestial time of day advances.
 */
class TimeOfDayChangedEvent : public ISimulationEvent {
public:
    float old_time_hours;
    float new_time_hours;
    float sun_altitude_rad;
    float sun_azimuth_rad;

    TimeOfDayChangedEvent(float old_t, float new_t, float alt = 0.0f, float az = 0.0f)
        : old_time_hours(old_t), new_time_hours(new_t), sun_altitude_rad(alt), sun_azimuth_rad(az) {}

    EventType getEventType() const override { return EventType::TIME_OF_DAY_CHANGED; }
    std::string getEventName() const override { return "TimeOfDayChangedEvent"; }
};

/**
 * Fired when atmospheric weather conditions shift.
 */
class WeatherConditionChangedEvent : public ISimulationEvent {
public:
    float cloud_coverage;
    float rain_intensity;
    float fog_density;

    WeatherConditionChangedEvent(float clouds, float rain, float fog)
        : cloud_coverage(clouds), rain_intensity(rain), fog_density(fog) {}

    EventType getEventType() const override { return EventType::WEATHER_CONDITION_CHANGED; }
    std::string getEventName() const override { return "WeatherConditionChangedEvent"; }
};

/**
 * Fired on geothermal or volcanic activity spikes.
 */
class VolcanicEruptionEvent : public ISimulationEvent {
public:
    float eruption_magnitude;
    float lava_effusion_rate;
    Spatial::Point3D vent_origin;

    VolcanicEruptionEvent(float magnitude, float effusion, const Spatial::Point3D& vent)
        : eruption_magnitude(magnitude), lava_effusion_rate(effusion), vent_origin(vent) {}

    EventType getEventType() const override { return EventType::VOLCANIC_ERUPTION; }
    std::string getEventName() const override { return "VolcanicEruptionEvent"; }
};

/**
 * Fired when player kinematics update (position/velocity).
 */
class PlayerMovedEvent : public ISimulationEvent {
public:
    Spatial::Point3D old_position;
    Spatial::Point3D new_position;
    Spatial::Vector3D velocity;
    bool on_ground;

    PlayerMovedEvent(const Spatial::Point3D& old_pos, const Spatial::Point3D& new_pos, const Spatial::Vector3D& vel, bool ground)
        : old_position(old_pos), new_position(new_pos), velocity(vel), on_ground(ground) {}

    EventType getEventType() const override { return EventType::PLAYER_MOVED; }
    std::string getEventName() const override { return "PlayerMovedEvent"; }
};

/**
 * Fired when player performs a ground jump or mid-air double jump.
 */
class PlayerJumpedEvent : public ISimulationEvent {
public:
    int jump_index; // 1 = initial jump, 2 = mid-air double jump
    Spatial::Point3D jump_location;

    PlayerJumpedEvent(int idx, const Spatial::Point3D& loc)
        : jump_index(idx), jump_location(loc) {}

    EventType getEventType() const override { return EventType::PLAYER_JUMPED; }
    std::string getEventName() const override { return "PlayerJumpedEvent"; }
};

/**
 * Fired when voxel volume is sculpted or excavated.
 */
class VoxelTerrainModifiedEvent : public ISimulationEvent {
public:
    int voxel_x, voxel_y, voxel_z;
    uint16_t old_material;
    uint16_t new_material;
    float radius;

    VoxelTerrainModifiedEvent(int x, int y, int z, uint16_t old_mat, uint16_t new_mat, float r = 1.0f)
        : voxel_x(x), voxel_y(y), voxel_z(z), old_material(old_mat), new_material(new_mat), radius(r) {}

    EventType getEventType() const override { return EventType::VOXEL_TERRAIN_MODIFIED; }
    std::string getEventName() const override { return "VoxelTerrainModifiedEvent"; }
};

/**
 * Fired when Wayland Compositor renders a new client buffer frame.
 */
class WaylandSurfaceUpdatedEvent : public ISimulationEvent {
public:
    int client_pid;
    int surface_width;
    int surface_height;
    std::string title;

    WaylandSurfaceUpdatedEvent(int pid, int w, int h, const std::string& t)
        : client_pid(pid), surface_width(w), surface_height(h), title(t) {}

    EventType getEventType() const override { return EventType::WAYLAND_SURFACE_UPDATED; }
    std::string getEventName() const override { return "WaylandSurfaceUpdatedEvent"; }
};

/**
 * Fired when hotbar slot changes.
 */
class HotbarSelectionChangedEvent : public ISimulationEvent {
public:
    int previous_slot;
    int new_slot;

    HotbarSelectionChangedEvent(int prev, int next)
        : previous_slot(prev), new_slot(next) {}

    EventType getEventType() const override { return EventType::HOTBAR_SELECTION_CHANGED; }
    std::string getEventName() const override { return "HotbarSelectionChangedEvent"; }
};

template<typename T>
struct EventTypeTrait;

#define DECLARE_EVENT_TYPE(Class, EnumVal) \
    template<> struct EventTypeTrait<Class> { static constexpr EventType value = EnumVal; };

DECLARE_EVENT_TYPE(IslandVoyageEvent, EventType::ISLAND_VOYAGE)
DECLARE_EVENT_TYPE(TimeOfDayChangedEvent, EventType::TIME_OF_DAY_CHANGED)
DECLARE_EVENT_TYPE(WeatherConditionChangedEvent, EventType::WEATHER_CONDITION_CHANGED)
DECLARE_EVENT_TYPE(VolcanicEruptionEvent, EventType::VOLCANIC_ERUPTION)
DECLARE_EVENT_TYPE(PlayerMovedEvent, EventType::PLAYER_MOVED)
DECLARE_EVENT_TYPE(PlayerJumpedEvent, EventType::PLAYER_JUMPED)
DECLARE_EVENT_TYPE(VoxelTerrainModifiedEvent, EventType::VOXEL_TERRAIN_MODIFIED)
DECLARE_EVENT_TYPE(WaylandSurfaceUpdatedEvent, EventType::WAYLAND_SURFACE_UPDATED)
DECLARE_EVENT_TYPE(HotbarSelectionChangedEvent, EventType::HOTBAR_SELECTION_CHANGED)

// ─── Thread-Safe Simulation Event Bus ─────────────────────────────────────────

using EventHandler = std::function<void(const ISimulationEvent&)>;

class EventBus {
public:
    static EventBus& instance() {
        static EventBus inst;
        return inst;
    }

    /**
     * Subscribes a listener callback to events of a specific event type.
     * Optional subject_filter restricts notifications to events matching a source SubjectId.
     */
    void subscribe(EventType type, EventHandler handler, SubjectId subject_filter = 0) {
        std::lock_guard<std::mutex> lock(sub_mutex_);
        subscriptions_[type].push_back({handler, subject_filter});
    }

    template<typename EventClass>
    void subscribe(std::function<void(const EventClass&)> handler, SubjectId subject_filter = 0) {
        subscribe(EventTypeTrait<EventClass>::value,
            [handler](const ISimulationEvent& evt) {
                if (auto typed = dynamic_cast<const EventClass*>(&evt)) {
                    handler(*typed);
                }
            },
            subject_filter
        );
    }

    /**
     * Synchronously dispatches an event immediately on the caller thread.
     */
    void publishSync(const ISimulationEvent& event) {
        std::vector<Subscription> targets;
        {
            std::lock_guard<std::mutex> lock(sub_mutex_);
            auto it = subscriptions_.find(event.getEventType());
            if (it != subscriptions_.end()) {
                targets = it->second;
            }
        }

        for (const auto& sub : targets) {
            if (event.isCancelled()) break;
            if (sub.subject_filter != 0) {
                auto src = event.getSourceSubject();
                if (!src || src->getSubjectId() != sub.subject_filter) continue;
            }
            try {
                sub.handler(event);
            } catch (const std::exception& e) {
                std::cerr << "[EventBus Error] Exception in handler for " << event.getEventName() << ": " << e.what() << std::endl;
            }
        }
    }

    /**
     * Asynchronously enqueues an event for deferred dispatch during the coordinator drain stage.
     */
    void publishAsync(std::shared_ptr<ISimulationEvent> event) {
        if (!event) return;
        std::lock_guard<std::mutex> lock(queue_mutex_);
        async_queue_.push(event);
    }

    /**
     * Drains and synchronously dispatches all queued asynchronous events.
     */
    void drainQueuedEvents() {
        std::vector<std::shared_ptr<ISimulationEvent>> to_dispatch;
        {
            std::lock_guard<std::mutex> lock(queue_mutex_);
            while (!async_queue_.empty()) {
                to_dispatch.push_back(async_queue_.front());
                async_queue_.pop();
            }
        }

        for (const auto& evt : to_dispatch) {
            if (evt) publishSync(*evt);
        }
    }

    void clear() {
        std::lock_guard<std::mutex> lock_sub(sub_mutex_);
        subscriptions_.clear();
        std::lock_guard<std::mutex> lock_q(queue_mutex_);
        while (!async_queue_.empty()) async_queue_.pop();
    }

private:
    struct Subscription {
        EventHandler handler;
        SubjectId subject_filter = 0;
    };

    mutable std::mutex sub_mutex_;
    std::unordered_map<EventType, std::vector<Subscription>> subscriptions_;

    mutable std::mutex queue_mutex_;
    std::queue<std::shared_ptr<ISimulationEvent>> async_queue_;
};

} // namespace SCR::Simulation

#endif // CAVE_SIMULATION_EVENTS_HPP
