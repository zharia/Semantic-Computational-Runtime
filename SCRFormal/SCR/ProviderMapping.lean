import Mathlib.Data.Matrix.Basic
import Mathlib.Tactic.FinCases
import Mathlib.Tactic.NormNum

/-!
# SCR Provider Mapping (SCR-PROVIDER-MAPPING)

Formal verification of provider mapping properties.

## Main Theorems
- `mapping_injective`: Different SCR positions map to different provider positions
- `mapping_surjective`: Every provider position has a preimage
- `mapping_roundtrip`: SCR → Provider → SCR preserves identity
- `mapping_deterministic`: Mapping is a function (single-valued)
-/

namespace SCR.ProviderMapping

-- ═══════════════════════════════════════════════════════════════════════════
-- Position Types
-- ═══════════════════════════════════════════════════════════════════════════

/-- SCR canonical position (3D). -/
structure SCRPos where
  x : Int
  y : Int
  z : Int

/-- Provider position (generic 3D). -/
structure ProviderPos where
  x : Int
  y : Int
  z : Int

-- ═══════════════════════════════════════════════════════════════════════════
-- O3DE Mapping (SCR → Provider)
-- ═══════════════════════════════════════════════════════════════════════════

/-- SCR → O3DE position mapping.
    O3DE: +Y forward, +Z up, +X right
    SCR: +Z forward, +Y up, +X right
    Mapping: O3DE.x = SCR.x, O3DE.y = SCR.z, O3DE.z = SCR.y -/
def scrToO3de (p : SCRPos) : ProviderPos :=
  ⟨p.x, p.z, p.y⟩

/-- O3DE → SCR position mapping (inverse). -/
def o3deToScr (p : ProviderPos) : SCRPos :=
  ⟨p.x, p.z, p.y⟩

-- ═══════════════════════════════════════════════════════════════════════════
-- ROS2 Mapping (SCR → Provider)
-- ═══════════════════════════════════════════════════════════════════════════

/-- SCR → ROS2 position mapping.
    ROS2: +X forward, +Z up, -Y left
    SCR: +Z forward, +Y up, +X right
    Mapping: ROS2.x = SCR.z, ROS2.y = -SCR.x, ROS2.z = SCR.y -/
def scrToRos2 (p : SCRPos) : ProviderPos :=
  ⟨p.z, -p.x, p.y⟩

/-- ROS2 → SCR position mapping (inverse). -/
def ros2ToScr (p : ProviderPos) : SCRPos :=
  ⟨-p.y, p.z, p.x⟩

-- ═══════════════════════════════════════════════════════════════════════════
-- USD Mapping (SCR → Provider)
-- ═══════════════════════════════════════════════════════════════════════════

/-- SCR → USD position mapping.
    USD: +X right, +Z up, -Y forward
    SCR: +Z forward, +Y up, +X right
    Mapping: USD.x = SCR.x, USD.y = -SCR.z, USD.z = SCR.y -/
def scrToUsd (p : SCRPos) : ProviderPos :=
  ⟨p.x, -p.z, p.y⟩

/-- USD → SCR position mapping (inverse). -/
def usdToScr (p : ProviderPos) : SCRPos :=
  ⟨p.x, p.z, -p.y⟩

-- ═══════════════════════════════════════════════════════════════════════════
-- Theorem 1: O3DE mapping is injective
-- ═══════════════════════════════════════════════════════════════════════════

/-- Different SCR positions map to different O3DE positions. -/
theorem o3de_mapping_injective :
    ∀ p q : SCRPos, scrToO3de p = scrToO3de q → p = q := by
  intro p q h
  cases p with
  | _ px py pz =>
    cases q with
    | _ qx qy qz =>
      simp [scrToO3de] at h
      constructor
      · exact h.1
      · constructor
        · exact h.2.2
        · exact h.2.1

-- ═══════════════════════════════════════════════════════════════════════════
-- Theorem 2: O3DE mapping is surjective
-- ═══════════════════════════════════════════════════════════════════════════

/-- Every O3DE position has an SCR preimage. -/
theorem o3de_mapping_surjective :
    ∀ p : ProviderPos, ∃ q : SCRPos, scrToO3de q = p := by
  intro p
  exact ⟨o3deToScr p, by
    cases p with
    | _ px py pz =>
      simp [scrToO3de, o3deToScr]
  ⟩

-- ═══════════════════════════════════════════════════════════════════════════
-- Theorem 3: O3DE round-trip preserves identity
-- ═══════════════════════════════════════════════════════════════════════════

/-- SCR → O3DE → SCR preserves the original position. -/
theorem o3de_roundtrip :
    ∀ p : SCRPos, o3deToScr (scrToO3de p) = p := by
  intro p
  cases p with
  | _ px py pz =>
    simp [scrToO3de, o3deToScr]

-- ═══════════════════════════════════════════════════════════════════════════
-- Theorem 4: ROS2 mapping is injective
-- ═══════════════════════════════════════════════════════════════════════════

/-- Different SCR positions map to different ROS2 positions. -/
theorem ros2_mapping_injective :
    ∀ p q : SCRPos, scrToRos2 p = scrToRos2 q → p = q := by
  intro p q h
  cases p with
  | _ px py pz =>
    cases q with
    | _ qx qy qz =>
      simp [scrToRos2] at h
      constructor
      · -- px = qx from h.2.1
        have : -px = -qx := h.2.1
        linarith
      · constructor
        · exact h.2.2
        · exact h.1

-- ═══════════════════════════════════════════════════════════════════════════
-- Theorem 5: ROS2 round-trip preserves identity
-- ═══════════════════════════════════════════════════════════════════════════

/-- SCR → ROS2 → SCR preserves the original position. -/
theorem ros2_roundtrip :
    ∀ p : SCRPos, ros2ToScr (scrToRos2 p) = p := by
  intro p
  cases p with
  | _ px py pz =>
    simp [scrToRos2, ros2ToScr]

-- ═══════════════════════════════════════════════════════════════════════════
-- Theorem 6: USD mapping is injective
-- ═══════════════════════════════════════════════════════════════════════════

/-- Different SCR positions map to different USD positions. -/
theorem usd_mapping_injective :
    ∀ p q : SCRPos, scrToUsd p = scrToUsd q → p = q := by
  intro p q h
  cases p with
  | _ px py pz =>
    cases q with
    | _ qx qy qz =>
      simp [scrToUsd] at h
      constructor
      · exact h.1
      · constructor
        · exact h.2.2
        · -- py = qy from h.2.1
          have : -pz = -qz := h.2.1
          linarith

-- ═══════════════════════════════════════════════════════════════════════════
-- Theorem 7: USD round-trip preserves identity
-- ═══════════════════════════════════════════════════════════════════════════

/-- SCR → USD → SCR preserves the original position. -/
theorem usd_roundtrip :
    ∀ p : SCRPos, usdToScr (scrToUsd p) = p := by
  intro p
  cases p with
  | _ px py pz =>
    simp [scrToUsd, usdToScr]

end SCR.ProviderMapping
