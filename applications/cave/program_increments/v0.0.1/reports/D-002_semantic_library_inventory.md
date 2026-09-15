# D-002 — Semantic Library Inventory

**Program Increment:** CAVE-000  
**Artifact:** Semantic Library Inventory  
**Status:** Complete

## Inventory of SCR Semantic Library Domains

This inventory covers all directories under `lib/` as of the CAVE-000 investigation. Each domain is classified by its implementation maturity and specification status.

### Domain Inventory

| ID | Domain Path | Purpose | Maturity | Spec Status | Implementation Status |
|---|---|---|---|---|---|
| D-002-01 | `000_meta/` | Repository metadata and control-plane infrastructure | experimental | draft | not_started |
| D-002-02 | `101_Core/` | Foundational semantic domain — identity, value, entity, relationship, state, transformation, constraint, observation, resources, errors | experimental | draft | not_started |
| D-002-03 | `201_Data/` | Data structures and information — buffer, collection, compression, matrix, memory, object, record, serialization, sharding, sparse, structured, table, tensor, transfer, types, unstructured, values, vector | experimental | draft | not_started |
| D-002-04 | `202_Math/` | Mathematical computation — algebra, arithmetic, calculus, functions, integral, interpolation, probability, quaternion, random, scalar, statistics, symbolic, tensor, transforms | experimental | draft | not_started |
| D-002-05 | `203_Graph/` | Graph structures and algorithms — hypergraph, search | experimental | draft | not_started |
| D-002-06 | `301_Field/` | Field semantics — information distributed over domains | experimental | draft | not_started |
| D-002-07 | `302_Geometry/` | Geometric structures and operations | experimental | draft | not_started |
| D-002-08 | `303_Topology/` | Topological structures | experimental | draft | not_started |
| D-002-09 | `401_Morphology/` | Morphological computation | experimental | draft | not_started |
| D-002-10 | `501_Physics/` | Physical laws and quantities | experimental | draft | not_started |
| D-002-11 | `502_Dynamics/` | Dynamic systems | experimental | draft | not_started |
| D-002-12 | `503_Simulation/` | Simulation framework | experimental | draft | not_started |
| D-002-13 | `601_Agent/` | Agent semantics | experimental | draft | not_started |
| D-002-14 | `602_Neural/` | Neural computation | experimental | draft | not_started |
| D-002-15 | `603_Perception/` | Perception | experimental | draft | not_started |
| D-002-16 | `604_Control/` | Control systems | experimental | draft | not_started |
| D-002-17 | `701_Optimization/` | Optimization | experimental | draft | not_started |
| D-002-18 | `702_Learning/` | Machine learning | experimental | draft | not_started |
| D-002-19 | `703_Adaptation/` | Adaptation | experimental | draft | not_started |
| D-002-20 | `704_Evolution/` | Evolution | experimental | draft | not_started |
| D-002-21 | `705_Ecology/` | Ecology | experimental | draft | not_started |
| D-002-22 | `801_Spatial/` | Spatial structures and indexing | experimental | draft | not_started |
| D-002-23 | `802_Stream/` | Streaming computation | experimental | draft | not_started |
| D-002-24 | `901_Analysis/` | Cross-cutting analysis | experimental | draft | not_started |
| D-002-25 | `902_Interfaces/` | Cross-cutting interfaces — Stateless, Stochastic, Streamable, Temporal, Tileable, Transformable, Vectorizable | experimental | draft | not_started |
| D-002-26 | `903_Lowering/` | MLIR lowering infrastructure — Arith, Async, Bufferization, CF, External, GPU, Linalg, LLVM, Math, MemRef, Native, Runtime, SCF, SPIRV, Standard, Tensor, Vector | experimental | draft | not_started |
| D-002-27 | `904_Providers/` | Execution providers — Accelerator, CPU, Distributed, External, Geometry, GPU, Messaging, Neural, Numerical, Physics, Rendering, Spatial, Storage | experimental | draft | not_started |
| D-002-28 | `905_Transforms/` | Transformations — Canonicalization, Composition, Decomposition, Differentiation, Distribution, Fusion, Hardware, Lowering, Memory, Parallelization, Representation, Scheduling, Specialization, Tiling, Vectorization | experimental | draft | not_started |
| D-002-29 | `A01_Render/` | Rendering — Animation, Camera, Compute, Frame, Geometry, GPU, IR, Light, Lighting, Material, Mesh, Object, Occlusion, Output, Particle, PathTracing, Pipeline, Projection, Raster, RayTracing, RenderPass, RenderTarget, Resource, Scene, SceneGraph, Shadow, Stream, Texture, Transform, Vector, View, Visibility, Volume | experimental | draft | not_started |
| D-002-30 | `scr_kernel/` | Semantic kernel | experimental | draft | not_started |

### Key Findings

1. **All 30 domains are classified as `experimental`** with `draft` specification status and `not_started` implementation status — no domain has progressed beyond the initial specification phase.

2. **No domain has a `101_spec.md` file** — only `101_definition.md` files exist (33 files) plus one template at `lib/_templates/semantic_domain/015_DOMAIN_TEMPLATE/101_spec.md`.

3. **Core domain (`101_Core/`)** is the foundational domain, defining: Identity, Value, Entity, Object, Attribute, Relationship, Role, Hypergraph, Region, Reference, Representation, Pattern, Transformation, Operation, State, Delta, Event, Stream, Temporal, Causal, Provenance, Constraint, Capability, Contract, Equivalence, Query, Observation, Resource, Error.

4. **Reference Executor (Moji)** implements a semantic kernel with: Entity, Value (Variant[Int, Float64, Bool, String]), EntityDefinition, Relationship, NonNegativeConstraint, SemanticField. All 13/13 tests pass.

5. **Lean formal verification** covers 14 SCRFormal modules with 100+ verified theorems across identity, entity, relationship, state, transformation, constraint, equivalence, and invariants.

6. **No provider implementations exist** — 904_Providers/ has 12 subdirectories all at `not_started` status.

7. **No MLIR dialect** exists — 903_Lowering/ has 11 subdirectories all at `not_started` status.

8. **No rendering pipeline** exists — A01_Render/ has 40+ subdirectories all at `experimental`/draft status.

9. **Seed metadata** (`seed/000_meta/102_status.yaml`) establishes: seed as foundational-vocabulary, lib as normative-domain-semantics, lean as formal-proof-kernel, external as evidence-only.

10. **Gap classification** (per CAVE-000 §12): All currently discovered gaps are classified as GAP-E (Application Composition) since Cave requires OGRE/Louvre providers and rendering/spatial/dynamics semantics that are not yet in SCR.

---
*Inventory generated from evidence-based repository inspection per CAVE-000 §7. SCR Semantic Library Inventory. Classification based on status.yaml files, 101_definition.md content, and observed implementation state.*