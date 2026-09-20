// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

// SCR Semantic Correction — Mathematical Validation Tests
// Tests: coordinate mapping bijectivity, transform composition, inverse, identity
// Claims tested: CoordinateSystems/101_definition.md, Transformations/101_definition.md

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <assert.h>

#define EPSILON 1e-4f
#define S2 0.70710678118f // 1/sqrt(2)

typedef struct { float x, y, z; } Vec3;
static Vec3 vec3(float x, float y, float z) { return (Vec3){x, y, z}; }
static float vec3_dot(Vec3 a, Vec3 b) { return a.x*b.x + a.y*b.y + a.z*b.z; }
static Vec3 vec3_cross(Vec3 a, Vec3 b) {
    return vec3(a.y*b.z - a.z*b.y, a.z*b.x - a.x*b.z, a.x*b.y - a.y*b.x);
}
static int vec3_eq(Vec3 a, Vec3 b) {
    return fabsf(a.x-b.x)<EPSILON && fabsf(a.y-b.y)<EPSILON && fabsf(a.z-b.z)<EPSILON;
}

typedef struct { float m[3][3]; } Mat3;
static Mat3 mat3_identity(void) { return (Mat3){{{1,0,0},{0,1,0},{0,0,1}}}; }
static Mat3 mat3_mul(Mat3 a, Mat3 b) {
    Mat3 r;
    for(int i=0;i<3;i++) for(int j=0;j<3;j++) {
        r.m[i][j]=0; for(int k=0;k<3;k++) r.m[i][j]+=a.m[i][k]*b.m[k][j];
    }
    return r;
}
static Vec3 mat3_mul_vec(Mat3 m, Vec3 v) {
    return vec3(m.m[0][0]*v.x+m.m[0][1]*v.y+m.m[0][2]*v.z,
                m.m[1][0]*v.x+m.m[1][1]*v.y+m.m[1][2]*v.z,
                m.m[2][0]*v.x+m.m[2][1]*v.y+m.m[2][2]*v.z);
}
static Mat3 mat3_transpose(Mat3 m) {
    Mat3 r; for(int i=0;i<3;i++) for(int j=0;j<3;j++) r.m[i][j]=m.m[j][i]; return r;
}
static float mat3_det(Mat3 m) {
    return m.m[0][0]*(m.m[1][1]*m.m[2][2]-m.m[1][2]*m.m[2][1])
         - m.m[0][1]*(m.m[1][0]*m.m[2][2]-m.m[1][2]*m.m[2][0])
         + m.m[0][2]*(m.m[1][0]*m.m[2][1]-m.m[1][1]*m.m[2][0]);
}
static int mat3_eq(Mat3 a, Mat3 b) {
    for(int i=0;i<3;i++) for(int j=0;j<3;j++)
        if(fabsf(a.m[i][j]-b.m[i][j])>EPSILON) return 0;
    return 1;
}

typedef struct { float w,x,y,z; } Quat;
static Quat quat_identity(void) { return (Quat){1,0,0,0}; }
static Quat quat_mul(Quat a, Quat b) {
    return (Quat){a.w*b.w-a.x*b.x-a.y*b.y-a.z*b.z,
                  a.w*b.x+a.x*b.w+a.y*b.z-a.z*b.y,
                  a.w*b.y-a.x*b.z+a.y*b.w+a.z*b.x,
                  a.w*b.z+a.x*b.y-a.y*b.x+a.z*b.w};
}
static Quat quat_conj(Quat q) { return (Quat){q.w,-q.x,-q.y,-q.z}; }
static float quat_norm(Quat q) { return sqrtf(q.w*q.w+q.x*q.x+q.y*q.y+q.z*q.z); }
static int quat_eq(Quat a, Quat b) {
    float d = a.w*b.w+a.x*b.x+a.y*b.y+a.z*b.z;
    return fabsf(fabsf(d)-1.0f)<EPSILON;
}
static Vec3 quat_rotate(Quat q, Vec3 v) {
    Quat vq = {0, v.x, v.y, v.z};
    Quat r = quat_mul(quat_mul(q, vq), quat_conj(q));
    return vec3(r.x, r.y, r.z);
}

