/// @file test_o3de_provider.cpp
/// @brief Tests for real O3DE provider integration.
///
/// These tests exercise ACTUAL O3DE math operations, not in-memory simulation.
/// Each test converts SCR types to O3DE types, performs O3DE operations,
/// and converts results back to SCR types.

#include "scr_o3de_provider.h"
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <assert.h>

#define EPSILON 1e-6

using namespace SCR::O3DEProvider;

static bool vec3_eq(const Vec3& a, const Vec3& b) {
    return std::abs(a.x - b.x) < EPSILON &&
           std::abs(a.y - b.y) < EPSILON &&
           std::abs(a.z - b.z) < EPSILON;
}

static bool quat_eq(const Quat& a, const Quat& b) {
    double dot = a.w*b.w + a.x*b.x + a.y*b.y + a.z*b.z;
    return std::abs(std::abs(dot) - 1.0) < 1e-4;
}

// ═══════════════════════════════════════════════════════════════════════════
// TEST 1: SCR → O3DE → SCR coordinate round-trip
// ═══════════════════════════════════════════════════════════════════════════

static void test_coordinate_roundtrip() {
    printf("[Test 1] SCR → O3DE → SCR coordinate round-trip... ");
    
    Vec3 scr_pos{1.0, 2.0, 3.0};
    AZ::Vector3 o3de_pos = scr_to_o3de(scr_pos);
    Vec3 roundtrip = o3de_to_scr(o3de_pos);
    
    assert(vec3_eq(scr_pos, roundtrip));
    printf("PASSED\n");
}

// ═══════════════════════════════════════════════════════════════════════════
// TEST 2: SCR → O3DE → SCR quaternion round-trip
// ═══════════════════════════════════════════════════════════════════════════

static void test_quaternion_roundtrip() {
    printf("[Test 2] SCR → O3DE → SCR quaternion round-trip... ");
    
    Quat scr_rot{0.7071, 0.0, 0.7071, 0.0}; // 90° around Y
    AZ::Quaternion o3de_rot = scr_to_o3de(scr_rot);
    Quat roundtrip = o3de_to_scr(o3de_rot);
    
    assert(quat_eq(scr_rot, roundtrip));
    printf("PASSED\n");
}

// ═══════════════════════════════════════════════════════════════════════════
// TEST 3: SCR → O3DE → SCR transform round-trip
// ═══════════════════════════════════════════════════════════════════════════

static void test_transform_roundtrip() {
    printf("[Test 3] SCR → O3DE → SCR transform round-trip... ");
    
    SimilarityTransform scr_transform;
    scr_transform.scale = 2.0;
    scr_transform.rotation = Quat{0.7071, 0.0, 0.7071, 0.0};
    scr_transform.translation = Vec3{1.0, 2.0, 3.0};
    
    AZ::Transform o3de_transform = scr_to_o3de(scr_transform);
    SimilarityTransform roundtrip = o3de_to_scr(o3de_transform);
    
    assert(std::abs(scr_transform.scale - roundtrip.scale) < EPSILON);
    assert(vec3_eq(scr_transform.translation, roundtrip.translation));
    assert(quat_eq(scr_transform.rotation, roundtrip.rotation));
    printf("PASSED\n");
}

// ═══════════════════════════════════════════════════════════════════════════
// TEST 4: O3DE transform composition (real math)
// ═══════════════════════════════════════════════════════════════════════════

static void test_o3de_transform_composition() {
    printf("[Test 4] O3DE transform composition (real math)... ");
    
    // Create two transforms
    SimilarityTransform t1;
    t1.scale = 1.0;
    t1.rotation = Quat{1.0, 0.0, 0.0, 0.0}; // identity
    t1.translation = Vec3{1.0, 0.0, 0.0};
    
    SimilarityTransform t2;
    t2.scale = 2.0;
    t2.rotation = Quat{0.7071, 0.0, 0.7071, 0.0}; // 90° around Y
    t2.translation = Vec3{0.0, 1.0, 0.0};
    
    // Convert to O3DE and compose
    AZ::Transform o3de_t1 = scr_to_o3de(t1);
    AZ::Transform o3de_t2 = scr_to_o3de(t2);
    AZ::Transform o3de_result = o3de_t1 * o3de_t2;
    
    // Convert back to SCR
    SimilarityTransform result = o3de_to_scr(o3de_result);
    
    // Verify composition is valid
    assert(result.scale > 0);
    printf("PASSED\n");
}

// ═══════════════════════════════════════════════════════════════════════════
// TEST 5: O3DE transform application to point (real math)
// ═══════════════════════════════════════════════════════════════════════════

