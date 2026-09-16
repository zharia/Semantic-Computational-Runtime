# Feedback — Subdomain Definition

**Path:** `lib/605_Interaction/Feedback/101_definition.md`  
**Version:** `0.0.1`  
**Status:** Normative Definition  
**Parent Domain:** `605_Interaction`  
**Parent Specification:** `lib/605_Interaction/101_definition.md`  

---

## 1. Purpose

The `Feedback` subdomain defines the semantic representation of runtime state returned to an Actor or Observer throughout the interaction lifecycle.

## 2. Core Concepts

### 2.1 Feedback (`INT-017`)
**Feedback** communicates computational state, preview consequences, recognition certainty, and execution results back to the interacting participant.

### 2.2 Feedback Phases
Feedback occurs across all phases of interaction:
1. `Preview`: Hypothetical state manifestation while a gesture is active (e.g. shadow of a dragged object).
2. `Recognition`: Confirmation that a gesture was detected.
3. `Confirmation`: Prompt or verification before executing irreversible actions.
4. `Result`: Semantic outcome of a committed action.
5. `Cancellation`: Clear indication that an interaction was aborted with no state changes.

### 2.3 Closed Feedback Loop
Interaction is a dynamic closed loop between Actor and Semantic Field:
$$\text{Actor} \to \text{Input} \to \text{Gesture} \to \text{Intent} \to \text{Action} \to \text{Field} \to \text{Feedback} \to \text{Actor}$$

## 3. Invariants
- `INT-017` (Feedback): Feedback communicates semantic state rather than mere implementation events.
- `INT-001` (Semantic Primacy): Feedback semantics remain valid whether manifested visually, haptically, or via acoustic indicators.
