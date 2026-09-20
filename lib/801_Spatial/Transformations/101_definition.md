# SCR Transformations

> Canonical transformation semantics for SCR.

**Path:** `lib/801_Spatial/Transformations/101_definition.md`

**Document type:** Normative semantic definition

**Status:** Formally Specified (corrected v0.0.3)

---

## Purpose

Defines the SCR transformation model: what a transformation is, which class SCR supports, composition rules, and mathematical properties.

## Scope

SCR transformation semantics apply to all spatial computation. Provider-specific transformation representations are mapped, not adopted.

---

## Terminology

| Term | Definition |
|------|-----------|
| **Position** | A point in space: p = (x, y, z) ∈ ℝ³ |
| **Orientation** | A rotation: R ∈ SO(3), represented as quaternion or rotation matrix |
| **Pose** | Position + Orientation: (R, t) where R ∈ SO(3), t ∈ ℝ³ |
| **Scale** | A scalar multiplier: s ∈ ℝ⁺ (uniform) or S = diag(sx, sy, sz) ∈ ℝ³⁺ (non-uniform) |
| **Rigid Transform** | Isometry preserving distances and angles: T = (R, t), R ∈ SO(3), t ∈ ℝ³ |
| **Similarity Transform** | Rigid transform + uniform scale: T = (s, R, t), s ∈ ℝ⁺ |
| **Affine Transform** | Linear map + translation: T = (A, t), A ∈ GL(3), t ∈ ℝ³ |

**Do not call every position/orientation/scale tuple a "pose."** A pose specifically refers to position + orientation without scale.

---

## Supported Transformation Class

**SCR supports similarity transforms as its primary transformation class.**

```
T = (s, R, t)
where:
  s ∈ ℝ⁺     (uniform scale, positive real)
  R ∈ SO(3)   (rotation, special orthogonal group)
  t ∈ ℝ³      (translation)
```

### Why Similarity?

- **Rigid transforms** (s=1) are insufficient: games and simulations need scale.
- **Non-uniform scale** (S = diag(sx, sy, sz)) does not compose cleanly with rotation:
  - R · S ≠ S · R in general
  - Composition produces shear: R₂ · S₂ · R₁ · S₁ ≠ (R₂R₁, S₂S₁) in general
  - Closed-form decomposition requires SVD at each step
- **Affine transforms** (general A ∈ GL(3)) are too permissive: shear and non-uniform scale obscure semantic meaning.

### Composition Closure

Similarity transforms are closed under composition:

```
T₂ ∘ T₁ = (s₂, R₂, t₂) ∘ (s₁, R₁, t₁)
         = (s₂·s₁, R₂·R₁, s₂·R₂·t₁ + t₂)
```

**Properties:**
- **Closure:** Result is always a similarity transform
- **Associativity:** (T₃ ∘ T₂) ∘ T₁ = T₃ ∘ (T₂ ∘ T₁) (inherited from matrix multiplication)
- **Identity:** T_id = (1, I, 0)
- **Inverse:** T⁻¹ = (1/s, Rᵀ, -(1/s)·Rᵀ·t)

### Non-Uniform Scale Handling

Non-uniform scale is represented separately when needed:

```
T_nu = (S, R, t) where S = diag(sx, sy, sz)
```

**Limitation:** Non-uniform scale + rotation is NOT closed under composition. SCR treats this as a provider-specific representation. When composition is required, decompose via SVD or restrict to uniform scale.

---

## Mathematical Properties

| Property | Similarity Transform | Rigid Transform |
|----------|---------------------|-----------------|
| Closure | ✓ | ✓ |
| Associativity | ✓ | ✓ |
| Identity | (1, I, 0) | (1, I, 0) |
| Inverse | (1/s, Rᵀ, -Rᵀ·t/s) | (Rᵀ, -Rᵀ·t) |
| Group structure | Yes (similarity group) | Yes (Euclidean group) |

---

## Transform Composition Rules

### Active vs Passive

- **Active (alibi):** Transform the object, keep the frame fixed
- **Passive (alias):** Transform the frame, keep the object fixed

SCR uses **active transforms** by default. Passive transforms are the inverse.

### Local vs Parent

- **Local-to-parent:** Transform from child frame to parent frame
- **Parent-to-local:** Transform from parent frame to child frame

SCR uses **local-to-parent** for hierarchical composition.

### Multiplication Order

SCR uses **column-vector convention** (right-multiply):

```
world_position = T_parent · T_child · local_position
```

### Quaternion Convention

- Quaternion: q = (w, x, y, z) where w is the scalar part
- Multiplication: Hamilton product (scalar-first)
- Rotation applied as: v' = q · v · q⁻¹

---

## Preconditions

- Source and destination coordinate frames must be defined.
- Scale values must be positive (s > 0).

## Postconditions

- Distances are scaled by s (similarity) or preserved exactly (rigid).
- Angles are preserved under rotation.

## Invariants

1. T ∘ T⁻¹ = T_id (inverse exists)
2. (T₃ ∘ T₂) ∘ T₁ = T₃ ∘ (T₂ ∘ T₁) (associativity)
3. T ∘ T_id = T (identity)

## Implementation Status

Documented: true
Formally Specified: true
Formally Verified: false (no Lean proof)
Implemented: true (Matrix4 in OGRE provider)
Tested: false
Validated: false

## Open Questions

- Should non-uniform scale be explicitly represented in the SCR transformation model?
- How do hierarchical transform chains interact with non-uniform scale?
