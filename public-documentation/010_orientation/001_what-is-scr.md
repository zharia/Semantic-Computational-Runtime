# What Is SCR?

The **Semantic Computational Runtime (SCR)** is an open computational framework built on MLIR for representing heterogeneous computational domains as formally specified, composable semantics.

Its central proposition is:

> **Applications should be expressed in terms of computational meaning rather than implementation technology.**

SCR is therefore not simply a runtime library. It is an architectural system for carrying meaning from a semantic definition through representation, analysis, transformation, lowering, provider selection, and execution.

## The computational pipeline

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
Provider / Adapter
    ↓
Runtime
    ↓
Execution Substrate
```

The important boundary is between **what a computation means** and **how that computation is realized**.

A semantic operation may ultimately execute on a CPU, GPU, accelerator, external runtime, or distributed system without changing its semantic identity.

## What SCR is not

SCR is not:

- merely an MLIR dialect collection;
- a simulation engine;
- a game engine;
- a graphics engine;
- an ML framework;
- a distributed message broker;
- a wrapper around an existing library;
- an abstraction layer whose only purpose is API convenience.

Those technologies can become providers, adapters, substrates, or components of an SCR system.

## Why MLIR?

MLIR already supplies a powerful compiler infrastructure: operations, values, types, attributes, regions, dialects, interfaces, verification, rewriting, canonicalization, conversion, analysis, serialization, and lowering.

SCR builds **semantic architecture on top of that infrastructure** rather than attempting to replace it.

## Why call it a runtime?

The runtime is responsible for realizing already-defined semantic computations. But SCR's runtime boundary is deliberately wider than a conventional function-call runtime.

It may participate in:

- provider selection;
- resource-aware execution;
- scheduling;
- specialization;
- state management;
- stream processing;
- observation;
- distributed execution;
- hardware-specific realization.

This motivates the longer-term description:

> **A Common Language Runtime for Computational Semantics.**

That phrase describes the intended architectural role, not a claim that every part of such a runtime is already implemented.

## The central test

A useful test for SCR architecture is:

> If the implementation changes, can the semantic meaning remain unchanged?

If yes, the architecture is preserving the distinction SCR is designed to make explicit.
