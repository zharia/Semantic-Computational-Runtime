#ifndef CAVE_SIM_IPC_CLIENT_HPP
#define CAVE_SIM_IPC_CLIENT_HPP

// Renderer-side IPC client.
// Connects to simulation AF_UNIX socket, receives snapshots, sends input.
// Header-only. No OGRE dependencies.

#include <cstdint>
#include <string>
#include <vector>
#include <mutex>
#include <iostream>

#include <nlohmann/json.hpp>

#include "simulation/sim_ipc_protocol.hpp"
#include "simulation/sim_ipc_transport.hpp"

namespace SCR::IPC {

// ---------------------------------------------------------------------------
// SimIpcClient
// ---------------------------------------------------------------------------

class SimIpcClient {
public:
    SimIpcClient() = default;
    ~SimIpcClient() { disconnect(); }

    // Non-copyable, movable
    SimIpcClient(const SimIpcClient&) = delete;
    SimIpcClient& operator=(const SimIpcClient&) = delete;

    SimIpcClient(SimIpcClient&& o) noexcept
        : transport_(std::move(o.transport_)),
          world_state_(std::move(o.world_state_)),
          generation_(o.generation_) {
        o.generation_ = 0;
    }

    SimIpcClient& operator=(SimIpcClient&& o) noexcept {
        if (this != &o) {
            disconnect();
            transport_ = std::move(o.transport_);
            world_state_ = std::move(o.world_state_);
            generation_ = o.generation_;
            o.generation_ = 0;
        }
        return *this;
    }

    // -- Lifecycle -------------------------------------------------------------

    bool connect(const std::string& socket_path) {
        if (transport_.isConnected()) disconnect();

        if (!transport_.connect(socket_path)) {
            std::cerr << "[SimIpcClient] connect(" << socket_path
                      << ") failed" << std::endl;
            return false;
        }

        generation_ = 0;
        std::cout << "[SimIpcClient] Connected to " << socket_path
                  << std::endl;
        return true;
    }

    void disconnect() {
        if (!transport_.isConnected()) return;

        // Send SHUTDOWN before disconnecting
        transport_.send(MessageType::SHUTDOWN, nullptr, 0);
        transport_.disconnect();
        generation_ = 0;

        std::cout << "[SimIpcClient] Disconnected." << std::endl;
    }

    // -- Receive ---------------------------------------------------------------

    /**
     * Non-blocking poll. Reads all available messages, updates local state.
     * Returns true if world_state_ changed.
     */
    bool poll() {
        if (!transport_.isConnected()) return false;

        bool changed = false;
        MessageHeader hdr{};
        std::vector<uint8_t> payload;

        // Drain all available messages (non-blocking via receiveTimed with 0ms)
        while (true) {
            ssize_t n = transport_.receiveTimed(hdr, payload, 0);
            if (n <= 0) break; // nothing left or error

            auto type = static_cast<MessageType>(hdr.type);

            switch (type) {
                case MessageType::SNAPSHOT_FULL: {
                    if (payload.empty()) break;
                    auto j = nlohmann::json::from_msgpack(payload);
                    std::lock_guard<std::mutex> lock(mutex_);
                    world_state_ = std::move(j);
                    generation_ = hdr.generation;
                    changed = true;
                    break;
                }
                case MessageType::SNAPSHOT_DELTA: {
                    if (payload.empty()) break;
                    auto j = nlohmann::json::from_msgpack(payload);
                    applyDelta(j);
                    generation_ = hdr.generation;
                    changed = true;
                    break;
                }
                case MessageType::PONG: {
                    // Response to our PING — acknowledged
                    break;
                }
                case MessageType::RESOURCE_CREATE: {
                    // Future: shared memory resource setup
                    break;
                }
                case MessageType::RESOURCE_RELEASE: {
                    // Future: shared memory teardown
                    break;
                }
                default:
                    break;
            }
        }

        return changed;
    }

    // -- Send ------------------------------------------------------------------

