# SCR Coordinate Systems

> Canonical coordinate-system semantics for SCR.

**Path:** `lib/801_Spatial/CoordinateSystems/101_definition.md`

**Document type:** Normative semantic definition

**Status:** Formally Specified (corrected v0.0.3)

---

## Purpose

Defines the canonical SCR coordinate system and coordinate-frame mapping semantics.

## Scope

SCR coordinate semantics apply to all spatial computation. Provider-specific coordinate conventions are mapped, not adopted.

---

## Canonical SCR Coordinate Convention

### Handedness

**SCR uses a right-handed coordinate system.**

Proof: Cross product of basis vectors satisfies e₁ × e₂ = e₃.

### Axis Assignment

| Axis | Direction | Semantic Role |
|------|-----------|---------------|
| +X | Right | Lateral positive |
| +Y | Up | Vertical positive |
| +Z | Forward | Depth positive (into the scene) |

### Units

| Quantity | SCR Unit | SI Equivalent |
|----------|----------|---------------|
| Position | meter (m) | 1 m |
| Orientation | radian (rad) | 1 rad |
| Scale | dimensionless | ratio |
| Velocity | m/s | 1 m/s |
| Acceleration | m/s² | 1 m/s² |

Unit conversion must never be hidden inside a coordinate mapping.

---

## Coordinate-Frame Mappings

### SCR ↔ O3DE

| Property | SCR | O3DE |
|----------|-----|------|
| Handedness | Right | Right |
| Forward | +Z | +Y |
| Up | +Y | +Z |
| Right | +X | +X |

**Mapping matrix (SCR → O3DE):**

```
M_SCR_O3DE = | 1  0  0 |    (XSCR → XO3DE)
             | 0  0  1 |    (YSCR → ZO3DE)
             | 0  1  0 |    (ZSCR → YO3DE)
```

This is a signed permutation matrix (det = -1, reflecting the axis swap).

**Inverse (O3DE → SCR):** M_SCR_O3DE⁻¹ = M_SCR_O3DEᵀ (orthogonal matrix)

### SCR ↔ ROS2

| Property | SCR | ROS2 (REP-103) |
|----------|-----|----------------|
| Handedness | Right | Right |
| Forward | +Z | +X |
| Up | +Y | +Z |
| Right | +X | -Y |

**Mapping matrix (SCR → ROS2):**

```
M_SCR_ROS2 = | 0  0  1 |    (ZSCR → XROS2)
             | 0  1  0 |    (YSCR → YROS2)
             |-1  0  0 |    (XSCR → -YROS2)
```

### SCR ↔ USD

| Property | SCR | USD |
|----------|-----|-----|
| Handedness | Right | Right |
| Forward | +Z | -Y |
| Up | +Y | +Z |
| Right | +X | +X |

**Mapping matrix (SCR → USD):**

```
M_SCR_USD = | 1  0  0 |    (XSCR → XUSD)
            | 0  0  1 |    (YSCR → ZUSD)
            | 0 -1  0 |    (ZSCR → -YUSD)
```

---

## Mathematical Properties

All mapping matrices are:
- **Signed permutation matrices** (exactly one ±1 per row and column)
- **Orthogonal** (M⁻¹ = Mᵀ)
- **Bijective** (det = ±1, preserving dimensional meaning)

Point transformation: p_dest = M · p_src + t (where t is origin offset)

Vector transformation: v_dest = M · v_src (direction only, no translation)

Normal transformation: n_dest = M⁻ᵀ · n_src = M · n_src (for orthogonal M)

---

## Preconditions

- Source and destination coordinate frames must be defined.
- Unit conversion must be explicit if source and destination use different units.

## Postconditions

- Dimensional meaning is preserved across the mapping.
- The mapping is invertible.

## Invariants

1. Mapping composition is associative: (M₁₂ · M₂₃) · M₃₄ = M₁₂ · (M₂₃ · M₃₄)
2. Every mapping has an inverse within the signed-permutation class
3. Unit conversion is never hidden inside a coordinate mapping

## Implementation Status

Documented: true
Formally Specified: true
Formally Verified: false (no Lean proof)
Implemented: false (no implementation code)
Tested: false
Validated: false

## Open Questions

- Should SCR adopt a different canonical convention for specific domains (e.g., geographic coordinates)?
- How do non-Euclidean coordinate systems participate in SCR spatial semantics?
