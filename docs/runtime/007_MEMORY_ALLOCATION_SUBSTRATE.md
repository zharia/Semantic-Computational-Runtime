# Memory Allocation Substrate

## 1. Principle

Memory is the substrate of manifestation, not the definition of value.

```text
Semantic Value → Runtime Object → Storage Representation → Physical Allocation
```

## 2. Allocation classes

SCR MAY use inline storage, heap allocation, size classes, pools, arenas, regions, slabs, segmented storage, memory-mapped storage and device allocations.

## 3. Lifetime

Lifetime classes include ephemeral, temporary, tick, frame, phase, session, persistent and externally owned. Lifetime is distinct from semantic identity.

## 4. Ownership

Ownership, borrowing, sharing and authority are runtime properties. A semantic object may survive relocation, copying or migration.

## 5. References

Stable semantic references SHOULD be represented by handles, identities or runtime references when physical relocation is possible. Raw pointers are implementation details unless explicitly exposed through an interoperability contract.

## 6. Domains

Allocation domains may include simulation, tick, frame, message, query, device, worker-local and persistent domains.

## 7. Adaptive allocation

The runtime MAY adapt allocation strategies using locality, object lifetime, pressure, topology, access frequency, NUMA and device characteristics, provided semantic behaviour is unchanged.

## 8. Determinism

Deterministic systems SHOULD avoid allocator behaviour becoming an uncontrolled source of semantic nondeterminism, especially where addresses leak into observable results.
