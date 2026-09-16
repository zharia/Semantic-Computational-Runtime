# Operation (`SCR-APP-OPERATION`)

**Path:** `lib/804_Application/Operation/101_definition.md`  
**Parent Domain:** [`lib/804_Application/101_definition.md`](../101_definition.md)  
**Version:** `0.1.0`  
**Status:** Normative Draft  
**Authority:** SCR Architectural Group  

---

## 1. Definition

An **Operation** is a discrete, typed, callable unit of application capability that receives input parameters, verifies preconditions, effects state transformations, enforces postconditions, and returns an output or error.

```text
Operation
├── Signature (Inputs, Outputs)
├── Preconditions
├── Postconditions
├── Idempotence Contract
└── Implementation Bindings
```

## 2. Invariants

- **`APP-OPR-001` (Executable Substitution)**: An Operation may have multiple valid executable implementations without changing semantic meaning.
- **`APP-OPR-002` (Contract Preservation)**: Any implementation binding must satisfy the declared pre- and post-conditions of the Operation.
- **`APP-OPR-003` (Atomicity)**: Operations either successfully complete state transitions or revert cleanly.
