# Milestone 009: PI-CAVE-001I — Semantic Field Effects

**Parent RoadMap:** [milestones/README.md](../README.md)  
**Target Area:** `applications/cave/program_increments/v0.0.1_PI-CAVE-001/milestones/009_PI-CAVE-001I_effect/`  
**Derived from:** `spec.md` (Sections 24, 25, 26, 27, 56, 76, 78, 80, 81, 95, 97)  
**Governing Documents:** [`docs/107_SEMANTIC_TRANSITION_CALCULUS.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/docs/107_SEMANTIC_TRANSITION_CALCULUS.md), [`docs/117_FIELD_PARTITIONING_AND_DISTRIBUTED_EXECUTION.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/docs/117_FIELD_PARTITIONING_AND_DISTRIBUTED_EXECUTION.md)  
**Status:** Planned  

---

## 1. Objective

Implement **Semantic Field Effects** in Cave, proving that interactive visual effects (such as a smoke or particle trail generated when dragging an application window) can be modeled, executed, and verified as **formal semantic state transformations within a volumetric field**, rather than ad-hoc GPU shader tricks or hardcoded rendering hacks.

---

## 2. Compliance with Authoritative Architecture

1. **Effects as Semantic Transformations ([`docs/107_SEMANTIC_TRANSITION_CALCULUS.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/docs/107_SEMANTIC_TRANSITION_CALCULUS.md)):**
   An effect is a formal state transition $\tau_{\text{effect}}: \text{Field} \times \text{Delta} \to \text{Field}'$ executed in response to a semantic event (e.g. `SurfaceMovedEvent`).
2. **Coupled Dynamics Separation ([`docs/117_FIELD_PARTITIONING_AND_DISTRIBUTED_EXECUTION.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/docs/117_FIELD_PARTITIONING_AND_DISTRIBUTED_EXECUTION.md)):**
   The effect pipeline decouples velocity injection, advection, dissipation, and rendering:
   $$\text{Surface Velocity} \xrightarrow{\text{inject}} \vec{V} \xrightarrow{\text{advect}} \rho \xrightarrow{\text{dissipate}} \rho' \xrightarrow{\text{manifest}} \text{Volumetric Render}$$
3. **Physics Boundary Clarity:**
   Full rigid-body collision simulation (Chrono) is demarcated as a separate provider capability; the minimum POC effect is restricted to fluid advection driven by kinematic window movement.

---

## 3. Sprint Breakdown

```text
009_PI-CAVE-001I_effect/
├── spec.md
└── sprints/
    ├── sprint_01_semantic_effect_pipeline.md      # Formal effect state transition pipeline
    ├── sprint_02_smoke_and_advection_effect.md    # Velocity injection & sparse density advection
    ├── sprint_03_levelset_and_physics_boundary.md # Distance field level sets & Chrono boundary
    └── sprint_04_volumetric_effect_rendering.md   # OpenVDB/OGRE volumetric raymarching
```

### [Sprint 01: Semantic Effect Pipeline Definition](sprints/sprint_01_semantic_effect_pipeline.md)
- Formalize `SemanticEffect` entity and pipeline schema.
- Map semantic triggers (`SurfaceMovedEvent`, `PointerMovedEvent`) to field impulse deltas.
- Define decay, diffusion, and dissipation parameters.

### [Sprint 02: Minimum Smoke & Advection Field Effect](sprints/sprint_02_smoke_and_advection_effect.md)
- Compute surface boundary velocity vector from window frame delta: $\vec{v}_{\text{surf}} = \frac{\Delta \vec{p}}{\Delta t}$.
- Inject velocity into OpenVDB `Vec3SGrid` along the trailing surface edge.
- Advect OpenVDB `FloatGrid` density field over time using MacCormack / semi-Lagrangian advection.

### [Sprint 03: Optional Level-Set & Physics Boundary](sprints/sprint_03_levelset_and_physics_boundary.md)
- Evaluate narrow-band level-set boundaries around window geometries.
- Document and enforce the boundary between kinematic spatial fields and general rigid-body physics engines (Chrono).

### [Sprint 04: Volumetric Effect Rendering](sprints/sprint_04_volumetric_effect_rendering.md)
- Implement volumetric raymarching shader in OGRE/OpenGL sampling OpenVDB/NanoVDB density grids.
- Composite volumetric smoke seamlessly with opaque textured surface quads.

---

## 4. Milestone Exit Criteria

1. Moving a window produces a visible, fluid-like smoke trail adhering to Navier-Stokes advection approximations.
2. The entire effect pipeline operates through formal semantic state transformations.
3. Volumetric rendering achieves stable $\ge 60$ FPS without frame stuttering.
