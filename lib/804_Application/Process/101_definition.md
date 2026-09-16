# Process (`SCR-APP-PROCESS`)

**Path:** `lib/804_Application/Process/101_definition.md`  
**Parent Domain:** [`lib/804_Application/101_definition.md`](../101_definition.md)  
**Version:** `0.1.0`  
**Status:** Normative Draft  
**Authority:** SCR Architectural Group  

---

## 1. Definition

A **Process** is an active, executing computational flow or long-running workflow within an Application, coordinating asynchronous operations, managing step execution, and maintaining execution context.

```text
Process
├── Identity
├── State (Pending, Running, Suspended, Completed, Failed)
├── Steps / Workflow DAG
├── Execution Context
└── Cancellation Token
```

## 2. Invariants

- **`APP-PRC-001` (Process/Service Separation)**: A Process is a dynamic execution instance; a Service is a static capability specification ($\text{Process} \neq \text{Service}$).
- **`APP-PRC-002` (Step Monotonicity)**: Completed workflow steps cannot be retroactively modified.
- **`APP-PRC-003` (Cancellation Safety)**: Cancellation cleanly rolls back uncommitted steps or reaches a consistent state.
