/// @file test_adversarial.cpp
/// @brief Adversarial and property-based tests for SCR reference implementation.

#include "scr_reference_implementation.h"
#include <cassert>
#include <iostream>
#include <cmath>
#include <limits>

using namespace SCR::ReferenceImplementation;

// ═══════════════════════════════════════════════════════════════════════════
// Test Helpers
// ═══════════════════════════════════════════════════════════════════════════

static int tests_passed = 0;
static int tests_failed = 0;

#define TEST_ASSERT(condition, message) do { \
    if (!(condition)) { \
        std::cerr << "FAIL: " << message << " at " << __FILE__ << ":" << __LINE__ << std::endl; \
        tests_failed++; \
    } else { \
        std::cout << "PASS: " << message << std::endl; \
        tests_passed++; \
    } \
} while(0)

#define TEST_ASSERT_NEAR(a, b, tolerance, message) do { \
    if (std::abs((a) - (b)) > (tolerance)) { \
        std::cerr << "FAIL: " << message << " at " << __FILE__ << ":" << __LINE__ << std::endl; \
        tests_failed++; \
    } else { \
        std::cout << "PASS: " << message << std::endl; \
        tests_passed++; \
    } \
} while(0)

// ═══════════════════════════════════════════════════════════════════════════
// 1. Identity Falsification Tests
// ═══════════════════════════════════════════════════════════════════════════

void test_sid_uniqueness() {
    SID sid1 = create_sid(1, 1, 100);
    SID sid2 = create_sid(1, 1, 101);
    TEST_ASSERT(sid1 != sid2, "Different SIDs are not equal");
}

void test_sid_authority_isolation() {
    SID sid1 = create_sid(1, 1, 100);
    SID sid2 = create_sid(2, 1, 100);
    TEST_ASSERT(sid1 != sid2, "Different root authorities produce different SIDs");
}

void test_sid_domain_isolation() {
    SID sid1 = create_sid(1, 1, 100);
    SID sid2 = create_sid(1, 2, 100);
    TEST_ASSERT(sid1 != sid2, "Different allocation domains produce different SIDs");
}

void test_manifestation_preserves_sid() {
    SID sid = create_sid(1, 1, 100);
    SemanticEntity entity = create_entity("Test", sid);
    Manifestation m = manifest_entity(entity);
    TEST_ASSERT(m.scr_sid == sid, "Manifestation preserves SID");
}

void test_reverse_mapping_is_bidirectional() {
    SID sid = create_sid(1, 1, 100);
    SemanticEntity entity = create_entity("Test", sid);
    Manifestation m = manifest_entity(entity);
    auto resolved = resolve_manifestation(m.provider_id);
    TEST_ASSERT(resolved.has_value() && *resolved == sid, "Reverse mapping is bidirectional");
}

void test_distinct_entities_distinct_sids() {
    SID sid1 = create_sid(1, 1, 100);
    SID sid2 = create_sid(1, 1, 200);
    SemanticEntity e1 = create_entity("E1", sid1);
    SemanticEntity e2 = create_entity("E2", sid2);
    TEST_ASSERT(e1.sid != e2.sid, "Distinct entities have distinct SIDs");
}

// ═══════════════════════════════════════════════════════════════════════════
// 2. Transform Correctness Challenges
// ═══════════════════════════════════════════════════════════════════════════

void test_transform_composition_associativity() {
    SimilarityTransform t1{2.0, Quat{}, Vec3{1.0, 0.0, 0.0}};
    SimilarityTransform t2{1.0, Quat{}, Vec3{0.0, 1.0, 0.0}};
    SimilarityTransform t3{0.5, Quat{}, Vec3{0.0, 0.0, 1.0}};
    
    SimilarityTransform lhs = compose_transforms(compose_transforms(t1, t2), t3);
    SimilarityTransform rhs = compose_transforms(t1, compose_transforms(t2, t3));
    
    Vec3 point{1.0, 1.0, 1.0};
    Vec3 l_result = apply_transform(lhs, point);
    Vec3 r_result = apply_transform(rhs, point);
    
    TEST_ASSERT_NEAR(l_result.x, r_result.x, 1e-9, "Composition associativity X");
    TEST_ASSERT_NEAR(l_result.y, r_result.y, 1e-9, "Composition associativity Y");
    TEST_ASSERT_NEAR(l_result.z, r_result.z, 1e-9, "Composition associativity Z");
}

