# Sprint 006-003: Semantic Reconciliation

## Objective
Resolve each contradiction by designating canonical definition, removing provider contamination, correcting mathematical claims, and producing unified corrected definitions.

## Deliverables
- Reconciliation decisions for each contradiction
- Updated definition files (minimal changes)
- Provider contamination removed from SCR artifacts

## Exit Criteria
- [ ] Every contradiction has a resolution
- [ ] Canonical definitions established
- [ ] Provider-specific patterns separated from SCR semantics
- [ ] No silent contradictions remain

## Implementation Plan
- For each contradiction: designate canonical SCR definition
- Designate provider-specific behavior
- Mark incorrect claims for correction
- Mark unresolved items for escalation
- Update definition files
- Clean provider contamination

## Agent Delegation
- **cavecrew-builder**: Apply reconciliation edits to definition files
- **cavecrew-reviewer**: Verify reconciliation preserves SCR invariants
