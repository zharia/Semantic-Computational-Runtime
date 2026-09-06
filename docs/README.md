# Semantic Computational Runtime — Documentation Foundation v2

This directory extends the four foundational SCR documents with the normative semantic and runtime specifications required to build the system outward from the Semantic Field.

## Authority order

1. `101_BACKGROUND.md` — motivation and design rationale
2. `102_ARCHITECTURE.md` — system architecture
3. `103_SEMANTIC_MODEL.md` — semantic ontology and field model
4. `104_SEMANTIC_INVARIANTS.md` — non-negotiable invariants
5. Domain/runtime specifications in this tree
6. Technical references and implementation notes

A lower document may refine an upper document but MUST NOT silently redefine its semantics.

## Documentation principle

> **Engineer outward from the Semantic Field.**

Every specification below therefore answers, in order:

1. What semantic structure exists?
2. How does it participate in the field?
3. What transformations are valid?
4. What representations are permitted?
5. How may those semantics be executed physically?

## Tree

```text
docs/
├── 101_BACKGROUND.md
├── 102_ARCHITECTURE.md
├── 103_SEMANTIC_MODEL.md
├── 104_SEMANTIC_INVARIANTS.md
├── 005_NUMERIC_SEMANTICS.md
├── 006_SEQUENCE_AND_TEXT_SEMANTICS.md
├── architecture/
│   └── 001_SPEC_DEPENDENCY_GRAPH.md
├── semantics/
│   ├── 001_SEMANTIC_TYPES.md
│   ├── 002_RELATIONSHIPS_AND_TOPOLOGY.md
│   └── 003_TRANSFORMATION_AND_REFINEMENT.md
├── runtime/
│   ├── NUMERIC_EXECUTION.md
│   ├── 007_MEMORY_ALLOCATION_SUBSTRATE.md
│   ├── 002_EXECUTION_MODEL.md
│   └── 003_RESOURCE_MODEL.md
├── messaging/
│   ├── 001_MESSAGE_SEMANTICS.md
│   └── 002_AMQP_MODEL.md
├── rendering/
│   ├── 001_RENDERING_SEMANTICS.md
│   └── 002_STREAM_PROCESSING.md
├── storage/
│   └── 001_STORAGE_SEMANTICS.md
├── networking/
│   └── 001_NETWORK_SEMANTICS.md
├── interoperability/
│   └── 001_INTEROPERABILITY.md
└── reference/
    ├── 001_GLOSSARY.md
    └── 002_EXTERNAL_STANDARDS.md
```

`technical-references/` remains implementation/reference material and is intentionally not reproduced by this package.
