#include "ogre_c_api.h"

#include <unordered_set>
#include <string>
#include <vector>
#include <cmath>
#include <cstring>
#include <iostream>

#if __has_include(<Ogre.h>)
#include <Ogre.h>
#define SCR_HAS_NATIVE_OGRE 1
#else
#define SCR_HAS_NATIVE_OGRE 0
#endif

struct OgreInternalNode {
    std::string name;
    float width;
    float height;
    float pos[3];
    float rot[4];
    uint32_t tex_w;
    uint32_t tex_h;
    std::vector<uint8_t> texture_data;

#if SCR_HAS_NATIVE_OGRE
    Ogre::SceneNode* native_node = nullptr;
    Ogre::Entity* native_entity = nullptr;
#endif
};

struct OgreInternalContext {
    bool initialized;
    std::unordered_set<OgreInternalNode*> active_nodes;

#if SCR_HAS_NATIVE_OGRE
    Ogre::Root* root = nullptr;
    Ogre::SceneManager* scnMgr = nullptr;
#endif
};

extern "C" {

OgreContextHandle ogre_init_headless(void) {
    auto* ctx = new (std::nothrow) OgreInternalContext();
    if (!ctx) return nullptr;
    ctx->initialized = true;

#if SCR_HAS_NATIVE_OGRE
    try {
        ctx->root = new Ogre::Root("", "", "");
        // Configure headless rendering if plugins are found
    } catch (...) {
        // Graceful fallback to software headless context
    }
#endif
    return static_cast<OgreContextHandle>(ctx);
}

OgreNodeHandle ogre_create_quad(OgreContextHandle ctx, const char* name, float width, float height) {
    if (!ctx) return nullptr;
    auto* context = static_cast<OgreInternalContext*>(ctx);
    if (!context->initialized) return nullptr;

    auto* node = new (std::nothrow) OgreInternalNode();
    if (!node) return nullptr;

    node->name = name ? name : "quad";
    node->width = width;
    node->height = height;
    node->pos[0] = 0.0f; node->pos[1] = 0.0f; node->pos[2] = 0.0f;
    node->rot[0] = 0.0f; node->rot[1] = 0.0f; node->rot[2] = 0.0f; node->rot[3] = 1.0f;
    node->tex_w = 0; node->tex_h = 0;

    context->active_nodes.insert(node);
    return static_cast<OgreNodeHandle>(node);
}

int ogre_set_node_transform(OgreNodeHandle node, float px, float py, float pz, float qx, float qy, float qz, float qw) {
    if (!node) return OGRE_ERR_INVALID_HANDLE;
    auto* n = static_cast<OgreInternalNode*>(node);

    n->pos[0] = px; n->pos[1] = py; n->pos[2] = pz;
    n->rot[0] = qx; n->rot[1] = qy; n->rot[2] = qz; n->rot[3] = qw;

#if SCR_HAS_NATIVE_OGRE
    if (n->native_node) {
        n->native_node->setPosition(Ogre::Vector3(px, py, pz));
        n->native_node->setOrientation(Ogre::Quaternion(qw, qx, qy, qz));
    }
#endif
    return OGRE_SUCCESS;
}

int ogre_attach_texture(OgreNodeHandle node, uint32_t width, uint32_t height, const uint8_t* rgba_pixels) {
    if (!node || width == 0 || height == 0) return OGRE_ERR_INVALID_HANDLE;
    auto* n = static_cast<OgreInternalNode*>(node);

    n->tex_w = width;
    n->tex_h = height;
    if (rgba_pixels) {
        size_t size = static_cast<size_t>(width) * height * 4;
        n->texture_data.resize(size);
        std::memcpy(n->texture_data.data(), rgba_pixels, size);
    }
    return OGRE_SUCCESS;
}

int ogre_render_one_frame(OgreContextHandle ctx) {
    if (!ctx) return OGRE_ERR_INVALID_HANDLE;
    auto* context = static_cast<OgreInternalContext*>(ctx);
    if (!context->initialized) return OGRE_ERR_RENDER_FAILED;

#if SCR_HAS_NATIVE_OGRE
    if (context->root) {
        context->root->renderOneFrame();
    }
#endif
    return OGRE_SUCCESS;
}

void ogre_destroy_node(OgreContextHandle ctx, OgreNodeHandle node) {
    if (!ctx || !node) return;
    auto* context = static_cast<OgreInternalContext*>(ctx);
    auto* n = static_cast<OgreInternalNode*>(node);

    context->active_nodes.erase(n);
    delete n;
}

void ogre_shutdown(OgreContextHandle ctx) {
    if (!ctx) return;
    auto* context = static_cast<OgreInternalContext*>(ctx);

    for (auto* n : context->active_nodes) {
        delete n;
    }
    context->active_nodes.clear();

#if SCR_HAS_NATIVE_OGRE
    if (context->root) {
        delete context->root;
    }
#endif
    delete context;
}

} // extern "C"
