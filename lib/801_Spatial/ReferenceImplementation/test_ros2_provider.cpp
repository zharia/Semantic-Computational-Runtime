/// @file test_ros2_provider.cpp
/// @brief ROS2 provider tests
/// @version 0.0.4
/// @date 2026-09-21
///
/// Test Coverage:
///   AC-01: Node creation
///   AC-02: Node destruction
///   AC-03: Transform set/get
///   AC-04: SID ↔ NodeHandle mapping
///   AC-05: Node count
///   AC-06: Duplicate SID prevention
///   AC-07: Invalid node operations
///   AC-08: Coordinate conversion (SCR ↔ ROS2)
///   AC-09: Quaternion conversion
///   AC-10: Provider initialization

#include "scr_ros2_provider.h"
#include <cassert>
#include <iostream>
#include <vector>
#include <cmath>

using namespace SCR::ROS2;

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
// Tests
// ═══════════════════════════════════════════════════════════════════════════

void test_initialization() {
    TEST(ProviderInitialization);
    ROS2Provider provider;
    assert(provider.Initialize());
    assert(provider.GetNodeCount() == 0);
    provider.Shutdown();
    PASS();
}

void test_create_node() {
    TEST(NodeCreation);
    ROS2Provider provider;
    provider.Initialize();
    
    uint64_t sid1 = 1001;
    uint64_t sid2 = 1002;
    
    uint64_t handle1 = provider.CreateNode(sid1, "TestNode1");
    uint64_t handle2 = provider.CreateNode(sid2, "TestNode2");
    
    assert(handle1 != 0);
    assert(handle2 != 0);
    assert(handle1 != handle2);
    assert(provider.GetNodeCount() == 2);
    
    provider.Shutdown();
    PASS();
}

void test_node_destruction() {
    TEST(NodeDestruction);
    ROS2Provider provider;
    provider.Initialize();
    
    uint64_t sid = 2001;
    uint64_t handle = provider.CreateNode(sid, "DestroyableNode");
    
    assert(provider.GetNodeCount() == 1);
    assert(provider.DestroyNode(handle));
    assert(provider.GetNodeCount() == 0);
    assert(provider.GetNodeName(handle) == "");
    
    provider.Shutdown();
    PASS();
}

void test_transform_set_get() {
    TEST(TransformSetGet);
    ROS2Provider provider;
    provider.Initialize();
    
    uint64_t sid = 3001;
    uint64_t handle = provider.CreateNode(sid, "TransformNode");
    
    SCRPosition pos = {1.0, 2.0, 3.0};
    SCRQuaternion quat = {0.707, 0.707, 0.0, 0.0};
    
    assert(provider.SetTransform(handle, pos, quat));
    
    // Lookup from same node to itself should give zero distance
    SCRPosition outPos;
    SCRQuaternion outQuat;
    assert(provider.LookupTransform(handle, handle, outPos, outQuat));
    assert(approxEqual(outPos.x, 0.0));
    assert(approxEqual(outPos.y, 0.0));
    assert(approxEqual(outPos.z, 0.0));
    
    provider.Shutdown();
    PASS();
}

void test_sid_mapping() {
    TEST(SIDNodeHandleMapping);
    ROS2Provider provider;
    provider.Initialize();
    
    uint64_t sid = 4001;
    uint64_t handle = provider.CreateNode(sid, "MappedNode");
    
    // Forward mapping: SID -> NodeHandle
    assert(provider.LookupBySID(sid) == handle);
    
    // Reverse mapping: NodeHandle -> SID
    assert(provider.LookupByNodeHandle(handle) == sid);
    
    // Non-existent SID
    assert(provider.LookupBySID(9999) == 0);
    
    // Non-existent NodeHandle
    assert(provider.LookupByNodeHandle(9999) == 0);
    
    provider.Shutdown();
    PASS();
}

void test_node_name() {
    TEST(NodeName);
    ROS2Provider provider;
    provider.Initialize();
    
    uint64_t sid = 5001;
    std::string name = "TestNodeName";
    uint64_t handle = provider.CreateNode(sid, name);
    
    assert(provider.GetNodeName(handle) == name);
    assert(provider.GetNodeName(9999) == "");
    
    provider.Shutdown();
    PASS();
}

void test_duplicate_sid() {
    TEST(DuplicateSIDPrevention);
    ROS2Provider provider;
    provider.Initialize();
    
    uint64_t sid = 6001;
    uint64_t handle1 = provider.CreateNode(sid, "Node1");
    uint64_t handle2 = provider.CreateNode(sid, "Node2");
    
    assert(handle1 != 0);
    assert(handle2 == 0);  // Duplicate SID returns 0
    assert(provider.GetNodeCount() == 1);
    
    provider.Shutdown();
    PASS();
}

