# Provider (`SCR-APP-PROVIDER`)

**Path:** `lib/804_Application/Provider/101_definition.md`  
**Parent Domain:** [`lib/804_Application/101_definition.md`](../101_definition.md)  
**Version:** `0.1.0`  
**Status:** Normative Draft  
**Authority:** SCR Architectural Group  

---

## 1. Definition

A **Provider** is an external technology, library, accelerator, or runtime system that implements specialized computational capabilities required by an Adapter.

```text
Provider
├── Provider Identity
├── Declared Capabilities
├── Hardware / System Requirements
└── Lifecycle Management
```

## 2. Invariants

- **`APP-PRV-001` (Provider Subordination)**: Providers implement contracts; they do not own or define semantic authority.
- **`APP-PRV-002` (Provider Non-Leakage)**: Provider-specific error codes, pointer types, or conventions must not leak beyond the Adapter layer.
- **`APP-PRV-003` (Provider Replacement)**: A Provider may be replaced by an equivalent provider without altering application state.
