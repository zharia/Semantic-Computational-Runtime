# Identity Domain Specification (`SCR-LIB-IDENTITY`)

> **Normative Specification for Semantic Identity and Coordinate Addressing in the Semantic Computational Runtime.**

**Path:** `lib/101_Core/Identity`  
**Version:** `0.1.0`  
**Status:** Operational  
**Authority:** SCR Architectural Group  
**Documentation Role:** Normative Domain Specification  

---

## 1. Executive Definition & Identity

Semantic Identity in SCR establishes **what an entity is, where it resides in semantic address space, how authority over its allocation is structured, and how it is distinguished from its temporary computational manifestations**.

> **Governing Principle:**  
> **SID is a coordinate, not an identity system.**  
> An identifier is not an isolated random token or UUID; it is a coordinate allocated within an explicit authority hierarchy and identity address space.

---

## 2. The SCR Identity Authority Hierarchy

Semantic identity is strictly stratified across nine distinct structural layers. Implementation convenience must never collapse these layers:

```text
Genesis
    ↓
Root Authority
    ↓
Identity Address Space
    ↓
Allocation Domain
    ↓
Authority
    ↓
Allocation
    ↓
SID Coordinate
    ↓
Semantic Identity
    ↓
Manifestation
```

### Layer Semantics

1. **Genesis**: The initial uncaused root of trust and cryptographic inception event for an entire runtime universe or federation.
2. **Root Authority**: The sovereign administrative root governing one or more identity address spaces. Under Multi-Root Model B, root authorities are autonomous, and global identity is scoped: $\text{GlobalIdentity} = (\text{RootAuthorityId}, \text{SidCoordinate})$. Root identifiers are never packed into internal SID coordinate bits.
3. **Identity Address Space**: The declared coordinate space (e.g. $[0, 2^{64})$ or $[0, 2^{128})$) establishing the geometric boundary and allocation policy.
4. **Allocation Domain**: A hierarchical partition of the coordinate space assigned to a designated authority. Domains are strictly disjoint ($D_i \cap D_j = \emptyset$) and enforce tree containment.
5. **Authority**: The cryptographic entity holding active delegation to issue allocations within an assigned domain. Authorities possess discrete generations; authority rotation increments the generation and fences off stale allocators.
6. **Allocation**: The atomic reservation and commitment of a coordinate within an active domain under a verified authority generation.
7. **SID Coordinate**: The canonical immutable coordinate identifying a discrete semantic position.
8. **Semantic Identity / Binding**: The contextual association linking a coordinate to a semantic entity, hypergraph node, or domain concept.
9. **Manifestation**: The ephemeral, runtime-specific representation (memory pointer, GPU buffer handle, actor ID, socket) that physically embodies the semantic entity during execution.

---

## 3. Correctness Decomposition

Identity correctness is decomposed into mutually independent verification concerns:

```text
Topology        → uniqueness across address spaces
Allocation      → local injectivity within domains
Authority       → permission and delegation validity
Cryptography    → provenance authenticity and non-repudiation
History         → durable non-reuse across restarts and crashes
Context         → resolution within runtime scopes
Semantic Graph  → meaning and structural relationships
Manifestation   → physical and runtime execution identity
```

---

## 4. Normative Rules (IAM-R001 through IAM-R020)

In addition to foundational rules, SCR Identity codifies the following normative operational rules:

* **Rule IAM-R017 (Snapshot Historical Consistency)**: A snapshot recovery must never leave surviving post-snapshot coordinates orphaned. Recovered state must carry forward complete provenance, domain membership, binding, and manifestation records for all coordinates present in the monotonic historical allocation log ($H$).
* **Rule IAM-R018 (Transaction Immutability & Non-Rebinding)**: A transaction identifier ($TransactionId$) is immutably bound to at most one coordinate $sid$. Replaying a committed transaction with an alternate coordinate is strictly rejected.
* **Rule IAM-R019 (Multi-Root Scoped Identity)**: Multiple independent roots are supported as autonomous peers (Model B). The globally unique identifier is the pair $(\text{RootId}, \text{SidCoordinate})$, where $\text{RootId}$ is contextual and coordinate bits remain clean.
* **Rule IAM-R020 (Deterministic Derived Allocation)**: Mathematical derivation functions are candidate generators, never autonomous allocation authorities. Any derived coordinate must be authorized by domain authority, reside within domain bounds, and respect historical non-reuse ($s \notin H$).

