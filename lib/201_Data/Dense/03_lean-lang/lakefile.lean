lean_version = "4"

package "lean_hypergraph" where
  leanOptions := #[
    `pp.unicode.fun := true,
    `autoImplicit := false,
    `relaxedAutoImplicit := false
  ]
import Lake
open Lake DSL

package "lean_hypergraph" where
  leanOptions := #[
    `pp.unicode.fun := true,
    `autoImplicit := false,
    `relaxedAutoImplicit := false
  ]
-- Lean 4 formalization of the SCR Search domain
-- Mirrors the normative definitions from 101_Core and the MLIR scr dialect
-- Provides machine-checked verification of search operations

-- Core types for search
-- GQLPattern: Graph Query Language pattern structure
-- Query: Search query structure  
-- QueryResult: Search result structure
-- SearchMetadata: Search execution metadata
-- is_valid_query: Well-formedness predicate

-- Search operations
-- match, filter, return, start

-- Invariants
-- SRCH-INV-001 through SRCH-INV-006
