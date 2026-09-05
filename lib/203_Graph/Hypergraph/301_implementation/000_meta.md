**Implementation Plan: SCR Semantic Hypergraph Domain**  
`lib/203_Graph/Hypergraph`

**Goal**  
Deliver a minimal, usable, well-tested Semantic Hypergraph substrate that higher SCR domains can depend on, while remaining strictly implementation-independent and upstream of MLIR.

**Guiding Principles** (from SCR + the existing definition)
- Semantics first; implementation must conform.
- Start extremely small and expand only with evidence.
- Hypergraph (not property graph) is the native model.
- No persistence, networking, serialization, or domain knowledge in the core.
- Strong typing, explicit identities, role-labelled participants.
- Every meaningful function follows: Describe → Specify → Test → Implement → Validate.

---

### Phase 0 — Control Plane & Inventory (1–2 days)

1. Create / complete the standard control-plane files:
   - `101_definition.md` (already exists as `001_hypergraphs.md` — promote or link it cleanly)
   - `102_status.yaml` (initialize with realistic “specified / not_started” state)
   - `103_library.graph.json` (derived later)

2. Fix the typo: rename `401_documentaion` → `401_documentation`.

3. Record explicit relationships to the parent `203_Graph` domain (REFINES / SPECIALIZES).

4. Produce a short “Minimal Viable Scope” document that carves the large definition down to what will ship in the first increment.

**Exit criteria**: Control-plane files exist and accurately reflect reality.

---

### Phase 1 — Minimal Viable Core (MVP) — 2–4 weeks

**Scope (ruthlessly limited)**  
Only the absolute minimum needed for higher domains to start expressing relationships:

- Semantic Identity (abstract IRI-like)
- Node (identity + type + attributes)
- Hyperedge (identity + type + role-labelled participants)
- Role
- Basic typed Attribute / Value
- Simple in-memory Graph container
- Core operations: CreateNode, CreateHyperedge, SetAttribute, Delete*
- Basic Delta representation and application
- Deterministic equality and basic validation

**Out of scope for MVP**
- Graph regions, references, representations, transformations, provenance, streams, subscriptions, causality, content identity, canonicalization, query language, MLIR, Lean, persistence.

**Work items**

1. **Specify** (in the definition or a dedicated `mvp_contract.md`):
   - Exact types and invariants
   - Ownership and lifetime rules
   - Error model
   - Determinism requirements

2. **Test-first**:
   - Identity uniqueness and equality
   - Node creation / attribute round-trip
   - Hyperedge with 0…N role-labelled participants
   - Higher-order participation (hyperedge as participant)
   - Invalid operations rejected
   - Delta application produces expected state

3. **Implement** in idiomatic Rust under `301_implementation/`:
   - Strongly typed IDs
   - `Arc` / interior mutability only where topology requires it
   - Explicit error types
   - No external graph crates unless they add clear value without leaking semantics

4. **Validate** against the MVP contract.

**Deliverable**: A small, documented, tested crate that can create and mutate a typed role-labelled hypergraph in memory.

---

### Phase 2 — Regions, References & Identity Hardening (2–3 weeks)

Add:
- GraphRegion (explicit membership first; pattern-based later)
- SemanticReference, RegionReference
- Clear separation of Semantic Identity vs Content Identity (content identity remains an abstraction)
- Basic resolution trait (no concrete resolvers yet)

**Focus**: Make partial graphs and cross-references usable without loading everything.

---

### Phase 3 — Operations, Deltas & State Evolution (2–3 weeks)

- Formalize the Operation → Delta → Materialized State pipeline
- Support for operation identity, basic provenance hooks, and temporal metadata placeholders
- Delta inversion / composition where it is cheap and correct
- Stream abstraction (interface only — no transport)

This phase makes the graph a proper evolving semantic substrate rather than a static structure.

---

### Phase 4 — Representations, Transformations & Provenance (3–4 weeks)

- Explicit Representation objects (media type + content identity + parameters)
- Transformation as a first-class semantic object (input/output patterns)
- Lightweight provenance model aligned with W3C PROV concepts (without depending on the ontology)

These features enable higher domains (Geometry, Morphology, Fields, etc.) to attach multiple views and record how objects were derived.

---

### Phase 5 — Query / Pattern Matching Foundations + MLIR Bridge (ongoing)

- Minimal pattern / query abstraction (not full GQL)
- Decide which parts of the model deserve MLIR types/ops
- First lowering / representation of core hypergraph concepts into MLIR (if and only if there is a concrete compilation need)

Lean formalization (`201_lean`) can begin in parallel once the MVP is stable, focusing on the core invariants.

---

### Cross-Cutting Rules for All Phases

- Update `102_status.yaml` after every meaningful change (evidence-based).
- Keep the public API free of Rust, filesystem, network, or storage details.
- Prefer composition and traits over large monolithic types.
- Every new capability must come with tests that demonstrate semantic contracts, not just “it compiles.”
- Reject any change that lets an implementation detail redefine the semantics.
- Regularly re-evaluate whether a feature is still needed in the core or can live in a higher domain / provider.

---

### Suggested First Milestone (Golden Path for this domain)

**“I can build a small hypergraph containing an Observation hyperedge that links an Agent, a Field, and a Time point, attach attributes, produce a delta, and re-apply that delta deterministically.”**

That single vertical slice already proves the most important architectural claims and gives other domains a real substrate to target.

---

### Risk Mitigations

- **Scope creep** → Strict MVP gate; anything not required for the first milestone goes into a backlog.
- **Over-abstraction** → Implement the simplest correct design first; refactor only with tests.
- **Missing status tracking** → Treat `102_status.yaml` as mandatory, not optional.
- **Isolation from rest of SCR** → Explicitly document how Morphology, Fields, and Simulation are expected to consume this library.

This plan turns the existing strong definition into a realistic, incremental delivery path while protecting the semantic purity that makes the domain valuable to the rest of SCR.
