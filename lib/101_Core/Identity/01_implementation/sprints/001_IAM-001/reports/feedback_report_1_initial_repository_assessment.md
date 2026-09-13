# Feedback Report 1 — Initial Repository Assessment

## IAM Development Assessment

### 1. Existing SCR Infrastructure

#### Identity Infrastructure Already Present

The SCR repository contains several identity-related structures that IAM-RM-001 can reuse:

**a) SCR Core Identity Domain** (`lib/101_Core/Identity/`)
- Current role: establishes a documented location for identity within the SCR library hierarchy
- Contains: `101_definition.md` only (no substantive implementation)
- Scope boundary: No additional semantic contract inferred from directory existence alone
- Notes: "Further semantic or implementation definition is outside the scope of this documentation pass"

**b) SCR Formal Identity** (`SCRFormal/SCR/Identity.lean`)
- Defines: `SameIdentity (a b : Entity) : Prop := a.id = b.id`
- Defines: `Representation` structure with `entity : EntityId` and `encoding : String`
- Defines: `RepresentationChangePreservesIdentity` theorem
- Key theorem: `representation_change_preserves_identity` — identity preserved through representation change
- Located in Lean formal verification layer, not implementation layer

**c) Agent Identity** (`lib/601_Agent/Identity/`)
- Current role: establishes a documented location for identity within agent domain
- Contains: `101_definition.md` only (no substantive implementation)
- Relationship to parent: `Identity` is a child of `601_Agent` within the SCR library hierarchy

**d) Lean Theorem Infrastructure**
- `lake build SCRFormal` passes (8881 jobs verified)
- 13/13 Reference Executor tests pass
- Lean provides formal verification framework for invariants

#### Integration Assessment

**Where IAM-RM-001 should integrate:**

The spec §32 directs: "Determine the appropriate existing domain/module/library for: identity, semantic identity, graph, cryptography, runtime, formalisation."

**Recommended integration point: `lib/101_Core/Identity/`**

Rationale:
- Core is the foundational semantic domain per `lib/101_definition.md` §108-149
- Core occupies the root of the SCR semantic library
- All other semantic domains MAY depend on Core; Core MUST NOT depend semantically on a higher-level domain
- The IAM architecture (Identity Space → Allocation Domain → Authority → Allocation → SID → Semantic Binding → Manifestation) flows naturally from Core's foundational concepts
- Core already defines: Identity ( §7 ), Type ( §8 ), Value ( §9 ), Entity/Object ( §10 ), Relationship ( §12 ), Roles ( §13 ), Semantic Hypergraph ( §14 ), Constraints ( §29 ), Capabilities ( §30 ), Contracts ( §31 ), Equivalence ( §33 ), Observations ( §35 ), Resources ( §36 ), Errors ( §37 ), Determinism ( §38 )
- The IAM state model Σ = (I, D, A, H, P, B, M, Q) from spec §4 maps naturally onto Core's existing abstractions:
  - I (Identity Spaces) → Core Identity domain
  - D (Allocation Domains) → Core Region/domain concepts ( §15 )
  - A (Authorities) → Core Capability concepts ( §30 )
  - H (Historical Allocation State) → Core Provenance ( §28 )
  - P (Cryptographic Provenance) → Core Provenance ( §28 ) + Core Constraints ( §29 )
  - B (Semantic Bindings) → Core Relationship + Role concepts ( §12, §13 )
  - M (Manifestations) → Core Observation concepts ( §35 )
  - Q (Outstanding Reservations/Transactions) → Core Event concepts ( §24 )

**Do NOT create a parallel identity system.** Per spec §81: "The SCR architectural principle remains: Reuse and extend semantic primitives; do not create unnecessary parallel abstractions."

#### Existing Gaps — What SCR Currently Lacks

Per spec §1102: "What does SCR currently lack?"

1. **No executable identity allocation model** — SCR has semantic definitions of identity but no reference machine implementing allocation, injection, historical tracking, or lifecycle
2. **No domain lifecycle implementation** — FREE → RESERVED → DELEGATED → ACTIVE → REVOKED → RETIRED sequence not implemented
3. **No authority generation mechanism** — Generation as fencing mechanism not implemented (spec §8: "Generation is a fencing mechanism")
4. **No local allocation with injectivity** — `allocate(x1) == allocate(x2) ⇒ x1 == x2` not implemented; `SID ∉ historical_allocation_set` not enforced
5. **No transaction model** — TransactionId separate from SID, idempotent commits not implemented (spec §13)
6. **No reservation model** — REQUEST → VALIDATE → RESERVE → COMMIT sequence not implemented (spec §14)
7. **No crash/recovery semantics** — Cases A-D (crash during/after commit, lost acknowledgement) not tested
8. **No snapshot safety** — H2 ⊇ H1, restoring H1 must not permit SIDs from H2 to be allocated again (spec §17)
9. **No contextual verification** — `verify(context, sid)` with context providing root, identity_space, geometry, verification policy, history view (spec §19)
10. **No semantic binding separate from allocation** — Bind SID → Semantic Entity → Manifest Entity, separate from allocation (spec §20)
11. **No manifestation separation from identity** — SID unchanged across manifestation changes, identity survives manifestation (spec §21)
12. **No exhaustive adversarial testing framework** — 25 adversarial scenarios (spec §24) not implemented

#### Risks

Per spec §1104-1106: "Identify architectural risks before implementation."

1. **SID width premature locking** — Spec §3.3 explicitly states: "128-bit is currently a candidate, not a decision." The first model uses N=8 for exhaustive state exploration but must remain capable of supporting 96, 128, 160, 192, 256. Risk: locking N=8 too early prevents future evolution.

