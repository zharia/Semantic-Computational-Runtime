# State (`SCR-APP-STATE`)

**Path:** `lib/804_Application/State/101_definition.md`  
**Parent Domain:** [`lib/804_Application/101_definition.md`](../101_definition.md)  
**Version:** `0.1.0`  
**Status:** Normative Draft  
**Authority:** SCR Architectural Group  

---

## 1. Definition

**State** represents the authoritative, versioned semantic data held by an Application, composed of discrete Entities, Components, and Relations, distinct from any presentation or display buffers.

```text
State
├── Entities
├── Components
├── State Transitions
├── Version Clock
└── Snapshot / Journal History
```

## 2. Invariants

- **`APP-STA-001` (State Authority)**: Presentation or rendering systems must not become authoritative owners of application state.
- **`APP-STA-002` (State Transition Calculus)**: State mutations occur solely via explicit, typed transformations.
- **`APP-STA-003` (Snapshot Safety)**: Historical state snapshots remain immutable and non-corruptible.
