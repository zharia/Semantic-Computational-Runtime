# 09 — Provider Requirements

A provider implementing an SCR contract should document, where applicable:

```
Semantic Coverage
Supported Types
Supported Operations
Precision
Determinism
Equivalence Guarantees
Performance Characteristics
Memory Behavior
Ownership
Lifecycle
Threading
Platform Restrictions
Failure Behavior
```

Provider limitations must not silently become semantic limitations.

If a provider supports only a subset of a semantic domain, represent that explicitly.
