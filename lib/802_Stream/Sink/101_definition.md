# SCR Semantic Library — 802 Stream / Sink

**Document:** `lib/802_Stream/Sink/101_definition.md`  
**Version:** `0.1.0`  
**Status:** Normative semantic definition  
**Domain:** Stream / Sink  
**Parent:** `lib/802_Stream/101_definition.md`  
**Authority:** Semantic Computational Runtime (SCR)  

---

## 1. Definition

A **Stream Sink** is a semantic egress boundary through which elements of a Stream are consumed, persisted, or delivered to external consumers or adjacent computational domains.

A Sink specifies:
* Delivery expectations (at-least-once, at-most-once, effectively-once semantic effect).
* Side-effect commitments and idempotency requirements.
* Terminal consumption or egress transformation.

---

## 2. Fundamental Distinction

> **A Sink is not a database writer, network socket, disk file, message publisher, or graphical display.**

These are physical realizations. The semantic Sink defines the delivery contract, side-effect boundaries, and consumption guarantees.

---

## 3. Subdomain Invariants

* **SNK-INV-001 (Delivery Distinction):** Receipt by a transport mechanism MUST NOT be equated with semantic consumption or commitment by the Sink.
* **SNK-INV-002 (Side-Effect Fencing):** Replayed elements MUST NOT induce duplicate side effects unless the Sink contract explicitly permits non-idempotent replay.
* **SNK-INV-003 (Termination Decoupling):** Egress throttling or backpressure at a Sink MUST NOT silently corrupt upstream stream ordering.
