# D-008 — CAVE-001 Implementation Plan

**Program Increment:** CAVE-000  
**Artifact:** CAVE-001 Implementation Plan  
**Status:** Complete — derived from CAVE-000 analysis

## Implementation Direction

Per CAVE-000 §18 (Completion Criteria) and §70 (First Execution Instruction): "Do not begin mass implementation until these artefacts exist." The CAVE-001 implementation plan is derived from the evidence collected during CAVE-000, not predetermined.

The fundamental architectural constraint (CAVE-000 §1495) states:

> **The objective of this program increment is therefore not to maximize code produced.**
> **It is to maximize architectural knowledge with evidence and establish the smallest correct implementation path for the next increment.**

### Minimum Set of Changes Required Before CAVE-001 Can Begin

Based on the CAVE-000 evidence analysis, the following changes are the **minimum required** before CAVE-001 can begin. These are ordered by dependency and priority.

---

## Priority 1: Semantic Library Specification (Gate 0 prerequisite)

### D-001 Repository Inventory — Already Complete
- All lib/ directories documented
- All domain relationships recorded
- Implementation status catalogued

### D-002 Semantic Library Inventory — Already Complete
- 30 domains inventoryed under `lib/`
- All classified as `experimental`/`draft`/`not_started`
- No domain has `101_spec.md` — this is the first fix

**CAVE-001 Action: Mandatory** — Every applicable lib/ directory MUST have a `101_spec.md` per the library specification programme (lib/101_definition.md §118-120). This is the foundational deliverable.

**Priority**: CRITICAL (blocks all downstream work)  
**Dependencies**: None  
**Evidence**: lib/101_definition.md §118: "Every applicable directory MUST contain 101_spec.md"

---

## Priority 2: Core Domain Specification

### D-002-02: `101_Core/` — Core Semantic Domain

**Required**: `101_spec.md` for Core domain with all 70 sections per template

**Key sections to populate** (per lib/_templates/semantic_domain/015_DOMAIN_TEMPLATE/101_spec.md):
- 1. Identity (Semantic Identity, Content Identity, Operation Identity, Region Identity)
- 2. Purpose (foundational semantic substrate)
- 3. Domain Definition (what Core represents)
- 4. Scope (identity, type, value, entity, object, attribute, relationship, role, hypergraph, region, reference, representation, pattern, transformation, operation, state, state transition, delta, event, stream, temporal, causal, provenance, constraint, capability, contract, composition, equivalence, query, observation, resource, error)
- 5. Non-Goals (what Core does NOT define)
- 6. Parent Relationship (null — root domain)
- 7. Child Domains (all 29 child domains under lib/)
- 8. Sibling Relationships (all domains at same level)
- 9. Semantic Model (C = (I, T, V, E, R, G, Q, X, O, S, Δ, Ev, St, τ, K, P, Cn, Cp, Eq, Obs, Res, Err))
- 10. Core Abstractions (identity, type, value, entity, object, attribute, relationship, role, hyperedge, region, reference, representation, pattern, transformation, operation, state, delta, event, stream, temporal, causal, provenance, constraint, capability, contract, equivalence, query, observation, resource, error)
- 11. Inputs (semantic concepts that feed into Core)
- 12. Outputs (semantic concepts that flow from Core)
- 13. Operations (define, execute, validate operations)
- 14. Invariants (CORE-INV-001 through CORE-INV-022)
- 15. Composition (how Core primitives compose)
- 16. MLIR Representation (how Core semantics map to MLIR)
- 17. Runtime Representation (how Core semantics map to runtime)
- 18. External Implementations and Adapters (Moji Reference Executor, Lean Formalisation)
- 19. Dependencies (required, optional, forbidden)
- 20. Error Semantics (error types, mapping)
- 21. Determinism and Reproducibility
- 22. Testing Requirements (semantic tests, invariant tests, unit tests, composition tests, IR tests, lowering tests, provider tests, equivalence tests)
- 23. Validation Requirements (semantic contract validation, implementation validation)
- 24. Security and Isolation Considerations
- 25. Performance Considerations
- 26. Extensibility (how new domains can be added)
- 27. Open Questions (all uncertainties recorded)
- 28. Implementation Status (all domains at experimental/not_started)
- 29. Specification History (initial version)

**Priority**: CRITICAL (foundational for all other work)  
**Dependencies**: D-001 repository inventory, D-002 semantic library inventory  
**Evidence**: lib/101_definition.md defines Core as foundational; golden-path.md §42 requires seed reviewed; reference executor passes 13/13 tests

---

### D-002-03: `201_Data/` — Data Structures Domain

**Required**: `101_spec.md` for Data domain

