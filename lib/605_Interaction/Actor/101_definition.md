# Actor — Subdomain Definition

**Path:** `lib/605_Interaction/Actor/101_definition.md`  
**Version:** `0.0.1`  
**Status:** Normative Definition  
**Parent Domain:** `605_Interaction`  
**Parent Specification:** `lib/605_Interaction/101_definition.md`  

---

## 1. Purpose

The `Actor` subdomain defines the semantic entities that participate in, initiate, or experience an interaction within a computational field.

## 2. Core Concepts

### 2.1 Actor
An **Actor** is an active participant in an interaction capable of generating inputs, expressing gestures, or holding intentions. An Actor may be:
- a human;
- a software agent (`601_Agent`);
- an autonomous process or machine;
- an external system.

### 2.2 Observer
An **Observer** is a participant that receives perceptual manifestations, feedback, or consequences of an interaction without necessarily initiating actions.

### 2.3 Human-Machine Equivalence (`INT-030`)
Interaction semantics remain invariant whether initiated by human, machine, or agent modalities. The origin is preserved in provenance metadata rather than altering semantic intent.

## 3. Invariants
- `INT-001` (Semantic Primacy): Actor definitions are independent of specific authentication frameworks.
- `INT-025` (Authorization Separation): Recognizing an Actor's participation does not automatically confer authority to execute actions.
- `INT-030` (Human-Machine Equivalence): Human and autonomous actors are semantically equivalent participants.
