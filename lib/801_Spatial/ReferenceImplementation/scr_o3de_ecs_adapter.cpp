/// @file scr_o3de_ecs_adapter.cpp
/// @brief O3DE Entity Component System adapter implementation
/// @version 0.0.4
/// @date 2026-09-21
///
/// This implementation works in stub mode (metadata tracking only).
/// When O3DE is available, it creates real AzFramework::Entity instances.
/// The adapter interface remains identical in both modes.

#include "scr_o3de_ecs_adapter.h"
#include <iostream>

namespace SCR::O3DE {

// ═══════════════════════════════════════════════════════════════════════════
// O3DEEntityAdapter Implementation
// ═══════════════════════════════════════════════════════════════════════════

O3DEEntityAdapter::O3DEEntityAdapter()
    : m_nextEntityId(1)
    , m_initialized(false)
{
}

O3DEEntityAdapter::~O3DEEntityAdapter() {
    Shutdown();
}

bool O3DEEntityAdapter::Initialize() {
    if (m_initialized) {
        return true;
    }

    // In full O3DE mode, this would initialize the AZ::Environment
    // AZ::Environment::Create();
    // AZ::Interface<AZ::ComponentApplication>::Create();

    m_initialized = true;
    return true;
}

void O3DEEntityAdapter::Shutdown() {
    if (!m_initialized) {
        return;
    }

    // Clear all data
    m_entities.clear();
    m_sidToEntity.clear();
    m_entityToSid.clear();
    m_initialized = false;
}

uint64_t O3DEEntityAdapter::CreateEntity(uint64_t sid, const std::string& name) {
    if (!m_initialized) {
        return 0;
    }

    // Check if SID already has an entity
    if (m_sidToEntity.find(sid) != m_sidToEntity.end()) {
        return 0;
    }

    uint64_t entityId = m_nextEntityId++;

    // Store record (metadata only)
    EntityRecord record;
    record.name = name;
    record.state = EntityState::Created;
    record.sid = sid;

    m_entities.emplace(entityId, std::move(record));

    // Update mappings
    m_sidToEntity[sid] = entityId;
    m_entityToSid[entityId] = sid;

    return entityId;
}

bool O3DEEntityAdapter::ActivateEntity(uint64_t entity_id) {
    if (!m_initialized) {
        return false;
    }

    auto it = m_entities.find(entity_id);
    if (it == m_entities.end()) {
        return false;
    }

    // Allow activation from Created or Suspended states
    if (it->second.state != EntityState::Created && 
        it->second.state != EntityState::Suspended) {
        return false;
    }

    // In full O3DE mode:
    // it->second.entity->Activate();

    it->second.state = EntityState::Active;
    return true;
}

bool O3DEEntityAdapter::DeactivateEntity(uint64_t entity_id) {
    if (!m_initialized) {
        return false;
    }

    auto it = m_entities.find(entity_id);
    if (it == m_entities.end()) {
        return false;
    }

    if (it->second.state != EntityState::Active) {
        return false;
    }

    // In full O3DE mode:
    // it->second.entity->Deactivate();

    it->second.state = EntityState::Suspended;
    return true;
}

bool O3DEEntityAdapter::DestroyEntity(uint64_t entity_id) {
    if (!m_initialized) {
        return false;
    }

    auto it = m_entities.find(entity_id);
    if (it == m_entities.end()) {
        return false;
    }

    // Must be deactivated first
    if (it->second.state == EntityState::Active) {
        DeactivateEntity(entity_id);
    }

    // In full O3DE mode:
    // it->second.entity.reset();

    it->second.state = EntityState::Destroyed;
    return true;
}

EntityState O3DEEntityAdapter::GetEntityState(uint64_t entity_id) const {
    auto it = m_entities.find(entity_id);
    if (it == m_entities.end()) {
        return EntityState::Destroyed;
    }
    return it->second.state;
}

bool O3DEEntityAdapter::EntityExists(uint64_t entity_id) const {
    return m_entities.find(entity_id) != m_entities.end();
}

uint64_t O3DEEntityAdapter::LookupBySID(uint64_t sid) const {
    auto it = m_sidToEntity.find(sid);
    if (it == m_sidToEntity.end()) {
        return 0;
    }
    return it->second;
}

uint64_t O3DEEntityAdapter::LookupByEntityId(uint64_t entity_id) const {
    auto it = m_entityToSid.find(entity_id);
    if (it == m_entityToSid.end()) {
        return 0;
    }
    return it->second;
}

std::string O3DEEntityAdapter::GetEntityName(uint64_t entity_id) const {
    auto it = m_entities.find(entity_id);
    if (it == m_entities.end()) {
        return "";
    }
    return it->second.name;
}

size_t O3DEEntityAdapter::GetEntityCount() const {
    return m_entities.size();
}

} // namespace SCR::O3DE
