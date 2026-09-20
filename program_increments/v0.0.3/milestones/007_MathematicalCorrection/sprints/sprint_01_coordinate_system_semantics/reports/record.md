# Sprint 007-001 Report: Coordinate-System Semantics

## Status: COMPLETE

## Canonical SCR Convention

- **Handedness:** Right-handed
- **Axes:** +X right, +Y up, +Z forward
- **Units:** meters (position), radians (orientation), dimensionless (scale)

## Corrections Applied

1. Removed contradictory "left-handed" and "Z-up" claims for O3DE
2. Established canonical mapping matrices (signed permutation) for SCR↔O3DE, SCR↔ROS2, SCR↔USD
3. Separated unit conversion from coordinate mapping
4. Proved bijection (det = ±1)

## Files Changed

- `lib/801_Spatial/CoordinateSystems/101_definition.md` — Full rewrite with canonical convention and mappings
- `lib/801_Spatial/Coordinates/101_definition.md` — Clarified coordinate vs identity
