// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

#include "../adapter/vulkan_c_api.h"

#include <stdio.h>
#include <stdlib.h>
#include <assert.h>

static void test_vulkan_lifecycle(void) {
    printf("[Test 1] Vulkan Instance & Device Lifecycle... ");
    VkInstanceHandle inst = NULL;
    int rc = vulkan_instance_create(&inst);
    assert(rc == VULKAN_SUCCESS);
    assert(inst != NULL);

    uint32_t dev_count = 0;
    rc = vulkan_get_physical_device_count(inst, &dev_count);
    assert(rc == VULKAN_SUCCESS);
    assert(dev_count >= 1);

    VkDeviceHandle dev = NULL;
    rc = vulkan_device_create(inst, 0, &dev);
    assert(rc == VULKAN_SUCCESS);
    assert(dev != NULL);

    rc = vulkan_queue_wait_idle(dev);
    assert(rc == VULKAN_SUCCESS);

    vulkan_device_destroy(dev);
    vulkan_instance_destroy(inst);
    printf("PASSED (Physical devices: %u)\n", dev_count);
}

static void test_vulkan_buffer(void) {
    printf("[Test 2] Vulkan Buffer Creation & Deallocation... ");
    VkInstanceHandle inst = NULL;
    int rc = vulkan_instance_create(&inst);
    assert(rc == VULKAN_SUCCESS);

    VkDeviceHandle dev = NULL;
    rc = vulkan_device_create(inst, 0, &dev);
    assert(rc == VULKAN_SUCCESS);

    VkBufferHandle buf = NULL;
    rc = vulkan_buffer_create(dev, 4096, &buf);
    assert(rc == VULKAN_SUCCESS);
    assert(buf != NULL);

    vulkan_buffer_destroy(dev, buf);
    vulkan_device_destroy(dev);
    vulkan_instance_destroy(inst);
    printf("PASSED (4096 bytes buffer)\n");
}

static void test_vulkan_error_handling(void) {
    printf("[Test 3] Vulkan Precondition and Error Handling... ");
    int rc = vulkan_instance_create(NULL);
    assert(rc == VULKAN_ERR_NULL_POINTER);

    VkBufferHandle buf = NULL;
    rc = vulkan_buffer_create(NULL, 1024, &buf);
    assert(rc == VULKAN_ERR_NULL_POINTER);

    VkInstanceHandle inst = NULL;
    vulkan_instance_create(&inst);
    VkDeviceHandle dev = NULL;
    vulkan_device_create(inst, 0, &dev);

    rc = vulkan_buffer_create(dev, 0, &buf); // 0 bytes invalid
    assert(rc == VULKAN_ERR_INVALID_HANDLE);

    vulkan_device_destroy(dev);
    vulkan_instance_destroy(inst);
    printf("PASSED\n");
}

int main(void) {
    printf("=======================================\n");
    printf(" Running Vulkan Provider Contract Tests\n");
    printf("=======================================\n");
    test_vulkan_lifecycle();
    test_vulkan_buffer();
    test_vulkan_error_handling();
    printf("\nAll Vulkan Contract Tests PASSED successfully.\n\n");
    return 0;
}