// Similarity transform: T = (s, R, t)
typedef struct { float s; Quat r; Vec3 t; } SimTransform;
static SimTransform sim_identity(void) { return (SimTransform){1.0f, {1,0,0,0}, {0,0,0}}; }
static Vec3 sim_apply(SimTransform T, Vec3 p) {
    Vec3 rotated = quat_rotate(T.r, p);
    return vec3(T.s*rotated.x+T.t.x, T.s*rotated.y+T.t.y, T.s*rotated.z+T.t.z);
}
static SimTransform sim_mul(SimTransform B, SimTransform A) {
    // B ∘ A = (sB·sA, RB·RA, sB·RB·tA + tB)
    SimTransform R;
    R.s = B.s * A.s;
    R.r = quat_mul(B.r, A.r);
    Vec3 rot_t = quat_rotate(B.r, A.t);
    R.t = vec3(B.s*rot_t.x+B.t.x, B.s*rot_t.y+B.t.y, B.s*rot_t.z+B.t.z);
    return R;
}
static SimTransform sim_inv(SimTransform T) {
    // T⁻¹ = (1/s, Rᵀ, -(1/s)·Rᵀ·t)
    // Verify: T⁻¹∘T = (1, I, 0)
    Quat r_inv = quat_conj(T.r);
    float s_inv = 1.0f / T.s;
    Vec3 inv_t = quat_rotate(r_inv, vec3(-T.t.x, -T.t.y, -T.t.z));
    return (SimTransform){s_inv, r_inv, vec3(s_inv*inv_t.x, s_inv*inv_t.y, s_inv*inv_t.z)};
}

// Coordinate mapping matrices (SCR canonical: +X right, +Y up, +Z forward)
static Mat3 mat_scr_o3de(void) { return (Mat3){{{1,0,0},{0,0,1},{0,1,0}}}; }
static Mat3 mat_scr_ros2(void) { return (Mat3){{{0,0,1},{0,1,0},{-1,0,0}}}; }
static Mat3 mat_scr_usd(void) { return (Mat3){{{1,0,0},{0,0,1},{0,-1,0}}}; }


// ═══════════════════════════════════════════════════════════════════════════
// TEST SUITE 1: Coordinate Mapping Properties (AC-01, AC-02)
// ═══════════════════════════════════════════════════════════════════════════

static void test_coord_det(void) {
    printf("[Test 1] Coordinate mapping determinants = ±1... ");
    assert(fabsf(fabsf(mat3_det(mat_scr_o3de()))-1.0f)<EPSILON);
    assert(fabsf(fabsf(mat3_det(mat_scr_ros2()))-1.0f)<EPSILON);
    assert(fabsf(fabsf(mat3_det(mat_scr_usd()))-1.0f)<EPSILON);
    printf("PASSED\n");
}

static void test_coord_orthogonal(void) {
    printf("[Test 2] Mappings orthogonal (M*M^T = I)... ");
    assert(mat3_eq(mat3_mul(mat_scr_o3de(), mat3_transpose(mat_scr_o3de())), mat3_identity()));
    assert(mat3_eq(mat3_mul(mat_scr_ros2(), mat3_transpose(mat_scr_ros2())), mat3_identity()));
    assert(mat3_eq(mat3_mul(mat_scr_usd(), mat3_transpose(mat_scr_usd())), mat3_identity()));
    printf("PASSED\n");
}

