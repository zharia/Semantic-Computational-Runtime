import Lake
open Lake DSL

package «SCRFormal» where
  version := v!"0.0.1"

require mathlib from git
  "https://github.com/leanprover-community/mathlib4" @ "v4.19.0"

@[default_target]
lean_lib «SCRFormal» where
  roots := #[`SCRFormal, `SCR.Basic, `SCR.Seed, `SCR.State, `SCR.Identity, `SCR.Relationship,
    `SCR.Equivalence, `SCR.Field, `SCR.Invariants, `SCR.Transformation,
    `SCR.STC, `SCR.STCLaws, `SCR.STCExamples, `SCR.STCCounterexamples,
    `SCR.STCGraphCounterexamples,
    `SCR.STCGraphLaws,
    `SCR.STCGraphMigration,
    `SCR.Schema, `SCR.Conformance, `SCR.Canonical, `SCR.SchemaBridge,
    `SCR.STCGraphCongruence,
    `SCR.STCGraphCausality,
    `SCR.STCGraphHyperedges,
    `SCR.REConformance,
    `SCR.Hypergraph,
    `SCR.Algebra,
    `SCR.AlgebraCounterexamples]
