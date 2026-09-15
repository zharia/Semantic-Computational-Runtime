# Sprint 02: Spatial Hierarchy & Composition

**Parent Milestone:** [Milestone 003: PI-CAVE-001C Spatial Semantics](../spec.md)  
**Derived from:** `spec.md` (Sections 12, 79)  
**Governing Documents:** [`docs/116_SPATIAL_STATE_MODEL.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/docs/116_SPATIAL_STATE_MODEL.md)  
**Status:** Planned  

---

## 1. Mission

Implement the hierarchical spatial tree manager, enabling nested reference frame composition from Desktop root down to individual surface elements with dirty-flag caching for real-time frame generation.

---

## 2. Technical Specifications

### 2.1 Hierarchy Tree Structure
```text
Desktop World Frame (Root: Identity)
   └── Workspace Frame (Translation / Offset in Space)
         └── Application Window Frame (Orientation, Scale, Position)
               ├── Surface Frame (Client surface quad)
               └── Child Sub-surface Frame (Popups, Tooltips, Menus)
```

### 2.2 Transform Composition Engine
```mojo
struct SpatialTreeManager:
    var frames: Dict[SemanticId, ReferenceFrame]

    fn get_world_transform(mut self, frame_id: SemanticId) raises -> Transform3D:
        var frame = self.frames[frame_id]
        if not frame.is_dirty:
            return frame.cached_world_transform

        if frame.parent_frame_id is None:
            frame.cached_world_transform = frame.local_transform
        else:
            var parent_world = self.get_world_transform(frame.parent_frame_id.value())
            frame.cached_world_transform = parent_world.compose(frame.local_transform)

        frame.is_dirty = False
        self.frames[frame_id] = frame
        return frame.cached_world_transform

    fn mark_dirty(mut self, frame_id: SemanticId):
        # Invalidate frame and recursively mark all descendants dirty
        ...
```

---

## 3. Verification & Invariants

1. **Hierarchy Integrity:** Verify that cycles in `parent_frame_id` are rejected upon attachment.
2. **Cache Invalidation:** Verify that modifying a workspace transform immediately marks all child surface frames dirty.
3. **World Coordinate Correctness:** Test a 3-tier hierarchy; assert that moving the workspace by $(10, 0, 0)$ moves a child surface at $(2, 3, 0)$ to $(12, 3, 0)$ in world coordinates.
