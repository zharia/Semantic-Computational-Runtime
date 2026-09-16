# Target — Subdomain Definition

**Path:** `lib/605_Interaction/Target/101_definition.md`  
**Version:** `0.0.1`  
**Status:** Normative Definition  
**Parent Domain:** `605_Interaction`  
**Parent Specification:** `lib/605_Interaction/101_definition.md`  

---

## 1. Purpose

The `Target` subdomain defines the semantic entities, fields, regions, or coordinates toward which an interaction is directed.

## 2. Core Concepts

### 2.1 Target
A **Target** represents the recipient of an interaction intent. Targets may be:
- An explicit SCR Semantic Entity (URI);
- A hypergraph element or relation;
- A spatial coordinate, bounding volume, or geometric region;
- A semantic field or region within a field;
- The computational environment itself (global target).

### 2.2 Reference Integrity (`INT-022`)
An interaction may target an entity by semantic reference. Deletion of the target entity does not alter the historical semantic fact of the interaction.

## 3. Invariants
- `INT-022` (Reference Integrity): References to targets adhere to SCR reference and identity semantics.
- `INT-023` (Deletion Integrity): Deleting a target does not silently invalidate or reverse committed interactions.
