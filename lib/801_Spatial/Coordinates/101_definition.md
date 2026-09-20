# SCR Coordinates

> Canonical coordinate semantics for SCR.

**Path:** `lib/801_Spatial/Coordinates/101_definition.md`

**Document type:** Normative semantic definition

**Status:** Formally Specified (corrected v0.0.3)

---

## Purpose

Defines what a coordinate is in SCR: a position within a reference frame, with explicit units and dimensional meaning.

## Definition

A **coordinate** is a tuple of real numbers specifying a position within a defined reference frame:

```
c = (c₁, c₂, ..., cₙ) ∈ ℝⁿ
```

where n is the dimensionality of the space.

### Properties

- Coordinates are always defined relative to a **reference frame**.
- Coordinates have **units** (meters, radians, etc.) that must be explicit.
- Coordinates are **not** identifiers. A coordinate describes where; an identity describes what.

### Coordinate vs Identity

| Concept | Question Answered | Example |
|---------|------------------|---------|
| Coordinate | Where is it? | (1.0, 2.0, 3.0) meters in world frame |
| Identity | What is it? | SID = root:domain:entity:42 |

Do not conflate coordinates with identity. A position may change; an identity does not.

---

## Preconditions

- A reference frame must be defined.
- Units must be specified.

## Postconditions

- The coordinate uniquely identifies a position within its reference frame.

## Implementation Status

Documented: true
Formally Specified: true
Formally Verified: false
Implemented: false
Tested: false
Validated: false
