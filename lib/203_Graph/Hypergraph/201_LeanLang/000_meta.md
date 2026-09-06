# Semantic Hypergraph — Lean Formalization

**Domain:** `lib/203_Graph/Hypergraph`  
**Directory:** `201_lean`  
**Purpose:** Formal specification and machine-checked proofs of the Semantic Hypergraph model in Lean 4.

---

## Role of this Directory

This directory contains the **Lean 4 formalization** of the Semantic Hypergraph substrate.

It exists to:

- Encode the normative semantic definitions from `101_definition/` as precise Lean types, structures, and predicates.
- State and prove core invariants, well-formedness conditions, and algebraic properties of the hypergraph model.
- Provide a machine-checked reference that implementations (Rust, MLIR, etc.) can be measured against.
- Support future extraction or refinement toward verified components where valuable.

This is **not** an implementation of the runtime hypergraph.  
It is a formal model of the *semantics*.

---

## Relationship to Other Directories

| Directory              | Relationship                                      |
|------------------------|---------------------------------------------------|
| `101_definition/`      | Normative source of truth. Lean must conform to it. |
| `301_Implementation/`  | Executable realization. Must satisfy the formal model. |
| `401_Documentation/`   | Human-readable notes and rationale.               |

Authority order remains:
