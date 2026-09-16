# Service (`SCR-APP-SERVICE`)

**Path:** `lib/804_Application/Service/101_definition.md`  
**Parent Domain:** [`lib/804_Application/101_definition.md`](../101_definition.md)  
**Version:** `0.1.0`  
**Status:** Normative Draft  
**Authority:** SCR Architectural Group  

---

## 1. Definition

A **Service** provides cohesive semantic application behavior and business logic by coordinating operations, managing domain state invariants, and dispatching transformations.

```text
Service
├── Identity
├── Capabilities
├── Operations
├── State Scope
└── Dependencies
```

## 2. Invariants

- **`APP-SRV-001` (Service Independence)**: Services depend upon semantic contracts rather than concrete infrastructure or physical storage.
- **`APP-SRV-002` (Process Separation)**: A Service defines executable capability; an active instance running concurrently is a Process ($\text{Service} \neq \text{Process}$).
- **`APP-SRV-003` (State Isolation)**: Services mutate state only via explicit semantic Operations.
