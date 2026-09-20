#ifndef CAVE_SIM_IPC_PROTOCOL_HPP
#define CAVE_SIM_IPC_PROTOCOL_HPP

#include <cstdint>
#include <cstring>
#include <array>
#include <vector>
#include <string>
#include <nlohmann/json.hpp>

namespace SCR::IPC {

// ---------------------------------------------------------------------------
// Message types
// ---------------------------------------------------------------------------

enum class MessageType : uint8_t {
    SNAPSHOT_FULL    = 0x01,
    SNAPSHOT_DELTA   = 0x02,
    RESOURCE_CREATE  = 0x10,
    RESOURCE_RELEASE = 0x11,
    INPUT_STATE      = 0x20,
    CAMERA_UPDATE    = 0x21,
    SUBSCRIBE_REGION  = 0x14,
    UNSUBSCRIBE_REGION = 0x15,
    SUBSCRIBE        = 0x30,
    UNSUBSCRIBE      = 0x31,
    PING             = 0x40,
    PONG             = 0x41,
    SHUTDOWN         = 0xFF,
};

inline const char* to_string(MessageType t) {
    switch (t) {
        case MessageType::SNAPSHOT_FULL:    return "SNAPSHOT_FULL";
        case MessageType::SNAPSHOT_DELTA:   return "SNAPSHOT_DELTA";
        case MessageType::RESOURCE_CREATE:  return "RESOURCE_CREATE";
        case MessageType::RESOURCE_RELEASE: return "RESOURCE_RELEASE";
        case MessageType::INPUT_STATE:      return "INPUT_STATE";
        case MessageType::CAMERA_UPDATE:    return "CAMERA_UPDATE";
        case MessageType::SUBSCRIBE_REGION:  return "SUBSCRIBE_REGION";
        case MessageType::UNSUBSCRIBE_REGION: return "UNSUBSCRIBE_REGION";
        case MessageType::SUBSCRIBE:        return "SUBSCRIBE";
        case MessageType::UNSUBSCRIBE:      return "UNSUBSCRIBE";
        case MessageType::PING:             return "PING";
        case MessageType::PONG:             return "PONG";
        case MessageType::SHUTDOWN:         return "SHUTDOWN";
        default:                            return "UNKNOWN";
    }
}

// ---------------------------------------------------------------------------
// Wire header: exactly 16 bytes, no padding
// ---------------------------------------------------------------------------

#pragma pack(push, 1)
struct MessageHeader {
    uint8_t  type;          // MessageType
    uint8_t  reserved;     // alignment / flags
    uint16_t payload_size;  // bytes after header
    uint32_t generation;    // snapshot ordering
    uint32_t sequence;      // per-connection monotonic
    uint32_t checksum;      // CRC32 of payload (0 = unchecked)
};
#pragma pack(pop)

static_assert(sizeof(MessageHeader) == 16, "MessageHeader must be 16 bytes");

// ---------------------------------------------------------------------------
// Resource descriptor (carried in RESOURCE_CREATE payloads)
// ---------------------------------------------------------------------------

struct ResourceDescriptor {
    int      fd       = -1;   // memfd file descriptor
    uint32_t size     = 0;    // bytes in shared region
    uint32_t lease_id = 0;    // caller-assigned lease
    uint64_t offset   = 0;    // offset within shared region
};

inline void to_json(nlohmann::json& j, const ResourceDescriptor& r) {
    j = {
        {"size",     r.size},
        {"lease_id", r.lease_id},
        {"offset",   r.offset},
        // fd is not serialized — carried via SCM_RIGHTS
    };
}

inline void from_json(const nlohmann::json& j, ResourceDescriptor& r) {
    j.at("size").get_to(r.size);
    if (j.contains("lease_id")) j.at("lease_id").get_to(r.lease_id);
    if (j.contains("offset"))   j.at("offset").get_to(r.offset);
}

// ---------------------------------------------------------------------------
// Spatial subscription (AABB bounds for region-of-interest)
// ---------------------------------------------------------------------------

struct SpatialSubscription {
    float    aabb_min[3]   = {0.f, 0.f, 0.f};
    float    aabb_max[3]   = {0.f, 0.f, 0.f};
    uint32_t subscription_id = 0;
};

inline void to_json(nlohmann::json& j, const SpatialSubscription& s) {
    j = {
        {"aabb_min",         {s.aabb_min[0], s.aabb_min[1], s.aabb_min[2]}},
        {"aabb_max",         {s.aabb_max[0], s.aabb_max[1], s.aabb_max[2]}},
        {"subscription_id",  s.subscription_id},
    };
}

inline void from_json(const nlohmann::json& j, SpatialSubscription& s) {
    auto& mn = j.at("aabb_min");
    s.aabb_min[0] = mn[0].get<float>();
    s.aabb_min[1] = mn[1].get<float>();
    s.aabb_min[2] = mn[2].get<float>();
    auto& mx = j.at("aabb_max");
    s.aabb_max[0] = mx[0].get<float>();
    s.aabb_max[1] = mx[1].get<float>();
    s.aabb_max[2] = mx[2].get<float>();
    j.at("subscription_id").get_to(s.subscription_id);
}

// ---------------------------------------------------------------------------
// Subscription request (carried in SUBSCRIBE_REGION payloads)
// ---------------------------------------------------------------------------

struct SubscriptionRequest {
    uint32_t subscription_id = 0;
    float    aabb_min[3]     = {-1000.f, -1000.f, -1000.f};
    float    aabb_max[3]     = {1000.f, 1000.f, 1000.f};
    uint32_t flags           = 0;  // bit 0: entities, bit 1: terrain, bit 2: atmosphere
};

inline void to_json(nlohmann::json& j, const SubscriptionRequest& r) {
    j = {
        {"subscription_id", r.subscription_id},
        {"aabb_min",        {r.aabb_min[0], r.aabb_min[1], r.aabb_min[2]}},
        {"aabb_max",        {r.aabb_max[0], r.aabb_max[1], r.aabb_max[2]}},
        {"flags",           r.flags},
    };
}

inline void from_json(const nlohmann::json& j, SubscriptionRequest& r) {
    j.at("subscription_id").get_to(r.subscription_id);
    auto& mn = j.at("aabb_min");
    r.aabb_min[0] = mn[0].get<float>();
    r.aabb_min[1] = mn[1].get<float>();
    r.aabb_min[2] = mn[2].get<float>();
    auto& mx = j.at("aabb_max");
    r.aabb_max[0] = mx[0].get<float>();
    r.aabb_max[1] = mx[1].get<float>();
    r.aabb_max[2] = mx[2].get<float>();
    if (j.contains("flags")) j.at("flags").get_to(r.flags);
}

// ---------------------------------------------------------------------------
// Snapshot header (prefix of SNAPSHOT_FULL payload)
// ---------------------------------------------------------------------------

struct SnapshotHeader {
    uint32_t generation     = 0;
    uint32_t tick_count     = 0;
    double   simulated_time = 0.0;
    uint32_t entity_count   = 0;
};

inline void to_json(nlohmann::json& j, const SnapshotHeader& h) {
    j = {
        {"generation",     h.generation},
        {"tick_count",     h.tick_count},
        {"simulated_time", h.simulated_time},
        {"entity_count",   h.entity_count},
    };
}

inline void from_json(const nlohmann::json& j, SnapshotHeader& h) {
    j.at("generation").get_to(h.generation);
    j.at("tick_count").get_to(h.tick_count);
    j.at("simulated_time").get_to(h.simulated_time);
    j.at("entity_count").get_to(h.entity_count);
}

// ---------------------------------------------------------------------------
// Delta header (prefix of SNAPSHOT_DELTA payload)
// ---------------------------------------------------------------------------

struct DeltaHeader {
    uint32_t base_generation  = 0;  // generation the delta applies to
    uint32_t delta_generation = 0;  // generation this delta produces
    uint32_t change_count     = 0;  // number of changed entities
};

inline void to_json(nlohmann::json& j, const DeltaHeader& d) {
    j = {
        {"base_generation",  d.base_generation},
        {"delta_generation", d.delta_generation},
        {"change_count",     d.change_count},
    };
}

inline void from_json(const nlohmann::json& j, DeltaHeader& d) {
    j.at("base_generation").get_to(d.base_generation);
    j.at("delta_generation").get_to(d.delta_generation);
    j.at("change_count").get_to(d.change_count);
}

// ---------------------------------------------------------------------------
// InputState — input from renderer (carried in INPUT_STATE messages)
// ---------------------------------------------------------------------------

struct InputState {
    enum class Kind : uint8_t { Input, CameraUpdate };

