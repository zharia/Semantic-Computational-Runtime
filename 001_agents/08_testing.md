# 08 — Testing Philosophy and Specification Tests

---

## Testing Philosophy

Tests should validate semantic contracts rather than merely implementation details.

The preferred hierarchy is:

```
Specification Tests
        ↓
Unit Tests
        ↓
Domain Tests
        ↓
Composition Tests
        ↓
MLIR Tests
        ↓
Lowering Tests
        ↓
Runtime Tests
        ↓
Cross-Substrate Tests
```

Where applicable, test:

```
Normal behavior
Boundary cases
Invalid inputs
Degenerate cases
Error behavior
Composition
Determinism
Invariant preservation
Serialization
MLIR verification
Canonicalization
Lowering
Runtime behavior
Provider behavior
Backend equivalence
```

A test that only demonstrates that an implementation runs is not necessarily a semantic test.

---

## Specification Tests

Prefer:

```
Semantic Contract
       ↓
Reference Behavior
       ↓
Implementation
       ↓
Conformance Test
```

Where practical, multiple providers should be capable of being tested against the same semantic expectations.

This is especially important for:

```
CPU / GPU
Provider substitution
Numerical implementations
Parallel implementations
Distributed implementations
External-library providers
```
