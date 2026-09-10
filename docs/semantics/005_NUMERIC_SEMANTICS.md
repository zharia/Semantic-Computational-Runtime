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

Machine types such as `i32`, `i64`, `f32`, `f64` are representations, not semantic identities.

## 3. Numeric Descriptor

A numeric value SHOULD be understood through a descriptor containing, where applicable:

- domain (per §2);
- unit and dimensionality;
- scale and offset;
- precision and accuracy requirements;
- admissible error;
- range and overflow policy;
- special-value semantics;
- rounding mode;
- determinism requirements;
- representation constraints.

## 4. Normalisation

Equivalent values SHOULD be normalised to a canonical semantic form before crossing architectural boundaries. Normalisation includes domain, unit, scale, sign convention, precision metadata, and special-value policy.

The runtime MUST NOT silently change semantic meaning merely to obtain a cheaper representation.

## 5. Quantisation

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

## 6. Error Semantics

Approximate numeric values MUST carry sufficient semantic information for the runtime to reason about admissible error. Exactness, tolerance, interval bounds, and quantisation state are distinct concepts.

## 7. Special Values

NaN, infinity, signed zero, overflow, underflow, saturation, and invalid-domain results MUST have explicitly defined semantics where the underlying representation supports them.

## 8. Unit Semantics

Physical quantities SHOULD be represented as a numeric magnitude plus explicit dimensional/unit semantics. Unit conversion MUST be semantic, not inferred solely from field names.

## 9. Runtime Selection

The runtime SHOULD select representations adaptively according to semantic constraints and workload. A single universal machine precision MUST NOT be assumed optimal.

## 10. Numeric Hierarchy

```text
Quantity
 └── Numeric Value
      ├── Scalar
      │    ├── Integer
      │    ├── Rational
      │    ├── Fixed/Decimal
      │    └── Approximate Real
      ├── Complex
      ├── Interval/Bounded
      └── Distribution
```

Structured numeric values such as vectors, matrices and tensors are compositions of numeric values plus shape, indexing and algebraic semantics; they are not merely large scalars.

## 11. Invariants

- **NUM-001:** Semantic numeric type is distinct from physical representation.
- **NUM-002:** Representation changes MUST preserve declared semantics.
- **NUM-003:** Quantisation MUST be bounded by an explicit or derivable error policy.
- **NUM-004:** Units and dimensions MUST NOT be silently discarded.
- **NUM-005:** Numeric normalisation MUST be deterministic where reproducibility is required.
- **NUM-006:** Precision MUST be treated as a semantic/execution constraint, not merely a storage-size choice.
