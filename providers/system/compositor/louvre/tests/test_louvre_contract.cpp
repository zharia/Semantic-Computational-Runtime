#include "../adapter/louvre_c_api.h"
#include <cassert>
#include <iostream>

static bool g_created = false;
static bool g_committed = false;
static bool g_destroyed = false;

static void test_on_create(void* user_data, uint64_t surface_id, const char* title) {
    (void)user_data; (void)surface_id; (void)title;
    g_created = true;
}

static void test_on_commit(void* user_data, uint64_t surface_id, int buffer_fd, int w, int h, int stride) {
    (void)user_data; (void)surface_id; (void)buffer_fd; (void)w; (void)h; (void)stride;
    g_committed = true;
}

static void test_on_destroy(void* user_data, uint64_t surface_id) {
    (void)user_data; (void)surface_id;
    g_destroyed = true;
}

void test_louvre_lifecycle() {
    std::cout << "[Test 1] Louvre Compositor Lifecycle... ";
    LouvreContextHandle comp = louvre_compositor_create("wayland-test-0", nullptr);
    assert(comp != nullptr);

    louvre_set_surface_create_cb(comp, test_on_create);
    louvre_set_surface_commit_cb(comp, test_on_commit);
    louvre_set_surface_destroy_cb(comp, test_on_destroy);

    int res = louvre_compositor_poll_events(comp, 10);
    assert(res == LOUVRE_SUCCESS);

    louvre_compositor_destroy(comp);
    std::cout << "PASSED\n";
}

void test_louvre_errors() {
    std::cout << "[Test 2] Louvre Error Robustness... ";
    assert(louvre_dispatch_pointer_motion(nullptr, 1, 0.5, 0.5) == LOUVRE_ERR_INVALID_HANDLE);
    assert(louvre_dispatch_pointer_button(nullptr, 1, 0x110, 1) == LOUVRE_ERR_INVALID_HANDLE);
    assert(louvre_compositor_poll_events(nullptr, 0) == LOUVRE_ERR_INVALID_HANDLE);
    std::cout << "PASSED\n";
}

int main() {
    std::cout << "========================================\n";
    std::cout << " Running Louvre Provider Contract Tests \n";
    std::cout << "========================================\n";

    test_louvre_lifecycle();
    test_louvre_errors();

    std::cout << "\nAll Louvre Contract Tests PASSED successfully.\n";
    return 0;
}
