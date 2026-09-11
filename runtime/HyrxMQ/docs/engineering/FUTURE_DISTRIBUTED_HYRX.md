# FUTURE_DISTRIBUTED_HYRX.md

**Date:** 2026-09-11
**Status:** Research/design only — must not destabilize current implementation

---

## Invariants that matter at process/machine boundaries

The current HyrxMQ implementation is single-process, single-threaded. The following invariants are trivially satisfied in the single-process case but require explicit design when crossing process or machine boundaries.

### Message identity

- **Current:** MessageID is a monotonic counter local to the Router.
- **Distributed concern:** MessageIDs must be globally unique or scoped to a replication domain. UUIDs or distributed counters required.
- **Risk:** Duplicate messageIDs across nodes cause incorrect deduplication.

### Ownership transfer

- **Current:** Message ownership transfers from queue to consumer on basic.deliver.
- **Distributed concern:** Ownership transfer must be atomic across network partitions. A consumer crash after deliver-but-before-ack must not leave the message in limbo.
- **Risk:** Split-brain causes duplicate delivery or message loss.

### Delivery identity

- **Current:** delivery_tag is a monotonic counter per consumer.
- **Distributed concern:** delivery_tag must be consistent across replication. A consumer connected to node A must not receive a delivery_tag that conflicts with node B.
- **Risk:** Incorrect ack routing.

### Topology

- **Current:** Exchange/queue/binding topology is in-memory only.
- **Distributed concern:** Topology must be replicated or persisted. A node restart must recover topology or receive it from a peer.
- **Risk:** Topology divergence causes routing failures.

### Ordering

- **Current:** Per-queue FIFO ordering guaranteed (single-threaded).
- **Distributed concern:** Multi-producer, multi-consumer across nodes breaks FIFO unless partitioned by key.
- **Risk:** Out-of-order delivery for partitioned workloads.

### Failure domains

- **Current:** Single process, single failure domain.
- **Distributed concern:** Node failure must not lose acknowledged messages. Unacknowledged messages must be requeued on failover.
- **Risk:** Message loss on node failure.

### Network partitions

- **Current:** No network partitions (single process).
- **Distributed concern:** Partition tolerance requires consensus (Raft, Paxos) or eventual consistency with conflict resolution.
- **Risk:** Inconsistent state across partitions.

### Duplicate delivery

- **Current:** No duplicate delivery possible (single thread, no retry).
- **Distributed concern:** At-least-once delivery requires idempotent consumers or deduplication at the broker.
- **Risk:** Duplicate processing.

### Acknowledgement

- **Current:** basic.ack is synchronous and local.
- **Distributed concern:** ack must be replicated to prevent message re-delivery on failover.
- **Risk:** Re-delivery of already-processed messages.

### Persistence

- **Current:** WAL journal is local filesystem.
- **Distributed concern:** Persistence must be replicated or use shared storage (e.g., Ceph, EBS).
- **Risk:** Data loss on node failure.

### Locality

- **Current:** All state is local.
- **Distributed concern:** Remote state access introduces latency. Prefer locality-aware routing.
- **Risk:** Performance degradation.

### Backpressure

- **Current:** Queue capacity bounds are local.
- **Distributed concern:** Backpressure must propagate across nodes to prevent unbounded memory growth.
- **Risk:** OOM on one node while others are idle.

---

## Design principles for distributed Hyrx

1. **Semantics first.** Distributed semantics must be specified before implementation.
2. **Single-process correctness is prerequisite.** Do not add distribution until single-process is proven.
3. **Partition tolerance is optional.** Hyrx may choose CP (consistency + partition tolerance) over AP (availability + partition tolerance) for messaging semantics.
4. **Replication is a transport concern.** The semantic layer should not know about replication.
5. **Idempotent operations.** All operations must be idempotent to support at-least-once delivery.

---

## Research areas

- Raft consensus for topology replication
- Vector clocks for causal ordering
- CRDTs for counter replication (messageID, delivery_tag)
- WAL replication (Raft log, or async replication with conflict detection)
- Consumer rebalancing across nodes
- Connection migration (consumer failover)
