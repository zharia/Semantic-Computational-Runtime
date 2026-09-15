# Sprint 02: Surface & Application Entities

**Parent Milestone:** [Milestone 004: PI-CAVE-001D Desktop Ontology](../spec.md)  
**Derived from:** `spec.md` (Sections 10.3, 10.4)  
**Governing Documents:** [`docs/103_SEMANTIC_MODEL.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/docs/103_SEMANTIC_MODEL.md)  
**Status:** Planned  

---

## 1. Mission

Implement `SurfaceEntity` and `ApplicationEntity` in Mojo, modeling 2D interactive surface quads, client application processes, and their parent-child relationships within workspaces.

---

## 2. Technical Specifications & Data Models

### 2.1 Application Entity
```mojo
struct ApplicationEntity:
    var id: SemanticId
    var app_id: String          # E.g. "org.gnome.Terminal"
    var process_id: Int
    var surfaces: List[SemanticId]
    var is_running: Bool
```

### 2.2 Surface Entity
```mojo
struct SurfaceEntity:
    var id: SemanticId
    var application_id: SemanticId
    var workspace_id: SemanticId
    var spatial_frame_id: SemanticId
    var active_buffer_id: Optional[SemanticId]
    var title: String
    var dimensions: Tuple[Int, Int]     # (width, height) in pixels
    var is_mapped: Bool
    var has_focus: Bool

    fn attach_buffer(mut self, buffer_id: SemanticId):
        self.active_buffer_id = buffer_id

    fn set_mapped(mut self, mapped: Bool):
        self.is_mapped = mapped
```

---

## 3. Verification & Invariants

1. **Owner Application Existence:** Every `SurfaceEntity` must reference a valid `ApplicationEntity`.
2. **Focus Exclusivity:** At most one surface within an active workspace can have `has_focus == True` simultaneously.
3. **Mapping Invariant:** An unmapped surface (`is_mapped == False`) does not produce rendering draw calls or ray hit test responses.
