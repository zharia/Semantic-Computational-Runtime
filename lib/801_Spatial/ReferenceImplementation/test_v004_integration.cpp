/// @file test_v004_integration.cpp
/// @brief v0.0.4 integration tests — all providers together
/// @version 0.0.4
/// @date 2026-09-21
///
/// Test Coverage:
///   - Provider interoperability (O3DE ECS + ROS2)
///   - Coordinate conversion consistency
///   - SID mapping across providers
///   - Lifecycle state machine across providers
///   - Reference implementation compatibility

#include "scr_reference_implementation.h"
#include "scr_o3de_ecs_adapter.h"
#include "scr_ros2_provider.h"
#include <cassert>
#include <iostream>
#include <vector>
#include <cmath>

using namespace SCR::ReferenceImplementation;

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

bool approxEqual(double a, double b, double eps = 1e-6) {
    return std::abs(a - b) < eps;
}

// ═══════════════════════════════════════════════════════════════════════════
// Integration Tests
// ═══════════════════════════════════════════════════════════════════════════

void test_provider_initialization() {
    TEST(ProviderInitialization);
    
    SCR::O3DE::O3DEEntityAdapter o3deAdapter;
    SCR::ROS2::ROS2Provider ros2Provider;
    
    assert(o3deAdapter.Initialize());
    assert(ros2Provider.Initialize());
    
    o3deAdapter.Shutdown();
    ros2Provider.Shutdown();
    
    PASS();
}

void test_coordinate_conversion_consistency() {
    TEST(CoordinateConversionConsistency);
    
    // SCR: +Z forward, +Y up, +X right
    Vec3 scrPos = {1.0, 2.0, 3.0};
    
    // Convert to ROS2
    SCR::ROS2::SCRPosition ros2ScrPos = {scrPos.x, scrPos.y, scrPos.z};
    auto ros2Pos = SCR::ROS2::scrToROS2(ros2ScrPos);
    
    // ROS2: +X forward, +Z up, +Y left
    assert(approxEqual(ros2Pos.x, 3.0));  // ROS2.x = SCR.z
    assert(approxEqual(ros2Pos.y, -1.0)); // ROS2.y = -SCR.x
    assert(approxEqual(ros2Pos.z, 2.0));  // ROS2.z = SCR.y
    
    // Round-trip
    SCR::ROS2::SCRPosition back = SCR::ROS2::ros2ToSCR(ros2Pos);
    assert(approxEqual(back.x, scrPos.x));
    assert(approxEqual(back.y, scrPos.y));
    assert(approxEqual(back.z, scrPos.z));
    
    PASS();
}

void test_sid_mapping_across_providers() {
    TEST(SIDMappingAcrossProviders);
    
    SCR::O3DE::O3DEEntityAdapter o3deAdapter;
    SCR::ROS2::ROS2Provider ros2Provider;
    
    o3deAdapter.Initialize();
    ros2Provider.Initialize();
    
    uint64_t sid = 10001;
    
    // Create entity in O3DE ECS adapter
    uint64_t o3deHandle = o3deAdapter.CreateEntity(sid, "O3DE_IntegrationTest");
    assert(o3deHandle != 0);
    
    // Create node in ROS2
    uint64_t ros2Handle = ros2Provider.CreateNode(sid, "ros2_integration_test");
    assert(ros2Handle != 0);
    
    // Verify both can look up by SID
    assert(o3deAdapter.LookupBySID(sid) == o3deHandle);
    assert(ros2Provider.LookupBySID(sid) == ros2Handle);
    
    // Cleanup
    o3deAdapter.DestroyEntity(o3deHandle);
    ros2Provider.DestroyNode(ros2Handle);
    
    o3deAdapter.Shutdown();
    ros2Provider.Shutdown();
    
    PASS();
}

