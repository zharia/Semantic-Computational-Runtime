# Sprint 009-002: Materialization & Lowering

## Objective
Correct materialization/lowering to be contract-driven, not fixed pipeline. Materialization does not assume unconditional reversibility.

## Deliverables
- Materialization contracts (semantic → provider)
- Lowering contracts (semantic → implementation)
- Reversibility documentation
- Provider-specific materialization patterns

## Exit Criteria
- [ ] Materialization is contract-driven
- [ ] Lowering is contract-driven
- [ ] Reversibility not assumed unconditional

## Implementation Plan
- Define materialization as semantic contract → provider representation
- Define lowering as semantic → implementation
- Document reversibility conditions
- Correct fixed-pipeline assumptions

## Agent Delegation
- **cavecrew-builder**: Edit materialization/lowering definitions
- **cavecrew-reviewer**: Verify correctness
