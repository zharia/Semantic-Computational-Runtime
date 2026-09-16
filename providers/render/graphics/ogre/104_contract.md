# ogre Provider Contract

**Provider:** ogre  
**Domain:** render  
**Subdomain:** graphics  
**Version:** 0.1.0  
**Status:** Normative Contract  
**Governing Documents:** [`docs/108_EXECUTION_MANIFESTATION_AND_CONFORMANCE.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/docs/108_EXECUTION_MANIFESTATION_AND_CONFORMANCE.md), [`applications/cave/.../006_PI-CAVE-001F_rendering/spec.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/applications/cave/program_increments/v0.0.1_PI-CAVE-001/milestones/006_PI-CAVE-001F_rendering/spec.md)  

---

## 1. Contract Overview

This contract defines the operational obligations for the OGRE 3D graphics provider. It governs the creation of the scene environment, quad geometry instantiation for 2D surface projection into 3D space, spatial transform synchronisation, texture mapping, and frame rendering.

---

## 2. Operations & C ABI Interface

* `ogre_init_headless() -> OgreContextHandle`
* `ogre_create_quad(OgreContextHandle ctx, const char* name, float width, float height) -> OgreNodeHandle`
* `ogre_set_node_transform(OgreNodeHandle node, float px, float py, float pz, float qx, float qy, float qz, float qw) -> int`
* `ogre_attach_texture(OgreNodeHandle node, uint32_t width, uint32_t height, const uint8_t* rgba_pixels) -> int`
* `ogre_render_one_frame(OgreContextHandle ctx) -> int`
* `ogre_destroy_node(OgreContextHandle ctx, OgreNodeHandle node) -> void`
* `ogre_shutdown(OgreContextHandle ctx) -> void`

---

## 3. Invariants & Guarantees

1. **Transform Monotonicity:** Updating a node's transform immediately reflects in the scene node local matrix.
2. **Context Isolation:** Scene nodes created under context $C_1$ cannot be referenced or destroyed by context $C_2$.
3. **No Semantic Leaks:** Node handles are opaque pointers; destroying a node releases OGRE memory without emitting semantic events.
4. **Failure Robustness:** Passing invalid node handles returns `OGRE_ERR_INVALID_HANDLE` without crashing.

---

## 4. Return Codes

* `OGRE_SUCCESS = 0`
* `OGRE_ERR_INVALID_HANDLE = -1`
* `OGRE_ERR_TEXTURE_FAILED = -2`
* `OGRE_ERR_RENDER_FAILED = -3`
