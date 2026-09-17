# CUDA Hardware Accelerator Provider Contract

**Provider:** cuda  
**Domain:** system  
**Subdomain:** accelerator  
**Version:** 0.1.0  
**Status:** Normative Contract  
**Governing Documents:** [`docs/architecture/103_provider_contracts.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/docs/architecture/103_provider_contracts.md)

---

## 1. Contract Overview

This document specifies the concrete Provider Contract implemented by the `cuda` provider for the `system/accelerator` capability domain. It defines compute accelerator query, device memory buffer allocation, bidirectional host-to-device memory staging, and stream execution synchronization.

---

## 2. Semantic Capabilities

* `[system, accelerator, cuda, device_query]` — Hardware accelerator device discovery.
* `[system, accelerator, cuda, mem_alloc]` — Device memory allocation and deallocation.
* `[system, accelerator, cuda, mem_copy]` — Host-to-device and device-to-host memory staging.
* `[system, accelerator, cuda, stream_sync]` — Asynchronous execution stream barrier and synchronization.

---

## 3. Operations & Signatures

* `cuda_device_get_count(out_count) -> int`
* `cuda_device_alloc(bytes, out_dev_ptr) -> int`
* `cuda_device_free(dev_ptr) -> int`
* `cuda_memcpy_host_to_device(dst, src, bytes) -> int`
* `cuda_memcpy_device_to_host(dst, src, bytes) -> int`
* `cuda_stream_create(out_stream) -> int`
* `cuda_stream_synchronize(stream) -> int`
* `cuda_stream_destroy(stream) -> int`

---

## 4. Preconditions & Postconditions

1. **Precondition (Non-Zero Allocation):** Buffer allocations require `bytes > 0`.
2. **Precondition (Pointer Integrity):** All pointer targets must be valid and non-null.
3. **Postcondition (Bitwise Equivalence):** Data retrieved from device via `cuda_memcpy_device_to_host` is bitwise identical to source bytes transferred via `cuda_memcpy_host_to_device`.

---

## 5. Failure Semantics & Error Codes

* `CUDA_SUCCESS = 0`
* `CUDA_ERR_NULL_POINTER = -1`
* `CUDA_ERR_INVALID_DEVICE = -2`
* `CUDA_ERR_OUT_OF_MEMORY = -3`
* `CUDA_ERR_INVALID_HANDLE = -4`
* `CUDA_ERR_EXECUTION_FAILED = -5`

---

## 6. Conformance Test Suite

The provider is validated against the conformance suite in `tests/test_cuda_contract.c`.
