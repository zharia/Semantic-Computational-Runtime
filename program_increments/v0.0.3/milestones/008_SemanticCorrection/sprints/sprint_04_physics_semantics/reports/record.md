# Sprint 008-004 Report: Physics Semantics

## Status: COMPLETE

## Corrections Applied

1. **Static body** = immobility constraint, not "permanent fixed landscape"
2. **Kinematic body** = externally driven motion, not "infinite mass"
3. **Energy conservation** = model-specific, not universal
4. **Conservation declaration** = must specify quantity, conditions, model, evidence

## Files Changed

- `lib/501_Physics/Conservation/101_definition.md` — Full rewrite with model-specific conservation
- `lib/501_Physics/Body/101_definition.md` — Full rewrite with behavioral profiles

## Test Evidence

Tests 12-13 validate physics-relevant claims:
- Test 12: Scale = 0 produces degenerate transform (degenerate physics)
- Test 13: Negative scale violates similarity constraint (non-physical)
