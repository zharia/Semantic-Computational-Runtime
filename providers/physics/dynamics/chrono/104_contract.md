# Chrono Multibody Dynamics Provider Contract

**Provider:** chrono  
**Domain:** physics  
**Subdomain:** dynamics  
**Version:** 0.1.0  
**Status:** Normative Contract  
**Governing Documents:** [`docs/architecture/103_provider_contracts.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/docs/architecture/103_provider_contracts.md)

---

## 1. Contract Overview

This document specifies the concrete Provider Contract implemented by the `chrono` provider for the `physics/dynamics` capability domain. It defines rigid body simulation, mass-inertia tensor properties, external force accumulation, and time integration for mechanical systems and physical dynamics.

---

## 2. Semantic Capabilities

* `[physics, multibody, system_lifecycle]` — Creation, configuration, and destruction of physical dynamic systems.
* `[physics, body, rigid_body_create]` — Registration of rigid bodies with mass and inertia tensors.
* `[physics, dynamics, apply_force]` — World-space force accumulation.
* `[physics, dynamics, step_forward]` — Symplectic time integration step ($dt > 0$).

---

## 3. Operations & Signatures

* `chrono_system_create() -> ChronoSystemHandle`
* `chrono_system_destroy(sys) -> void`
* `chrono_system_set_gravity(sys, gx, gy, gz) -> int`
* `chrono_body_create(sys, mass, ixx, iyy, izz, pos, out_body_id) -> int`
* `chrono_body_set_velocity(sys, body_id, vel) -> int`
* `chrono_body_apply_force(sys, body_id, force) -> int`
* `chrono_body_get_position(sys, body_id, out_pos) -> int`
* `chrono_body_get_velocity(sys, body_id, out_vel) -> int`
* `chrono_system_step(sys, dt) -> int`

---

## 4. Preconditions & Postconditions

1. **Precondition (Positive Mass):** Any created body must possess mass $m > 0$. Violations return `CHRONO_ERR_INVALID_PARAMETER`.
2. **Precondition (Positive Timestep):** System step requires $dt > 0$. Violations return `CHRONO_ERR_INVALID_PARAMETER`.
3. **Postcondition (Newtonian Conservation):** Net momentum changes match applied impulse $\int F \, dt$ within integration numerical tolerance.

---

## 5. Failure Semantics & Error Codes

* `CHRONO_SUCCESS = 0`
* `CHRONO_ERR_NULL_HANDLE = -1`
* `CHRONO_ERR_INVALID_PARAMETER = -2`
* `CHRONO_ERR_BODY_NOT_FOUND = -3`
* `CHRONO_ERR_COMPUTATION_FAILED = -4`

---

## 6. Conformance Test Suite

The provider is validated against the conformance suite in `tests/test_chrono_contract.cpp`.
