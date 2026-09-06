# Sequence and Text Semantics

**Status:** Normative foundation

## 1. Sequence as a primitive semantic structure

SCR treats ordered collections as instances of a general `Sequence<T>` semantic structure. Strings are not a privileged machine primitive.

```text
Sequence<T>
  semantic element type
  logical length
  representation
  allocation policy
  mutation policy
  storage
```

## 2. String semantics

A textual value is a sequence of defined textual values. Depending on the contract, the element domain may be:

- bytes;
- encoding units;
- Unicode scalar values;
- grapheme clusters;
- tokens;
- domain-specific symbols.

These layers MUST NOT be conflated.

NUL termination is an interoperability convention and MUST NOT be part of the semantic definition of a string.

## 3. Binary and text

Binary data and text data MUST be distinguishable at the semantic boundary. An encoding transformation establishes a relationship between them; arbitrary byte interpretation MUST NOT be assumed to be text.

## 4. Mutation

Sequence semantics permit immutable, mutable, transactional, copy-on-write, uniquely-owned, append-only and streaming mutation models. Mutation policy is separate from semantic identity.

## 5. Representation

Permitted physical manifestations include contiguous arrays, segmented buffers, ropes, inline storage, external storage, memory-mapped regions and streaming sequences. Logical length is independent of capacity.

## 6. Views

A sequence view MAY reference another sequence without copying. A view MUST carry sufficient lifetime/ownership semantics to prevent invalid access.

## 7. Indexing

Indexing semantics MUST specify whether indexes address elements, code units, bytes, graphemes or another declared unit. An implementation MUST NOT substitute one indexing domain for another.

## 8. Allocation

High-frequency mutation is a first-class runtime concern. Growth strategy, allocation domain, capacity and relocation are physical policies and MUST NOT alter semantic content.

## 9. Interoperability

When interfacing with C-style APIs, NUL-terminated buffers MAY be materialised as an interoperability representation. The terminator MUST NOT become part of the SCR string value unless explicitly declared.
