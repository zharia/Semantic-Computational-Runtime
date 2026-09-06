# Numeric Semantics

**Status:** Normative
**Scope:** Semantic Computational Runtime — value model, numeric semantics, type normalisation

## 1. Purpose

SCR treats numeric representation as an execution concern constrained by semantic meaning. A numeric value is not defined by its machine storage type alone.

The runtime MUST distinguish:

1. semantic numeric domain;
2. value and unit/scale semantics;
3. precision and admissible error;
4. representation format;
5. execution policy.

## 2. Numeric Domains

SCR SHOULD model numeric values through semantic domains such as:

- integer;
- unsigned integer;
- rational;
- fixed-point;
- real/approximate real;
- decimal;
- complex;
- interval/bounded value;
- probability/distribution;
- vector/tensor-valued numeric structures.

Machine types such as `i32`, `i64`, `f32`, and `f64` are representations, not semantic identities.

## 3. Normalisation

Equivalent values SHOULD be normalised to a canonical semantic form before crossing architectural boundaries. Normalisation includes domain, unit, scale, sign convention, precision metadata, and special-value policy.

The runtime MUST NOT silently change semantic meaning merely to obtain a cheaper representation.

## 4. Quantisation

Quantisation is the deliberate reduction of representation precision or dynamic range subject to an explicit error budget.

Quantisation policy SHOULD consider:

- required accuracy;
- numerical stability;
- sensitivity of downstream operations;
- spatial and temporal scale;
- storage pressure;
- bandwidth;
- accelerator availability;
- determinism requirements.

A value MAY be represented at lower precision when the resulting error remains within its semantic tolerance.

## 5. Error Semantics

Approximate numeric values MUST carry sufficient semantic information for the runtime to reason about admissible error. Exactness, tolerance, interval bounds, and quantisation state are distinct concepts.

## 6. Special Values

NaN, infinity, signed zero, overflow, underflow, saturation, and invalid-domain results MUST have explicitly defined semantics where the underlying representation supports them.

## 7. Unit Semantics

Physical quantities SHOULD be represented as a numeric magnitude plus explicit dimensional/unit semantics. Unit conversion MUST be semantic, not inferred solely from field names.

## 8. Runtime Selection

The runtime SHOULD select representations adaptively according to semantic constraints and workload. A single universal machine precision MUST NOT be assumed optimal.

## 9. Invariants

- **NUM-001:** Semantic numeric type is distinct from physical representation.
- **NUM-002:** Representation changes MUST preserve declared semantics.
- **NUM-003:** Quantisation MUST be bounded by an explicit or derivable error policy.
- **NUM-004:** Units and dimensions MUST NOT be silently discarded.
- **NUM-005:** Numeric normalisation MUST be deterministic where reproducibility is required.
- **NUM-006:** Precision MUST be treated as a semantic/execution constraint, not merely a storage-size choice.
