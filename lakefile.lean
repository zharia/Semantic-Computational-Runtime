import Lake

open Lake DSL

package «SemanticComputationalRuntime» where
  leanOptions := #[
    ⟨`pp.unicode.fun, true⟩,
    ⟨`autoImplicit, false⟩,
    ⟨`relaxedAutoImplicit, false⟩,
    ⟨`maxRecDepth, 100000⟩
  ]

require mathlib from git
  "https://github.com/leanprover-community/mathlib4" @ "master"

@[default_target]
lean_lib SCRFormal where
  srcDir := "formal"
  roots := #[`SCR.Basic]
