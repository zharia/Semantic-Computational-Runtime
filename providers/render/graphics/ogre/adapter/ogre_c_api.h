#ifndef SCR_PROVIDERS_OGRE_C_API_H
#define SCR_PROVIDERS_OGRE_C_API_H

#include <stdint.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

#define OGRE_SUCCESS               0
#define OGRE_ERR_INVALID_HANDLE  (-1)
#define OGRE_ERR_TEXTURE_FAILED  (-2)
#define OGRE_ERR_RENDER_FAILED   (-3)

typedef void* OgreContextHandle;
typedef void* OgreNodeHandle;

/**
 * Initialize OGRE rendering context (supports headless and offscreen rendering).
 */
OgreContextHandle ogre_init_headless(void);

/**
 * Instantiate a 2D surface projection quad mesh within the 3D scene.
 */
OgreNodeHandle ogre_create_quad(OgreContextHandle ctx, const char* name, float width, float height);

/**
 * Update the 3D spatial pose (position + quaternion) of a scene node quad.
 */
int ogre_set_node_transform(OgreNodeHandle node, float px, float py, float pz, float qx, float qy, float qz, float qw);

/**
 * Bind or update RGBA pixel texture on the target quad.
 */
int ogre_attach_texture(OgreNodeHandle node, uint32_t width, uint32_t height, const uint8_t* rgba_pixels);

/**
 * Execute one forward render pass.
 */
int ogre_render_one_frame(OgreContextHandle ctx);

/**
 * Destroy a quad node and release its GPU resources.
 */
void ogre_destroy_node(OgreContextHandle ctx, OgreNodeHandle node);

/**
 * Shut down the OGRE rendering context.
 */
void ogre_shutdown(OgreContextHandle ctx);

#ifdef __cplusplus
}
#endif

#endif /* SCR_PROVIDERS_OGRE_C_API_H */
