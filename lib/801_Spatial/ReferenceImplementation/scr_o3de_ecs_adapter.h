#pragma once

/// @file scr_o3de_ecs_adapter.h
/// @brief O3DE Entity Component System adapter for SCR
/// @version 0.0.4
/// @date 2026-09-21
///
/// Adapter Specification:
///   Maps SCR semantic contracts to O3DE AzFramework::Entity lifecycle.
///   Provides SCR SID → O3DE EntityId manifestation.
///   Maps SCR entity lifecycle to O3DE component activation.
///
/// Design:
///   This adapter uses opaque handles (uint64_t EntityIds) rather than
///   direct AZ::Entity pointers, allowing compilation without O3DE headers.
///   When O3DE is available, the adapter creates real entities. When not,
///   it operates in stub mode with metadata tracking only.
///
/// Dependencies:
///   O3DE 26.05 AzCore, AzFramework (optional at compile time)

#include <cstdint>
#include <string>
#include <unordered_map>

namespace SCR::O3DE {

/// @brief O3DE Entity lifecycle states (mirrors SCR EntityState)
enum class EntityState : uint8_t {
    Created = 0,    ///< Entity created but not activated
    Active = 1,     ///< Entity activated and running
    Suspended = 2,  ///< Entity deactivated but still exists
    Destroyed = 3   ///< Entity destroyed (terminal)
};

/// @brief Convert SCR EntityState to O3DE EntityState
/// @param scr_state SCR state (0=Created, 1=Active, 2=Suspended, 3=Destroyed)
/// @return Corresponding O3DE state
inline EntityState scrToO3deState(int scr_state) {
    switch (scr_state) {
        case 0: return EntityState::Created;
        case 1: return EntityState::Active;
        case 2: return EntityState::Suspended;
        case 3: return EntityState::Destroyed;
        default: return EntityState::Created;
    }
}

/// @brief O3DE Entity Adapter
/// @details Maps SCR semantics to O3DE entity lifecycle using opaque handles.
///
/// Architecture:
///   SCR Semantic Definition → SCR Entity → O3DE Entity Adapter → AzFramework::Entity
///
/// The adapter maintains a bidirectional mapping between SCR SIDs and
/// O3DE EntityIds, allowing any SCR entity to be manifested as an O3DE entity.
///
/// Usage:
///   O3DEEntityAdapter adapter;
///   adapter.Initialize();
///   uint64_t eid = adapter.CreateEntity(sid, "MyEntity");
///   adapter.ActivateEntity(eid);
///   // ... use entity ...
///   adapter.DeactivateEntity(eid);
///   adapter.DestroyEntity(eid);
///   adapter.Shutdown();
class O3DEEntityAdapter {
public:
    O3DEEntityAdapter();
    ~O3DEEntityAdapter();

    /// @brief Initialize the adapter (must be called before use)
    /// @return true if initialization succeeded
    bool Initialize();

    /// @brief Shutdown the adapter (cleanup resources)
    void Shutdown();

    /// @brief Create an O3DE entity from SCR metadata
    /// @param sid SCR semantic identifier
    /// @param name Entity name
    /// @return O3DE EntityId (0 on failure)
    uint64_t CreateEntity(uint64_t sid, const std::string& name);

    /// @brief Activate an entity (activate all components)
    /// @param entity_id O3DE EntityId
    /// @return true if activation succeeded
    bool ActivateEntity(uint64_t entity_id);

    /// @brief Deactivate an entity (deactivate all components)
    /// @param entity_id O3DE EntityId
    /// @return true if deactivation succeeded
    bool DeactivateEntity(uint64_t entity_id);

    /// @brief Destroy an entity
    /// @param entity_id O3DE EntityId
    /// @return true if destruction succeeded
    bool DestroyEntity(uint64_t entity_id);

    /// @brief Get entity current state
    /// @param entity_id O3DE EntityId
    /// @return Current EntityState
    EntityState GetEntityState(uint64_t entity_id) const;

    /// @brief Check if entity exists
    /// @param entity_id O3DE EntityId
    /// @return true if entity exists
    bool EntityExists(uint64_t entity_id) const;

    /// @brief Look up O3DE EntityId from SCR SID
    /// @param sid SCR semantic identifier
    /// @return O3DE EntityId (0 if not found)
    uint64_t LookupBySID(uint64_t sid) const;

    /// @brief Look up SCR SID from O3DE EntityId
    /// @param entity_id O3DE EntityId
    /// @return SCR SID (0 if not found)
    uint64_t LookupByEntityId(uint64_t entity_id) const;

    /// @brief Get entity name
    /// @param entity_id O3DE EntityId
    /// @return Entity name (empty if not found)
    std::string GetEntityName(uint64_t entity_id) const;

    /// @brief Get number of managed entities
    /// @return Entity count
    size_t GetEntityCount() const;

private:
    struct EntityRecord {
        std::string name;
        EntityState state;
        uint64_t sid;
    };

    std::unordered_map<uint64_t, EntityRecord> m_entities;
    std::unordered_map<uint64_t, uint64_t> m_sidToEntity;
    std::unordered_map<uint64_t, uint64_t> m_entityToSid;
    uint64_t m_nextEntityId;
    bool m_initialized;
};

} // namespace SCR::O3DE