**Priority**: HIGH (supports Core and higher domains)  
**Dependencies**: D-002-02 Core specification  
**Evidence**: 25 subdirectories under 201_Data/ (Buffer, Collection, Compression, Dense, Locality, Matrix, Memory, Object, Partitioning, Record, Scalar, Sequence, Serialization, Sharding, Sparse, Structured, Table, Tensor, Transfer, Types, Unstructured, Values, Vector)

---

### D-002-04: `202_Math/` — Mathematical Computation Domain

**Required**: `101_spec.md` for Math domain

**Priority**: HIGH (supports Dynamics, Simulation, Rendering)  
**Dependencies**: D-002-02 Core specification  
**Evidence**: 26 subdirectories under 202_Math/ (Algebra, Arithmetic, Calculus, Functions, Integral, Interpolation, Probability, Quaternion, Random, Scalar, Statistics, Symbolic, Tensor, Transforms, Vector)

---

## Priority 3: Cave Requirement Refinement

### D-003 Cave Requirement Catalogue — Already Complete

The requirement catalogue is complete, but several requirements need refinement before CAVE-001:

**Requirements to refine** (GAP-B composition gaps — define the compositions):

1. **Transform composition** (CAVE-REQ-SPATIAL-006): Formalize transform = position + orientation + scale
2. **Damage event composition** (CAVE-REQ-RENDER-010): Formalize damage = Event + Observation
3. **External resource abstraction** (CAVE-REQ-RESOURCE-001): Formalize external resource = Resource capability + ownership composition
4. **Ownership composition** (CAVE-REQ-RESOURCE-003): Formalize ownership = Persistable + Stateless capability composition
5. **Lifetime composition** (CAVE-REQ-RESOURCE-004): Formalize lifetime = Event ⊕ Delta composition
6. **Dependency composition** (CAVE-REQ-GRAPH-006): Formalize dependency = Relationship + Constraint
7. **Damage event subtype** (CAVE-REQ-STREAM-005): Formalize damage event as Event subtype
8. **Client event subtype** (CAVE-REQ-STREAM-006): Formalize client event as Event subtype
9. **Frame composition** (CAVE-REQ-RENDER-009): Define frame as composition of render steps
10. **Frame sequence composition** (CAVE-REQ-RENDER-011): Define frame sequence as ordered frames
11. **Version identity composition** (CAVE-REQ-IDENTITY-006): Formalize version/content identity = Capability with versioning composition
12. **Local-coordinate conversion** (CAVE-REQ-INTERACTION-007): Formalize local-coordinate conversion = Value + Relationship composition
13. **Dimensions composition** (CAVE-REQ-RESOURCE-007): Formalize dimensions = Value composition
14. **Format composition** (CAVE-REQ-RESOURCE-006): Formalize format = Value composition

**Priority**: HIGH (enables Cave to reuse SCR compositions rather than build new primitives)  
**Dependencies**: D-003 cave requirement catalogue, D-004 traceability matrix  
**Evidence**: D-003 classifications show 38 requirements as GAP-B (composable)

---

## Priority 4: Provider Capability Mapping

### D-005 Provider Capability Matrix — Already Complete

**OGRE provider**: 17 capabilities all missing; classified as GAP-D (Provider)  
**Louvre provider**: 12+ capabilities all missing; classified as GAP-D (Provider)

**CAVE-001 Action**: Do NOT implement OGRE/Louvre integration during CAVE-001 per spec non-goals (§19-20, §780-791). Instead:

1. Document the provider boundary per §13
2. Map SCR semantics to provider manifestations (for future increments)
3. Do not create SCR-specific OgreTexture/LouvreTexture primitives

**Priority**: HIGH (preserves semantic/provider boundary)  
**Dependencies**: D-005 provider capability matrix  
**Evidence**: CAVE-000 §197-201 (OGRE ≠ semantic model, Louvre ≠ semantic model)

---

## Priority 5: Runtime/EGS Capability Matrix

### D-006 Gap Register — Critical Gaps Identified

**Runtime gaps (GAP-C) that must be addressed for headless execution**:

1. **GAP-C-001**: Damage event management in runtime/EGS
2. **GAP-C-002**: External GPU resource lifecycle management
3. **GAP-C-003**: Native GPU handle management
4. **GAP-C-004**: Resource synchronization mechanisms
5. **GAP-C-005**: Resource version/serial management
6. **GAP-C-006**: Resource invalidation detection
7. **GAP-C-007**: Resource replacement mechanism
8. **GAP-C-008**: Frame event management
9. **GAP-C-009**: Frame stream management
10. **GAP-C-010**: Session management
11. **GAP-C-011**: Execution environment management
12. **GAP-C-012**: Movement semantics execution