void test_lifecycle_state_machine() {
    TEST(LifecycleStateMachine);
    
    SCR::O3DE::O3DEEntityAdapter adapter;
    adapter.Initialize();
    
    uint64_t sid = 20001;
    uint64_t eid = adapter.CreateEntity(sid, "LifecycleTest");
    
    // Created -> Active
    assert(adapter.GetEntityState(eid) == SCR::O3DE::EntityState::Created);
    assert(adapter.ActivateEntity(eid));
    assert(adapter.GetEntityState(eid) == SCR::O3DE::EntityState::Active);
    
    // Active -> Suspended
    assert(adapter.DeactivateEntity(eid));
    assert(adapter.GetEntityState(eid) == SCR::O3DE::EntityState::Suspended);
    
    // Suspended -> Active
    assert(adapter.ActivateEntity(eid));
    assert(adapter.GetEntityState(eid) == SCR::O3DE::EntityState::Active);
    
    // Active -> Destroyed
    assert(adapter.DestroyEntity(eid));
    assert(adapter.GetEntityState(eid) == SCR::O3DE::EntityState::Destroyed);
    
    adapter.Shutdown();
    PASS();
}

void test_quaternion_conversion_consistency() {
    TEST(QuaternionConversionConsistency);
    
    Quat scrQuat = {0.707, 0.707, 0.0, 0.0};  // w, x, y, z
    
    // Convert to ROS2 (x, y, z, w)
    SCR::ROS2::SCRQuaternion ros2ScrQuat = {scrQuat.w, scrQuat.x, scrQuat.y, scrQuat.z};
    auto ros2Quat = SCR::ROS2::scrToROS2Quat(ros2ScrQuat);
    assert(approxEqual(ros2Quat.x, 0.707));
    assert(approxEqual(ros2Quat.y, 0.0));
    assert(approxEqual(ros2Quat.z, 0.0));
    assert(approxEqual(ros2Quat.w, 0.707));
    
    // Round-trip
    SCR::ROS2::SCRQuaternion back = SCR::ROS2::ros2ToSCRQuat(ros2Quat);
    assert(approxEqual(back.w, scrQuat.w));
    assert(approxEqual(back.x, scrQuat.x));
    assert(approxEqual(back.y, scrQuat.y));
    assert(approxEqual(back.z, scrQuat.z));
    
    PASS();
}

void test_reference_implementation_compatibility() {
    TEST(ReferenceImplementationCompatibility);
    
    // Create entity using reference implementation API
    SID sid = create_sid(1, 1, 30001);
    assert(validate_sid(sid));
    
    SemanticEntity entity = create_entity("CompatTest", sid);
    assert(entity.sid == sid);
    assert(entity.name == "CompatTest");
    
    PASS();
}

void test_multiple_providers_concurrent() {
    TEST(MultipleProvidersConcurrent);
    
    SCR::O3DE::O3DEEntityAdapter o3deAdapter;
    SCR::ROS2::ROS2Provider ros2Provider;
    
    o3deAdapter.Initialize();
    ros2Provider.Initialize();
    
    // Create 100 entities in each provider
    for (uint64_t i = 0; i < 100; i++) {
        uint64_t sid = 40000 + i;
        
        uint64_t o3deHandle = o3deAdapter.CreateEntity(sid, "O3DE_" + std::to_string(i));
        uint64_t ros2Handle = ros2Provider.CreateNode(sid, "ros2_" + std::to_string(i));
        
        assert(o3deHandle != 0);
        assert(ros2Handle != 0);
    }
    
    assert(o3deAdapter.GetEntityCount() == 100);
    assert(ros2Provider.GetNodeCount() == 100);
    
    // Cleanup
    for (uint64_t i = 0; i < 100; i++) {
        uint64_t sid = 40000 + i;
        uint64_t o3deHandle = o3deAdapter.LookupBySID(sid);
        uint64_t ros2Handle = ros2Provider.LookupBySID(sid);
        
        o3deAdapter.DestroyEntity(o3deHandle);
        ros2Provider.DestroyNode(ros2Handle);
    }
    
    o3deAdapter.Shutdown();
    ros2Provider.Shutdown();
    
    PASS();
}

// ═══════════════════════════════════════════════════════════════════════════
// Main
// ═══════════════════════════════════════════════════════════════════════════

int main() {
    std::cout << "v0.0.4 Integration Tests" << std::endl;
    std::cout << "========================" << std::endl;
    
    test_provider_initialization();
    test_coordinate_conversion_consistency();
    test_sid_mapping_across_providers();
    test_lifecycle_state_machine();
    test_quaternion_conversion_consistency();
    test_reference_implementation_compatibility();
    test_multiple_providers_concurrent();
    
    std::cout << std::endl;
    std::cout << "Results: " << pass_count << "/" << test_count << " PASS" << std::endl;
    
    return (pass_count == test_count) ? 0 : 1;
}
