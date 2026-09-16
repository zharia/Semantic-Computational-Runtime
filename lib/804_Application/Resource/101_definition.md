# Resource (`SCR-APP-RESOURCE`)

**Path:** `lib/804_Application/Resource/101_definition.md`  
**Parent Domain:** [`lib/804_Application/101_definition.md`](../101_definition.md)  
**Version:** `0.1.0`  
**Status:** Normative Draft  
**Authority:** SCR Architectural Group  

---

## 1. Definition

A **Resource** represents an allocation of computational, storage, memory, GPU, network, or external handle capacity utilized by an Application.

```text
Resource
├── Resource Type
├── Allocation Quota
├── Current Utilization
├── Provider Handle
└── Ownership & Cleanup Lifecycle
```

## 2. Invariants

- **`APP-RES-001` (Resource Bounds)**: Applications must operate within declared resource quotas.
- **`APP-RES-002` (Cleanup Guarantee)**: Releasing an Application or Service cleanly frees all associated physical and logical resources.