**Priority**: CRITICAL (these prevent headless end-to-end execution — Gate 4+ in Golden Path)  
**Dependencies**: D-006 gap register, D-004 traceability matrix  
**Evidence**: GP-INV-007 (Implementation Derivation), GP-INV-016 (Provider Independence), verification report §4 gate status

---

## Priority 6: Gap Resolution (CAVE-001 Scope)

### Resolve GAP-B (Semantic Composition) — 30 gaps

**Action**: Define composition relations rather than create new primitives. This is the primary CAVE-001 work:

1. Transform = position + orientation + scale (position: Value, orientation: Value, scale: Value → Transform)
2. Damage event = Event + Observation
3. External resource = Resource capability + ownership composition
4. Ownership = Persistable + Stateless capability composition
5. Lifetime = Event ⊕ Delta
6. Dependency = Relationship + Constraint
7. Damage event subtype (partial Event)
8. Client event subtype (partial Event)
9. Frame = composition of render steps
10. Frame sequence = ordered frame stream
11. Version identity = Capability with versioning composition
12. Local-coordinate conversion = Value + Relationship composition
13. Dimensions = Value composition
14. Format = Value composition

**Priority**: HIGH (38 requirements classified as GAP-B; resolving enables reuse without new primitives)  
**Dependencies**: D-003 catalogue, D-004 traceability, D-007 proposed extensions (none)  
**Evidence**: §12 Q2 (composition possible), §42 (progressive abstraction)

---

### Address GAP-C (Runtime) — 12 critical gaps

**Action**: Extend runtime/EGS, NOT semantic library. These are execution infrastructure gaps:

1. Implement damage event management in runtime loop
2. Implement external GPU resource lifecycle (borrow/return)
3. Implement native GPU handle management (DMA-BUF/EGLImage)
4. Implement resource synchronization (fences, barriers)
5. Implement resource version/serial tracking
6. Implement resource invalidation detection
7. Implement resource replacement mechanism
8. Implement frame event management
9. Implement frame stream management
10. Implement session management (create/initialize/destroy)
11. Implement execution environment management (compile/instantiate/step/destroy)
12. Implement movement semantics execution

**Priority**: CRITICAL (these prevent headless execution; Gate 4+ in Golden Path)  
**Dependencies**: D-006 gap register, golden-path.md §32 (runtime boundary §1230-1264), §33 (runtime state evolution §1258-1288)  
**Evidence**: verification report §4 gate status (Gates 4-8 not started), GP-INV-010 (Runtime Separation)

---

### Do NOT Address During CAVE-001

**GAP-A (Semantic Primitive)**: 12 gaps pending investigation. Per §70: "Do not begin mass implementation until artefacts exist." Investigate first.

**GAP-D (Provider)**: 10 gaps. Per §19-20 and §780-791: "This increment shall not implement OGRE integration, Louvre integration, Wayland integration, GPU resource bridging." These are subsequent increments.

**GAP-E (Application Composition)**: 34 gaps. Per §780-791: "This increment shall not implement the complete Cave desktop, redesign SCR without evidence, duplicate SCR semantics inside Cave, create OGRE-specific or Louvre-specific semantic primitives merely for convenience." Keep these in Cave.

---

## Priority 7: Deliverables for CAVE-001

The following artefacts must exist before CAVE-001 begins (per CAVE-000 §16, §18, §770-776):

### Required Artefacts (Exist or Be Created)

| Artefact | Status | Action |
|---|---|---|
| D-001 Repository Inventory | Complete | Already done — reference for CAVE-001 |
| D-002 Semantic Library Inventory | Complete | Already done — reference for CAVE-001 |
| D-003 Cave Requirement Catalogue | Complete | Already done — reference for CAVE-001 |
| D-004 Cave/SCR Traceability Matrix | Complete | Already done — reference for CAVE-001 |
| D-005 Provider Capability Matrix | Complete | Already done — reference for CAVE-001 |
| D-006 Gap Register | Complete | Already done — reference for CAVE-001 |
| D-007 Proposed SCR Extensions | Complete | Already done — 0 primitives proposed |
| D-008 CAVE-001 Implementation Plan | Complete | This document |

### New Artefacts to Create for CAVE-001

| Artefact | Priority | Description |
|---|---|---|
| `lib/101_spec.md` for all 30 domains | CRITICAL | Mandatory per lib/101_definition.md §118-120; currently 0 of 30 have 101_spec.md |
| Core `101_spec.md` with all 70 sections | CRITICAL | Foundational; enables all downstream specification |
| Data `101_spec.md` | HIGH | Supports Core and higher domains |
| Math `101_spec.md` | HIGH | Supports Dynamics, Simulation, Rendering |
| Refined Cave requirement compositions | HIGH | Define 30 GAP-B compositions from existing primitives |
| Runtime extension design for GAP-C | CRITICAL | Design 12 runtime/EGS extensions (do NOT create new SCR primitives) |
| Provider boundary documentation | HIGH | Document SCR/provider boundary per §13 for future increments |
| CAVE-001 implementation plan (this document) | CRITICAL | Derived from CAVE-000 analysis; guides next increment |

