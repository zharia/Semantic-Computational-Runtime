# Sprint 04: Temporal, Identity & State Ownership

Document temporal semantics, identity mappings, and state ownership model.

## Deliverables
- Temporal semantics classification (wall-clock / simulation / observation / network / frame / physics timestep)
- Identity mapping table (SCR SID ↔ O3DE EntityId ↔ network ID ↔ USD path ↔ ROS entity)
- State ownership model (who owns/mutates/observes/predicts/reconciles each state)

## Exit Criteria
- [ ] Frame number ≠ simulation time unless justified
- [ ] Identity scope/lifetime/stability/collision documented
- [ ] State ownership explicit for all mapped states