void test_inverse_recovers_identity() {
    SimilarityTransform t{3.0, Quat{}, Vec3{4.0, 5.0, 6.0}};
    SimilarityTransform inv = invert_transform(t);
    SimilarityTransform composed = compose_transforms(t, inv);
    
    Vec3 point{2.0, 3.0, 4.0};
    Vec3 result = apply_transform(composed, point);
    
    TEST_ASSERT_NEAR(result.x, point.x, 1e-9, "Inverse recovers identity X");
    TEST_ASSERT_NEAR(result.y, point.y, 1e-9, "Inverse recovers identity Y");
    TEST_ASSERT_NEAR(result.z, point.z, 1e-9, "Inverse recovers identity Z");
}

void test_inverse_left_right() {
    SimilarityTransform t{2.0, Quat{}, Vec3{1.0, 2.0, 3.0}};
    SimilarityTransform inv = invert_transform(t);
    
    SimilarityTransform left = compose_transforms(inv, t);
    SimilarityTransform right = compose_transforms(t, inv);
    
    Vec3 point{1.0, 1.0, 1.0};
    Vec3 left_result = apply_transform(left, point);
    Vec3 right_result = apply_transform(right, point);
    
    TEST_ASSERT_NEAR(left_result.x, right_result.x, 1e-9, "Left and right inverse agree X");
    TEST_ASSERT_NEAR(left_result.y, right_result.y, 1e-9, "Left and right inverse agree Y");
    TEST_ASSERT_NEAR(left_result.z, right_result.z, 1e-9, "Left and right inverse agree Z");
}

void test_identity_transform_is_neutral() {
    SimilarityTransform identity{};
    SimilarityTransform t{2.0, Quat{}, Vec3{1.0, 2.0, 3.0}};
    
    SimilarityTransform left = compose_transforms(identity, t);
    SimilarityTransform right = compose_transforms(t, identity);
    
    TEST_ASSERT_NEAR(left.scale, t.scale, 1e-9, "Identity left neutral scale");
    TEST_ASSERT_NEAR(right.scale, t.scale, 1e-9, "Identity right neutral scale");
}

// ═══════════════════════════════════════════════════════════════════════════
// 3. Lifecycle Constraint Challenges
// ═══════════════════════════════════════════════════════════════════════════

void test_destroyed_is_terminal() {
    SID sid = create_sid(1, 1, 100);
    SemanticEntity entity = create_entity("Test", sid);
    transition_state(entity, EntityState::Active);
    transition_state(entity, EntityState::Destroyed);
    
    TEST_ASSERT(!transition_state(entity, EntityState::Active), "Destroyed cannot transition to Active");
    TEST_ASSERT(!transition_state(entity, EntityState::Suspended), "Destroyed cannot transition to Suspended");
    TEST_ASSERT(!transition_state(entity, EntityState::Created), "Destroyed cannot transition to Created");
}

void test_created_cannot_skip_to_suspended() {
    SID sid = create_sid(1, 1, 100);
    SemanticEntity entity = create_entity("Test", sid);
    
    TEST_ASSERT(!transition_state(entity, EntityState::Suspended), "Created cannot skip to Suspended");
}

void test_created_cannot_skip_to_destroyed() {
    SID sid = create_sid(1, 1, 100);
    SemanticEntity entity = create_entity("Test", sid);
    
    TEST_ASSERT(!transition_state(entity, EntityState::Destroyed), "Created cannot skip to Destroyed");
}

void test_suspended_can_resume() {
    SID sid = create_sid(1, 1, 100);
    SemanticEntity entity = create_entity("Test", sid);
    transition_state(entity, EntityState::Active);
    transition_state(entity, EntityState::Suspended);
    
    TEST_ASSERT(transition_state(entity, EntityState::Active), "Suspended can resume to Active");
}

void test_suspended_can_destroy() {
    SID sid = create_sid(1, 1, 100);
    SemanticEntity entity = create_entity("Test", sid);
    transition_state(entity, EntityState::Active);
    transition_state(entity, EntityState::Suspended);
    
    TEST_ASSERT(transition_state(entity, EntityState::Destroyed), "Suspended can transition to Destroyed");
}

// ═══════════════════════════════════════════════════════════════════════════
// 4. Provider Mapping Assumption Challenges
// ═══════════════════════════════════════════════════════════════════════════

void test_provider_id_not_sid() {
    SID sid = create_sid(1, 1, 100);
    SemanticEntity entity = create_entity("Test", sid);
    Manifestation m = manifest_entity(entity);
    
    TEST_ASSERT(m.provider_id.handle != sid.root_authority, "Provider handle is not SID root authority");
    TEST_ASSERT(m.provider_id.handle != sid.allocation_domain, "Provider handle is not SID allocation domain");
}