---

## Implementation Sequence for CAVE-001

```text
Phase 1 — Semantic Library Specification (Weeks 1-4)
  1. Create 101_spec.md for Core domain (all 70 sections)
  2. Create 101_spec.md for Data domain
  3. Create 101_spec.md for Math domain
  4. Verify lake build SCRFormal succeeds after changes
  5. Record open questions and uncertainties

Phase 2 — Cave Requirement Composition Definition (Weeks 5-8)
  1. Define 30 GAP-B composition relations (transform, damage, resource, etc.)
  2. Update D-004 traceability matrix with composition evidence
  3. Verify all compositions pass Reference Executor tests
  4. Record any composition failures as new gaps

Phase 3 — Runtime/EGS Extension Design (Weeks 9-12)
  1. Design 12 runtime/EGS extensions for GAP-C gaps
  2. Design without creating new SCR primitives
  3. Verify extensions do not distort semantic meaning
  4. Document extension boundaries per GP-INV-010, GP-INV-016, GP-INV-017

Phase 4 — Provider Boundary Documentation (Weeks 13-16)
  1. Document OGRE/provider boundary per §13
  2. Document Louvre/provider boundary per §13
  3. Map SCR semantics to provider manifestations (for CAVE-002+)
  4. Do NOT implement provider bindings during CAVE-001

Phase 5 — Validation and Gate Review (Weeks 17-20)
  1. Run lake build SCRFormal — must pass
  2. Run 13/13 Reference Executor tests — must pass
  3. Verify all GAP-B compositions are semantically valid
  4. Verify no semantic distortion introduced
  5. CAVE-001 complete; CAVE-002 can begin
```

---

## Success Criteria for CAVE-001

CAVE-001 is complete when all of the following are satisfied:

### Semantic Library Criteria
- [ ] Every applicable lib/ directory has a 101_spec.md (30 of 30)
- [] Core 101_spec.md has all 70 sections populated
- [] lake build SCRFormal passes (8881+ jobs verified)
- [] 13/13 Reference Executor tests pass
- [] No semantic contradictions introduced by new specifications

### Cave Requirement Criteria
- [ ] 38 GAP-B requirements resolved by composition (not new primitives)
- [ ] 0 new SCR primitives proposed (per D-007)
- [ ] All Cave requirements classified (GAP-A through GAP-E)
- [ ] No Cave-specific primitive created that should be in SCR

### Runtime/EGS Criteria
- [ ] 12 GAP-C runtime gaps designed (not yet implemented — for CAVE-002)
- [ ] Runtime extensions preserve semantic authority (GP-INV-007, GP-INV-010, GP-INV-016, GP-INV-017)
- [ ] No provider-specific code added to semantic library
- [ ] Headless execution pipeline designed (not necessarily implemented)

### Provider Criteria
- [ ] OGRE provider boundary documented (no SCR primitives created)
- [ ] Louvre provider boundary documented (no SCR primitives created)
- [ ] No OgreTexture/LouvreTexture primitives created
- [ ] Provider mapping follows §13 preferred pattern

### Documentation Criteria
- [ ] D-001 through D-008 all exist under applications/cave/program_increments/v0.0.1/reports/
- [ ] All specifications follow lib/_templates/semantic_domain/015_DOMAIN_TEMPLATE/101_spec.md convention
- [ ] All status files follow seed/000_meta/102_status.yaml schema
- [ ] Traceability matrix D-004 links every requirement to SCR capability or classification
- [ ] Gap register D-006 classifies all 98 gaps with exactly one primary classification
- [ ] Proposed SCR extension register D-007 confirms 0 new primitives justified

### The Key Question (per CAVE-000 §19, §1446-1448)

> **"What is the minimum set of changes required before CAVE-001 can begin?"**

**Answer**: The minimum set is: (1) Create 101_spec.md for all 30 lib/ domains, starting with Core; (2) Define 30 GAP-B composition relations; (3) Design 12 runtime/EGS extensions; (4) Document provider boundaries. No new SCR primitives are proposed. The Cave application itself is not implemented during CAVE-001.

---
*CAVE-001 Implementation Plan derived from CAVE-000 evidence analysis per §18 completion criteria and §70 first execution instruction. All conclusions derived from repository evidence, not assumptions.*