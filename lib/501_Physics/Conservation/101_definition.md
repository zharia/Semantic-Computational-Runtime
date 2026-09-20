# Conservation (`SCR-PHYS-CONSERVATION`)

**Path:** `lib/501_Physics/Conservation/101_definition.md`  
**Parent Domain:** [`lib/501_Physics/101_definition.md`](../101_definition.md)  
**Version:** `0.1.0`  
**Status:** Normative Draft (corrected v0.0.3)  
**Authority:** SCR Architectural Group

---

## 1. Definition

Conservation semantics describe when and how physical quantities remain invariant under transformation or evolution.

### v0.0.3 Correction: Scope

**Conservation is model-specific, not universal.** SCR does not assert universal energy conservation for all physical systems.

A conservation law applies when:

1. The system is closed (no external work)
2. The symmetry exists (Noether's theorem)
3. The numerical method preserves the invariant (e.g., symplectic integration)

### What SCR Defines

SCR defines conservation as a **semantic property that models may declare**:

```
ConservationDeclaration = {
  quantity: ConservationQuantity,
  conditions: List[Condition],
  model: PhysicsModel,
  evidence: EvidenceLevel
}
```

A model declaring conservation must specify:
- Which quantity (energy, momentum, angular momentum, etc.)
- Under what conditions (closed system, no friction, etc.)
- Which physics model applies
- Evidence level (documented, specified, tested, validated)

### What SCR Does NOT Define

- Universal energy conservation for all systems
- Bitwise conservation across floating-point computation
- Conservation in dissipative systems (friction, drag, inelastic collisions)
- Conservation in systems with external forces (motors, gravity sources)

---

## 2. Conservation Quantities

| Quantity | Symbol | When Conserved |
|----------|--------|---------------|
| Energy | E | Closed system, no dissipation |
| Linear momentum | p | No external forces |
| Angular momentum | L | No external torques |
| Mass | m | Non-relativistic systems |
| Charge | q | Always (in classical physics) |

---

## 3. Integration and Conservation

Numerical integration methods affect conservation:

| Method | Energy | Momentum | Notes |
|--------|--------|----------|-------|
| Symplectic Euler | Bounded | Conserved | Energy oscillates around true value |
| Verlet | Bounded | Conserved | Better long-term stability |
| RK4 | Not bounded | Not bounded | Higher accuracy but no conservation guarantee |
| Implicit Euler | Dissipated | Conserved | Artificial damping |

### Bullet3 Provider

Bullet3 uses **symplectic Euler integration**, which guarantees:
- Energy is **bounded** (oscillates, doesn't diverge)
- Momentum is **conserved** (to machine precision)

This is NOT the same as exact energy conservation.

---

## 4. Invariants

- **`CON-INV-001` (Declaration Required)**: A model claiming conservation must explicitly declare it.
- **`CON-INV-002` (Conditions Required)**: Conservation declarations must specify conditions under which the invariant holds.
- **`CON-INV-003` (Integration Aware)**: Conservation claims must account for numerical integration method.

---

## Evidence Status

Documented: true
Formally Specified: true
Formally Verified: false
Implemented: false
Tested: false
Validated: false
