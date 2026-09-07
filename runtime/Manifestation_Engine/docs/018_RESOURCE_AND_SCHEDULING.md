# Manifestation Engine — Resource and Scheduling Model

## 1. Resource principle

Physical resources are execution constraints and optimization inputs. They are not semantic identities unless explicitly promoted into the semantic model.

## 2. Resource classes

The Engine may manage:

- CPU;
- GPU/accelerator;
- memory;
- storage;
- bandwidth;
- concurrency slots;
- device handles;
- power/thermal budgets;
- provider quotas.

## 3. Admission

Before execution, the Engine SHOULD determine whether the required resources can be allocated under policy.

Admission failure is not semantic invalidity.

## 4. Scheduling

Scheduling may consider:

- dependency readiness;
- priority;
- deadlines;
- locality;
- data movement;
- provider capabilities;
- resource availability;
- fairness;
- energy/cost.

## 5. Fairness

Where multiple semantic principals share resources, scheduling policy SHOULD prevent starvation and respect configured quotas.

## 6. Resource accounting

Allocations SHOULD be attributable to execution identity and manifestation identity.

## 7. Backpressure

The Engine SHOULD propagate or manage backpressure before resource exhaustion. Semantic stream contracts determine whether dropping, delaying or buffering data is permissible.

## 8. Preemption

Preemption MUST preserve semantic state or expose the loss/partial execution explicitly.

## 9. Locality

Data locality and execution locality may strongly influence provider selection. They remain realization properties unless semantically constrained.
