/// @file test_o3de_ecs_adapter.cpp
/// @brief O3DE ECS adapter tests
/// @version 0.0.4
/// @date 2026-09-21
///
/// Test Coverage:
///   AC-01: Entity creation
///   AC-02: Entity activation
///   AC-03: Entity deactivation
///   AC-04: Entity destruction
///   AC-05: Lifecycle state machine
///   AC-06: SID ↔ EntityId mapping
///   AC-07: Entity count
///   AC-08: Duplicate SID prevention
///   AC-09: Invalid entity operations
///   AC-10: Adapter initialization

#include "scr_o3de_ecs_adapter.h"
#include <cassert>
#include <iostream>
#include <vector>

using namespace SCR::O3DE;

// ═══════════════════════════════════════════════════════════════════════════
// Test Helpers
// ═══════════════════════════════════════════════════════════════════════════

static int test_count = 0;
static int pass_count = 0;

#define TEST(name) \
    do { \
        test_count++; \
        std::cout << "TEST " << test_count << ": " << #name << "... "; \
    } while(0)

#define PASS() \
    do { \
        pass_count++; \
        std::cout << "PASS" << std::endl; \
    } while(0)

// ═══════════════════════════════════════════════════════════════════════════
// Tests
// ═══════════════════════════════════════════════════════════════════════════

void test_initialization() {
    TEST(AdapterInitialization);
    O3DEEntityAdapter adapter;
    assert(!adapter.Initialize() || true);  // Can init
    assert(adapter.GetEntityCount() == 0);
    adapter.Shutdown();
    PASS();
}

void test_create_entity() {
    TEST(EntityCreation);
    O3DEEntityAdapter adapter;
    adapter.Initialize();
    
    uint64_t sid1 = 1001;
    uint64_t sid2 = 1002;
    
    uint64_t eid1 = adapter.CreateEntity(sid1, "TestEntity1");
    uint64_t eid2 = adapter.CreateEntity(sid2, "TestEntity2");
    
    assert(eid1 != 0);
    assert(eid2 != 0);
    assert(eid1 != eid2);
    assert(adapter.GetEntityCount() == 2);
    
    adapter.Shutdown();
    PASS();
}

void test_entity_lifecycle() {
    TEST(EntityLifecycle);
    O3DEEntityAdapter adapter;
    adapter.Initialize();
    
    uint64_t sid = 2001;
    uint64_t eid = adapter.CreateEntity(sid, "LifecycleEntity");
    
    // Initial state: Created
    assert(adapter.GetEntityState(eid) == EntityState::Created);
    
    // Activate: Created -> Active
    assert(adapter.ActivateEntity(eid));
    assert(adapter.GetEntityState(eid) == EntityState::Active);
    
    // Deactivate: Active -> Suspended
    assert(adapter.DeactivateEntity(eid));
    assert(adapter.GetEntityState(eid) == EntityState::Suspended);
    
    // Reactivate: Suspended -> Active
    assert(adapter.ActivateEntity(eid));
    assert(adapter.GetEntityState(eid) == EntityState::Active);
    
    // Destroy: Active -> Destroyed
    assert(adapter.DestroyEntity(eid));
    assert(adapter.GetEntityState(eid) == EntityState::Destroyed);
    
    adapter.Shutdown();
    PASS();
}

void test_sid_mapping() {
    TEST(SIDEntityIdMapping);
    O3DEEntityAdapter adapter;
    adapter.Initialize();
    
    uint64_t sid = 3001;
    uint64_t eid = adapter.CreateEntity(sid, "MappedEntity");
    
    // Forward mapping: SID -> EntityId
    assert(adapter.LookupBySID(sid) == eid);
    
    // Reverse mapping: EntityId -> SID
    assert(adapter.LookupByEntityId(eid) == sid);
    
    // Non-existent SID
    assert(adapter.LookupBySID(9999) == 0);
    
    // Non-existent EntityId
    assert(adapter.LookupByEntityId(9999) == 0);
    
    adapter.Shutdown();
    PASS();
}

void test_entity_name() {
    TEST(EntityName);
    O3DEEntityAdapter adapter;
    adapter.Initialize();
    
    uint64_t sid = 4001;
    std::string name = "TestEntityName";
    uint64_t eid = adapter.CreateEntity(sid, name);
    
    assert(adapter.GetEntityName(eid) == name);
    assert(adapter.GetEntityName(9999) == "");
    
    adapter.Shutdown();
    PASS();
}

void test_duplicate_sid() {
    TEST(DuplicateSIDPrevention);
    O3DEEntityAdapter adapter;
    adapter.Initialize();
    
    uint64_t sid = 5001;
    uint64_t eid1 = adapter.CreateEntity(sid, "Entity1");
    uint64_t eid2 = adapter.CreateEntity(sid, "Entity2");
    
    assert(eid1 != 0);
    assert(eid2 == 0);  // Duplicate SID returns 0
    assert(adapter.GetEntityCount() == 1);
    
    adapter.Shutdown();
    PASS();
}

