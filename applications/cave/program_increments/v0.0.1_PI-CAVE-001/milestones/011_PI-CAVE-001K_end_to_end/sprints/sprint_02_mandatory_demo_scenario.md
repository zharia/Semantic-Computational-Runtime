# Sprint 02: Mandatory Demonstration Scenario Execution

**Parent Milestone:** [Milestone 011: PI-CAVE-001K End-to-End & Acceptance](../spec.md)  
**Derived from:** `spec.md` (Sections 58, 59, 98)  
**Governing Documents:** [`docs/108_EXECUTION_MANIFESTATION_AND_CONFORMANCE.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/docs/108_EXECUTION_MANIFESTATION_AND_CONFORMANCE.md), [`docs/114_SPATIAL_SEMANTICS.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/docs/114_SPATIAL_SEMANTICS.md)  
**Status:** Planned  

---

## 1. Mission

Implement and execute the mandatory, reproducible demonstration scenario defined in `spec.md` §58 and §59. Validate that an end-user running a standard Wayland client experiences full 3D spatial transformation, inverse pointer interaction, and real-time volumetric smoke trails powered by OpenVDB, while maintaining invariant semantic identity and lifecycle provenance across provider reloads and client exit.

---

## 2. Technical Specifications & Step-by-Step Scenario Protocol

### 2.1 The 20-Step Execution Sequence (AT-CAVE-001)

| Step | Action | Architectural Verification | Expected State |
| :--- | :--- | :--- | :--- |
| **01** | Start Cave Core | SCR Runtime initializes world and identity allocator | System state = `RUNNING` |
| **02** | Start Compositor | Louvre Wayland socket opens (`/run/user/1000/wayland-1`) | Socket listening |
| **03** | Launch Client | Real client (`foot` or synthetic tester) connects | Connection accepted |
| **04** | Create Surface | Client issues `wl_compositor.create_surface` | Semantic Surface node allocated in ESH |
| **05** | Record ID | Capture `surface_id = surface.identity()` | UUID recorded in test journal |
| **06** | Move Surface | Inject 3D translation $\Delta \mathbf{p} = (2.0, 1.5, -0.5)$ | Spatial transform hyperedge updated |
| **07** | Rotate Surface | Apply quaternion rotation $\mathbf{q} = \text{RotY}(45^\circ)$ | Rotation manifested in OGRE scene node |
| **08** | Verify Identity | Assert `surface.identity() == surface_id` | **Invariant PASS** |
| **09** | Move Pointer | Physical pointer moves across 3D window quad | Screen ray intersection performed |
| **10** | Inverse Map | Ray cast computes local $(u, v) \in [0, 1]^2$ | Local coordinates sent to Wayland client |
| **11** | Trigger Effect | Movement velocity triggers kinematic smoke advection | Semantic Effect hyperedge activated |
| **12** | Velocity Field | Surface motion bounds inject velocity vector field | OpenVDB `Vec3SGrid` populated |
| **13** | Density Field | Smoke source injects scalar density | OpenVDB `FloatGrid` populated |
| **14** | Field Advection | Run RK3 advection step $\Delta t = 16.6\text{ms}$ | Smoke trail forms dynamically behind surface |
| **15** | Render Volume | Volume raymarching / NanoVDB blit to viewport | Visual smoke plume visible in viewport |
| **16** | Replace Resource| Trigger OpenGL texture / EGLImage reallocation | Provider handle changes; metadata refreshed |
| **17** | Verify Identity | Assert `surface.identity() == surface_id` | **Invariant PASS** (Survives provider reload) |
| **18** | Terminate Client| Send `SIGTERM` to client; client disconnects | `wl_surface.destroy` handled |
| **19** | Provider Teardown| OGRE quad destroyed, OpenVDB grids retired | Zero GPU resource leaks |
| **20** | Lifecycle Audit | Audit provenance trail from creation to retirement | Complete lifecycle log verified |

### 2.2 Visual Demonstration Layout (§59)
```text
┌────────────────────────────────────────────────────────┐
│                      Cave Desktop                      │
│                                                        │
│            ┌─────────────────────────┐                 │
│            │   Wayland Client (foot) │                 │
│            │  $ ls -la               │                 │
│            │  drwxr-xr-x 4 kobus ... │                 │
│            └────────────┬────────────┘                 │
│                         │ (Spatial Velocity Vector)    │
│                         ▼                              │
│                    ≋≋≋≋≋≋≋≋≋≋≋                         │
│                  ≋≋≋ OpenVDB ≋≋≋                       │
│                 ≋ Kinematic Smoke ≋                    │
│                   ≋≋ Advection ≋≋                      │
│                                                        │
│ 3D Spatial Frame / ESH Semantic Coordinate Space       │
└────────────────────────────────────────────────────────┘
```

---

## 3. Verification & Automated Test Scripting

1. **Automated Demo Runner (`test_mandatory_demo_scenario.mojo`):**
   * Script that executes all 20 steps programmatically using a headless Wayland client harness.
   * Logs every semantic ID, matrix state, and provider handle to `/tmp/cave_demo_provenance.json`.
2. **Interactive Visual Mode:**
   * Script to launch interactive session where user can grab and drag a window quad with mouse, witnessing real-time OpenVDB smoke trails.
3. **Provider Resource Invalidation Test:**
   * Force OpenGL context loss / recreate texture while window is moving; assert zero flicker or ID regeneration.
