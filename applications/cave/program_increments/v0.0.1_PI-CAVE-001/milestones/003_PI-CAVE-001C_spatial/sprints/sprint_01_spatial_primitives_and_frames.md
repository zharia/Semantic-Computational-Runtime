# Sprint 01: Spatial Primitives & Reference Frames

**Parent Milestone:** [Milestone 003: PI-CAVE-001C Spatial Semantics](../spec.md)  
**Derived from:** `spec.md` (Sections 11, 12, 79)  
**Governing Documents:** [`docs/114_SPATIAL_SEMANTICS.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/docs/114_SPATIAL_SEMANTICS.md)  
**Status:** Planned  

---

## 1. Mission

Implement mathematical 3D spatial primitives, rigid/affine transformation operators, bounding volumes, and explicit reference frames in Mojo conforming to SCR spatial semantics.

---

## 2. Technical Specifications & Data Models

### 2.1 Spatial Primitives
```mojo
@value
struct Point3D:
    var x: Float64
    var y: Float64
    var z: Float64

@value
struct Vector3D:
    var x: Float64
    var y: Float64
    var z: Float64
    
    fn length(self) -> Float64:
        return math.sqrt(self.x * self.x + self.y * self.y + self.z * self.z)
    
    fn normalize(self) -> Vector3D:
        var l = self.length()
        return Vector3D(self.x / l, self.y / l, self.z / l)

@value
struct Quaternion:
    var w: Float64
    var x: Float64
    var y: Float64
    var z: Float64

@value
struct Transform3D:
    var translation: Vector3D
    var rotation: Quaternion
    var scale: Vector3D

    fn to_matrix4x4(self) -> Matrix4x4:
        ...

    fn compose(self, child: Transform3D) -> Transform3D:
        ...

    fn inverse(self) -> Transform3D:
        ...
```

### 2.2 Reference Frame
```mojo
struct ReferenceFrame:
    var id: SemanticId
    var parent_frame_id: Optional[SemanticId]
    var local_transform: Transform3D
    var cached_world_transform: Transform3D
    var is_dirty: Bool
    var bounds: BoundingBox3D
```

---

## 3. Verification & Invariants

1. **Transform Invertibility:** Verify that $\forall T, \quad T \circ T^{-1} = I$ within numerical tolerance ($10^{-6}$).
2. **Associativity:** Verify that $(T_1 \circ T_2) \circ T_3 = T_1 \circ (T_2 \circ T_3)$.
3. **Identity Element:** Verify that composition with $T_{\text{identity}}$ leaves any transform unchanged.
