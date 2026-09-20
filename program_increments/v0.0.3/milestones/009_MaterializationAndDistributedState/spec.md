# Milestone 009: Materialization & Distributed-State Semantics

## 1. Scope & Objective
Correct manifestation/projection/replication/clone/migration semantics. Correct materialization/lowering to be contract-driven rather than fixed-pipeline. Correct distributed-state semantics with explicit consistency models.

## 2. Deliverables
- Manifestation semantics (semantic → provider mapping)
- Projection semantics (representational subset)
- Replication semantics (with explicit consistency model)
- Clone semantics (new identity derivation)
- Snapshot semantics (versioned state capture)
- Migration semantics (provider transfer with invariant preservation)
- Materialization contracts (not fixed pipeline)
- Distributed-state corrections (authority scoped, replication explicit)

## 3. Formal Invariants
1. SID preservation rules are explicit for each operation.
2. Materialization does not assume unconditional reversibility.
3. Replication does not automatically guarantee consistency.
4. Transport guarantees ≠ application consistency.

## 4. Exit Criteria
- [ ] Manifestation/projection/replication/clone/migration distinguished
- [ ] SID preservation documented per operation
- [ ] Materialization is contract-driven, not fixed-pipeline
- [ ] Replication has explicit consistency model
- [ ] Transport separated from application semantics

## 5. Dependencies
- Milestone 008 (semantic correction establishes identity/lifecycle foundation)
