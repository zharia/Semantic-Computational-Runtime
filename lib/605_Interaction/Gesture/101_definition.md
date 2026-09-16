# Gesture — Subdomain Definition

**Path:** `lib/605_Interaction/Gesture/101_definition.md`  
**Version:** `0.0.1`  
**Status:** Normative Definition  
**Parent Domain:** `605_Interaction`  
**Parent Specification:** `lib/605_Interaction/101_definition.md`  

---

## 1. Purpose

The `Gesture` subdomain defines the semantic interpretation of interaction trajectories, postures, or temporal sequences of observations.

## 2. Core Concepts

### 2.1 Gesture
A **Gesture** is a meaningful motion, posture, acoustic utterance, or discrete pattern performed by an Actor. Examples include:
- Point, Tap, DoubleTap, PressAndHold;
- Drag, Swipe, Flick;
- Pinch, Spread, Rotate;
- Spatial Wave, Grab, Release;
- Voice Command, Semantic Trigger.

### 2.2 Gesture Candidate & Recognition (`INT-004`)
Before certainty is established, an interaction trajectory exists as a **Gesture Candidate**. Recognition evaluates candidates against models or criteria, producing recognized gestures with explicit confidence measures.

### 2.3 Gesture Phase
Gestures evolve through well-defined phases:
1. `Rest`: Baseline state before motion.
2. `Preparation`: Initial movement establishing trajectory.
3. `Stroke`: The core intentional movement carrying semantic meaning.
4. `Hold`: Sustained posture or state.
5. `Retraction`: Movement returning to rest.

### 2.4 Gesture Path & Constraints
A Gesture may follow a continuous spatial trajectory (`GesturePath`) bounded by geometric, topological, or temporal constraints (`GestureConstraint`).

## 3. Invariants
- `INT-003` (Gesture Distinction): Gesture is distinct from the raw inputs that compose it.
- `INT-004` (Recognition Distinction): Recognition of a gesture is distinct from the gesture itself.
- `INT-005` (Intent Distinction): A Gesture expresses an Intent, but is not the Intent ($\text{Gesture} \ne \text{Intent}$).
