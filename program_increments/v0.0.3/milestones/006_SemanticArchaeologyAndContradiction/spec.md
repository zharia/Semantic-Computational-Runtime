# Milestone 006: Semantic Archaeology & Contradiction Detection

## 1. Scope & Objective
Inspect the repository, map existing canonical definitions, detect contradictions across SCR definitions/milestones/providers/implementation, and reconcile them. This is the foundation for all subsequent correction work.

## 2. Deliverables
- Repository archaeology map (concept → canonical location → status → dependencies → evidence)
- Contradiction inventory
- Reconciliation decisions (canonical vs provider-specific vs incorrect vs unresolved)

## 3. Formal Invariants
1. Every concept has exactly one canonical SCR definition.
2. Contradictions are explicitly resolved, not silently ignored.
3. Provider-specific behavior is not promoted to SCR semantics.

## 4. Exit Criteria
- [ ] All 12 scope areas mapped to canonical locations
- [ ] All contradictions identified and classified
- [ ] Reconciliation decisions made for each contradiction
- [ ] No silent contradictions remain

## 5. Dependencies
- None (foundational)