2. **Embedding certificates into SID** — Spec §638 explicitly: "Do not embed full certificates into every SID." Risk: SID becomes a capability rather than an identity coordinate.

3. **Turning SID into a capability** — Spec §638: "Do not turn SID into a capability." Risk: conflating identity coordinate with authority/permissions.

4. **Generation encoding into SID** — Spec §312: "Do not encode generation into the SID." Risk: if generation is in SID, old processes with old generation could incorrectly allocate.

5. **RETIRED → FREE transition** — Spec §271-273 explicitly prohibits: "RETIRED → FREE" for durable identity domains. Risk: historical allocation set becomes unsound if retirement resets to FREE.

6. **Historical state erasure** — Spec §277: "historical domain information must not be erased merely because the domain is retired or revoked." Risk: if historical SIDs are removed, non-reuse invariant (IAM-I010) collapses.

7. **Domain partitioning vs delegation confusion** — Spec §336-344 explicitly: "Do not confuse: partition, delegation, allocation. They are separate operations." Risk: conflating these leads to allocation rights overlap.

8. **Snapshot rollback resurrecting SIDs** — Spec §587-591: "historical SID allocations cannot be resurrected." Risk: snapshot storage mechanism inadvertently allows SID reuse.

9. **Concurrent allocation without coordination** — Spec §856-862: "Do not fake concurrency by simply serialising everything." Risk: if domain partitioning doesn't properly remove coordination need, concurrent allocations cause overlaps.

10. **Stale process after key rotation** — Spec §821: "malicious allocation outside domain; stale process after key rotation." Risk: authority rotation not properly invalidating old allocations.

#### Plan — Implementation Sequence

Per spec §1110-1113: "Give the concrete implementation sequence. Do not make architectural changes merely to satisfy this report."

**Phase 1: Repository Integration (Weeks 1-2)**
- Integrate IAM-RM-001 into `lib/101_Core/Identity/` following existing conventions
- Create `101_spec.md` following `lib/_templates/semantic_domain/015_DOMAIN_TEMPLATE/101_spec.md` convention
- Document state model Σ = (I, D, A, H, P, B, M, Q) per spec §4
- Reference existing Lean formalisation in `SCRFormal/SCR/Identity.lean`

**Phase 2: Minimal Reference Machine (Weeks 3-6)**
- Implement identity space with coordinate_space = [0, 256), N=8 per spec §5
- Implement domain model per spec §6: Domain {id, parent, region, state, authority, generation}
- Implement domain lifecycle per spec §7: FREE → RESERVED → DELEGATED → ACTIVE → REVOKED → RETIRED
- Implement authority model per spec §8: Authority {id, generation, state, credential_reference}
- Implement partitioning per spec §9: parent partitioned into disjoint child domains
- Implement delegation per spec §10: hierarchical delegation with child ⊆ parent

**Phase 3: Allocation & Historical State (Weeks 7-10)**
- Implement local allocation with injectivity per spec §11: allocate(x1) == allocate(x2) ⇒ x1 == x2
- Implement historical state per spec §12: historical_sids, monotonic H(t) ⊆ H(t+1)
- Enforce SID ∉ historical_allocation_set for new allocations
- Implement transaction model per spec §13: TransactionId separate from SID, idempotent commits

**Phase 4: Reservation & Atomicity (Weeks 11-14)**
- Implement reservation model per spec §14: REQUEST → VALIDATE → RESERVE → COMMIT
- Implement atomicity per spec §15: T : Σ × Event → Σ | Error, no partially applied state

**Phase 5: Crash/Recovery & Snapshots (Weeks 15-18)**
- Implement crash/recovery semantics per spec §16: Cases A-D
- Implement snapshot safety per spec §17: H2 ⊇ H1, restoring H1 must not permit SIDs from H2 to be allocated again

**Phase 6: Provenance & Binding (Weeks 19-22)**
- Implement cryptographic provenance per spec §18
- Implement contextual verification per spec §19: verify(context, sid)
- Implement semantic binding separate from allocation per spec §20: Allocate SID → Bind SID → Semantic Entity → Manifest Entity
- Implement manifestation separation per spec §21: SID unchanged, identity survives manifestation

**Phase 7: Exhaustive & Adversarial Testing (Weeks 23-28)**
- Implement exhaustive N=8 exploration per spec §23
- Implement all 25 adversarial testing scenarios per spec §24
- Implement counterexample reporting per spec §27
- Implement property-based testing per spec §28

**Phase 8: Concurrency & Final Review (Weeks 29-32)**
- Implement concurrency distinctions per spec §25: disjoint domains → independent allocation; shared domain → coordination required
- Implement failure classification per spec §26: Invalid request vs Protocol failure
- Produce Architecture Review per spec §38 (Feedback Report 5)
- Produce final consolidated report per spec §39 (Mandatory Final Report Structure)

**Do NOT implement during initial phase:**
- Final 128-bit SID (spec §30: "Do NOT yet implement: final 128-bit SID")
- Production SID textual syntax (spec §30: "production SID textual syntax")
- ULID/UUID compatibility (spec §30: "ULID compatibility; UUID compatibility")
- Distributed production allocator (spec §30: "distributed production allocator")
- Production certificate protocol (spec §30: "production certificate protocol")
- Production persistence engine (spec §30: "production persistence engine")
- Production cryptographic key-management infrastructure (spec §30: "production cryptographic key-management infrastructure")
- Prefix-compressed production index (spec §30: "prefix-compressed production index")
- Final historical compression (spec §30: "final historical compression")
- Production network protocol (spec §30: "production network protocol")

---
*Initial repository assessment completed per IAM-001 §34. All conclusions derived from evidence-based repository inspection. Integration point recommended: lib/101_Core/Identity/. All risks and gaps documented from spec analysis.*