    Kind kind       = Kind::Input;
    int  client_fd  = -1;

    // Movement
    bool move_forward  = false;
    bool move_backward = false;
    bool move_left     = false;
    bool move_right    = false;
    bool move_up       = false;
    bool move_down     = false;
    bool sprint        = false;
    bool crouch        = false;
    bool jump          = false;
    bool action_primary   = false;
    bool action_secondary = false;
    bool show_hud         = false;
    float mouse_dx     = 0.0f;
    float mouse_dy     = 0.0f;
    int   selected_hotbar_slot = 1;

    // Camera (when kind == CameraUpdate)
    float cam_x    = 0.0f;
    float cam_y    = 0.0f;
    float cam_z    = 0.0f;
    float cam_yaw  = 0.0f;
    float cam_pitch = 0.0f;
};

// ---------------------------------------------------------------------------
// Convenience: build a framed message (header + payload bytes)
// ---------------------------------------------------------------------------

struct FramedMessage {
    MessageHeader header{};
    std::vector<uint8_t> payload;
};

inline FramedMessage make_framed(MessageType type, uint32_t generation,
                                  uint32_t sequence,
                                  const std::vector<uint8_t>& data) {
    FramedMessage fm;
    fm.header.type         = static_cast<uint8_t>(type);
    fm.header.reserved     = 0;
    fm.header.payload_size = static_cast<uint16_t>(data.size());
    fm.header.generation   = generation;
    fm.header.sequence     = sequence;
    fm.header.checksum     = 0; // CRC32 TODO
    fm.payload = data;
    return fm;
}

inline std::vector<uint8_t> serialize(const FramedMessage& fm) {
    std::vector<uint8_t> buf(sizeof(MessageHeader) + fm.payload.size());
    std::memcpy(buf.data(), &fm.header, sizeof(MessageHeader));
    if (!fm.payload.empty()) {
        std::memcpy(buf.data() + sizeof(MessageHeader),
                    fm.payload.data(), fm.payload.size());
    }
    return buf;
}

inline bool deserialize_header(const uint8_t* raw, size_t len,
                                MessageHeader& out) {
    if (len < sizeof(MessageHeader)) return false;
    std::memcpy(&out, raw, sizeof(MessageHeader));
    return true;
}

} // namespace SCR::IPC

#endif // CAVE_SIM_IPC_PROTOCOL_HPP
