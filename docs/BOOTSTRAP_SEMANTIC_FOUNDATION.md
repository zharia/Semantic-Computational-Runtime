# Semantic Foundation Bootstrap

## Objective

Establish a coherent semantic foundation before systematic expansion of `lib/`.

## Required order

1. Establish Seed vocabulary.
2. Establish distinctions and anti-definitions.
3. Establish foundational laws.
4. Establish Lean kernel.
5. Establish Seed ↔ Lean mapping.
6. Establish normative `lib/` references to Seed concepts.
7. Implement stable kernel semantics in Mojo.
8. Align Reference Executor behaviour.
9. Lower through MLIR.
10. Add domain-specific formalization incrementally.

## Formalization policy

Lean formalization is required for stable algebraic laws and invariants where a meaningful proposition can be stated. Implementation-only concerns must remain explicitly implementation-only.

## Reference Executor policy

The Reference Executor is an executable behavioural baseline. It is not the source of semantic authority.

## Mojo policy

Mojo is the preferred primary implementation language. This does not make Mojo definitions authoritative over the Seed or Lean formal semantics.

## MLIR policy

MLIR is the compiler and representation substrate. SCR semantics must remain meaningful independently of MLIR-specific representation choices.

## Completion

The bootstrap is complete when:

- Seed validates;
- Lean project builds;
- foundational declarations compile;
- formalized laws have passing proofs;
- Seed mappings resolve;
- Reference Executor demonstrates the kernel;
- conformance tests connect semantic definitions to execution;
- no domain definition introduces vocabulary that conflicts with Seed without an explicit rationale.
