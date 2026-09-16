#include "louvre_c_api.h"

#include <string>
#include <unordered_map>
#include <iostream>
#include <cstring>

#if __has_include(<Louvre/LCompositor.h>)
#include <Louvre/LCompositor.h>
#include <Louvre/LSurface.h>
#define SCR_HAS_NATIVE_LOUVRE 1
#else
#define SCR_HAS_NATIVE_LOUVRE 0
#endif

struct LouvreInternalContext {
    std::string socket_name;
    void* user_data = nullptr;

    LouvreSurfaceCreateFn on_create = nullptr;
    LouvreSurfaceCommitFn on_commit = nullptr;
    LouvreSurfaceDestroyFn on_destroy = nullptr;

    uint64_t next_synthetic_id = 1;
    std::unordered_map<uint64_t, std::string> active_surfaces;
};

extern "C" {

LouvreContextHandle louvre_compositor_create(const char* socket_name, void* user_data) {
    auto* ctx = new (std::nothrow) LouvreInternalContext();
    if (!ctx) return nullptr;

    ctx->socket_name = socket_name ? socket_name : "wayland-cave-0";
    ctx->user_data = user_data;

#if SCR_HAS_NATIVE_LOUVRE
    // Native Louvre initialization
#endif
    return static_cast<LouvreContextHandle>(ctx);
}

void louvre_set_surface_create_cb(LouvreContextHandle ctx, LouvreSurfaceCreateFn cb) {
    if (!ctx) return;
    static_cast<LouvreInternalContext*>(ctx)->on_create = cb;
}

void louvre_set_surface_commit_cb(LouvreContextHandle ctx, LouvreSurfaceCommitFn cb) {
    if (!ctx) return;
    static_cast<LouvreInternalContext*>(ctx)->on_commit = cb;
}

void louvre_set_surface_destroy_cb(LouvreContextHandle ctx, LouvreSurfaceDestroyFn cb) {
    if (!ctx) return;
    static_cast<LouvreInternalContext*>(ctx)->on_destroy = cb;
}

int louvre_dispatch_pointer_motion(LouvreContextHandle ctx, uint64_t surface_id, double local_u, double local_v) {
    if (!ctx) return LOUVRE_ERR_INVALID_HANDLE;
    auto* context = static_cast<LouvreInternalContext*>(ctx);
    if (context->active_surfaces.find(surface_id) == context->active_surfaces.end()) {
        return LOUVRE_ERR_CLIENT_DISCONNECT;
    }

    // In native Louvre: translate normalized (u, v) to surface local pixels and post event
    (void)local_u;
    (void)local_v;
    return LOUVRE_SUCCESS;
}

int louvre_dispatch_pointer_button(LouvreContextHandle ctx, uint64_t surface_id, uint32_t button, uint32_t state) {
    if (!ctx) return LOUVRE_ERR_INVALID_HANDLE;
    auto* context = static_cast<LouvreInternalContext*>(ctx);
    if (context->active_surfaces.find(surface_id) == context->active_surfaces.end()) {
        return LOUVRE_ERR_CLIENT_DISCONNECT;
    }

    (void)button;
    (void)state;
    return LOUVRE_SUCCESS;
}

int louvre_compositor_poll_events(LouvreContextHandle ctx, int timeout_ms) {
    if (!ctx) return LOUVRE_ERR_INVALID_HANDLE;
    (void)timeout_ms;
    return LOUVRE_SUCCESS;
}

void louvre_compositor_destroy(LouvreContextHandle ctx) {
    if (!ctx) return;
    auto* context = static_cast<LouvreInternalContext*>(ctx);

    // Issue destroy callbacks for all open surfaces on shutdown
    if (context->on_destroy) {
        for (const auto& p : context->active_surfaces) {
            context->on_destroy(context->user_data, p.first);
        }
    }
    delete context;
}

} // extern "C"