    void sendInput(const InputState& input) {
        // Serialize InputState fields to JSON, send as INPUT_STATE
        nlohmann::json j;
        j["move_forward"]   = input.move_forward;
        j["move_backward"]  = input.move_backward;
        j["move_left"]      = input.move_left;
        j["move_right"]     = input.move_right;
        j["move_up"]        = input.move_up;
        j["move_down"]      = input.move_down;
        j["sprint"]         = input.sprint;
        j["crouch"]         = input.crouch;
        j["jump"]           = input.jump;
        j["action_primary"]   = input.action_primary;
        j["action_secondary"] = input.action_secondary;
        j["show_hud"]         = input.show_hud;
        j["mouse_dx"]       = input.mouse_dx;
        j["mouse_dy"]       = input.mouse_dy;
        j["selected_hotbar_slot"] = input.selected_hotbar_slot;

        std::vector<uint8_t> payload = nlohmann::json::to_msgpack(j);
        transport_.send(MessageType::INPUT_STATE, payload.data(),
                        payload.size());
    }

    void sendCameraUpdate(float x, float y, float z,
                          float yaw, float pitch) {
        nlohmann::json j;
        j["x"]     = x;
        j["y"]     = y;
        j["z"]     = z;
        j["yaw"]   = yaw;
        j["pitch"] = pitch;

        std::vector<uint8_t> payload = nlohmann::json::to_msgpack(j);
        transport_.send(MessageType::CAMERA_UPDATE, payload.data(),
                        payload.size());
    }

    void sendPing() {
        transport_.send(MessageType::PING, nullptr, 0);
    }

    // -- Spatial subscriptions --------------------------------------------------

    void subscribe(uint32_t id, float aabb_min[3], float aabb_max[3],
                   uint32_t flags = 0x07) {
        SubscriptionRequest req;
        req.subscription_id = id;
        std::memcpy(req.aabb_min, aabb_min, sizeof(float) * 3);
        std::memcpy(req.aabb_max, aabb_max, sizeof(float) * 3);
        req.flags = flags;

        nlohmann::json j;
        to_json(j, req);
        std::vector<uint8_t> payload = nlohmann::json::to_msgpack(j);
        transport_.send(MessageType::SUBSCRIBE_REGION, payload.data(),
                        payload.size());
    }

    void unsubscribe(uint32_t id) {
        nlohmann::json j;
        j["subscription_id"] = id;
        std::vector<uint8_t> payload = nlohmann::json::to_msgpack(j);
        transport_.send(MessageType::UNSUBSCRIBE_REGION, payload.data(),
                        payload.size());
    }

    // -- Accessors -------------------------------------------------------------

    const nlohmann::json& getWorldState() const {
        std::lock_guard<std::mutex> lock(mutex_);
        return world_state_;
    }

    uint64_t getGeneration() const { return generation_; }

    bool isConnected() const { return transport_.isConnected(); }

private:
    // -- Delta application -----------------------------------------------------

    void applyDelta(const nlohmann::json& delta) {
        std::lock_guard<std::mutex> lock(mutex_);

        // Ensure world_state_ has the expected structure
        if (!world_state_.contains("entities")) {
            world_state_ = {{"header", {}}, {"entities", {}}};
        }

        auto& entities = world_state_["entities"];

        // Apply additions
        if (delta.contains("added")) {
            for (auto& [id, state] : delta["added"].items()) {
                entities[id] = state;
            }
        }

        // Apply removals
        if (delta.contains("removed")) {
            for (const auto& id : delta["removed"]) {
                entities.erase(id.get<std::string>());
            }
        }

        // Update header
        if (delta.contains("delta_generation")) {
            world_state_["header"]["generation"] =
                delta["delta_generation"];
        }
        if (delta.contains("tick_count")) {
            world_state_["header"]["tick_count"] =
                delta["tick_count"];
        }
        if (delta.contains("simulated_time")) {
            world_state_["header"]["simulated_time"] =
                delta["simulated_time"];
        }

        // Update entity count
        world_state_["header"]["entity_count"] = entities.size();
    }

    // -- State -----------------------------------------------------------------

    IpcTransport transport_;

    mutable std::mutex mutex_;
    nlohmann::json world_state_ = {{"header", {}}, {"entities", {}}};
    uint64_t generation_ = 0;
};

} // namespace SCR::IPC

#endif // CAVE_SIM_IPC_CLIENT_HPP
