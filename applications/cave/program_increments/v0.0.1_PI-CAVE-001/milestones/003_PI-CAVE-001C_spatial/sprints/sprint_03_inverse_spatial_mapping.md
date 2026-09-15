# Sprint 03: Inverse Spatial Mapping & Hit Testing

**Parent Milestone:** [Milestone 003: PI-CAVE-001C Spatial Semantics](../spec.md)  
**Derived from:** `spec.md` (Sections 13, 51)  
**Governing Documents:** [`docs/114_SPATIAL_SEMANTICS.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/docs/114_SPATIAL_SEMANTICS.md) §4.3  
**Status:** Planned  

---

## 1. Mission

Implement inverse spatial mapping to project 2D screen pointer inputs (or 3D spatial rays) through the inverted spatial transform tree to calculate precise local coordinates $(u, v)$ on target semantic surfaces.

---

## 2. Mathematical Formulation & Algorithm

### 2.1 Viewport Ray Generation
Given a camera with projection matrix $M_{\text{proj}}$ and view matrix $M_{\text{view}}$, a screen coordinate $(x_s, y_s) \in [-1, 1] \times [-1, 1]$ generates a world-space ray:
$$\vec{r}(t) = \vec{o} + t \cdot \vec{d}, \quad t \ge 0$$
where $\vec{o} = \text{camera\_position}$ and $\vec{d} = \text{normalize}((M_{\text{proj}} \cdot M_{\text{view}})^{-1} \cdot (x_s, y_s, 1, 1)^T)$.

### 2.2 Surface Quad Intersection
For each active surface quad defined in local space with width $W$ and height $H$ spanning $[0, W] \times [0, H]$ on the plane $z = 0$:
1. Transform world ray into surface local space:
   $$\vec{r}_{\text{local}}(t) = T_{\text{world}}^{-1} \cdot \vec{r}(t)$$
2. Compute intersection with local plane $z=0$:
   $$t_{\text{hit}} = -\frac{o_{z,\text{local}}}{d_{z,\text{local}}}$$
3. Check bounds:
   $$u = \frac{x_{\text{local}}}{W}, \quad v = \frac{y_{\text{local}}}{H}$$
   Hit is valid if $t_{\text{hit}} > 0 \land u \in [0, 1] \land v \in [0, 1]$.
4. Select the closest hit (minimum $t_{\text{hit}}$).

---

## 3. Verification & Invariants

1. **Orthogonal Ray Hit Test:** Verify that a pointer centered on a surface at $(0, 0, -5)$ yields $(u, v) = (0.5, 0.5)$.
2. **Rotated Surface Hit Test:** Rotate surface by $45^\circ$ along the Y-axis; verify that the hit calculation correctly resolves projected local $(u, v)$.
3. **Miss Detection:** Verify that rays missing the surface bounding quad return `None` without false positives.
4. **Z-Ordering Resolution:** When two surfaces overlap along the ray, assert that the closer surface receives the hit event.