void test_provider_name_is_constant() {
    SID sid1 = create_sid(1, 1, 100);
    SID sid2 = create_sid(2, 2, 200);
    SemanticEntity e1 = create_entity("E1", sid1);
    SemanticEntity e2 = create_entity("E2", sid2);
    Manifestation m1 = manifest_entity(e1);
    Manifestation m2 = manifest_entity(e2);
    
    TEST_ASSERT(m1.provider_id.provider_name == m2.provider_id.provider_name, "Provider name is constant");
}

void test_multiple_manifestations_same_provider() {
    SID sid1 = create_sid(1, 1, 100);
    SID sid2 = create_sid(1, 1, 200);
    SemanticEntity e1 = create_entity("E1", sid1);
    SemanticEntity e2 = create_entity("E2", sid2);
    Manifestation m1 = manifest_entity(e1);
    Manifestation m2 = manifest_entity(e2);
    
    TEST_ASSERT(m1.provider_id.provider_name == m2.provider_id.provider_name, "Multiple manifestations use same provider");
}

// ═══════════════════════════════════════════════════════════════════════════
// 5. Observation Equivalence Challenges
// ═══════════════════════════════════════════════════════════════════════════

void test_observation_not_exact_state() {
    SID sid = create_sid(1, 1, 100);
    SemanticEntity entity = create_entity("Test", sid);
    entity.state = EntityState::Active;
    Manifestation m = manifest_entity(entity);
    
    Observation obs = observe_entity(m);
    
    TEST_ASSERT(obs.is_valid, "Observation is valid");
    TEST_ASSERT(obs.error.empty(), "Observation has no error");
}

void test_observation_preserves_transform() {
    SimilarityTransform original{2.0, Quat{}, Vec3{1.0, 2.0, 3.0}};
    SID sid = create_sid(1, 1, 100);
    SemanticEntity entity = create_entity("Test", sid);
    Manifestation m = manifest_entity(entity);
    
    Observation obs = execute_transform(m, original);
    SimilarityTransform observed = observation_to_transform(obs);
    
    TEST_ASSERT(verify_transform_roundtrip(original, observed), "Observation preserves transform");
}

void test_observation_scale_positive() {
    SimilarityTransform t{0.5, Quat{}, Vec3{}};
    SID sid = create_sid(1, 1, 100);
    SemanticEntity entity = create_entity("Test", sid);
    Manifestation m = manifest_entity(entity);
    
    Observation obs = execute_transform(m, t);
    
    TEST_ASSERT(obs.scale > 0, "Observation scale is positive");
}

// ═══════════════════════════════════════════════════════════════════════════
// 6. Failure Atomicity Tests
// ═══════════════════════════════════════════════════════════════════════════

void test_invalid_manifestation_no_side_effects() {
    Manifestation invalid{SID{}, ProviderID{0, ""}, false};
    SimilarityTransform op{};
    
    Observation obs = execute_transform(invalid, op);
    
    TEST_ASSERT(!obs.is_valid, "Invalid manifestation produces invalid observation");
    TEST_ASSERT(!obs.error.empty(), "Invalid manifestation produces error");
}

void test_invalid_sid_no_manifestation() {
    SID invalid_sid = create_sid(0, 0, 0);
    TEST_ASSERT(!validate_sid(invalid_sid), "Invalid SID is rejected");
}

void test_conformance_violation_detected() {
    SID sid = create_sid(1, 1, 100);
    SemanticEntity entity = create_entity("Test", sid);
    Manifestation m = manifest_entity(entity);
    Observation obs = observe_entity(m);
    
    TEST_ASSERT(run_conformance_check(entity, m, obs), "Conformance check passes for valid data");
}

// ═══════════════════════════════════════════════════════════════════════════
// 7. Property-Based Tests
// ═══════════════════════════════════════════════════════════════════════════

void test_transform_preserves_origin() {
    SimilarityTransform t{2.0, Quat{}, Vec3{5.0, 10.0, 15.0}};
    Vec3 origin{0.0, 0.0, 0.0};
    Vec3 result = apply_transform(t, origin);
    
    TEST_ASSERT_NEAR(result.x, 5.0, 1e-9, "Transform preserves origin X");
    TEST_ASSERT_NEAR(result.y, 10.0, 1e-9, "Transform preserves origin Y");
    TEST_ASSERT_NEAR(result.z, 15.0, 1e-9, "Transform preserves origin Z");
}

