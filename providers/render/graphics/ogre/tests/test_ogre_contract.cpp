#include "../adapter/ogre_c_api.h"
#include <cassert>
#include <iostream>
#include <vector>

void test_scene_node_lifecycle() {
    std::cout << "[Test 1] OGRE Quad Creation and Transform... ";
    OgreContextHandle ctx = ogre_init_headless();
    assert(ctx != nullptr);

    OgreNodeHandle quad = ogre_create_quad(ctx, "surface_quad_01", 1920.0f, 1080.0f);
    assert(quad != nullptr);

    // Update spatial pose
    int res = ogre_set_node_transform(quad, 10.0f, 20.0f, -5.0f, 0.0f, 0.7071f, 0.0f, 0.7071f);
    assert(res == OGRE_SUCCESS);

    // Attach texture
    std::vector<uint8_t> dummy_rgba(64 * 64 * 4, 255);
    res = ogre_attach_texture(quad, 64, 64, dummy_rgba.data());
    assert(res == OGRE_SUCCESS);

    // Render frame
    res = ogre_render_one_frame(ctx);
    assert(res == OGRE_SUCCESS);

    // Destroy node and verify clean shutdown
    ogre_destroy_node(ctx, quad);
    ogre_shutdown(ctx);
    std::cout << "PASSED\n";
}

void test_ogre_error_handling() {
    std::cout << "[Test 2] OGRE Error Handling... ";
    assert(ogre_create_quad(nullptr, "fail", 100, 100) == nullptr);
    assert(ogre_set_node_transform(nullptr, 0, 0, 0, 0, 0, 0, 1) == OGRE_ERR_INVALID_HANDLE);
    assert(ogre_attach_texture(nullptr, 0, 0, nullptr) == OGRE_ERR_INVALID_HANDLE);
    std::cout << "PASSED\n";
}

int main() {
    std::cout << "======================================\n";
    std::cout << " Running OGRE Provider Contract Tests \n";
    std::cout << "======================================\n";

    test_scene_node_lifecycle();
    test_ogre_error_handling();

    std::cout << "\nAll OGRE Contract Tests PASSED successfully.\n";
    return 0;
}
