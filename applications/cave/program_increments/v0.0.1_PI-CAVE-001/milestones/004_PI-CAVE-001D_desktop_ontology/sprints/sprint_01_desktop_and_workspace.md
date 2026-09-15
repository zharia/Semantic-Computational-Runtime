# Sprint 01: Desktop & Workspace Semantic Entities

**Parent Milestone:** [Milestone 004: PI-CAVE-001D Desktop Ontology](../spec.md)  
**Derived from:** `spec.md` (Sections 10.1, 10.2)  
**Governing Documents:** [`docs/103_SEMANTIC_MODEL.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/docs/103_SEMANTIC_MODEL.md)  
**Status:** Planned  

---

## 1. Mission

Implement `DesktopEntity` and `WorkspaceEntity` in Mojo as first-class semantic entities, defining their spatial containment, active workspace switching, and focus semantics.

---

## 2. Technical Specifications & Data Models

### 2.1 Desktop Entity
```mojo
struct DesktopEntity:
    var id: SemanticId
    var name: String
    var active_workspace: Optional[SemanticId]
    var workspaces: List[SemanticId]
    var spatial_frame_id: SemanticId

    fn switch_workspace(mut self, target_ws: SemanticId) raises:
        ...
```

### 2.2 Workspace Entity
```mojo
struct WorkspaceEntity:
    var id: SemanticId
    var name: String
    var parent_desktop_id: SemanticId
    var surface_ids: List[SemanticId]
    var spatial_frame_id: SemanticId
    var is_visible: Bool

    fn add_surface(mut self, surface_id: SemanticId):
        ...

    fn remove_surface(mut self, surface_id: SemanticId):
        ...
```

---

## 3. Verification & Invariants

1. **Active Workspace Validity:** `desktop.active_workspace` must always refer to a workspace present in `desktop.workspaces`.
2. **Workspace Isolation:** Switching active workspaces toggles `is_visible` without destroying or resetting child surface states.
3. **Reference Frame Alignment:** The workspace reference frame must be a direct child of the desktop world frame.
