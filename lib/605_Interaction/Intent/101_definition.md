# Intent — Subdomain Definition

**Path:** `lib/605_Interaction/Intent/101_definition.md`  
**Version:** `0.0.1`  
**Status:** Normative Definition  
**Parent Domain:** `605_Interaction`  
**Parent Specification:** `lib/605_Interaction/101_definition.md`  

---

## 1. Purpose

The `Intent` subdomain defines the semantic representation of an Actor's desired goal, purpose, or request before it is executed as an action.

## 2. Core Concepts

### 2.1 Intent
An **Intent** is an explicit declaration of desired outcome (e.g. `Select`, `Translate`, `Delete`, `Connect`, `Inspect`, `Execute`).

### 2.2 Intent vs Gesture vs Action (`INT-005`, `INT-006`)
SCR mandates a strict distinction:
$$\text{Gesture} \ne \text{Intent} \ne \text{Action}$$
- A **Gesture** is the motion or pattern performed (e.g. Pinch & Drag).
- An **Intent** is the expressed purpose (e.g. ScaleObject by 1.5x).
- An **Action** is the actual state transformation request executed against the computational field.

### 2.3 Confidence & Disambiguation (`INT-027`)
An Intent may carry a confidence score. If multiple alternative intents are consistent with the observed gesture, alternative hypotheses are preserved until disambiguation.

## 3. Invariants
- `INT-005` (Intent Distinction): Intent is distinct from Gesture.
- `INT-006` (Action Distinction): Intent is distinct from Action.
- `INT-027` (Confidence): Intent confidence is distinct from semantic truth.
