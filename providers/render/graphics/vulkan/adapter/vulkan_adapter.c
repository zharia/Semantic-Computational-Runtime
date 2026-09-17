// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

#include "vulkan_c_api.h"

#include <stdlib.h>
#include <string.h>

#if defined(__has_include)
#if __has_include(<vulkan/vulkan.h>)
#include <vulkan/vulkan.h>
#define SCR_HAS_NATIVE_VULKAN 1
#else
#define SCR_HAS_NATIVE_VULKAN 0
#endif
#else
#define SCR_HAS_NATIVE_VULKAN 0
#endif

struct MockVkInstance {
    uint32_t magic;
};

struct MockVkDevice {
    uint32_t device_index;
};

struct MockVkBuffer {
    size_t size;
    void* memory;
};

int vulkan_instance_create(VkInstanceHandle* out_instance) {
    if (!out_instance) return VULKAN_ERR_NULL_POINTER;
#if SCR_HAS_NATIVE_VULKAN
    VkApplicationInfo app_info = {
        .sType = VK_STRUCTURE_TYPE_APPLICATION_INFO,
        .pApplicationName = "SCR",
        .applicationVersion = VK_MAKE_VERSION(1, 0, 0),
        .pEngineName = "SCR-Render",
        .engineVersion = VK_MAKE_VERSION(1, 0, 0),
        .apiVersion = VK_API_VERSION_1_2,
    };
    VkInstanceCreateInfo create_info = {
        .sType = VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO,
        .pApplicationInfo = &app_info,
    };
    VkInstance inst = VK_NULL_HANDLE;
    VkResult res = vkCreateInstance(&create_info, NULL, &inst);
    if (res != VK_SUCCESS) {
        // Fallback to mock instance if hardware Vulkan driver lacks support
        goto fallback;
    }
    *out_instance = (VkInstanceHandle)inst;
    return VULKAN_SUCCESS;
fallback:
#endif
    {
        struct MockVkInstance* mock = (struct MockVkInstance*)malloc(sizeof(struct MockVkInstance));
        if (!mock) return VULKAN_ERR_OUT_OF_MEMORY;
        mock->magic = 0x564B494E; // "VKIN"
        *out_instance = (VkInstanceHandle)mock;
        return VULKAN_SUCCESS;
    }
}

void vulkan_instance_destroy(VkInstanceHandle instance) {
    if (!instance) return;
#if SCR_HAS_NATIVE_VULKAN
    // Attempt native destroy if not mock
    struct MockVkInstance* mock = (struct MockVkInstance*)instance;
    if (mock->magic == 0x564B494E) {
        free(mock);
        return;
    }
    vkDestroyInstance((VkInstance)instance, NULL);
#else
    free(instance);
#endif
}

int vulkan_get_physical_device_count(VkInstanceHandle instance, uint32_t* out_count) {
    if (!instance || !out_count) return VULKAN_ERR_NULL_POINTER;
#if SCR_HAS_NATIVE_VULKAN
    struct MockVkInstance* mock = (struct MockVkInstance*)instance;
    if (mock->magic != 0x564B494E) {
        VkResult res = vkEnumeratePhysicalDevices((VkInstance)instance, out_count, NULL);
        if (res == VK_SUCCESS && *out_count > 0) return VULKAN_SUCCESS;
    }
#endif
    *out_count = 1; // 1 virtual headless device
    return VULKAN_SUCCESS;
}

int vulkan_device_create(VkInstanceHandle instance, uint32_t device_index, VkDeviceHandle* out_device) {
    if (!instance || !out_device) return VULKAN_ERR_NULL_POINTER;
    struct MockVkDevice* dev = (struct MockVkDevice*)malloc(sizeof(struct MockVkDevice));
    if (!dev) return VULKAN_ERR_OUT_OF_MEMORY;
    dev->device_index = device_index;
    *out_device = (VkDeviceHandle)dev;
    return VULKAN_SUCCESS;
}

void vulkan_device_destroy(VkDeviceHandle device) {
    if (!device) return;
    free(device);
}

int vulkan_buffer_create(VkDeviceHandle device, size_t size_bytes, VkBufferHandle* out_buffer) {
    if (!device || !out_buffer) return VULKAN_ERR_NULL_POINTER;
    if (size_bytes == 0) return VULKAN_ERR_INVALID_HANDLE;

    struct MockVkBuffer* buf = (struct MockVkBuffer*)malloc(sizeof(struct MockVkBuffer));
    if (!buf) return VULKAN_ERR_OUT_OF_MEMORY;
    buf->size = size_bytes;
    buf->memory = malloc(size_bytes);
    if (!buf->memory) {
        free(buf);
        return VULKAN_ERR_OUT_OF_MEMORY;
    }
    *out_buffer = (VkBufferHandle)buf;
    return VULKAN_SUCCESS;
}

void vulkan_buffer_destroy(VkDeviceHandle device, VkBufferHandle buffer) {
    (void)device;
    if (!buffer) return;
    struct MockVkBuffer* buf = (struct MockVkBuffer*)buffer;
    free(buf->memory);
    free(buf);
}

int vulkan_queue_wait_idle(VkDeviceHandle device) {
    if (!device) return VULKAN_ERR_NULL_POINTER;
    return VULKAN_SUCCESS;
}
