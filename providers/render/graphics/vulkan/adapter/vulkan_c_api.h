// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

#ifndef SCR_VULKAN_C_API_H
#define SCR_VULKAN_C_API_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#define VULKAN_SUCCESS 0
#define VULKAN_ERR_NULL_POINTER -1
#define VULKAN_ERR_INVALID_HANDLE -2
#define VULKAN_ERR_OUT_OF_MEMORY -3
#define VULKAN_ERR_INITIALIZATION_FAILED -4

typedef void* VkInstanceHandle;
typedef void* VkDeviceHandle;
typedef void* VkBufferHandle;

/**
 * Creates a Vulkan runtime instance.
 */
int vulkan_instance_create(VkInstanceHandle* out_instance);

/**
 * Destroys a Vulkan runtime instance.
 */
void vulkan_instance_destroy(VkInstanceHandle instance);

/**
 * Queries the count of available physical graphics/compute devices.
 */
int vulkan_get_physical_device_count(VkInstanceHandle instance, uint32_t* out_count);

/**
 * Creates a logical graphics/compute device.
 */
int vulkan_device_create(VkInstanceHandle instance, uint32_t device_index, VkDeviceHandle* out_device);

/**
 * Destroys a logical device.
 */
void vulkan_device_destroy(VkDeviceHandle device);

/**
 * Creates a GPU-accessible buffer of specified byte size.
 */
int vulkan_buffer_create(VkDeviceHandle device, size_t size_bytes, VkBufferHandle* out_buffer);

/**
 * Destroys a GPU buffer.
 */
void vulkan_buffer_destroy(VkDeviceHandle device, VkBufferHandle buffer);

/**
 * Waits until all queued operations on the device queue complete.
 */
int vulkan_queue_wait_idle(VkDeviceHandle device);

#ifdef __cplusplus
}
#endif

#endif // SCR_VULKAN_C_API_H
