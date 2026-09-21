# Development Agent Instruction

## 006 — Extended Formal Verification

**Program Increment:** v0.0.4

**Predecessor:** v0.0.3/003 (Reference Implementation)

**Objective type:** Formal verification

---

# 1. Mission

Extend Lean proofs to cover transformation algebra properties and entity lifecycle invariants, building on the coordinate mapping proofs from v0.0.3/003.

The preceding objective established 10 Lean theorems for coordinate mapping properties. This objective extends the formal verification to cover transformation composition, inverse correctness, and entity state machine properties.

---

# 2. Governing Principles

## 2.1 Prove properties, not implementations

Prove mathematical properties of SCR contracts, not implementation details.

## 2.2 Link proofs to specifications

Each proof must reference the specification it verifies.

## 2.3 Distinguish formal from empirical

A Lean proof establishes mathematical truth. A test establishes empirical behavior.

---

# 3. Scope

## 3.1 Transformation Algebra

### Properties to Prove

| Property | Statement | Specification |
|----------|-----------|---------------|
| Composition associativity | (T₃ ∘ T₂) ∘ T₁ = T₃ ∘ (T₂ ∘ T₁) | lib/905_Transforms/101_definition.md |
| Identity left | I ∘ T = T | lib/905_Transforms/101_definition.md |
| Identity right | T ∘ I = T | lib/905_Transforms/101_definition.md |
| Inverse left | T⁻¹ ∘ T = I | lib/905_Transforms/101_definition.md |
| Inverse right | T ∘ T⁻¹ = I | lib/905_Transforms/101_definition.md |

### Implementation

Represent SimilarityTransform as a structure with:
- Scale: ℚ₊ (positive rational)
- Rotation: quaternion (Hamilton, scalar-first)
- Translation: ℚ³

Prove group properties using Lean's algebraic hierarchy.

## 3.2 Entity Lifecycle

### Properties to Prove

| Property | Statement | Specification |
|----------|-----------|---------------|
| Valid transitions | Only specified transitions are allowed | lib/101_Core/State/101_definition.md |
| No self-destruction | Entity cannot transition to Created from Destroyed | lib/101_Core/State/101_definition.md |
| Terminal state | Destroyed has no outgoing transitions | lib/101_Core/State/101_definition.md |

### Implementation

Model lifecycle as a finite state machine with states:
- Created
- Active
- Suspended
- Destroyed

Prove transition constraints using Lean's inductive types.

## 3.3 Provider Mapping

### Properties to Prove

| Property | Statement | Specification |
|----------|-----------|---------------|
| Mapping injectivity | Distinct SIDs map to distinct ProviderIDs | lib/801_Spatial/ReferenceImplementation/adapter_specification.md |
| Mapping surjectivity | Every ProviderID maps to a SID | lib/801_Spatial/ReferenceImplementation/adapter_specification.md |
| Round-trip | SID → ProviderID → SID preserves identity | lib/801_Spatial/ReferenceImplementation/adapter_specification.md |

---

# 4. Implementation Requirements

## 4.1 File Structure

```
SCRFormal/SCR/
├── SpatialMath.lean          (existing - coordinate mappings)
├── TransformAlgebra.lean     (new - transformation properties)
├── EntityLifecycle.lean      (new - state machine properties)
└── ProviderMapping.lean      (new - mapping properties)
```

## 4.2 Proof Method

- Use Lean 4 with Mathlib
- Use `native_decide` for computable properties
- Use `decide` for decidable propositions
- Use `omega` for linear arithmetic
- Use `simp` for simplification

## 4.3 Build Command

```bash
cd SCRFormal
lake build SCR.TransformAlgebra
lake build SCR.EntityLifecycle
lake build SCR.ProviderMapping
```

---

# 5. Testing

## 5.1 Verification

Each proof must compile with `lake build`.

## 5.2 Cross-Validation

Each Lean property should have a corresponding C++ test in the reference implementation.

---

# 6. Deliverables

1. `SCRFormal/SCR/TransformAlgebra.lean` — Transformation algebra proofs
2. `SCRFormal/SCR/EntityLifecycle.lean` — Entity lifecycle proofs
3. `SCRFormal/SCR/ProviderMapping.lean` — Provider mapping proofs
4. Updated `SCRFormal/lakefile.lean` — New modules
5. Updated final report

---

# 7. Acceptance Criteria

- [ ] Transformation algebra proofs compile
- [ ] Entity lifecycle proofs compile
- [ ] Provider mapping proofs compile
- [ ] Each proof linked to specification
- [ ] No existing proofs broken
- [ ] Documentation updated
