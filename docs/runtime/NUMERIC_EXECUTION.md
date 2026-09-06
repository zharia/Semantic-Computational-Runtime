# Numeric Execution

## 1. Purpose

This document defines how numeric semantics become executable representations while preserving the numeric contract in `005_NUMERIC_SEMANTICS.md`.

## 2. Execution precision

Execution precision MAY differ from storage precision. The runtime SHOULD select precision according to error budget, operation sensitivity, hardware capability, reproducibility requirements and downstream consumers.

## 3. Conversion boundaries

Conversions MUST be explicit semantic operations. Narrowing conversions require a declared policy for rounding, saturation, overflow, underflow and exceptional values.

## 4. Quantised execution

Quantised execution is permitted where the accumulated error remains within the declared contract. Providers SHOULD expose their numerical error characteristics to compilation and scheduling.

## 5. Reduction

Parallel reductions MUST declare whether order is semantically significant. Deterministic reductions require a stable reduction strategy or an equivalent mathematically constrained method.

## 6. Hardware

The runtime MAY lower semantic numeric operations to CPU SIMD, GPU, accelerator, fixed-point, vector or distributed execution. Hardware representation is a manifestation selected under semantic constraints.

## 7. Numerical auditability

For deterministic workloads the runtime SHOULD be able to report representation choices, rounding policy, provider selection and relevant precision transitions.
