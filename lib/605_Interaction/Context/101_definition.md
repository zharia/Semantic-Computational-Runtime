# Context — Subdomain Definition

**Path:** `lib/605_Interaction/Context/101_definition.md`  
**Version:** `0.0.1`  
**Status:** Normative Definition  
**Parent Domain:** `605_Interaction`  
**Parent Specification:** `lib/605_Interaction/101_definition.md`  

---

## 1. Purpose

The `Context` subdomain defines the contextual and environmental frame within which an interaction takes place.

## 2. Core Concepts

### 2.1 Interaction Context (`INT-007`)
An **Interaction Context** defines the state against which an interaction expression is interpreted. It encompasses:
- Spatial reference frames;
- Temporal anchors;
- Active actor identities;
- Environmental variables.

### 2.2 Interaction Modes
An **InteractionMode** modifies the active interpretation of gestures. Modes include:
- `Navigation`: Motion gestures reposition camera or observer.
- `Selection`: Motion gestures select entities or subgraphs.
- `Manipulation`: Motion gestures translate, rotate, or scale targets.
- `Creation`: Gestures instantiate new semantic entities.
- `Inspection`: Gestures reveal internal properties or telemetry.

A mode changes the interpretation context without redefining the underlying gesture itself.

## 3. Invariants
- `INT-007` (Context Dependence): The meaning of a gesture depends on its declared context.
- `INT-001` (Semantic Primacy): Context is represented as explicit semantic state, not implicit UI state.
