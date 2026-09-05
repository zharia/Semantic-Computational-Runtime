# SCR and MLIR

SCR is **built on top of MLIR**.

MLIR provides the compiler infrastructure; SCR provides the semantic architecture that gives computational meaning a more explicit role.

## What MLIR already provides

MLIR supplies infrastructure for:

- operations;
- values;
- types;
- attributes;
- regions;
- blocks;
- dialects;
- interfaces;
- traits;
- verification;
- rewriting;
- canonicalization;
- analysis;
- dialect conversion;
- lowering;
- serialization;
- target-specific compilation.

SCR should use these capabilities rather than recreating them.

## The SCR relationship

```text
SCR Semantic Model
        ↓
Domain Representation
        ↓
MLIR
        ↓
MLIR Transformation Infrastructure
        ↓
Target Lowering
```

SCR therefore does not attempt to create a second independent compiler framework.

## Why SCR is still distinct

MLIR does not by itself constitute the complete semantic architecture proposed by SCR.

SCR adds an architectural model for:

- semantic domains;
- semantic contracts;
- semantic identity;
- provider independence;
- semantic equivalence;
- information structures;
- capabilities;
- morphology;
- fields;
- graph semantics;
- execution relationships.

## Not every concept needs a dialect

A semantic domain can use MLIR mechanisms in different ways.

Some concepts may map naturally to operations and types. Others may be represented through attributes, interfaces, external models, analysis structures, or combinations of existing dialects.

The architectural requirement is semantic fidelity, not maximal dialect proliferation.

## The governing principle

> **MLIR represents and transforms computational structures; SCR defines the semantic architecture those structures participate in.**

The two layers are complementary.
