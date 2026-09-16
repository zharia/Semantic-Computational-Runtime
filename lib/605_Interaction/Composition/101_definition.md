# Composition — Subdomain Definition

**Path:** `lib/605_Interaction/Composition/101_definition.md`  
**Version:** `0.0.1`  
**Status:** Normative Definition  
**Parent Domain:** `605_Interaction`  
**Parent Specification:** `lib/605_Interaction/101_definition.md`  

---

## 1. Purpose

The `Composition` subdomain defines the algebraic composition of gestures and inputs into complex interaction expressions.

## 2. Core Concepts

### 2.1 Gesture Sequence (`INT-008`)
A **Gesture Sequence** is an ordered temporal progression of gestures:
$$\text{Sequence}(G_1, G_2, \dots, G_n)$$
where $G_i$ precedes $G_{i+1}$ in time.

### 2.2 Gesture Chord (`INT-009`)
A **Gesture Chord** is a concurrent combination of gestures occurring simultaneously:
$$\text{Chord}(G_1, G_2, \dots, G_n)$$
where all constituent gestures must overlap in active temporal execution.

### 2.3 Sequence/Chord Non-Equivalence (`INT-010`)
A fundamental invariant of SCR Interaction:
$$\text{Sequence}(G_A, G_B) \ne \text{Chord}(G_A, G_B)$$
Temporal precedence and concurrent overlap convey fundamentally distinct semantic meanings.

### 2.4 Multimodal Chord (`INT-029`)
A Chord combining distinct modalities (e.g. Gaze + Hand Pinch + Voice Command).

### 2.5 Composition Operators (`INT-011`)
Interaction expressions support regular algebraic operators:
- **Sequence** ($\cdot$): $A \cdot B$
- **Chord** ($\&$): $A \& B$
- **Alternative** ($|$): $A \mid B$ (either $A$ or $B$)
- **Optional** ($?$): $A?$ ($A$ or empty)
- **Repetition** ($*$ or $+$): $A*$ (zero or more repetitions).

## 3. Invariants
- `INT-008` (Sequence Semantics): Temporal order is strictly preserved.
- `INT-009` (Chord Semantics): Concurrency is strictly preserved.
- `INT-010` (Non-Equivalence): Sequences and chords are never semantically interchangeable.
- `INT-011` (Composition): Composed expressions preserve constituent identities.
