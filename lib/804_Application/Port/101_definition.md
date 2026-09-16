# Port (`SCR-APP-PORT`)

**Path:** `lib/804_Application/Port/101_definition.md`  
**Parent Domain:** [`lib/804_Application/101_definition.md`](../101_definition.md)  
**Version:** `0.1.0`  
**Status:** Normative Draft  
**Authority:** SCR Architectural Group  

---

## 1. Definition

A **Port** is an explicit semantic boundary interface in the hexagonal architecture model:
- **Inbound Port**: Defines how external actors invoke application capabilities.
- **Outbound Port**: Defines how the application communicates with external providers, filesystems, networks, or hardware.

```text
Port
├── Direction (Inbound, Outbound)
├── Protocol Contract
├── Message / Data Types
└── Boundary Constraints
```

## 2. Invariants

- **`APP-PRT-001` (Boundary Explicitness)**: All dependencies crossing the application boundary must pass through declared Ports.
- **`APP-PRT-002` (Technology Neutrality)**: Ports define semantic message and data types without referencing socket formats, IPC mechanisms, or external libraries.