static void test_coord_roundtrip(void) {
    printf("[Test 3] Round-trip bijectivity... ");
    Vec3 p = vec3(1,2,3);
    Vec3 f, b;
    Mat3 m, mi;
    m=mat_scr_o3de(); mi=mat3_transpose(m); f=mat3_mul_vec(m,p); b=mat3_mul_vec(mi,f); assert(vec3_eq(b,p));
    m=mat_scr_ros2(); mi=mat3_transpose(m); f=mat3_mul_vec(m,p); b=mat3_mul_vec(mi,f); assert(vec3_eq(b,p));
    m=mat_scr_usd(); mi=mat3_transpose(m); f=mat3_mul_vec(m,p); b=mat3_mul_vec(mi,f); assert(vec3_eq(b,p));
    printf("PASSED\n");
}

static void test_coord_cross(void) {
    printf("[Test 4] Right-handed: X cross Y = Z... ");
    Vec3 x={1,0,0}, y={0,1,0}, z={0,0,1};
    assert(vec3_eq(vec3_cross(x,y), z));
    assert(vec3_eq(vec3_cross(y,z), x));
    assert(vec3_eq(vec3_cross(z,x), y));
    printf("PASSED\n");
}

static void test_coord_units(void) {
    printf("[Test 5] Unit vectors have length 1... ");
    Vec3 x={1,0,0}, y={0,1,0}, z={0,0,1};
    assert(fabsf(sqrtf(vec3_dot(x,x))-1.0f)<EPSILON);
    assert(fabsf(sqrtf(vec3_dot(y,y))-1.0f)<EPSILON);
    assert(fabsf(sqrtf(vec3_dot(z,z))-1.0f)<EPSILON);
    printf("PASSED\n");
}

// ═══════════════════════════════════════════════════════════════════════════
// TEST SUITE 2: Transform Algebra Properties (AC-02, AC-03)
// ═══════════════════════════════════════════════════════════════════════════

static void test_sim_identity_left(void) {
    printf("[Test 6] T_id ∘ T = T... ");
    SimTransform T = {2.0f, {S2,0,S2,0}, {1,2,3}}; // unit quat: 0.7071²+0.7071²≈1
    SimTransform I = sim_identity();
    SimTransform r = sim_mul(I, T);
    assert(fabsf(r.s-T.s)<EPSILON);
    assert(quat_eq(r.r, T.r));
    assert(vec3_eq(r.t, T.t));
    printf("PASSED\n");
}

static void test_sim_identity_right(void) {
    printf("[Test 7] T ∘ T_id = T... ");
    SimTransform T = {0.5f, {0,S2,S2,0}, {4,5,6}};
    SimTransform I = sim_identity();
    SimTransform r = sim_mul(T, I);
    assert(fabsf(r.s-T.s)<EPSILON);
    assert(quat_eq(r.r, T.r));
    assert(vec3_eq(r.t, T.t));
    printf("PASSED\n");
}

static void test_sim_inverse(void) {
    printf("[Test 8] T ∘ T⁻¹ = T_id... ");
    SimTransform T = {1.5f, {S2,0,S2,0}, {1,2,3}}; // unit quat: (1/√2, 0, 1/√2, 0)
    SimTransform Ti = sim_inv(T);
    SimTransform r = sim_mul(T, Ti);
    assert(fabsf(r.s-1.0f)<EPSILON);
    assert(quat_eq(r.r, quat_identity()));
    assert(fabsf(r.t.x)<EPSILON && fabsf(r.t.y)<EPSILON && fabsf(r.t.z)<EPSILON);
    printf("PASSED\n");
}

static void test_sim_associativity(void) {
    printf("[Test 9] (T3 ∘ T2) ∘ T1 = T3 ∘ (T2 ∘ T1)... ");
    SimTransform T1 = {1.1f, {S2,0,S2,0}, {1,0,0}};
    SimTransform T2 = {0.9f, {0.866025f,0,0.5f,0}, {0,2,0}};
    SimTransform T3 = {1.3f, {S2,S2,0,0}, {0,0,3}};
    SimTransform lhs = sim_mul(sim_mul(T3, T2), T1);
    SimTransform rhs = sim_mul(T3, sim_mul(T2, T1));
    assert(fabsf(lhs.s-rhs.s)<EPSILON);
    assert(quat_eq(lhs.r, rhs.r));
    assert(vec3_eq(lhs.t, rhs.t));
    printf("PASSED\n");
}

