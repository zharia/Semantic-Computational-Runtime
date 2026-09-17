// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

#ifndef SCR_CUDA_C_API_H
#define SCR_CUDA_C_API_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#define CUDA_SUCCESS 0
#define CUDA_ERR_NULL_POINTER -1
#define CUDA_ERR_INVALID_DEVICE -2
#define CUDA_ERR_OUT_OF_MEMORY -3
#define CUDA_ERR_INVALID_HANDLE -4
#define CUDA_ERR_EXECUTION_FAILED -5

typedef void* CudaStreamHandle;
typedef void* CudaDevicePtr;

/**
 * Queries the count of compute-capable accelerator devices.
 */
int cuda_device_get_count(int* out_count);

/**
 * Allocates contiguous device memory.
 */
int cuda_device_alloc(size_t bytes, CudaDevicePtr* out_dev_ptr);

/**
 * Frees previously allocated device memory.
 */
int cuda_device_free(CudaDevicePtr dev_ptr);

/**
 * Copies bytes from host memory to accelerator device memory.
 */
int cuda_memcpy_host_to_device(CudaDevicePtr dst, const void* src, size_t bytes);

/**
 * Copies bytes from accelerator device memory to host memory.
 */
int cuda_memcpy_device_to_host(void* dst, const CudaDevicePtr src, size_t bytes);

/**
 * Creates an asynchronous accelerator stream.
 */
int cuda_stream_create(CudaStreamHandle* out_stream);

/**
 * Synchronizes execution on an asynchronous stream until all queued work completes.
 */
int cuda_stream_synchronize(CudaStreamHandle stream);

/**
 * Destroys an asynchronous accelerator stream.
 */
int cuda_stream_destroy(CudaStreamHandle stream);

#ifdef __cplusplus
}
#endif

#endif // SCR_CUDA_C_API_H
