// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

#include "../adapter/blas_c_api.h"

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <assert.h>

static void test_blas_gemm(void) {
    printf("[Test 1] BLAS GEMM 2x2 Matrix Multiplication... ");
    // A = [1 2; 3 4], B = [5 6; 7 8]
    // A*B = [19 22; 43 50]
    float a[4] = { 1.0f, 2.0f, 3.0f, 4.0f };
    float b[4] = { 5.0f, 6.0f, 7.0f, 8.0f };
    float c[4] = { 0.0f, 0.0f, 0.0f, 0.0f };

    int rc = blas_gemm_f32(2, 2, 2, 1.0f, a, 2, b, 2, 0.0f, c, 2);
    assert(rc == BLAS_SUCCESS);
    assert(fabsf(c[0] - 19.0f) < 1e-5f);
    assert(fabsf(c[1] - 22.0f) < 1e-5f);
    assert(fabsf(c[2] - 43.0f) < 1e-5f);
    assert(fabsf(c[3] - 50.0f) < 1e-5f);
    printf("PASSED\n");
}

static void test_blas_gemv_dot_nrm2(void) {
    printf("[Test 2] BLAS GEMV, Dot Product, and Norm... ");
    float a[6] = { 1.0f, 2.0f, 3.0f, 4.0f, 5.0f, 6.0f }; // 2x3 matrix
    float x[3] = { 1.0f, 0.5f, -1.0f };
    float y[2] = { 0.0f, 0.0f };

    int rc = blas_gemv_f32(2, 3, 1.0f, a, 3, x, 0.0f, y);
    assert(rc == BLAS_SUCCESS);
    // row 0: 1*1 + 2*0.5 + 3*(-1) = 1 + 1 - 3 = -1
    // row 1: 4*1 + 5*0.5 + 6*(-1) = 4 + 2.5 - 6 = 0.5
    assert(fabsf(y[0] - (-1.0f)) < 1e-5f);
    assert(fabsf(y[1] - 0.5f) < 1e-5f);

    float dot_val = 0.0f;
    rc = blas_dot_f32(3, x, x, &dot_val);
    assert(rc == BLAS_SUCCESS);
    // 1^2 + 0.5^2 + (-1)^2 = 1 + 0.25 + 1 = 2.25
    assert(fabsf(dot_val - 2.25f) < 1e-5f);

    float norm_val = 0.0f;
    rc = blas_nrm2_f32(3, x, &norm_val);
    assert(rc == BLAS_SUCCESS);
    assert(fabsf(norm_val - 1.5f) < 1e-5f);

    printf("PASSED\n");
}

static void test_blas_error_handling(void) {
    printf("[Test 3] BLAS Error Handling and Preconditions... ");
    float val = 0.0f;
    int rc = blas_dot_f32(0, &val, &val, &val);
    assert(rc == BLAS_ERR_INVALID_DIMENSION);

    rc = blas_gemm_f32(2, 2, 2, 1.0f, NULL, 2, &val, 2, 0.0f, &val, 2);
    assert(rc == BLAS_ERR_NULL_POINTER);
    printf("PASSED\n");
}

int main(void) {
    printf("======================================\n");
    printf(" Running BLAS Provider Contract Tests\n");
    printf("======================================\n");
    test_blas_gemm();
    test_blas_gemv_dot_nrm2();
    test_blas_error_handling();
    printf("\nAll BLAS Contract Tests PASSED successfully.\n\n");
    return 0;
}
