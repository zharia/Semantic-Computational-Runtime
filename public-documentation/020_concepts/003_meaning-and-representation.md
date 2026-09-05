# Meaning and Representation

SCR deliberately separates meaning from representation.

```text
Semantic Meaning
       ≠
Language Representation
       ≠
IR Representation
       ≠
Memory Representation
       ≠
Device Representation
```

## Semantic meaning

Meaning answers questions such as:

- What is this object?
- What does this operation do?
- What state does it represent?
- What constraints apply?
- What observations are significant?
- What relationships does it participate in?

## Representation

Representation answers questions such as:

- How is the object encoded?
- Which IR type is used?
- How is memory laid out?
- Which device resource stores it?
- How is it serialized?

Representations can change without necessarily changing meaning.

## Compilation

A valid compilation pipeline may therefore transform:

```text
Semantic Object
    ↓
Domain Representation
    ↓
MLIR Representation
    ↓
Lowered Representation
    ↓
Memory Representation
    ↓
Device Representation
```

Each transition must preserve the semantic contract relevant to that transition.

## This is stronger than ordinary abstraction

Traditional abstraction often means that callers do not need to know implementation details.

SCR asks a stronger question:

> Can the system itself retain enough semantic knowledge to reason about implementation choices?

That is the foundation for semantic analysis, provider selection, equivalence, optimization, and adaptive execution.
