# 18 — The 20 Mandatory Rules

The following rules are mandatory:

1. **Semantics are authoritative.**
2. **Implementation does not define meaning.**
3. **Status does not define meaning.**
4. **The filesystem is not the semantic architecture.**
5. **Relationships must be explicit.**
6. **Providers implement contracts; they do not own them.**
7. **Representations must preserve semantics.**
8. **Use MLIR rather than unnecessarily duplicating MLIR infrastructure.**
9. **Do not invent missing foundational semantics.**
10. **Specify before implementing when semantic behavior is new.**
11. **Test contracts, not merely implementations.**
12. **Distinguish semantic, numerical and bitwise equivalence.**
13. **Validate invariants explicitly.**
14. **Prefer minimal complete vertical slices.**
15. **Do not expand task scope without justification.**
16. **Derived artifacts must remain derived.**
17. **Optimization follows correctness and measurement.**
18. **External technologies remain subordinate to SCR contracts.**
19. **When architecture is genuinely ambiguous, stop and escalate.**
20. **The code is not the architecture.**

---

## Governing Principle

SCR exists to make computational meaning portable across representations, implementations and execution substrates.

Therefore:

```
Meaning
  ↓
Contract
  ↓
Representation
  ↓
Transformation
  ↓
Implementation
  ↓
Execution
```

must remain traceable.

The agent's job is not merely to make the code work.

The agent's job is to make the implementation **faithfully realize the computational semantics of SCR**.

> **Do not let the implementation become the architecture.**
