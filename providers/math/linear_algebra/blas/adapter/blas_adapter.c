// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

#include "blas_c_api.h"

#include <math.h>
#include <string.h>

#if defined(__has_include)
#if __has_include(<cblas.h>)
#include <cblas.h>
#define SCR_HAS_NATIVE_BLAS 1
#else
#define SCR_HAS_NATIVE_BLAS 0
#endif
#else
#define SCR_HAS_NATIVE_BLAS 0
#endif

int blas_gemm_f32(
    size_t m, size_t n, size_t k,
    float alpha,
    const float* a, size_t lda,
    const float* b, size_t ldb,
    float beta,
    float* c, size_t ldc
) {
    if (!a || !b || !c) return BLAS_ERR_NULL_POINTER;
    if (m == 0 || n == 0 || k == 0) return BLAS_ERR_INVALID_DIMENSION;
    if (lda < k || ldb < n || ldc < n) return BLAS_ERR_INVALID_DIMENSION;

#if SCR_HAS_NATIVE_BLAS
    cblas_sgemm(
        CblasRowMajor, CblasNoTrans, CblasNoTrans,
        (int)m, (int)n, (int)k,
        alpha, a, (int)lda,
        b, (int)ldb,
        beta, c, (int)ldc
    );
#else
    for (size_t i = 0; i < m; ++i) {
        for (size_t j = 0; j < n; ++j) {
            float sum = 0.0f;
            for (size_t p = 0; p < k; ++p) {
                sum += a[i * lda + p] * b[p * ldb + j];
            }
            if (beta == 0.0f) {
                c[i * ldc + j] = alpha * sum;
            } else {
                c[i * ldc + j] = alpha * sum + beta * c[i * ldc + j];
            }
        }
    }
#endif
    return BLAS_SUCCESS;
}

int blas_gemv_f32(
    size_t m, size_t n,
    float alpha,
    const float* a, size_t lda,
    const float* x,
    float beta,
    float* y
) {
    if (!a || !x || !y) return BLAS_ERR_NULL_POINTER;
    if (m == 0 || n == 0) return BLAS_ERR_INVALID_DIMENSION;
    if (lda < n) return BLAS_ERR_INVALID_DIMENSION;

#if SCR_HAS_NATIVE_BLAS
    cblas_sgemv(
        CblasRowMajor, CblasNoTrans,
        (int)m, (int)n,
        alpha, a, (int)lda,
        x, 1,
        beta, y, 1
    );
#else
    for (size_t i = 0; i < m; ++i) {
        float sum = 0.0f;
        for (size_t j = 0; j < n; ++j) {
            sum += a[i * lda + j] * x[j];
        }
        if (beta == 0.0f) {
            y[i] = alpha * sum;
        } else {
            y[i] = alpha * sum + beta * y[i];
        }
    }
#endif
    return BLAS_SUCCESS;
}

int blas_dot_f32(
    size_t n,
    const float* x,
    const float* y,
    float* out_result
) {
    if (!x || !y || !out_result) return BLAS_ERR_NULL_POINTER;
    if (n == 0) return BLAS_ERR_INVALID_DIMENSION;

#if SCR_HAS_NATIVE_BLAS
    *out_result = cblas_sdot((int)n, x, 1, y, 1);
#else
    float sum = 0.0f;
    for (size_t i = 0; i < n; ++i) {
        sum += x[i] * y[i];
    }
    *out_result = sum;
#endif
    return BLAS_SUCCESS;
}

int blas_nrm2_f32(
    size_t n,
    const float* x,
    float* out_result
) {
    if (!x || !out_result) return BLAS_ERR_NULL_POINTER;
    if (n == 0) return BLAS_ERR_INVALID_DIMENSION;

#if SCR_HAS_NATIVE_BLAS
    *out_result = cblas_snrm2((int)n, x, 1);
#else
    float sum = 0.0f;
    for (size_t i = 0; i < n; ++i) {
        sum += x[i] * x[i];
    }
    *out_result = sqrtf(sum);
#endif
    return BLAS_SUCCESS;
}

int blas_scal_f32(
    size_t n,
    float alpha,
    float* x
) {
    if (!x) return BLAS_ERR_NULL_POINTER;
    if (n == 0) return BLAS_ERR_INVALID_DIMENSION;

#if SCR_HAS_NATIVE_BLAS
    cblas_sscal((int)n, alpha, x, 1);
#else
    for (size_t i = 0; i < n; ++i) {
        x[i] *= alpha;
    }
#endif
    return BLAS_SUCCESS;
}

int blas_axpy_f32(
    size_t n,
    float alpha,
    const float* x,
    float* y
) {
    if (!x || !y) return BLAS_ERR_NULL_POINTER;
    if (n == 0) return BLAS_ERR_INVALID_DIMENSION;

#if SCR_HAS_NATIVE_BLAS
    cblas_saxpy((int)n, alpha, x, 1, y, 1);
#else
    for (size_t i = 0; i < n; ++i) {
        y[i] += alpha * x[i];
    }
#endif
    return BLAS_SUCCESS;
}
