# Controller (`SCR-APP-CONTROLLER`)

**Path:** `lib/804_Application/Controller/101_definition.md`  
**Parent Domain:** [`lib/804_Application/101_definition.md`](../101_definition.md)  
**Version:** `0.1.0`  
**Status:** Normative Draft  
**Authority:** SCR Architectural Group  

---

## 1. Definition

A **Controller** acts as an inbound interaction mediator that accepts Observations, Events, or Commands from external actors, translates them into semantic application Operations, and invokes the appropriate Services.

```text
Controller
├── Inbound Triggers (Events, Commands)
├── Validation & Sanitization
├── Translation Logic
└── Operation Dispatch
```

## 2. Invariants

- **`APP-CTL-001` (Controller Boundary)**: Controllers translate inbound interactions into semantic application operations; they do not implement core domain state logic.
- **`APP-CTL-002` (Presentation Decoupling)**: Controllers are decoupled from concrete presentation frameworks (e.g. Wayland, Qt, DOM).
- **`APP-CTL-003` (Command Validation)**: Inbound commands must be validated against controller schemas before execution.
