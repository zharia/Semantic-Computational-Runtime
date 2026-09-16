# Policy (`SCR-APP-POLICY`)

**Path:** `lib/804_Application/Policy/101_definition.md`  
**Parent Domain:** [`lib/804_Application/101_definition.md`](../101_definition.md)  
**Version:** `0.1.0`  
**Status:** Normative Draft  
**Authority:** SCR Architectural Group  

---

## 1. Definition

A **Policy** specifies declarative constraints, access control rules, validation criteria, rate limits, or behavioral guarantees enforced across Modules, Services, and Operations.

```text
Policy
├── Policy Type (Authorization, Validation, RateLimit, Integrity)
├── Predicates / Rules
├── Enforcement Level (Mandatory, Advisory)
└── Failure Action (Reject, Audit, Fallback)
```

## 2. Invariants

- **`APP-POL-001` (Authorization Separation)**: Visibility, availability, capability, and authorization remain distinct concerns (`A15`).
- **`APP-POL-002` (Mandatory Enforcement)**: Invocations violating mandatory policies are strictly rejected before state mutation.
