# SCR Semantic Library — 202 Math / Interpolation

**Document:** `lib/202_Math/Interpolation/101_definition.md`  
**Version:** `0.1.0`  
**Status:** Normative semantic definition  
**Domain:** Math / Interpolation  
**Parent:** `lib/202_Math/101_definition.md`  
**Authority:** Semantic Computational Runtime (SCR)  

---

## 1. Definition

The **Interpolation Domain** defines the construction of new data points within the range of a discrete set of known data points using polynomial, spline, or radial basis functions.

---

## 2. Fundamental Distinction

> **Interpolation is not linear blending in a shader; it is an exact passage through given coordinate-value pairs $f(x_i) = y_i$.**

Mathematical semantics remain authoritative; physical arrays, hardware registers, GPU buffers, and numerical libraries remain subordinate.

---

## 3. Subdomain Invariants

* **ITP-INV-001 (Exact Fitting):** An interpolant $P$ MUST satisfy $P(x_i) = y_i$ for all interpolation nodes.
* **ITP-INV-002 (Continuity Class):** Splines and higher-order interpolants MUST declare and preserve their continuity order ($C^0, C^1, C^2$).
* **ITP-INV-003 (Domain Convex Hull):** Interpolation MUST distinguish interpolation inside the convex hull from extrapolation outside.