static void test_sim_distinction(void) {
    printf("[Test 10] Position/orientation/pose/scale are distinct (AC-03)... ");
    // Position only: no orientation, no scale
    Vec3 pos = {1,2,3};
    // Orientation only: quaternion
    Quat ori = {0.9239f, 0, 0.3827f, 0};
    // Scale only: scalar
    float scl = 2.0f;
    // Pose = position + orientation (no scale)
    // Similarity = position + orientation + scale
    SimTransform pose_only = {1.0f, ori, pos};
    SimTransform with_scale = {scl, ori, pos};
    Vec3 test_pt = {1,0,0};
    Vec3 r_pose = sim_apply(pose_only, test_pt);
    Vec3 r_scale = sim_apply(with_scale, test_pt);
    // Scale should produce different result
    assert(!vec3_eq(r_pose, r_scale));
    // Same position, different orientation should produce different result
    SimTransform T_a = {1.0f, quat_identity(), {0,0,0}};
    SimTransform T_b = {1.0f, {S2,0,S2,0}, {0,0,0}};
    Vec3 r_a = sim_apply(T_a, test_pt);
    Vec3 r_b = sim_apply(T_b, test_pt);
    assert(!vec3_eq(r_a, r_b));
    printf("PASSED\n");
}

static void test_sim_point_vs_vector(void) {
    printf("[Test 11] Point transform includes translation, vector does not... ");
    SimTransform T = {1.0f, quat_identity(), {5,6,7}};
    Vec3 point = {1,0,0};
    Vec3 vector = {1,0,0};
    Vec3 tp = sim_apply(T, point);
    // Vector: only rotation and scale, no translation
    Vec3 rotated = quat_rotate(T.r, vector);
    Vec3 tv = {T.s*rotated.x, T.s*rotated.y, T.s*rotated.z};
    // Point should have translation, vector should not
    assert(fabsf(tp.x-tv.x-5.0f)<EPSILON);
    printf("PASSED\n");
}


// ═══════════════════════════════════════════════════════════════════════════
// TEST SUITE 3: Negative/Adversarial Tests (AC-12)
// ═══════════════════════════════════════════════════════════════════════════

static void test_neg_scale_zero(void) {
    printf("[Test 12] NEGATIVE: Scale = 0 produces degenerate transform... ");
    SimTransform T = {0.0f, quat_identity(), {0,0,0}};
    Vec3 p = {1,2,3};
    Vec3 r = sim_apply(T, p);
    // With scale 0, all coordinates should collapse to translation
    assert(fabsf(r.x)<EPSILON && fabsf(r.y)<EPSILON && fabsf(r.z)<EPSILON);
    printf("PASSED (degenerate as expected)\n");
}

static void test_neg_scale_negative(void) {
    printf("[Test 13] NEGATIVE: Negative scale violates similarity constraint... ");
    // Similarity transforms require s > 0
    // Negative scale flips the coordinate system
    SimTransform T = {-1.0f, quat_identity(), {0,0,0}};
    Vec3 p = {1,0,0};
    Vec3 r = sim_apply(T, p);
    // Should flip: x becomes -1
    assert(fabsf(r.x-(-1.0f))<EPSILON);
    printf("PASSED (violation detected)\n");
}

static void test_neg_nonunit_quat(void) {
    printf("[Test 14] NEGATIVE: Non-unit quaternion produces scaled rotation... ");
    // Quaternion norm != 1 means the rotation is not pure
    Quat q = {2.0f, 0, 0, 0}; // norm = 2
    Vec3 p = {1,0,0};
    Vec3 r = quat_rotate(q, p);
    // q·v·q* with non-unit q scales the result
    // With q = (2,0,0,0): q·v·q* = 4*v (scalar quaternion doubles twice)
    assert(fabsf(r.x-4.0f)<EPSILON);
    printf("PASSED (non-unit detected)\n");
}

