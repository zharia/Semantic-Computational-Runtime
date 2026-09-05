# SCR and MLIR

SCR and MLIR are complementary.

## MLIR

MLIR is a compiler infrastructure and extensible intermediate representation framework.

It provides mechanisms for:

- IR construction;
- operations;
- types;
- attributes;
- regions;
- dialects;
- interfaces;
- verification;
- rewriting;
- analysis;
- conversion;
- lowering;
- code generation infrastructure.

## SCR

SCR uses MLIR as its compiler foundation while adding a semantic architecture concerned with:

- computational meaning;
- semantic contracts;
- semantic domains;
- semantic identity;
- provider independence;
- equivalence;
- capabilities;
- information structures;
- morphology;
- fields;
- graph semantics;
- runtime realization.

## The distinction

```text
SCR Semantic Model
        ↓
MLIR
        ↓
Lowering
        ↓
Execution
```

SCR therefore should not be described as an alternative to MLIR.

Nor should it be reduced to a collection of custom dialects.

## Why the distinction matters

A dialect can represent operations.

SCR asks a broader architectural question:

> What does the operation mean, what contracts govern it, how can it compose with other domains, what implementations can realize it, and how can equivalence be established?

MLIR provides much of the machinery needed to act on those answers.

## Summary

**MLIR supplies compiler infrastructure. SCR supplies a semantic runtime architecture built using that infrastructure.**
