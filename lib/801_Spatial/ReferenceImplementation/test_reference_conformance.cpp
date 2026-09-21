/// @file test_reference_conformance.cpp
/// @brief Conformance tests for SCR reference implementation.

#include "scr_reference_implementation.h"
#include <cassert>
#include <iostream>
#include <cmath>

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
// 1. Identity Tests
// ═══════════════════════════════════════════════════════════════════════════

void test_sid_creation() {
    SID sid = create_sid(1, 1, 100);
    TEST_ASSERT(validate_sid(sid), "SID creation and validation");
}

void test_sid_equality() {
    SID sid1 = create_sid(1, 1, 100);
    SID sid2 = create_sid(1, 1, 100);
    SID sid3 = create_sid(1, 1, 200);
    
    TEST_ASSERT(sid1 == sid2, "SID equality");
    TEST_ASSERT(sid1 != sid3, "SID inequality");
}

void test_sid_invalid() {
    SID invalid = create_sid(1, 1, 0);
    TEST_ASSERT(!validate_sid(invalid), "Invalid SID (zero coordinate)");
}

// ═══════════════════════════════════════════════════════════════════════════
// 2. Transform Tests
// ═══════════════════════════════════════════════════════════════════════════

void test_identity_transform() {
    SimilarityTransform identity{};
    Vec3 point{1.0, 2.0, 3.0};
    Vec3 result = apply_transform(identity, point);
    
    TEST_ASSERT_NEAR(result.x, 1.0, 1e-9, "Identity transform X");
    TEST_ASSERT_NEAR(result.y, 2.0, 1e-9, "Identity transform Y");
    TEST_ASSERT_NEAR(result.z, 3.0, 1e-9, "Identity transform Z");
}

void test_scale_transform() {
    SimilarityTransform scale{2.0, Quat{}, Vec3{}};
    Vec3 point{1.0, 2.0, 3.0};
    Vec3 result = apply_transform(scale, point);
    
    TEST_ASSERT_NEAR(result.x, 2.0, 1e-9, "Scale transform X");
    TEST_ASSERT_NEAR(result.y, 4.0, 1e-9, "Scale transform Y");
    TEST_ASSERT_NEAR(result.z, 6.0, 1e-9, "Scale transform Z");
}

void test_translation_transform() {
    SimilarityTransform translate{1.0, Quat{}, Vec3{10.0, 20.0, 30.0}};
    Vec3 point{1.0, 2.0, 3.0};
    Vec3 result = apply_transform(translate, point);
    
    TEST_ASSERT_NEAR(result.x, 11.0, 1e-9, "Translation transform X");
    TEST_ASSERT_NEAR(result.y, 22.0, 1e-9, "Translation transform Y");
    TEST_ASSERT_NEAR(result.z, 33.0, 1e-9, "Translation transform Z");
}

void test_transform_composition() {
    SimilarityTransform t1{1.0, Quat{}, Vec3{1.0, 0.0, 0.0}};
    SimilarityTransform t2{1.0, Quat{}, Vec3{0.0, 1.0, 0.0}};
    
    SimilarityTransform composed = compose_transforms(t1, t2);
    
    Vec3 point{0.0, 0.0, 0.0};
    Vec3 result = apply_transform(composed, point);
    
    TEST_ASSERT_NEAR(result.x, 1.0, 1e-9, "Composition X");
    TEST_ASSERT_NEAR(result.y, 1.0, 1e-9, "Composition Y");
    TEST_ASSERT_NEAR(result.z, 0.0, 1e-9, "Composition Z");
}

void test_transform_inversion() {
    SimilarityTransform original{2.0, Quat{}, Vec3{1.0, 2.0, 3.0}};
    SimilarityTransform inverse = invert_transform(original);
    
    SimilarityTransform composed = compose_transforms(original, inverse);
    
    Vec3 point{1.0, 1.0, 1.0};
    Vec3 result = apply_transform(composed, point);
    
    TEST_ASSERT_NEAR(result.x, 1.0, 1e-9, "Inversion roundtrip X");
    TEST_ASSERT_NEAR(result.y, 1.0, 1e-9, "Inversion roundtrip Y");
    TEST_ASSERT_NEAR(result.z, 1.0, 1e-9, "Inversion roundtrip Z");
}

// ═══════════════════════════════════════════════════════════════════════════
// 3. Entity Tests
// ═══════════════════════════════════════════════════════════════════════════

