# The Two Graphs

SCR has two different kinds of graph that must not be conflated.

## The library architecture graph

This describes the repository and semantic library itself:

```text
Domains
  ↕
Definitions
  ↕
Interfaces
  ↕
Implementations
  ↕
Providers
  ↕
Transforms
  ↕
Lowerings
  ↕
Tests
  ↕
Documentation
```

The repository filesystem is one representation of this graph.

## The computational semantic graph

This describes the computation being represented.

It may contain:

- entities;
- values;
- types;
- relationships;
- operations;
- state;
- events;
- constraints;
- capabilities;
- resources;
- observations;
- temporal relationships;
- causal relationships;
- spatial relationships;
- data flow;
- control flow.

## Why the distinction matters

A filesystem hierarchy might contain:

```text
lib/401_Morphology/
```

That does not mean morphology has only one relationship to the rest of SCR.

Semantically, morphology may:

- refine geometry;
- depend on topology;
- derive from patterns;
- consume fields;
- evolve through dynamics;
- produce render representations.

Therefore:

```text
Filesystem Tree ≠ Semantic Architecture
```

## The semantic library control plane

Each domain is progressively described through:

```text
<domain>/
├── 101_definition.md
├── 102_status.yaml
└── 103_library.graph.json
```

The authority model is:

> **Definition is normative. Status is descriptive. Graph is derived.**

Keeping the graphs distinct prevents repository organization from accidentally becoming semantic ontology.
