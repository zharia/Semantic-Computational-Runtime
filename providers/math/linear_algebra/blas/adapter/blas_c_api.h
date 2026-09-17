// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

#ifndef SCR_BLAS_C_API_H
#define SCR_BLAS_C_API_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#define BLAS_SUCCESS 0
#define BLAS_ERR_NULL_POINTER -1
#define BLAS_ERR_INVALID_DIMENSION -2
#define BLAS_ERR_COMPUTATION_FAILED -3

/**
 * General Matrix Multiplication: C = alpha * A * B + beta * C
 * All matrices are stored in row-major order.
 * A is M x K, B is K x N, C is M x N.
 */
int blas_gemm_f32(
    size_t m, size_t n, size_t k,
    float alpha,
    const float* a, size_t lda,
    const float* b, size_t ldb,
    float beta,
    float* c, size_t ldc
);

/**
 * General Matrix-Vector Multiplication: y = alpha * A * x + beta * y
 * A is M x N, x is N-element vector, y is M-element vector.
 */
int blas_gemv_f32(
    size_t m, size_t n,
    float alpha,
    const float* a, size_t lda,
    const float* x,
    float beta,
    float* y
);

/**
 * Dot product of two vectors: dot = x . y
 */
int blas_dot_f32(
    size_t n,
    const float* x,
    const float* y,
    float* out_result
);

/**
 * Euclidean 2-norm of a vector: ||x||_2
 */
int blas_nrm2_f32(
    size_t n,
    const float* x,
    float* out_result
);

/**
 * Element-wise vector scaling: x = alpha * x
 */
int blas_scal_f32(
    size_t n,
    float alpha,
    float* x
);

/**
 * Vector addition: y = alpha * x + y
 */
int blas_axpy_f32(
    size_t n,
    float alpha,
    const float* x,
    float* y
);

#ifdef __cplusplus
}
#endif

#endif // SCR_BLAS_C_API_H
