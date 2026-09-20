# Milestone 008: Semantic Correction

## 1. Scope & Objective
Correct semantic definitions for identity, context/scope, ownership/authority, lifecycle, and entity/component composition. Separate SCR semantics from O3DE provider patterns.

## 2. Deliverables
- Identity semantics (SID uniqueness, authority, persistence, derivation, provider mapping)
- Context/scope semantics (independent from identity)
- Ownership semantics (independent from authority)
- Authority semantics (scoped to explicit state/operation)
- Lifecycle semantics (profile-based, not universal)
- Entity/component semantics (cardinality, identity, composition)

## 3. Formal Invariants
1. SID is the sole identity authority.
2. Identity ≠ scope ≠ context ≠ ownership ≠ authority.
3. Lifecycle is a profile, not a universal entity law.
4. Component cardinality is explicitly defined, not assumed.

## 4. Exit Criteria
- [ ] Identity, scope, context, ownership, authority separated
- [ ] Lifecycle expressed as applicable profile
- [ ] Entity/component composition rules corrected
- [ ] O3DE patterns not silently promoted to SCR law

## 5. Dependencies
- Milestone 007 (mathematical correction establishes spatial foundation)
