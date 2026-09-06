# Sequence and Text Semantics

**Status:** Normative
**Scope:** Semantic Computational Runtime — value model, sequences, text, storage and mutation semantics

## 1. Purpose

SCR defines ordered collections through a general `Sequence<T>` abstraction. Strings are not primitive memory layouts; they are semantic sequences whose element domain is explicitly defined.

## 2. Sequence

A sequence is an ordered, finite collection of values of a defined semantic element type.

Conceptually:

```text
Sequence<T>
    semantic_type
    length
    capacity
    representation
    allocation_policy
    mutation_policy
    storage
```

This is illustrative rather than an ABI requirement.

`length` describes the logical value. `capacity` describes available physical storage and MUST NOT alter semantic length.

## 3. Text

A text value SHOULD be modelled as a sequence over an explicitly selected textual domain. Possible domains include:

- bytes;
- encoding units;
- Unicode scalar values;
- grapheme clusters;
- tokens or other higher-level linguistic units.

The runtime MUST NOT conflate these levels.

## 4. NUL Termination

NUL termination is NOT a semantic property of a string.

SCR strings MUST NOT require a terminating NUL in their canonical representation. NUL termination MAY be introduced when crossing an ABI or external interface that requires it.

Embedded NUL values are therefore valid whenever permitted by the selected element domain.

## 5. Representation Independence

A sequence MAY be represented as:

- contiguous storage;
- inline storage;
- segmented storage;
- rope/tree storage;
- slice/view;
- shared or copy-on-write storage;
- external storage;
- streaming storage.

Representation MAY change during execution without changing semantic identity or value.

## 6. Mutation

Immutability is a policy, not an inherent property of text.

SCR MAY support immutable, uniquely mutable, transactional, copy-on-write, append-only, and shared representations. A uniquely owned mutable sequence SHOULD permit in-place mutation where safe.

Frequent simulation updates SHOULD favour capacity reuse and mutation without unnecessary reallocation or copying.

## 7. Allocation

Allocation policy is independent from sequence semantics. Policies MAY include exact, fixed, inline, geometric, reserved, segmented, pooled, arena, rope, or externally managed storage.

`reserve(n)` changes physical capacity expectations; it MUST NOT change logical sequence length. `resize(n)` changes logical length according to the sequence's element/default-value rules.

## 8. Encoding

Encoding and text semantics MUST remain explicit. A Unicode encoding such as UTF-8 is a representation of Unicode text, not the semantic definition of a character.

## 9. Grapheme Semantics

Where user-perceived characters are required, the runtime SHOULD operate over grapheme clusters rather than code units or bytes.

## 10. Simulation Requirements

High-frequency mutable sequences SHOULD exploit:

- in-place updates;
- capacity reuse;
- object pooling;
- segmented growth where relocation is expensive;
- allocation amortisation;
- locality-aware storage;
- adaptive representation selection.

## 11. Invariants

- **SEQ-001:** Sequence semantics are independent of storage representation.
- **SEQ-002:** Logical length is distinct from physical capacity.
- **SEQ-003:** NUL termination is never implicitly required by sequence semantics.
- **SEQ-004:** Element domain MUST be explicit.
- **SEQ-005:** Encoding MUST NOT be confused with semantic text.
- **SEQ-006:** Representation transitions MUST preserve value semantics.
- **SEQ-007:** Mutation policy MUST be explicit or derivable from ownership/state.
- **SEQ-008:** Embedded zero values are valid unless excluded by the semantic domain.
- **SEQ-009:** Reserve operations MUST NOT alter logical length.
- **SEQ-010:** Runtime optimisation MUST NOT change semantic identity.

## 12. Governing Principle

**Semantics determine what a value is. Execution policy determines how efficiently that value is embodied.**
