# Sprint 007-001: Coordinate-System Semantics

## Objective
Define canonical SCR coordinate system. Correct all contradictory axis claims. Define coordinate-frame mappings with signed-permutation matrices and unit conversions.

## Deliverables
- Canonical SCR coordinate convention (handedness, axes, units)
- Coordinate-frame mappings (SCR ↔ O3DE ↔ USD ↔ ROS2)
- Proof that mappings are bijective
- Unit conversion separation

## Exit Criteria
- [ ] Single canonical SCR coordinate system defined
- [ ] All contradictory axis claims resolved
- [ ] Each mapping has explicit mathematical representation
- [ ] Unit conversion not hidden in coordinate mapping

## Implementation Plan
- SCR canonical: +Z forward, +Y up, +X right (right-handed)
- O3DE: +Y forward, +Z up, +X right
- USD: +Y forward, +Z up
- ROS2: +X forward, +Z up, +Y left
- Define signed-permutation matrices for each mapping
- Prove bijection (determinant = ±1)
- Separate unit conversion

## Agent Delegation
- **cavecrew-builder**: Write coordinate convention definitions
- **cavecrew-reviewer**: Verify mathematical correctness