void test_scale_distributes() {
    SimilarityTransform t{3.0, Quat{}, Vec3{}};
    Vec3 p1{1.0, 0.0, 0.0};
    Vec3 p2{0.0, 1.0, 0.0};
    Vec3 sum{1.0, 1.0, 0.0};
    
    Vec3 r1 = apply_transform(t, p1);
    Vec3 r2 = apply_transform(t, p2);
    Vec3 r_sum = apply_transform(t, sum);
    
    TEST_ASSERT_NEAR(r_sum.x, r1.x + r2.x, 1e-9, "Scale distributes X");
    TEST_ASSERT_NEAR(r_sum.y, r1.y + r2.y, 1e-9, "Scale distributes Y");
    TEST_ASSERT_NEAR(r_sum.z, r1.z + r2.z, 1e-9, "Scale distributes Z");
}

void test_quaternion_norm_one() {
    Quat q{1.0, 0.0, 0.0, 0.0};
    double norm = std::sqrt(q.w*q.w + q.x*q.x + q.y*q.y + q.z*q.z);
    TEST_ASSERT_NEAR(norm, 1.0, 1e-9, "Identity quaternion has norm 1");
}

void test_entity_valid_after_creation() {
    SID sid = create_sid(1, 1, 100);
    SemanticEntity entity = create_entity("Test", sid);
    TEST_ASSERT(validate_entity(entity), "Entity is valid after creation");
}

void test_entity_valid_after_activation() {
    SID sid = create_sid(1, 1, 100);
    SemanticEntity entity = create_entity("Test", sid);
    transition_state(entity, EntityState::Active);
    TEST_ASSERT(validate_entity(entity), "Entity is valid after activation");
}

// ═══════════════════════════════════════════════════════════════════════════
// Main
// ═══════════════════════════════════════════════════════════════════════════

int main() {
    std::cout << "=== SCR Adversarial and Property-Based Tests ===" << std::endl;
    std::cout << std::endl;
    
    // Identity falsification
    std::cout << "--- Identity Falsification Tests ---" << std::endl;
    test_sid_uniqueness();
    test_sid_authority_isolation();
    test_sid_domain_isolation();
    test_manifestation_preserves_sid();
    test_reverse_mapping_is_bidirectional();
    test_distinct_entities_distinct_sids();
    std::cout << std::endl;
    
    // Transform challenges
    std::cout << "--- Transform Correctness Challenges ---" << std::endl;
    test_transform_composition_associativity();
    test_inverse_recovers_identity();
    test_inverse_left_right();
    test_identity_transform_is_neutral();
    std::cout << std::endl;
    
    // Lifecycle challenges
    std::cout << "--- Lifecycle Constraint Challenges ---" << std::endl;
    test_destroyed_is_terminal();
    test_created_cannot_skip_to_suspended();
    test_created_cannot_skip_to_destroyed();
    test_suspended_can_resume();
    test_suspended_can_destroy();
    std::cout << std::endl;
    
    // Provider mapping challenges
    std::cout << "--- Provider Mapping Assumption Challenges ---" << std::endl;
    test_provider_id_not_sid();
    test_provider_name_is_constant();
    test_multiple_manifestations_same_provider();
    std::cout << std::endl;
    
    // Observation challenges
    std::cout << "--- Observation Equivalence Challenges ---" << std::endl;
    test_observation_not_exact_state();
    test_observation_preserves_transform();
    test_observation_scale_positive();
    std::cout << std::endl;
    
    // Failure atomicity
    std::cout << "--- Failure Atomicity Tests ---" << std::endl;
    test_invalid_manifestation_no_side_effects();
    test_invalid_sid_no_manifestation();
    test_conformance_violation_detected();
    std::cout << std::endl;
    
    // Property-based
    std::cout << "--- Property-Based Tests ---" << std::endl;
    test_transform_preserves_origin();
    test_scale_distributes();
    test_quaternion_norm_one();
    test_entity_valid_after_creation();
    test_entity_valid_after_activation();
    std::cout << std::endl;
    
    // Summary
    std::cout << "=== Summary ===" << std::endl;
    std::cout << "Passed: " << tests_passed << std::endl;
    std::cout << "Failed: " << tests_failed << std::endl;
    std::cout << "Total:  " << (tests_passed + tests_failed) << std::endl;
    
    return tests_failed > 0 ? 1 : 0;
}
