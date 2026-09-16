#ifndef SCR_PROVIDERS_LOUVRE_C_API_H
#define SCR_PROVIDERS_LOUVRE_C_API_H

#include <stdint.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

#define LOUVRE_SUCCESS                 0
#define LOUVRE_ERR_INVALID_HANDLE    (-1)
#define LOUVRE_ERR_SOCKET_FAILED     (-2)
#define LOUVRE_ERR_CLIENT_DISCONNECT (-3)

typedef void* LouvreContextHandle;

typedef void (*LouvreSurfaceCreateFn)(void* user_data, uint64_t surface_id, const char* title);
typedef void (*LouvreSurfaceCommitFn)(void* user_data, uint64_t surface_id, int buffer_fd, int w, int h, int stride);
typedef void (*LouvreSurfaceDestroyFn)(void* user_data, uint64_t surface_id);

/**
 * Instantiate and bind a Louvre Wayland compositor context.
 */
LouvreContextHandle louvre_compositor_create(const char* socket_name, void* user_data);

/**
 * Register callbacks for semantic entity lifecycle mapping.
 */
void louvre_set_surface_create_cb(LouvreContextHandle ctx, LouvreSurfaceCreateFn cb);
void louvre_set_surface_commit_cb(LouvreContextHandle ctx, LouvreSurfaceCommitFn cb);
void louvre_set_surface_destroy_cb(LouvreContextHandle ctx, LouvreSurfaceDestroyFn cb);

/**
 * Forward transformed pointer motion in normalized surface coordinates [0, 1].
 */
int louvre_dispatch_pointer_motion(LouvreContextHandle ctx, uint64_t surface_id, double local_u, double local_v);

/**
 * Forward pointer button event (button = linux input event code, state = 1 pressed, 0 released).
 */
int louvre_dispatch_pointer_button(LouvreContextHandle ctx, uint64_t surface_id, uint32_t button, uint32_t state);

/**
 * Poll Wayland file descriptors and dispatch pending protocol events.
 */
int louvre_compositor_poll_events(LouvreContextHandle ctx, int timeout_ms);

/**
 * Destroy the compositor context and release socket resources.
 */
void louvre_compositor_destroy(LouvreContextHandle ctx);

#ifdef __cplusplus
}
#endif

#endif /* SCR_PROVIDERS_LOUVRE_C_API_H */