void test_invalid_operations() {
    TEST(InvalidNodeOperations);
    ROS2Provider provider;
    provider.Initialize();
    
    uint64_t sid = 7001;
    uint64_t handle = provider.CreateNode(sid, "InvalidOpsNode");
    
    // Operations on non-existent node
    assert(!provider.SetTransform(9999, {0,0,0}, {1,0,0,0}));
    
    SCRPosition pos;
    SCRQuaternion quat;
    assert(!provider.LookupTransform(9999, handle, pos, quat));
    assert(!provider.LookupTransform(handle, 9999, pos, quat));
    assert(!provider.DestroyNode(9999));
    
    provider.Shutdown();
    PASS();
}

void test_coordinate_conversion() {
    TEST(CoordinateConversion);
    
    // SCR: +Z forward, +Y up, +X right
    SCRPosition scr = {1.0, 2.0, 3.0};
    
    // ROS2: +X forward, +Z up, +Y left
    ROS2Position ros2 = scrToROS2(scr);
    
    assert(approxEqual(ros2.x, 3.0));  // ROS2.x = SCR.z
    assert(approxEqual(ros2.y, -1.0)); // ROS2.y = -SCR.x
    assert(approxEqual(ros2.z, 2.0));  // ROS2.z = SCR.y
    
    // Round-trip
    SCRPosition back = ros2ToSCR(ros2);
    assert(approxEqual(back.x, scr.x));
    assert(approxEqual(back.y, scr.y));
    assert(approxEqual(back.z, scr.z));
    
    PASS();
}

void test_quaternion_conversion() {
    TEST(QuaternionConversion);
    
    // SCR: Hamilton (scalar-first)
    SCRQuaternion scr = {0.707, 0.707, 0.0, 0.0};  // w, x, y, z
    
    // ROS2: scalar-last
    ROS2Quaternion ros2 = scrToROS2Quat(scr);
    
    assert(approxEqual(ros2.x, 0.707));
    assert(approxEqual(ros2.y, 0.0));
    assert(approxEqual(ros2.z, 0.0));
    assert(approxEqual(ros2.w, 0.707));
    
    // Round-trip
    SCRQuaternion back = ros2ToSCRQuat(ros2);
    assert(approxEqual(back.w, scr.w));
    assert(approxEqual(back.x, scr.x));
    assert(approxEqual(back.y, scr.y));
    assert(approxEqual(back.z, scr.z));
    
    PASS();
}

void test_multiple_nodes() {
    TEST(MultipleNodes);
    ROS2Provider provider;
    provider.Initialize();
    
    std::vector<uint64_t> sids = {9001, 9002, 9003, 9004, 9005};
    std::vector<uint64_t> handles;
    
    for (uint64_t sid : sids) {
        uint64_t handle = provider.CreateNode(sid, "MultiNode_" + std::to_string(sid));
        handles.push_back(handle);
        assert(handle != 0);
    }
    
    assert(provider.GetNodeCount() == 5);
    
    // Set transforms for all
    for (uint64_t handle : handles) {
        SCRPosition pos = {1.0, 2.0, 3.0};
        SCRQuaternion quat = {1.0, 0.0, 0.0, 0.0};
        assert(provider.SetTransform(handle, pos, quat));
    }
    
    // Destroy all
    for (uint64_t handle : handles) {
        assert(provider.DestroyNode(handle));
    }
    
    assert(provider.GetNodeCount() == 0);
    
    provider.Shutdown();
    PASS();
}

void test_reinitialize() {
    TEST(ReinitializeProvider);
    ROS2Provider provider;
    
    // First init
    provider.Initialize();
    uint64_t sid1 = 10001;
    provider.CreateNode(sid1, "ReinitNode1");
    assert(provider.GetNodeCount() == 1);
    provider.Shutdown();
    
    // Second init
    provider.Initialize();
    assert(provider.GetNodeCount() == 0);  // Should be clean
    uint64_t sid2 = 10002;
    provider.CreateNode(sid2, "ReinitNode2");
    assert(provider.GetNodeCount() == 1);
    provider.Shutdown();
    
    PASS();
}

// ═══════════════════════════════════════════════════════════════════════════
// Main
// ═══════════════════════════════════════════════════════════════════════════

int main() {
    std::cout << "ROS2 Provider Tests" << std::endl;
    std::cout << "===================" << std::endl;
    
    test_initialization();
    test_create_node();
    test_node_destruction();
    test_transform_set_get();
    test_sid_mapping();
    test_node_name();
    test_duplicate_sid();
    test_invalid_operations();
    test_coordinate_conversion();
    test_quaternion_conversion();
    test_multiple_nodes();
    test_reinitialize();
    
    std::cout << std::endl;
    std::cout << "Results: " << pass_count << "/" << test_count << " PASS" << std::endl;
    
    return (pass_count == test_count) ? 0 : 1;
}
