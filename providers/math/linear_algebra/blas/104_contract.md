# BLAS Provider Contract

**Provider:** blas  
**Domain:** math  
**Subdomain:** linear_algebra  
**Version:** 0.1.0  
**Status:** Normative Contract  
**Governing Documents:** [`docs/architecture/103_provider_contracts.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/docs/architecture/103_provider_contracts.md)

---

## 1. Contract Overview

This document specifies the concrete Provider Contract implemented by the `blas` provider for the `math/linear_algebra` capability domain. It defines standard dense matrix and vector linear algebra operations for continuous fields and numerical solvers.

---

## 2. Semantic Capabilities

* `[math, linear_algebra, blas, gemm]` — General matrix-matrix multiplication.
* `[math, linear_algebra, blas, gemv]` — General matrix-vector multiplication.
* `[math, linear_algebra, blas, dot]` — Vector dot product.
* `[math, linear_algebra, blas, nrm2]` — Euclidean vector 2-norm.
* `[math, linear_algebra, blas, axpy]` — Scaled vector addition.

---

## 3. Operations & Signatures

* `blas_gemm_f32(m, n, k, alpha, a, lda, b, ldb, beta, c, ldc) -> int`
* `blas_gemv_f32(m, n, alpha, a, lda, x, beta, y) -> int`
* `blas_dot_f32(n, x, y, out_result) -> int`
* `blas_nrm2_f32(n, x, out_result) -> int`
* `blas_scal_f32(n, alpha, x) -> int`
* `blas_axpy_f32(n, alpha, x, y) -> int`

---

## 4. Preconditions & Postconditions

1. **Precondition (Pointer Validity):** All operand pointers must be non-null. Passing null returns `BLAS_ERR_NULL_POINTER`.
2. **Precondition (Dimension Consistency):** Dimension counts `m, n, k` must be greater than zero. Leading dimensions `lda, ldb, ldc` must be at least equal to row widths in row-major layout.
3. **Postcondition (Numerical Precision):** Evaluated outputs must adhere to IEEE 754 single-precision floating point invariants.

---

## 5. Failure Semantics & Error Codes

* `BLAS_SUCCESS = 0`
* `BLAS_ERR_NULL_POINTER = -1`
* `BLAS_ERR_INVALID_DIMENSION = -2`
* `BLAS_ERR_COMPUTATION_FAILED = -3`

---

## 6. Conformance Test Suite

The provider is validated against the conformance suite in `tests/test_blas_contract.c`.
