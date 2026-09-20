# Milestone 007: Mathematical Correction

## 1. Scope & Objective
Correct coordinate-system semantics, transform algebra, and produce validation tests. Resolve all contradictory axis claims. Define the supported transformation class with mathematical precision.

## 2. Deliverables
- Canonical SCR coordinate convention (handedness, axes, units)
- Mathematically precise coordinate-frame mappings (SCR ↔ O3DE ↔ USD ↔ ROS2)
- Transform algebra specification (position/orientation/pose/scale/rigid/affine)
- Composition rules, inverses, identity elements
- Validation tests for all transform properties

## 3. Formal Invariants
1. Transform composition is associative for the supported class.
2. Every supported transform has an inverse within the class.
3. Coordinate mappings are bijective and preserve dimensional meaning.
4. Unit conversion is never hidden inside coordinate mapping.

## 4. Exit Criteria
- [ ] Canonical SCR coordinate convention documented
- [ ] All contradictory axis claims resolved
- [ ] Transform class explicitly defined (rigid/similarity/affine)
- [ ] Composition/inverse/identity verified for claimed class
- [ ] Non-uniform scale + rotation closure conditions stated
- [ ] 12+ validation tests produced with numerical tolerances

## 5. Dependencies
- Milestone 006 (archaeology and contradiction detection)
