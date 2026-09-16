# Mapping — Subdomain Definition

**Path:** `lib/605_Interaction/Mapping/101_definition.md`  
**Version:** `0.0.1`  
**Status:** Normative Definition  
**Parent Domain:** `605_Interaction`  
**Parent Specification:** `lib/605_Interaction/101_definition.md`  

---

## 1. Purpose

The `Mapping` subdomain defines the resolution rules that transform recognized gesture expressions and intents into concrete actions or commands.

## 2. Core Concepts

### 2.1 Interaction Mapping
An **Interaction Mapping** is a semantic contract that binds an Interaction Expression (or Intent) to a specific Action within a declared Context.

### 2.2 Action & Command (`INT-006`)
An **Action** is an operation that transforms or requests transformation of a semantic field. A **Command** is an executable reification of an Action.

### 2.3 Reversibility
Mappings must declare the reversibility semantics of resulting actions:
- `Reversible`: Can be undone via explicit inverse transformation.
- `Irreversible`: Cannot be undone (e.g. permanent deletion).
- `Transactional`: Atomic execution with rollback support.

## 3. Invariants
- `INT-006` (Action Distinction): Mapping resolves an Intent into an Action; Intent is not the Action.
- `INT-019` (Provider Independence): Mappings are defined semantically and independent of specific provider APIs.
