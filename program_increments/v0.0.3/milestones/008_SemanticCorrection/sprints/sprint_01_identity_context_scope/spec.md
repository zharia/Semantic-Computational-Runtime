# Sprint 008-001: Identity, Context & Scope

## Objective
Correct identity, context, and scope semantics. Ensure SID is sole identity authority. Separate identity from scope and context.

## Deliverables
- Identity semantics (SID uniqueness, authority, persistence, derivation)
- Context semantics (independent from identity)
- Scope semantics (independent from identity)
- Provider mapping table

## Exit Criteria
- [ ] Identity, context, scope are separate concepts
- [ ] SID is sole identity authority
- [ ] Provider patterns not promoted to SCR law

## Implementation Plan
- Correct identity: SID = globally unique semantic identifier
- Correct context: computational context, not identity
- Correct scope: spatial/semantic scope, not identity
- Ensure no conflation in definitions
- Map to O3DE: EntityId = runtime identity

## Agent Delegation
- **cavecrew-builder**: Edit identity/context/scope definitions
- **cavecrew-reviewer**: Verify separation of concerns
