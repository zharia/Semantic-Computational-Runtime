# Current State

SCR is currently **experimental and specification-first**.

The architectural model is broader than the implementation.

## Established architectural direction

The repository establishes a direction around:

- semantic primacy;
- implementation independence;
- semantic domains;
- domain IR;
- MLIR-based compilation;
- provider separation;
- semantic equivalence;
- information as a computational substrate;
- fields;
- graphs and hypergraphs;
- morphology;
- geometry and topology;
- dynamics;
- simulation;
- agents;
- perception;
- control;
- streams;
- messaging;
- rendering;
- hardware-aware execution.

## What this does not mean

The presence of a domain directory, specification, type, or architectural description does **not** by itself prove that the corresponding capability is fully implemented.

SCR deliberately distinguishes:

- architecture;
- specification;
- implementation;
- experiment;
- research.

## Evidence hierarchy

Implementation status should be established from evidence such as:

- source code;
- tests;
- executable examples;
- build results;
- integration tests;
- provider implementations;
- program increment acceptance criteria.

## Development strategy

The preferred strategy is to prove the architecture through vertical slices rather than by creating broad collections of stubs.

A meaningful vertical slice should connect:

```text
Semantic Definition
      ↓
Semantic Model
      ↓
SCR Semantic MLIR
      ↓
MLIR
      ↓
Transformation / Lowering
      ↓
Execution
      ↓
Observation
```

## Golden Path

The initial computational path is intended to demonstrate:

```text
Semantic Definition
      ↓
Semantic Model
      ↓
SCR Semantic MLIR
      ↓
MLIR
      ↓
CPU Execution
      ↓
Simulation State
      ↓
Render State
      ↓
Rendering
      ↓
Visible Result
```

## Current thesis

The most important result is not the breadth of the domain catalogue.

It is evidence that:

> **Semantic computation can be expressed independently of final implementation, compiled through MLIR, realized by a provider, executed on a concrete substrate, and observed without losing the semantic model.**

That is the architectural proposition the implementation must ultimately prove.
