# Sprint 02: Semantic Surface Scene Node Binding

**Parent Milestone:** [Milestone 006: PI-CAVE-001F Rendering Provider](../spec.md)  
**Derived from:** `spec.md` (Sections 14, 53)  
**Governing Documents:** [`docs/108_EXECUTION_MANIFESTATION_AND_CONFORMANCE.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/docs/108_EXECUTION_MANIFESTATION_AND_CONFORMANCE.md)  
**Status:** Planned  

---

## 1. Mission

Implement the binding between SCR `SurfaceEntity` reference frames and OGRE `SceneNode` instances, mapping 3D spatial transforms to scene nodes and dynamically rendering textured planar quads.

---

## 2. Technical Specifications

### 2.1 Procedural Surface Quad Generation
For each registered surface with width $W$ and height $H$:
* Generate a unit quad mesh on the $XY$ plane:
  $$\text{Vertices: } (0, 0, 0), (W, 0, 0), (W, H, 0), (0, H, 0)$$
  $$\text{Normals: } (0, 0, 1)$$
  $$\text{UVs: } (0, 1), (1, 1), (1, 0), (0, 0)$$
* Attach the mesh to an `Ogre::Entity` parented to a dedicated `Ogre::SceneNode`.

### 2.2 Transform Synchronization Loop
On each engine frame update:
```cpp
void CaveOgreRenderer::updateSurfaceTransform(uint64_t surface_id, const TransformDTO &transform) {
    auto *node = m_surfaceNodes[surface_id];
    node->setPosition(transform.pos_x, transform.pos_y, transform.pos_z);
    node->setOrientation(Ogre::Quaternion(transform.rot_w, transform.rot_x, transform.rot_y, transform.rot_z));
    node->setScale(transform.scale_x, transform.scale_y, transform.scale_z);
}
```

---

## 3. Verification & Testing Tasks

1. **Geometry Scale Test:** Verify that an $800 \times 600$ pixel window generates an quad scaled according to the desktop's physical metric scale (e.g. 0.8m $\times$ 0.6m).
2. **Transform Precision:** Assert that translating the surface in SCR moves the OGRE scene node to within $10^{-5}$ precision.
3. **Dynamic Quad Resizing:** Verify that resizing a window recomputes quad vertex positions without recreating the entire scene node.
