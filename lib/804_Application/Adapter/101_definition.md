# Adapter (`SCR-APP-ADAPTER`)

**Path:** `lib/804_Application/Adapter/101_definition.md`  
**Parent Domain:** [`lib/804_Application/101_definition.md`](../101_definition.md)  
**Version:** `0.1.0`  
**Status:** Normative Draft  
**Authority:** SCR Architectural Group  

---

## 1. Definition

An **Adapter** is a mediation component that bridges a semantic Port to a concrete technology, external library, operating system API, network protocol, or hardware driver.

```text
Adapter
├── Target Port
├── Provider / Technology Reference
├── Marshalling / Serialization Logic
└── Error Translation
```

## 2. Invariants

- **`APP-ADP-001` (Boundary Isolation)**: Adapters isolate technology-specific protocols and data representations so they do not contaminate the core application semantics.
- **`APP-ADP-002` (Substitutability)**: Replacing an Adapter must not modify the semantics of the Port it connects.
