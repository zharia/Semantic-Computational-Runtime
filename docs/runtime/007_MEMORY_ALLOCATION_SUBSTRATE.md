# Memory Allocation Substrate

**Status:** Normative
**Scope:** Semantic Computational Runtime — runtime memory management and allocation policy

## 1. Purpose

Memory allocation is an execution mechanism, not a semantic property of a value. SCR therefore separates semantic identity from object representation and physical storage.

## 2. Allocation Layers

The runtime SHOULD reason through four layers:

```text
Semantic Value
      ↓
Runtime Object
      ↓
Storage Representation
      ↓
Physical Allocation
```

A change at a lower layer MUST preserve the contracts established above it.

## 3. Allocation Classes

SCR MAY employ:

- inline storage;
- general heap allocation;
- size-class allocation;
- pools/slabs;
- arenas/regions;
- simulation-epoch regions;
- frame/message/query arenas;
- segmented allocation;
- external/device memory.

No single allocator strategy is assumed universally optimal.

## 4. Allocation Domains

Allocation SHOULD be associated with an execution domain such as:

- persistent;
- simulation;
- tick;
- phase;
- frame;
- message;
- query;
- temporary;
- device/external.

Domain selection SHOULD exploit common lifetime and locality characteristics.

## 5. Lifetime

Useful lifetime classes include ephemeral, short-lived, tick, frame, phase, session, persistent, and externally owned.

Lifetime is distinct from semantic ownership and identity.

## 6. Ownership and Borrowing

Physical ownership MUST NOT be confused with semantic identity. Borrowed storage MAY be exposed where lifetime guarantees are sufficient.

Stable references SHOULD use handles or indirection when physical relocation is expected. Relocatable objects MAY use direct references when the runtime can update them safely.

## 7. Growth and Relocation

Dynamic storage SHOULD grow geometrically or through a tiered policy rather than reallocating on every incremental append.

Policies MAY include:

- exact growth;
- linear growth;
- geometric growth;
- tiered growth;
- predictive growth;
- segmented growth.

The runtime SHOULD exploit in-place extension where the underlying allocator permits it.

## 8. Predictive Allocation

SCR MAY use historical workload information to anticipate future capacity requirements. Predictive allocation MUST remain subordinate to semantic correctness and explicit resource constraints.

## 9. Locality

Allocation policy SHOULD consider:

- cache locality;
- NUMA locality;
- worker locality;
- false sharing;
- access frequency;
- traversal patterns;
- producer/consumer topology.

Worker-local allocation and bulk reclamation SHOULD be preferred for strongly partitioned temporary workloads.

## 10. Simulation Epochs

Simulation state MAY be allocated by epoch, tick, phase, or snapshot generation. Bulk reclamation is preferred where object lifetimes share a boundary.

Snapshotting MAY use copy-on-write or structural sharing when this reduces duplication without compromising determinism.

## 11. Messaging and Zero Copy

Message payloads SHOULD support ownership transfer, borrowing, reference-counted/shared storage, or zero-copy pathways where safe.

Serialization MUST be treated as a semantic boundary rather than an incidental memory operation.

## 12. Graph and Structured Data

Graph-heavy workloads SHOULD favour allocation schemes that preserve adjacency locality and minimise per-node allocation overhead. Stable handles MAY be preferred over raw pointers where topology is dynamic.

## 13. Pool Reuse and Identity

When storage slots are reused, semantic object identity MUST NOT be inferred from the physical address alone. Generational handles or equivalent identity mechanisms SHOULD be used when stale references are possible.

## 14. Determinism

Where reproducibility is required, allocation behaviour that can affect observable execution MUST be controlled or isolated. Address-dependent behaviour MUST NOT influence semantic results.

## 15. Memory Pressure

Under memory pressure the runtime MAY:

- compact;
- relocate;
- evict externalisable state;
- compress;
- reduce representation precision where permitted by numeric semantics;
- release arena/epoch storage;
- change representation;
- throttle allocation.

Semantic invariants remain authoritative.

## 16. Allocation Policy Hierarchy

Policy precedence SHOULD be:

```text
Correctness constraints
    > hardware constraints
    > explicit local policy
    > domain policy
    > runtime policy
    > adaptive heuristic
    > allocator default
```

## 17. Telemetry

The allocator SHOULD expose telemetry sufficient to evaluate:

- allocation rate;
- deallocation rate;
- peak usage;
- fragmentation;
- relocation frequency;
- capacity utilisation;
- lifetime distribution;
- pool hit rate;
- arena reclamation efficiency.

Telemetry SHOULD inform optimisation without becoming a semantic dependency.

## 18. Invariants

- **MEM-001:** Memory representation MUST NOT define semantic identity.
- **MEM-002:** Allocation policy MUST preserve semantic correctness.
- **MEM-003:** Logical size and physical capacity are distinct.
- **MEM-004:** Lifetime MUST be explicit or derivable.
- **MEM-005:** Ownership MUST be distinct from identity.
- **MEM-006:** Relocation MUST NOT silently invalidate protected references.
- **MEM-007:** Reused storage MUST NOT resurrect stale semantic identity.
- **MEM-008:** Allocation policy MAY adapt to workload.
- **MEM-009:** Deterministic domains MUST control observable allocation effects.
- **MEM-010:** Temporary storage SHOULD support bulk reclamation.
- **MEM-011:** Zero-copy mechanisms MUST preserve ownership/lifetime safety.
- **MEM-012:** Memory pressure MUST NOT silently violate semantic precision/error contracts.

## 19. Governing Principle

**Memory is the substrate of manifestation, not the definition of value.**
