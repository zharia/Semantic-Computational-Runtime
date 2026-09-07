# Manifestation Engine — Compute Manifestation

## 1. Principle

A semantic operation expresses what computation means. Compute manifestation determines how and where it is executed.

## 2. Compute classes

Potential realizations include:

- scalar CPU execution;
- vector CPU execution;
- GPU kernels;
- accelerators;
- numerical libraries;
- distributed kernels;
- remote providers;
- generated code;
- interpreter/reference execution.

## 3. Compilation

Compilation may occur before execution, on demand, incrementally or adaptively.

Compilation is a realization mechanism and MUST preserve the semantic contract.

## 4. Specialization

Specialization may use context such as known values, shapes, hardware, precision, locality or provider capabilities.

Specialization MUST NOT remove semantic behavior required by the contract.

## 5. Representation selection

A semantic structure may be represented as dense, sparse, tiled, vectorized, compressed, procedural or other forms.

Representation selection is a realization decision.

## 6. Scheduling

The Engine may schedule work according to dependencies, resource availability, locality, priority and semantic constraints.

## 7. Fusion and reordering

Transformations such as fusion, tiling, vectorization and reordering are valid only when semantic equivalence is preserved.

## 8. Precision

Precision is a semantic constraint when observable correctness depends on it. It is an optimization resource only when the contract permits variation.

## 9. Remote compute

Remote execution is a provider realization. Network transport, host identity and remote process details MUST NOT leak into semantic graph dependencies.
