# Semantic Primacy

**Semantic primacy** is the architectural rule that implementation does not define meaning.

The normative direction is:

```text
Semantic Definition
        ↓
Semantic Contract
        ↓
Representation
        ↓
Implementation
        ↓
Execution
```

Not:

```text
Implementation
        ↓
Whatever semantics happen to emerge
```

## Example

```text
Semantic Position
        ≠
Rust Position Struct
        ≠
MLIR Position Type
        ≠
GPU Buffer
        ≠
Vulkan Resource
```

These may represent the same semantic concept at different levels, but each belongs to a different architectural layer.

## Why this matters

If implementation becomes the semantic authority, replacing an implementation silently changes the meaning of the application.

That destroys provider independence.

A semantic definition should survive:

- programming-language changes;
- data-layout changes;
- compiler changes;
- provider changes;
- hardware changes;
- serialization changes;
- rendering changes.

## The semantic authority test

For any rule in SCR, ask:

> Would this rule still be true if the implementation changed?

If the answer is no, it may be an implementation constraint rather than a semantic invariant.

## Provider independence

Providers satisfy semantic contracts. They do not own them.

A provider may expose additional capabilities or constraints, but it must not silently redefine the semantic identity of the operation it realizes.

This distinction is fundamental to substitution, optimization, portability, and verification.
