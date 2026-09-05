# Semantic Computational Runtime — Public Documentation

## Phase I

The Semantic Computational Runtime (SCR) is an MLIR-based computational framework in which **computational meaning is treated as a first-class object of compilation**.

> **Express what computation means. Let the compiler and runtime determine how, where, and with which implementation it executes.**

This documentation explains the ideas, architecture, examples, research directions, and current status of SCR for technically sophisticated readers who are not necessarily contributors.

## Start here

1. [What Is SCR?](010_orientation/001_what-is-scr.md)
2. [Why Semantic Computation?](010_orientation/002_why-semantic-computation.md)
3. [The Computational Universe](010_orientation/003_the-computational-universe.md)
4. [Semantic Computation](020_concepts/001_semantic-computation.md)
5. [Semantic Primacy](020_concepts/002_semantic-primacy.md)
6. [Meaning and Representation](020_concepts/003_meaning-and-representation.md)
7. [Architecture Overview](030_architecture/001_architecture-overview.md)
8. [SCR and MLIR](030_architecture/004_mlir.md)
9. [SCR and Simulation Engines](080_comparisons/003_scr-and-simulation-engines.md)
10. [Current State](100_status/001-current-state.md)

## Documentation authority

Public documentation is explanatory. It does not silently replace normative semantic definitions.

```text
Semantic Definitions
        ↓
Normative Meaning

Program Increment Specifications
        ↓
Current Development Contract

Status Records
        ↓
Engineering State

Public Documentation
        ↓
Public Explanation
```

When a public document and a normative definition appear to disagree, the normative definition is authoritative.

## Status vocabulary

- **Established** — supported by current architectural or semantic evidence.
- **Implemented** — present in the current implementation.
- **Experimental** — implemented but subject to change.
- **Specified** — defined architecturally but not necessarily implemented.
- **Proposed** — intended future architecture.
- **Research** — open investigation.
- **Illustrative** — conceptual example only.

SCR deliberately uses these distinctions because the architecture is broader than the current implementation.

## Phase I scope

Phase I establishes the conceptual spine of SCR:

- semantic computation;
- semantic primacy;
- representation independence;
- information as computation;
- patterns and morphology;
- MLIR integration;
- providers;
- adaptive execution;
- the semantic and library graphs;
- representative simulation/rendering examples;
- semantic equivalence;
- semantic hypergraphs;
- current implementation status.

See `_meta/` for documentation governance and traceability.
