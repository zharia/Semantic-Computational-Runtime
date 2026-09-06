# SCR Foundational Documentation v2

This package is the proposed v2 foundational refactor of the four existing SCR documents:

- `101_BACKGROUND.md`
- `102_ARCHITECTURE.md`
- `103_SEMANTIC_MODEL.md`
- `104_SEMANTIC_INVARIANTS.md`

## Central architectural change

The Semantic Field is promoted to the foundational substrate of SCR.

The four documents now form a coherent dependency chain:

```text
101 BACKGROUND
     ↓ establishes why
102 ARCHITECTURE
     ↓ establishes how
103 SEMANTIC MODEL
     ↓ establishes what
104 SEMANTIC INVARIANTS
     ↓ establishes what must remain true
```

Cross-cutting implementation references, including MLIR, remain subordinate technical infrastructure.

## Normative principle

> Engineer outward from the Semantic Field.

The v2 documents deliberately avoid creating a separate `SEMANTIC_FIELD.md` because that would duplicate the semantic model. The Semantic Field is instead made the organising principle of the existing foundational model.
