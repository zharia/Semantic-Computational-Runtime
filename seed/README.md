# SCR Semantic Foundation / Seed v0.0.1

This package bootstraps the Semantic Computational Runtime (SCR) semantic foundation.

## Purpose

The Seed is the canonical semantic vocabulary and knowledge substrate from which SCR domain definitions are expressed. It is **not** a second specification system and it does not replace `lib/**/101_definition.md`.

The dependency direction is:

    Seed
      ↓
    Lean + Mathlib formal foundation
      ↓
    SCR normative specifications
      ↓
    lib/
      ↓
    Mojo implementation
      ↓
    MLIR / lowering
      ↓
    Reference Executor / providers
      ↓
    execution

## Roles

| Layer | Authority / role |
|---|---|
| `seed/` | foundational vocabulary, relations, distinctions, laws, provenance |
| `SCRFormal/` | mechanically checked formal projection of the stable kernel |
| `lib/` | normative domain semantics and implementation contracts |
| Mojo | preferred primary implementation language |
| MLIR | compiler/IR substrate |
| Reference Executor | executable behavioral baseline |
| Providers | concrete realizations |

## Status

This package is a bootstrap foundation. It deliberately formalizes a small kernel and maps the broader Seed vocabulary to future formalization work. It does **not** claim that every SCR invariant or domain is already formally proven.

## Compatibility

The package is designed around the current SCR Semantic Field architecture:

    Semantic Field
        → Structure
        → Transformation
        → Execution
        → Physical Manifestation

The hypergraph, graph, mesh, tensor, buffer, GPU object, or other representation is never treated as the semantic definition merely because it is convenient to implement.

## Bootstrap command

```bash
cd SCRFormal
lake build SCRFormal
```

If the repository already contains a `SCRFormal` project, merge the modules under `SCR/` carefully rather than creating a competing Lean project.

## Non-negotiable rule

Do not infer implementation status from Seed entries. A Seed concept marked `established` is a semantic vocabulary item, not proof that a corresponding library operation, Mojo type, MLIR operation, or runtime capability exists.
