# Architecture Overview

SCR separates semantic meaning from the mechanisms used to realize it.

## Canonical architecture

```text
Application
    ↓
Semantic Model
    ↓
SCR Semantic MLIR
    ↓
MLIR
    ↓
Analysis / Verification / Transformation
    ↓
Lowering
    ↓
Provider
    ↓
Runtime
    ↓
Execution Substrate
```

The key architectural distinction is:

```text
Semantic Meaning
    ≠
Representation
    ≠
Transformation
    ≠
Lowering
    ≠
Provider
    ≠
Runtime
    ≠
Hardware
```

## Semantic model

The semantic model expresses the meaning of the computation.

It includes domain concepts, types, operations, relationships, constraints, state, capabilities, and contracts.

## SCR Semantic MLIR

SCR Semantic MLIR provides a computational representation suitable for analysis and transformation while retaining domain-level semantics.

It is not necessarily a single monolithic dialect.

## MLIR

MLIR provides the compiler infrastructure through which semantic representations can be transformed and lowered.

SCR is built on MLIR rather than beside it.

## Providers

Providers implement semantic contracts.

A provider may target:

- CPU;
- GPU;
- accelerator;
- numerical library;
- physics engine;
- geometry engine;
- rendering engine;
- messaging system;
- distributed runtime;
- external service.

## Runtime

The runtime coordinates realization and execution.

Long-term, it may incorporate capability discovery, resource analysis, provider selection, scheduling, specialization, telemetry, and adaptive re-analysis.

## Execution substrate

The substrate is where the computation ultimately runs.

SCR should be hardware-aware without making semantic definitions hardware-dependent.

## Architectural objective

Preserve meaning for as long as possible, then lower deliberately when implementation decisions become necessary.
