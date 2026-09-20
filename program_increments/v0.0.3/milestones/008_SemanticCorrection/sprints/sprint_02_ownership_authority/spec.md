# Sprint 008-002: Ownership & Authority

## Objective
Correct ownership and authority semantics. Ownership ≠ authority. Authority is scoped to explicit state/operation.

## Deliverables
- Ownership semantics (possession, responsibility)
- Authority semantics (decision rights, scoped to state/operation)
- Provider mapping table

## Exit Criteria
- [ ] Ownership and authority are separate concepts
- [ ] Authority is scoped, not global
- [ ] Provider patterns not promoted to SCR law

## Implementation Plan
- Correct ownership: possession/responsibility for state
- Correct authority: decision rights for state/operations
- Ensure authority is scoped
- Map to O3DE: authority patterns in component system

## Agent Delegation
- **cavecrew-builder**: Edit ownership/authority definitions
- **cavecrew-reviewer**: Verify separation
