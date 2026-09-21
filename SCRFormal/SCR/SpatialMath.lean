import Mathlib.Data.Matrix.Basic
import Mathlib.Tactic.FinCases
import Mathlib.Tactic.NormNum

/-!
# SCR Spatial Mathematics (SCR-SPATIAL-MATH)

Formal verification of coordinate mapping properties.

## Main Theorems
- `o3de_orthogonal`: M · Mᵀ = I
- `o3de_entries`: entries are ±1 or 0
- `ros2_orthogonal`: ROS2 mapping is orthogonal
- `usd_orthogonal`: USD mapping is orthogonal
-/

namespace SCR.SpatialMath

-- ═══════════════════════════════════════════════════════════════════════════
-- O3DE Mapping: SCR(+Z forward, +Y up) → O3DE(+Y forward, +Z up)
-- ═══════════════════════════════════════════════════════════════════════════

def o3deMapping : Matrix (Fin 3) (Fin 3) ℤ :=
  Matrix.of fun i j => match i, j with
    | ⟨0, _⟩, ⟨0, _⟩ => (1 : ℤ) | ⟨0, _⟩, ⟨1, _⟩ => (0 : ℤ) | ⟨0, _⟩, ⟨2, _⟩ => (0 : ℤ)
    | ⟨1, _⟩, ⟨0, _⟩ => (0 : ℤ) | ⟨1, _⟩, ⟨1, _⟩ => (0 : ℤ) | ⟨1, _⟩, ⟨2, _⟩ => (1 : ℤ)
    | ⟨2, _⟩, ⟨0, _⟩ => (0 : ℤ) | ⟨2, _⟩, ⟨1, _⟩ => (1 : ℤ) | ⟨2, _⟩, ⟨2, _⟩ => (0 : ℤ)

theorem o3de_entries :
    ∀ i j, o3deMapping i j = 1 ∨ o3deMapping i j = -1 ∨ o3deMapping i j = 0 := by
  intro i j
  fin_cases i <;> fin_cases j <;> native_decide

theorem o3de_orthogonal :
    o3deMapping * Matrix.transpose o3deMapping = (1 : Matrix (Fin 3) (Fin 3) ℤ) := by
  native_decide

theorem o3de_left_inv :
    Matrix.transpose o3deMapping * o3deMapping = (1 : Matrix (Fin 3) (Fin 3) ℤ) := by
  native_decide

-- ═══════════════════════════════════════════════════════════════════════════
-- ROS2 Mapping: SCR → ROS2(+X forward, +Z up, +Y left)
-- ═══════════════════════════════════════════════════════════════════════════

def ros2Mapping : Matrix (Fin 3) (Fin 3) ℤ :=
  Matrix.of fun i j => match i, j with
    | ⟨0, _⟩, ⟨0, _⟩ => (0 : ℤ) | ⟨0, _⟩, ⟨1, _⟩ => (0 : ℤ) | ⟨0, _⟩, ⟨2, _⟩ => (1 : ℤ)
    | ⟨1, _⟩, ⟨0, _⟩ => (0 : ℤ) | ⟨1, _⟩, ⟨1, _⟩ => (1 : ℤ) | ⟨1, _⟩, ⟨2, _⟩ => (0 : ℤ)
    | ⟨2, _⟩, ⟨0, _⟩ => (-1 : ℤ) | ⟨2, _⟩, ⟨1, _⟩ => (0 : ℤ) | ⟨2, _⟩, ⟨2, _⟩ => (0 : ℤ)

theorem ros2_entries :
    ∀ i j, ros2Mapping i j = 1 ∨ ros2Mapping i j = -1 ∨ ros2Mapping i j = 0 := by
  intro i j
  fin_cases i <;> fin_cases j <;> native_decide

theorem ros2_orthogonal :
    ros2Mapping * Matrix.transpose ros2Mapping = (1 : Matrix (Fin 3) (Fin 3) ℤ) := by
  native_decide

theorem ros2_left_inv :
    Matrix.transpose ros2Mapping * ros2Mapping = (1 : Matrix (Fin 3) (Fin 3) ℤ) := by
  native_decide

-- ═══════════════════════════════════════════════════════════════════════════
-- USD Mapping: SCR → USD(+X right, +Z up, -Y forward)
-- ═══════════════════════════════════════════════════════════════════════════

def usdMapping : Matrix (Fin 3) (Fin 3) ℤ :=
  Matrix.of fun i j => match i, j with
    | ⟨0, _⟩, ⟨0, _⟩ => (1 : ℤ) | ⟨0, _⟩, ⟨1, _⟩ => (0 : ℤ) | ⟨0, _⟩, ⟨2, _⟩ => (0 : ℤ)
    | ⟨1, _⟩, ⟨0, _⟩ => (0 : ℤ) | ⟨1, _⟩, ⟨1, _⟩ => (0 : ℤ) | ⟨1, _⟩, ⟨2, _⟩ => (1 : ℤ)
    | ⟨2, _⟩, ⟨0, _⟩ => (0 : ℤ) | ⟨2, _⟩, ⟨1, _⟩ => (-1 : ℤ) | ⟨2, _⟩, ⟨2, _⟩ => (0 : ℤ)

theorem usd_entries :
    ∀ i j, usdMapping i j = 1 ∨ usdMapping i j = -1 ∨ usdMapping i j = 0 := by
  intro i j
  fin_cases i <;> fin_cases j <;> native_decide

theorem usd_orthogonal :
    usdMapping * Matrix.transpose usdMapping = (1 : Matrix (Fin 3) (Fin 3) ℤ) := by
  native_decide

theorem usd_left_inv :
    Matrix.transpose usdMapping * usdMapping = (1 : Matrix (Fin 3) (Fin 3) ℤ) := by
  native_decide

-- ═══════════════════════════════════════════════════════════════════════════
-- Cross-mapping: O3DE round-trip preserves identity
-- ═══════════════════════════════════════════════════════════════════════════

/-- O3DE mapping composed with itself (round-trip) is identity. -/
theorem o3de_roundtrip :
    o3deMapping * o3deMapping = (1 : Matrix (Fin 3) (Fin 3) ℤ) := by
  native_decide

end SCR.SpatialMath