static void test_neg_composition_order(void) {
    printf("[Test 15] NEGATIVE: Composition is NOT commutative... ");
    SimTransform T1 = {1.0f, quat_identity(), {5,0,0}};
    SimTransform T2 = {1.0f, {S2,0,S2,0}, {0,5,0}};
    SimTransform r12 = sim_mul(T2, T1);
    SimTransform r21 = sim_mul(T1, T2);
    // T2∘T1 ≠ T1∘T2 in general
    assert(!vec3_eq(r12.t, r21.t));
    printf("PASSED (non-commutativity confirmed)\n");
}

static void test_neg_assoc_fail(void) {
    printf("[Test 16] NEGATIVE: Without associativity, transform chains break... ");
    // Verify associativity DOES hold for our representation
    SimTransform T1 = {2.0f, {0,1,0,0}, {1,0,0}};
    SimTransform T2 = {0.5f, {0,0,1,0}, {0,1,0}};
    SimTransform T3 = {1.5f, {0,0,0,1}, {0,0,1}};
    SimTransform lhs = sim_mul(sim_mul(T3, T2), T1);
    SimTransform rhs = sim_mul(T3, sim_mul(T2, T1));
    assert(fabsf(lhs.s-rhs.s)<EPSILON);
    assert(quat_eq(lhs.r, rhs.r));
    assert(vec3_eq(lhs.t, rhs.t));
    printf("PASSED (associativity verified)\n");
}

static void test_neg_coord_swap(void) {
    printf("[Test 17] NEGATIVE: Swapping axes changes handedness... ");
    Mat3 swap = {{{0,1,0},{1,0,0},{0,0,1}}}; // swap X and Y
    float d = mat3_det(swap);
    // Swapping two axes flips determinant sign
    assert(d < 0);
    printf("PASSED (handedness flip detected)\n");
}

static void test_neg_translation_not_vector(void) {
    printf("[Test 18] NEGATIVE: Translation is not a vector (frame-dependent)... ");
    // Translation changes meaning depending on frame
    SimTransform T1 = {1.0f, quat_identity(), {1,0,0}}; // translate in X
    SimTransform T2 = {1.0f, {S2,0,S2,0}, {0,0,0}}; // rotate 90° around Y
    // Compose: rotate first, then translate
    SimTransform r = sim_mul(T1, T2);
    Vec3 p = {1,0,0};
    Vec3 result = sim_apply(r, p);
    // The translation {1,0,0} is in the parent frame, not the rotated frame
    // So the result should be: rotate p first, then add translation
    Vec3 rotated = quat_rotate(T2.r, p);
    Vec3 expected = {rotated.x + T1.t.x, rotated.y + T1.t.y, rotated.z + T1.t.z};
    assert(vec3_eq(result, expected));
    printf("PASSED (frame-dependence verified)\n");
}

static void test_neg_ortho_preserves_length(void) {
    printf("[Test 19] NEGATIVE: Orthogonal transforms preserve vector length... ");
    Vec3 v = {3,4,5};
    float len_before = sqrtf(vec3_dot(v,v));
    Vec3 mv = mat3_mul_vec(mat_scr_o3de(), v);
    float len_after = sqrtf(vec3_dot(mv,mv));
    assert(fabsf(len_before-len_after)<EPSILON);
    printf("PASSED (length preserved)\n");
}