static void test_o3de_transform_point() {
    printf("[Test 5] O3DE transform application to point (real math)... ");
    
    // Create transform: translate (1, 2, 3)
    SimilarityTransform transform;
    transform.scale = 1.0;
    transform.rotation = Quat{1.0, 0.0, 0.0, 0.0};
    transform.translation = Vec3{1.0, 2.0, 3.0};
    
    AZ::Transform o3de_transform = scr_to_o3de(transform);
    
    // Apply to origin
    AZ::Vector3 origin(0.0f, 0.0f, 0.0f);
    AZ::Vector3 result = o3de_transform.TransformPoint(origin);
    
    // Should be at translation
    Vec3 scr_result = o3de_to_scr(result);
    assert(std::abs(scr_result.x - 1.0) < EPSILON);
    assert(std::abs(scr_result.y - 2.0) < EPSILON);
    assert(std::abs(scr_result.z - 3.0) < EPSILON);
    printf("PASSED\n");
}

// ═══════════════════════════════════════════════════════════════════════════
// TEST 6: Provider manifestation (real SID → EntityId)
// ═══════════════════════════════════════════════════════════════════════════

static void test_provider_manifestation() {
    printf("[Test 6] Provider manifestation (real SID → EntityId)... ");
    
    ProviderRegistry registry;
    SID sid{1, 2, 3};
    
    Manifestation m = registry.manifest(sid, "test_entity");
    
    assert(m.is_valid);
    assert(m.scr_sid == sid);
    assert(m.entity_id > 0);
    assert(registry.size() == 1);
    printf("PASSED\n");
}

// ═══════════════════════════════════════════════════════════════════════════
// TEST 7: Bidirectional identity mapping
// ═══════════════════════════════════════════════════════════════════════════

static void test_bidirectional_mapping() {
    printf("[Test 7] Bidirectional identity mapping... ");
    
    ProviderRegistry registry;
    SID sid{10, 20, 30};
    
    Manifestation m = registry.manifest(sid, "entity");
    auto resolved = registry.resolve(m.entity_id);
    
    assert(resolved.has_value());
    assert(registry.validate(m, sid));
    printf("PASSED\n");
}

// ═══════════════════════════════════════════════════════════════════════════
// TEST 8: Full execution path (SCR → O3DE → execute → observe → SCR)
// ═══════════════════════════════════════════════════════════════════════════

static void test_full_execution_path() {
    printf("[Test 8] Full execution path (SCR → O3DE → execute → observe → SCR)... ");
    
    ProviderRegistry registry;
    SID sid{1, 2, 3};
    
    // 1. Manifest
    Manifestation m = registry.manifest(sid, "test");
    assert(m.is_valid);
    
    // 2. Current state
    SimilarityTransform current;
    current.scale = 1.0;
    current.rotation = Quat{1.0, 0.0, 0.0, 0.0};
    current.translation = Vec3{0.0, 0.0, 0.0};
    
    // 3. Operation: translate (1, 2, 3)
    SimilarityTransform operation;
    operation.scale = 1.0;
    operation.rotation = Quat{1.0, 0.0, 0.0, 0.0};
    operation.translation = Vec3{1.0, 2.0, 3.0};
    
    // 4. Execute (real O3DE math)
    Observation obs = execute_transform(m, operation, current);
    assert(obs.is_valid);
    
    // 5. Verify result
    assert(std::abs(obs.position.x - 1.0) < EPSILON);
    assert(std::abs(obs.position.y - 2.0) < EPSILON);
    assert(std::abs(obs.position.z - 3.0) < EPSILON);
    
    // 6. Map back to SCR
    SimilarityTransform result = observation_to_transform(obs);
    assert(std::abs(result.translation.x - 1.0) < EPSILON);
    assert(std::abs(result.translation.y - 2.0) < EPSILON);
    assert(std::abs(result.translation.z - 3.0) < EPSILON);
    
    printf("PASSED\n");
}

// ═══════════════════════════════════════════════════════════════════════════
// TEST 9: O3DE rotation (real math)
// ═══════════════════════════════════════════════════════════════════════════

static void test_o3de_rotation() {
    printf("[Test 9] O3DE rotation (real math)... ");
    
    // Rotate point (1,0,0) 90° around Y axis
    // SCR: +Z forward, +Y up, +X right
    // 90° around Y should map X→Z
    SimilarityTransform transform;
    transform.scale = 1.0;
    transform.rotation = Quat{0.7071, 0.0, 0.7071, 0.0}; // 90° around Y
    transform.translation = Vec3{0.0, 0.0, 0.0};
    
    AZ::Transform o3de_transform = scr_to_o3de(transform);
    
    AZ::Vector3 input(1.0f, 0.0f, 0.0f);
    AZ::Vector3 result = o3de_transform.TransformPoint(input);
    
    Vec3 scr_result = o3de_to_scr(result);
    
    // After 90° Y rotation: X→Z, Z→-X
    // Input (1,0,0) → should become approximately (0,0,1) in SCR
    assert(std::abs(scr_result.x) < 0.1);
    assert(std::abs(scr_result.y) < 0.1);
    assert(std::abs(scr_result.z - 1.0) < 0.1);
    printf("PASSED\n");
}