void test_entity_creation() {
    SID sid = create_sid(1, 1, 100);
    SemanticEntity entity = create_entity("TestEntity", sid);
    
    TEST_ASSERT(validate_entity(entity), "Entity creation and validation");
    TEST_ASSERT(entity.name == "TestEntity", "Entity name");
    TEST_ASSERT(entity.state == EntityState::Created, "Entity initial state");
}

void test_entity_state_transitions() {
    SID sid = create_sid(1, 1, 100);
    SemanticEntity entity = create_entity("TestEntity", sid);
    
    TEST_ASSERT(transition_state(entity, EntityState::Active), "Created -> Active");
    TEST_ASSERT(entity.state == EntityState::Active, "State is Active");
    
    TEST_ASSERT(transition_state(entity, EntityState::Suspended), "Active -> Suspended");
    TEST_ASSERT(entity.state == EntityState::Suspended, "State is Suspended");
    
    TEST_ASSERT(transition_state(entity, EntityState::Active), "Suspended -> Active");
    TEST_ASSERT(entity.state == EntityState::Active, "State is Active again");
    
    TEST_ASSERT(transition_state(entity, EntityState::Destroyed), "Active -> Destroyed");
    TEST_ASSERT(entity.state == EntityState::Destroyed, "State is Destroyed");
}

void test_entity_invalid_transitions() {
    SID sid = create_sid(1, 1, 100);
    SemanticEntity entity = create_entity("TestEntity", sid);
    
    TEST_ASSERT(!transition_state(entity, EntityState::Suspended), "Created -> Suspended (invalid)");
    TEST_ASSERT(!transition_state(entity, EntityState::Destroyed), "Created -> Destroyed (invalid)");
    TEST_ASSERT(!transition_state(entity, EntityState::Created), "Created -> Created (invalid)");
}

// ═══════════════════════════════════════════════════════════════════════════
// 4. Manifestation Tests
// ═══════════════════════════════════════════════════════════════════════════

void test_manifestation() {
    SID sid = create_sid(1, 1, 100);
    SemanticEntity entity = create_entity("TestEntity", sid);
    
    Manifestation m = manifest_entity(entity);
    
    TEST_ASSERT(validate_manifestation(m, sid), "Manifestation validates SID");
    TEST_ASSERT(m.is_valid, "Manifestation is valid");
    TEST_ASSERT(m.provider_id.provider_name == "ReferenceProvider", "Provider name");
}

void test_reverse_mapping() {
    SID sid = create_sid(1, 1, 100);
    SemanticEntity entity = create_entity("TestEntity", sid);
    
    Manifestation m = manifest_entity(entity);
    auto resolved = resolve_manifestation(m.provider_id);
    
    TEST_ASSERT(resolved.has_value(), "Reverse mapping resolves");
    TEST_ASSERT(*resolved == sid, "Reverse mapping returns correct SID");
}

void test_reverse_mapping_invalid() {
    ProviderID invalid{99999, "NonExistentProvider"};
    auto resolved = resolve_manifestation(invalid);
    
    TEST_ASSERT(!resolved.has_value(), "Invalid provider ID returns no value");
}

// ═══════════════════════════════════════════════════════════════════════════
// 5. Execution Tests
// ═══════════════════════════════════════════════════════════════════════════

void test_execute_transform() {
    SID sid = create_sid(1, 1, 100);
    SemanticEntity entity = create_entity("TestEntity", sid);
    Manifestation m = manifest_entity(entity);
    
    SimilarityTransform op{1.0, Quat{}, Vec3{5.0, 10.0, 15.0}};
    Observation obs = execute_transform(m, op);
    
    TEST_ASSERT(obs.is_valid, "Execution produces valid observation");
    TEST_ASSERT_NEAR(obs.position.x, 5.0, 1e-9, "Execution position X");
    TEST_ASSERT_NEAR(obs.position.y, 10.0, 1e-9, "Execution position Y");
    TEST_ASSERT_NEAR(obs.position.z, 15.0, 1e-9, "Execution position Z");
}

void test_observe_entity() {
    SID sid = create_sid(1, 1, 100);
    SemanticEntity entity = create_entity("TestEntity", sid);
    Manifestation m = manifest_entity(entity);
    
    Observation obs = observe_entity(m);
    
    TEST_ASSERT(obs.is_valid, "Observation is valid");
}

void test_observation_mapping() {
    Observation obs{Vec3{1.0, 2.0, 3.0}, Quat{}, 1.0, true, ""};
    SimilarityTransform transform = observation_to_transform(obs);
    
    TEST_ASSERT_NEAR(transform.translation.x, 1.0, 1e-9, "Observation mapping X");
    TEST_ASSERT_NEAR(transform.translation.y, 2.0, 1e-9, "Observation mapping Y");
    TEST_ASSERT_NEAR(transform.translation.z, 3.0, 1e-9, "Observation mapping Z");
}