---

## 5. Normative Invariant Suite (IAM-I001 through IAM-I017)

Every conforming SCR Identity implementation must satisfy all 17 invariants unconditionally:

| Invariant | Name | Formal Statement |
|---|---|---|
| **IAM-I001** | Root Uniqueness | Root authority identifiers are globally unique: $\forall r_1, r_2 \in A_{\text{root}}, r_1.id = r_2.id \implies r_1 = r_2$. |
| **IAM-I002** | Domain Disjointness | Sibling domains within an identity space have pairwise disjoint coordinate regions: $D_i \cap D_j = \emptyset \quad (\forall i \neq j)$. |
| **IAM-I003** | Domain Containment | Child domains are strictly contained within parent domains: $\text{region}(D_{\text{child}}) \subseteq \text{region}(D_{\text{parent}})$. |
| **IAM-I004** | Allocation Containment | Allocated coordinates reside strictly within the allocating domain's declared region: $\forall s \in \text{alloc}(D), s \in \text{region}(D)$. |
| **IAM-I005** | Allocation Injectivity | No two distinct allocations within a space yield the same coordinate: $\text{alloc}_i(t_1) = \text{alloc}_j(t_2) \implies i = j \land t_1 = t_2$. |
| **IAM-I006** | Authority Containment | Allocating authority must match the active authority assigned to the domain: $\text{auth}(s) = D.\text{authority}$. |
| **IAM-I007** | Cryptographic Provenance | Every committed coordinate has an authentic provenance record linking Genesis, Root, Authority, Generation, Domain, and Transaction: $\forall s \in H, P(s) \neq \bot$. |
| **IAM-I008** | Generation Validity | Allocations must specify the current generation of the authority: $\text{gen}(s) = \text{gen}(A_{\text{alloc}})$. |
| **IAM-I009** | Historical Monotonicity | The historical allocation set $H$ is monotonically non-decreasing over time: $t_1 \le t_2 \implies H(t_1) \subseteq H(t_2)$. |
| **IAM-I010** | Durable Non-Reuse | A retired, revoked, or deleted coordinate is never re-allocated: $\forall t > t_{\text{alloc}}, s \notin \text{Available}(t)$. |
| **IAM-I011** | Crash Monotonicity | System restart or crash recovery never reduces the historical allocation set: $H_{\text{post-crash}} \supseteq H_{\text{pre-crash}}$. |
| **IAM-I012** | Snapshot Safety | Restoring a snapshot never resurrects stale active allocations or rolls back $H$: $H_{\text{restored}} \supseteq H_{\text{live}} \cup H_{\text{snapshot}}$. |
| **IAM-I013** | Contextual Resolution | Coordinate resolution requires an explicit verification context $(RootId, SpaceId)$. |
| **IAM-I014** | Manifestation Separation | Manifestation handles may be mutated, migrated, or destroyed without altering the canonical coordinate: $\text{Coord}(M) = \text{const}$. |
| **IAM-I015** | Binding Separation | Semantic bindings to entities may evolve without altering the coordinate: $\text{Entity}(s)$ does not redefine $s$. |
| **IAM-I016** | Transaction Idempotence | Replaying a committed transaction $(\text{tx\_id}, s)$ returns success idempotently without double-allocating. |
| **IAM-I017** | Historical Consistency | Surviving allocations across rollback or recovery retain valid provenance, domain membership, and binding consistency: $\forall s \in H, P(s) \in P \land D(s) \in D$. |

---

## 6. Concrete Coordinate Geometry (`SID-001`)

The concrete `SID-001` coordinate geometry defines:
1. **Domain Prefix / Identifier**: High-order coordinate bits or structured identifier identifying the allocation domain.
2. **Sequence / Local Coordinate**: Ordinal coordinate index within the domain's declared interval $[low, high)$.
3. **Generation Counter**: Fencing generation preventing replay across authority rotations.
4. **Canonical Form**: Representable as a 128-bit integer (`u128`), a pair of 64-bit words (`(u64, u64)`), or a standardized URI string (`sid://<root>/<domain>/<index>#gen=<generation>`).
