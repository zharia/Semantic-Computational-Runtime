# Sprint 008-003: Lifecycle & Entity/Component

## Objective
Correct lifecycle semantics (profile-based, not universal). Correct entity/component composition (cardinality, identity, composition rules).

## Deliverables
- Lifecycle semantics (applicable profiles, not universal law)
- Entity semantics (identity, composition, SID)
- Component semantics (cardinality, identity, composition rules)
- Provider mapping table

## Exit Criteria
- [ ] Lifecycle expressed as profile, not entity law
- [ ] Entity/component composition rules explicit
- [ ] Cardinality defined for each component type

## Implementation Plan
- Correct lifecycle: activate/deactivate/update is a profile
- Correct entity: has SID, composed of components
- Correct component: may or may not have SID, cardinality explicit
- Map to O3DE: EntityComponent system patterns

## Agent Delegation
- **cavecrew-builder**: Edit lifecycle/entity/component definitions
- **cavecrew-reviewer**: Verify correctness
