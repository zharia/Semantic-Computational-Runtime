# SCR Semantic Library — 902 Interfaces / Controllable

**Document:** `lib/902_Interfaces/Controllable/101_definition.md`  
**Version:** `0.1.0`  
**Status:** Normative semantic definition  
**Domain:** Interfaces / Controllable  
**Parent:** `lib/902_Interfaces/101_definition.md`  
**Authority:** Semantic Computational Runtime (SCR)  

---

## 1. Definition

The **Controllable Interface** defines the semantic boundary through which an external controller or agent can observe and drive system state toward target objectives via defined control inputs.

---

## 2. Fundamental Distinction

> **Controllability is not an RPC endpoint or GUI slider; it is the formal mathematical reachability of system state trajectories under bounded control signals.**

The semantic contract remains authoritative; hardware acceleration, compiler vectorizers, threads, and realization frameworks remain subordinate.

---

## 3. Subdomain Invariants

* **CTL-INV-001 (Actuation Bounds):** Control inputs MUST declare valid dynamic ranges and actuation limits.
* **CTL-INV-002 (Reachability Contract):** A controllable interface MUST specify whether the target state space is fully or partially reachable.
* **CTL-INV-003 (Latency Transparency):** The delay between control input application and actuation effect MUST be bounded and declared.
