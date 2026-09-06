# Numeric Semantics

**Status:** Normative foundation

## 1. Purpose

Numeric values in SCR are semantic values first and machine encodings second. A numeric semantic domain MUST NOT be inferred solely from the physical width or instruction set used to represent it.

The runtime therefore separates:

```text
numeric meaning → semantic domain → numeric contract → representation → execution policy
```

## 2. Numeric semantic descriptor

A numeric value SHOULD be understood through a descriptor containing, where applicable:

- domain: integer, unsigned integer, rational, fixed-point, decimal, real/approximate-real, complex, interval, probability/distribution;
- unit and dimensionality;
- scale and offset;
- precision and accuracy requirements;
- admissible error;
- range and overflow policy;
- special-value semantics;
- rounding mode;
- determinism requirements;
- representation constraints.

## 3. Representation independence

`i32`, `i64`, `f32`, `f64`, decimal encodings, packed vectors, and accelerator-specific formats are representations. They do not, by themselves, establish semantic identity.

A provider MAY choose a representation when it can prove that the selected representation satisfies the semantic contract.

## 4. Normalisation

Normalisation establishes a canonical semantic form. It MAY include unit conversion, scale normalisation, sign canonicalisation, precision metadata canonicalisation, and explicit treatment of special values.

Normalisation MUST NOT silently change the represented quantity.

## 5. Quantisation

Quantisation is a deliberate reduction of representational precision or dynamic range. It is valid only when an explicit or inherited error budget permits it.

Quantisation is therefore a semantic transformation, not merely a storage optimisation.

## 6. Exceptional values

NaN, infinity, signed zero, overflow, underflow, saturation and invalid operations MUST have declared semantics where they are admitted. An implementation MUST NOT introduce accidental host-language semantics into a semantic contract.

## 7. Units and dimensions

Dimensionally incompatible operations MUST be rejected unless a declared transformation establishes compatibility. Unit conversion belongs to semantic normalisation, not to an implicit ABI convention.

## 8. Determinism

Where a computation is declared deterministic, reduction order, rounding, overflow behaviour and provider substitutions MUST preserve the declared result contract. Parallel execution MAY use different physical execution orders only when semantic equivalence is maintained.

## 9. Precision is contextual

Storage precision, execution precision, communication precision and observation precision MAY differ. The runtime SHOULD choose the least expensive representation that satisfies the active semantic contract.

## 10. Numeric hierarchy

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
