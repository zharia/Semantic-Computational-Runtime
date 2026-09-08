# 12 — Dependencies, Performance, Concurrency, Errors, Serialization, Security

---

## Dependency Discipline

Before adding a dependency:

1. Determine whether the functionality already exists.
2. Determine whether MLIR or an existing SCR component provides the required capability.
3. Determine whether the dependency belongs at the semantic, compiler, provider, runtime, or tooling layer.
4. Determine whether it introduces semantic coupling.
5. Determine its platform and licensing implications.
6. Determine whether the dependency is required for the current milestone.

A dependency must not become part of semantic meaning merely because it provides a convenient implementation.

---

## Performance

Correctness precedes optimization.

Use:

```
Correctness
    ↓
Semantic Validation
    ↓
Measurement
    ↓
Optimization
    ↓
Equivalence Validation
```

Do not optimize based on assumptions.

Do not introduce representation-specific optimizations that alter semantic behavior without an explicit contract permitting the change.

Performance characteristics may themselves be part of a provider contract where required.

---

## Concurrency and Parallelism

Concurrency must be explicit.

Consider:

```
Ordering
Synchronization
Ownership
Mutability
Race behavior
Determinism
Memory visibility
Atomicity
Failure propagation
Cancellation
```

Do not assume that a sequential semantic definition automatically permits arbitrary parallelization.

A transformation must establish that required semantic guarantees remain valid.

---

## Error Semantics

Errors are part of computational semantics where they affect observable behavior.

Distinguish:

```
Invalid Input
Contract Violation
Unsupported Capability
Provider Limitation
Resource Exhaustion
Execution Failure
Numerical Failure
Environmental Failure
```

Do not convert semantic errors into arbitrary implementation exceptions without preserving their meaning.

---

## Serialization, Persistence and References

Do not confuse:

```
Semantic Identity
Representation Identity
Content Identity
Storage Location
```

A semantic reference must remain meaningful independently of where its representation happens to be stored.

Persistence mechanisms must not silently redefine semantic identity.

---

## Security and Isolation

When modifying runtime, provider, messaging, storage, or external-library integration, consider:

```
Trust Boundary
Capability Boundary
Resource Limits
Input Validation
Isolation
Credential Handling
Data Exposure
Provider Permissions
Failure Containment
```

Do not introduce hidden execution or network behavior merely for convenience.