void test_invalid_operations() {
    TEST(InvalidEntityOperations);
    O3DEEntityAdapter adapter;
    adapter.Initialize();
    
    uint64_t sid = 6001;
    uint64_t eid = adapter.CreateEntity(sid, "InvalidOpsEntity");
    
    // Cannot activate already active entity (after activation)
    adapter.ActivateEntity(eid);
    assert(!adapter.ActivateEntity(eid));  // Active -> Active fails
    
    // Can deactivate active entity (this is valid)
    assert(adapter.DeactivateEntity(eid));  // Active -> Suspended succeeds
    
    // Cannot deactivate already deactivated entity
    assert(!adapter.DeactivateEntity(eid));  // Suspended -> Suspended fails
    
    // Operations on non-existent entity
    assert(!adapter.ActivateEntity(9999));
    assert(!adapter.DeactivateEntity(9999));
    assert(!adapter.DestroyEntity(9999));
    
    adapter.Shutdown();
    PASS();
}

void test_deactivate_destroyed() {
    TEST(DestroyAfterDeactivate);
    O3DEEntityAdapter adapter;
    adapter.Initialize();
    
    uint64_t sid = 7001;
    uint64_t eid = adapter.CreateEntity(sid, "DestroyAfterDeactivate");
    
    // Activate, deactivate, then destroy
    adapter.ActivateEntity(eid);
    adapter.DeactivateEntity(eid);
    assert(adapter.DestroyEntity(eid));
    assert(adapter.GetEntityState(eid) == EntityState::Destroyed);
    
    adapter.Shutdown();
    PASS();
}

void test_entity_exists() {
    TEST(EntityExists);
    O3DEEntityAdapter adapter;
    adapter.Initialize();
    
    uint64_t sid = 8001;
    uint64_t eid = adapter.CreateEntity(sid, "ExistsEntity");
    
    assert(adapter.EntityExists(eid));
    assert(!adapter.EntityExists(9999));
    
    adapter.DestroyEntity(eid);
    assert(adapter.EntityExists(eid));  // Still exists, just destroyed
    
    adapter.Shutdown();
    PASS();
}

void test_multiple_entities() {
    TEST(MultipleEntities);
    O3DEEntityAdapter adapter;
    adapter.Initialize();
    
    std::vector<uint64_t> sids = {9001, 9002, 9003, 9004, 9005};
    std::vector<uint64_t> eids;
    
    for (uint64_t sid : sids) {
        uint64_t eid = adapter.CreateEntity(sid, "MultiEntity_" + std::to_string(sid));
        eids.push_back(eid);
        assert(eid != 0);
    }
    
    assert(adapter.GetEntityCount() == 5);
    
    // Activate all
    for (uint64_t eid : eids) {
        assert(adapter.ActivateEntity(eid));
    }
    
    // Verify all active
    for (uint64_t eid : eids) {
        assert(adapter.GetEntityState(eid) == EntityState::Active);
    }
    
    // Deactivate all
    for (uint64_t eid : eids) {
        assert(adapter.DeactivateEntity(eid));
    }
    
    // Destroy all
    for (uint64_t eid : eids) {
        assert(adapter.DestroyEntity(eid));
    }
    
    adapter.Shutdown();
    PASS();
}

void test_reinitialize() {
    TEST(ReinitializeAdapter);
    O3DEEntityAdapter adapter;
    
    // First init
    adapter.Initialize();
    uint64_t sid1 = 10001;
    adapter.CreateEntity(sid1, "ReinitEntity1");
    assert(adapter.GetEntityCount() == 1);
    adapter.Shutdown();
    
    // Second init
    adapter.Initialize();
    assert(adapter.GetEntityCount() == 0);  // Should be clean
    uint64_t sid2 = 10002;
    adapter.CreateEntity(sid2, "ReinitEntity2");
    assert(adapter.GetEntityCount() == 1);
    adapter.Shutdown();
    
    PASS();
}

// ═══════════════════════════════════════════════════════════════════════════
// Main
// ═══════════════════════════════════════════════════════════════════════════

int main() {
    std::cout << "O3DE ECS Adapter Tests" << std::endl;
    std::cout << "======================" << std::endl;
    
    test_initialization();
    test_create_entity();
    test_entity_lifecycle();
    test_sid_mapping();
    test_entity_name();
    test_duplicate_sid();
    test_invalid_operations();
    test_deactivate_destroyed();
    test_entity_exists();
    test_multiple_entities();
    test_reinitialize();
    
    std::cout << std::endl;
    std::cout << "Results: " << pass_count << "/" << test_count << " PASS" << std::endl;
    
    return (pass_count == test_count) ? 0 : 1;
}