// ═══════════════════════════════════════════════════════════════════════════
// 6. Conformance Tests
// ═══════════════════════════════════════════════════════════════════════════

void test_conformance_check() {
    SID sid = create_sid(1, 1, 100);
    SemanticEntity entity = create_entity("TestEntity", sid);
    entity.state = EntityState::Active;
    
    Manifestation m = manifest_entity(entity);
    Observation obs = observe_entity(m);
    
    TEST_ASSERT(run_conformance_check(entity, m, obs), "Full conformance check passes");
}

void test_transform_roundtrip() {
    SimilarityTransform original{2.0, Quat{}, Vec3{1.0, 2.0, 3.0}};
    
    SID sid = create_sid(1, 1, 100);
    SemanticEntity entity = create_entity("TestEntity", sid);
    Manifestation m = manifest_entity(entity);
    
    Observation obs = execute_transform(m, original);
    SimilarityTransform observed = observation_to_transform(obs);
    
    TEST_ASSERT(verify_transform_roundtrip(original, observed), "Transform roundtrip verification");
}

void test_identity_mapping_verification() {
    SID sid = create_sid(1, 1, 100);
    SemanticEntity entity = create_entity("TestEntity", sid);
    Manifestation m = manifest_entity(entity);
    
    TEST_ASSERT(verify_identity_mapping(entity, m), "Identity mapping verification");
}

// ═══════════════════════════════════════════════════════════════════════════
// 7. Failure Tests
// ═══════════════════════════════════════════════════════════════════════════

void test_invalid_manifestation_execution() {
    Manifestation invalid{SID{}, ProviderID{0, ""}, false};
    SimilarityTransform op{};
    
    Observation obs = execute_transform(invalid, op);
    
    TEST_ASSERT(!obs.is_valid, "Invalid manifestation produces invalid observation");
    TEST_ASSERT(!obs.error.empty(), "Invalid manifestation produces error message");
}

void test_error_strings() {
    TEST_ASSERT(std::string(error_string(ErrorCode::Success)) == "Success", "Error string Success");
    TEST_ASSERT(std::string(error_string(ErrorCode::InvalidSID)) == "Invalid SID", "Error string InvalidSID");
    TEST_ASSERT(std::string(error_string(ErrorCode::ConformanceViolation)) == "Conformance violation", "Error string ConformanceViolation");
}

// ═══════════════════════════════════════════════════════════════════════════
// Main
// ═══════════════════════════════════════════════════════════════════════════

int main() {
    std::cout << "=== SCR Reference Implementation Conformance Tests ===" << std::endl;
    std::cout << std::endl;
    
    // Identity tests
    std::cout << "--- Identity Tests ---" << std::endl;
    test_sid_creation();
    test_sid_equality();
    test_sid_invalid();
    std::cout << std::endl;
    
    // Transform tests
    std::cout << "--- Transform Tests ---" << std::endl;
    test_identity_transform();
    test_scale_transform();
    test_translation_transform();
    test_transform_composition();
    test_transform_inversion();
    std::cout << std::endl;
    
    // Entity tests
    std::cout << "--- Entity Tests ---" << std::endl;
    test_entity_creation();
    test_entity_state_transitions();
    test_entity_invalid_transitions();
    std::cout << std::endl;
    
    // Manifestation tests
    std::cout << "--- Manifestation Tests ---" << std::endl;
    test_manifestation();
    test_reverse_mapping();
    test_reverse_mapping_invalid();
    std::cout << std::endl;
    
    // Execution tests
    std::cout << "--- Execution Tests ---" << std::endl;
    test_execute_transform();
    test_observe_entity();
    test_observation_mapping();
    std::cout << std::endl;
    
    // Conformance tests
    std::cout << "--- Conformance Tests ---" << std::endl;
    test_conformance_check();
    test_transform_roundtrip();
    test_identity_mapping_verification();
    std::cout << std::endl;
    
    // Failure tests
    std::cout << "--- Failure Tests ---" << std::endl;
    test_invalid_manifestation_execution();
    test_error_strings();
    std::cout << std::endl;
    
    // Summary
    std::cout << "=== Summary ===" << std::endl;
    std::cout << "Passed: " << tests_passed << std::endl;
    std::cout << "Failed: " << tests_failed << std::endl;
    std::cout << "Total:  " << (tests_passed + tests_failed) << std::endl;
    
    return tests_failed > 0 ? 1 : 0;
}
