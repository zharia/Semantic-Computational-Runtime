# 301_Implementation

> Directory documentation for the current SCR library tree.

**Path:** `lib/203_Graph/Hypergraph/301_Implementation`

**Documentation role:** Repository inventory

## Purpose

Executable implementation of the Semantic Hypergraph domain. Contains the implementation plan, language-specific subdirectories (Rust), and conformance documentation for realizing the semantic model in code.

## Current Contents

| Entry | Type | Notes |
|-------|------|-------|
| `000_meta.md` | file | 149 lines; detailed phased implementation plan |
| `101_implementation.md` | file | 44 lines; Lean formalization scope/status/conventions (seems misplaced — content describes Lean, not Rust) |
| `rust/` | subdirectory | Contains only an empty `000_meta.md` |

No Rust source files (`.rs`), `Cargo.toml`, or test files exist yet.

## Current Role

Planning stage. The `000_meta.md` contains a detailed 5-phase implementation plan (Control Plane → MVP → Regions/References → Operations/Deltas → Representations/Transformations → Query/MLIR Bridge). No code has been written.

## Relationship to Parent

Parent is `lib/203_Graph/Hypergraph`. This directory is the executable realization of the hypergraph semantic contract. Must satisfy the formal model (`201_LeanLang`) and conform to the normative definition (`101_definition.md` at Hypergraph root).

## Implementation Evidence

- `000_meta.md`: Comprehensive plan with MVP scope (nodes, hyperedges, roles, attributes, identity, in-memory container, CRUD operations, deltas, validation).
- `101_implementation.md`: Contains Lean formalization conventions and scope — likely misplaced content from `201_LeanLang`.
- `rust/000_meta.md`: Empty file.
- No `.rs` files, no `Cargo.toml`, no test files.

## Documentation Status

- [partially populated] — planning docs exist but no implementation

## Scope Boundary

Should contain when populated:
- Rust crate(s) implementing the hypergraph semantic model
- Test suites validating semantic contracts
- API documentation
- Conformance tests against the definition

Should NOT contain:
- Semantic authority (upstream in `101_definition.md`)
- MLIR dialect definitions (belongs in `101_IR/`)
- Formal proofs (belongs in `201_LeanLang/`)

## Notes

The implementation plan in `000_meta.md` identified a typo in the Documentation directory name (corrected). The `101_implementation.md` file appears to contain content intended for the Lean formalization directory (`201_LeanLang`), as it discusses Lean conventions and formalization scope.