// ═══════════════════════════════════════════════════════════════════════════
// TEST 10: O3DE scale (real math)
// ═══════════════════════════════════════════════════════════════════════════

static void test_o3de_scale() {
    printf("[Test 10] O3DE scale (real math)... ");
    
    SimilarityTransform transform;
    transform.scale = 2.0;
    transform.rotation = Quat{1.0, 0.0, 0.0, 0.0};
    transform.translation = Vec3{0.0, 0.0, 0.0};
    
    AZ::Transform o3de_transform = scr_to_o3de(transform);
    
    AZ::Vector3 input(1.0f, 0.0f, 0.0f);
    AZ::Vector3 result = o3de_transform.TransformPoint(input);
    
    Vec3 scr_result = o3de_to_scr(result);
    assert(std::abs(scr_result.x - 2.0) < EPSILON);
    assert(std::abs(scr_result.y) < EPSILON);
    assert(std::abs(scr_result.z) < EPSILON);
    printf("PASSED\n");
}

// ═══════════════════════════════════════════════════════════════════════════
// TEST 11: Conformance - identity mapping verification
// ═══════════════════════════════════════════════════════════════════════════

static void test_conformance_identity() {
    printf("[Test 11] Conformance - identity mapping verification... ");
    
    ProviderRegistry registry;
    SID sid{100, 200, 300};
    
    Manifestation m = registry.manifest(sid, "conformance_test");
    bool valid = verify_identity_mapping(sid, m, registry);
    
    assert(valid);
    printf("PASSED\n");
}

// ═══════════════════════════════════════════════════════════════════════════
// TEST 12: Conformance - transform round-trip verification
// ═══════════════════════════════════════════════════════════════════════════

static void test_conformance_roundtrip() {
    printf("[Test 12] Conformance - transform round-trip verification... ");
    
    SimilarityTransform original;
    original.scale = 1.5;
    original.rotation = Quat{0.7071, 0.0, 0.7071, 0.0};
    original.translation = Vec3{1.0, 2.0, 3.0};
    
    // Convert to O3DE and back
    AZ::Transform o3de = scr_to_o3de(original);
    SimilarityTransform roundtrip = o3de_to_scr(o3de);
    
    bool valid = verify_transform_roundtrip(original, roundtrip);
    assert(valid);
    printf("PASSED\n");
}

// ═══════════════════════════════════════════════════════════════════════════
// TEST 13: Conformance - coordinate conversion preserves handedness
// ═══════════════════════════════════════════════════════════════════════════

static void test_conformance_handedness() {
    printf("[Test 13] Conformance - coordinate conversion preserves handedness... ");
    
    bool valid = verify_coordinate_conversion();
    assert(valid);
    printf("PASSED\n");
}

// ═══════════════════════════════════════════════════════════════════════════
// TEST 14: Failure - invalid manifestation
// ═══════════════════════════════════════════════════════════════════════════

static void test_failure_invalid_manifestation() {
    printf("[Test 14] Failure - invalid manifestation... ");
    
    Manifestation invalid;
    invalid.is_valid = false;
    
    SimilarityTransform op;
    SimilarityTransform current;
    
    Observation obs = execute_transform(invalid, op, current);
    assert(!obs.is_valid);
    assert(!obs.error.empty());
    printf("PASSED\n");
}

// ═══════════════════════════════════════════════════════════════════════════
// TEST 15: Failure - resolve nonexistent entity
// ═══════════════════════════════════════════════════════════════════════════

static void test_failure_resolve_nonexistent() {
    printf("[Test 15] Failure - resolve nonexistent entity... ");
    
    ProviderRegistry registry;
    auto resolved = registry.resolve(999999);
    
    assert(!resolved.has_value());
    printf("PASSED\n");
}

// ═══════════════════════════════════════════════════════════════════════════
// MAIN
// ═══════════════════════════════════════════════════════════════════════════

int main(void) {
    printf("============================================================\n");
    printf(" SCR O3DE Provider — Real Execution Tests\n");
    printf("============================================================\n\n");
    
    printf("--- Coordinate Conversion ---\n");
    test_coordinate_roundtrip();
    test_quaternion_roundtrip();
    test_transform_roundtrip();
    
    printf("\n--- O3DE Real Math ---\n");
    test_o3de_transform_composition();
    test_o3de_transform_point();
    test_o3de_rotation();
    test_o3de_scale();
    
    printf("\n--- Provider Operations ---\n");
    test_provider_manifestation();
    test_bidirectional_mapping();
    test_full_execution_path();
    
    printf("\n--- Conformance ---\n");
    test_conformance_identity();
    test_conformance_roundtrip();
    test_conformance_handedness();
    
    printf("\n--- Failure Paths ---\n");
    test_failure_invalid_manifestation();
    test_failure_resolve_nonexistent();
    
    printf("\n============================================================\n");
    printf(" All 15 O3DE Provider Tests PASSED\n");
    printf("============================================================\n\n");
    
    return 0;
}
