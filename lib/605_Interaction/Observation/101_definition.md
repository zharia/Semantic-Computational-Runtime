# Observation — Subdomain Definition

**Path:** `lib/605_Interaction/Observation/101_definition.md`  
**Version:** `0.0.1`  
**Status:** Normative Definition  
**Parent Domain:** `605_Interaction`  
**Parent Specification:** `lib/605_Interaction/101_definition.md`  

---

## 1. Purpose

The `Observation` subdomain defines the semantic representation of interaction stimuli observed by the system.

## 2. Core Concepts

### 2.1 Interaction Observation
An **Interaction Observation** is information captured from an Actor or Input channel that is available for gesture recognition and intent interpretation.

### 2.2 Boundary Semantics
Observation represents the arrival boundary of external stimuli into the computational runtime. It preserves:
- Timestamp (capture time);
- Source channel / device;
- Modality characteristics;
- Spatial and temporal parameters.

## 3. Invariants
- `INT-003` (Gesture Distinction): An observation of an input is not itself a gesture ($\text{Observation} \ne \text{Gesture}$).
- `INT-026` (Provenance): Observations retain source and temporal provenance.
