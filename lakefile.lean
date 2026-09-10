/-
  The Lean formal development lives in ./SCRFormal (Lean v4.19.0).
  Build: cd SCRFormal && lake build
  The former root `formal/` (v4.34 + Mathlib master) was merged into
  SCRFormal on 2026-09-10; see docs/113_FORMAL_ONTOLOGY_MERGE.md.
-/
import Lake
open Lake DSL

package «SemanticComputationalRuntime» where
  leanOptions := #[
    ⟨`pp.unicode.fun, true⟩,
    ⟨`autoImplicit, false⟩,
    ⟨`relaxedAutoImplicit, false⟩
  ]