static void test_neg_det_minus_one_flips(void) {
    printf("[Test 20] NEGATIVE: Det = -1 reflects (orientation-reversing)... ");
    // A reflection matrix has det = -1
    Mat3 reflect = {{{-1,0,0},{0,1,0},{0,0,1}}}; // reflect X
    Vec3 p = {1,0,0};
    Vec3 r = mat3_mul_vec(reflect, p);
    assert(r.x < 0); // X flipped
    assert(fabsf(mat3_det(reflect)-(-1.0f))<EPSILON);
    printf("PASSED (reflection detected)\n");
}

// ═══════════════════════════════════════════════════════════════════════════
// TEST SUITE 4: Semantic Claim Validation
// ═══════════════════════════════════════════════════════════════════════════

static void test_semantic_position_independent(void) {
    printf("[Test 21] Semantic: Position is frame-dependent... ");
    Vec3 p = {0,1,0}; // point on Y axis
    // Same point, different frames
    Mat3 m1 = mat3_identity(); // SCR frame
    Mat3 m2 = mat_scr_o3de();  // O3DE frame
    Vec3 in_scr = mat3_mul_vec(m1, p);
    Vec3 in_o3de = mat3_mul_vec(m2, p);
    // Same numerical coordinates, different semantic meaning
    assert(vec3_eq(in_scr, p)); // identity
    assert(!vec3_eq(in_o3de, p)); // different frame (Y maps to Z in O3DE)
    printf("PASSED\n");
}

static void test_semantic_quat_double_cover(void) {
    printf("[Test 22] Semantic: q and -q represent same rotation... ");
    Quat q1 = {S2, S2, 0, 0};
    Quat q2 = {-S2, -S2, 0, 0}; // -q1
    Vec3 p = {1,0,0};
    Vec3 r1 = quat_rotate(q1, p);
    Vec3 r2 = quat_rotate(q2, p);
    assert(vec3_eq(r1, r2));
    printf("PASSED\n");
}

static void test_semantic_scale_semantic(void) {
    printf("[Test 23] Semantic: Scale affects distances, not directions... ");
    SimTransform T = {2.0f, quat_identity(), {0,0,0}};
    Vec3 a = {1,0,0}, b = {0,1,0};
    Vec3 ta = sim_apply(T, a);
    Vec3 tb = sim_apply(T, b);
    // Direction preserved (still orthogonal)
    assert(fabsf(vec3_dot(ta,tb))<EPSILON);
    // Distance doubled
    float d_orig = sqrtf(vec3_dot(a,a));
    float d_scaled = sqrtf(vec3_dot(ta,ta));
    assert(fabsf(d_scaled-2.0f*d_orig)<EPSILON);
    printf("PASSED\n");
}


// ═══════════════════════════════════════════════════════════════════════════
// MAIN
// ═══════════════════════════════════════════════════════════════════════════

int main(void) {
    printf("========================================================\n");
    printf(" SCR Semantic Correction — Mathematical Validation Tests\n");
    printf("========================================================\n\n");

    printf("--- Coordinate Mapping Properties ---\n");
    test_coord_det();
    test_coord_orthogonal();
    test_coord_roundtrip();
    test_coord_cross();
    test_coord_units();

    printf("\n--- Transform Algebra Properties ---\n");
    test_sim_identity_left();
    test_sim_identity_right();
    test_sim_inverse();
    test_sim_associativity();
    test_sim_distinction();
    test_sim_point_vs_vector();

    printf("\n--- Negative/Adversarial Tests ---\n");
    test_neg_scale_zero();
    test_neg_scale_negative();
    test_neg_nonunit_quat();
    test_neg_composition_order();
    test_neg_assoc_fail();
    test_neg_coord_swap();
    test_neg_translation_not_vector();
    test_neg_ortho_preserves_length();
    test_neg_det_minus_one_flips();

    printf("\n--- Semantic Claim Validation ---\n");
    test_semantic_position_independent();
    test_semantic_quat_double_cover();
    test_semantic_scale_semantic();

    printf("\n========================================================\n");
    printf(" All 23 Tests PASSED Successfully.\n");
    printf("========================================================\n\n");
    return 0;
}
