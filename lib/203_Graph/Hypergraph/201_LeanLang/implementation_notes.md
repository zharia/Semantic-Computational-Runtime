
The Lean model may reveal ambiguities or missing invariants in the definition; those must be resolved in the definition, not by silently changing the formalization.

---

## Scope (Current Intent)

**In scope**
- Core types: nodes, hyperedges, roles, attributes, identities, regions (as they stabilize).
- Well-formedness predicates.
- Basic operation and delta semantics.
- Key invariants (identity uniqueness, role constraints, delta application properties, etc.).

**Out of scope (for now)**
- Full executable runtime simulation.
- Persistence, networking, or concrete serialization.
- Domain-specific theories (physics, morphology, etc.).
- Automated extraction of production Rust/MLIR code (unless later justified).

---

## Status

- **Formalization status:** not started
- **Proof coverage:** 0 %
- **Lean toolchain:** to be pinned when work begins
- **Primary reference:** `../101_definition.md`

---

## Conventions

- Prefer small, composable definitions over large monolithic structures.
- Make every axiom and assumption explicit.
- Prefer constructive proofs where practical.
- Keep the formal model as close as possible to the English definition so that divergence is easy to detect.
- Document any intentional simplifications or idealizations.

---

## Notes

This directory is currently a placeholder.  
No Lean source files exist yet. Work should begin only after the Minimal Viable Core of the hypergraph has been specified and a first executable implementation exists, so that the formalization targets a stable contract rather than a moving vision.
