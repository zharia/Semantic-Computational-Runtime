# Providers

A **provider** is an implementation mechanism capable of satisfying a semantic contract.

Providers are deliberately subordinate to semantic meaning.

## Provider examples

A semantic operation might be implemented by:

- a generic CPU kernel;
- SIMD code;
- a GPU kernel;
- an accelerator;
- a numerical library;
- a geometry library;
- a physics engine;
- a renderer;
- a distributed execution system;
- an external runtime.

## Provider selection

Long-term provider selection can consider:

```text
Semantic Requirements
        ↓
Capability Analysis
        ↓
Resource Analysis
        ↓
Provider Candidates
        ↓
Compatibility / Equivalence
        ↓
Scheduling
        ↓
Specialization
        ↓
Execution
```

Potential selection criteria include:

- capabilities;
- precision;
- determinism;
- locality;
- available memory;
- parallelism;
- hardware;
- data movement;
- latency;
- throughput;
- numerical constraints;
- scheduling constraints.

## Provider independence

A provider must not redefine the semantic operation it implements.

For example, a GPU implementation and CPU implementation can differ internally while satisfying the same contract.

## API compatibility is not semantic equivalence

Two APIs can have identical shapes while implementing different semantics.

Conversely, two implementations can expose very different APIs while realizing the same semantic contract.

SCR therefore treats equivalence as a semantic property rather than a syntactic one.

## Status

The provider architecture is an established architectural direction. The complete adaptive provider-selection system is not implied to be implemented merely because provider categories exist in the repository.
