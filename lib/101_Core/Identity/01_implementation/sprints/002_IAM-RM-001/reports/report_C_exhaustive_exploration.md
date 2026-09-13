# Report C — Exhaustive Exploration Report

**Milestone:** IAM-RM-001  
**Explorer:** `StateExplorer(n_bits=8, max_depth=3, max_states=20000)`

## Parameters

```text
N                = 8
coordinate space = [0, 256)
event alphabet   = 8 sample SIDs + rotate_authority + bind_sid + manifest_sid
                   + retire_sid + 2 domain-reserve events (one legal, one overlapping)
max trace depth  = 3
max states       = 20000
seed             = 0 (deterministic)
```

## Results

| Metric | Value |
|---|---|
| States explored | 155 |
| Transitions attempted | 504 |
| Transitions legal | 170 |
| Transitions illegal (rejected) | 334 |
| Maximum trace depth reached | 3 |
| States pruned (symmetry/visited) | reported in JSON |
| Invariant violations | 0 |
| Execution time | 0.14 s |
| Boundary reason | **complete** |
| Unexplored state classes | none within declared bound |

## What "exhaustive" means here — and what it does not

**Precisely stated:** The exploration is *complete over the declared finite event alphabet and trace depth ≤ 3, starting from the canonical root configuration, with visited-state pruning*. Within that bound, every reachable state was visited and all 16 invariants were checked at each state.

**It is NOT:**
- a proof over unbounded traces;
- exhaustive over all possible SID coordinates and all configurations;
- exhaustive over arbitrary delegation trees.

The state space grows with the number of domain/SID/authority choices; complete exploration beyond depth 3 and over the full 256 coordinate space was not performed because the event/state space explodes. This distinction is reported deliberately per spec §7.

## Invariant results

At every explored state (155/155), `check_all_invariants` returned **no violations**. The atomicity property was also checked across all 334 rejected transitions: no rejected transition mutated state (`Σ' = Σ`).

## Reproduction

```bash
cd lib/101_Core/Identity/01_implementation/sprints/002_IAM-RM-001
uv run --project <repo-root> python run_verification.py
```

Evidence: `reports/verification_evidence.json` → key `exploration`.

---
*Report C per IAM-RM-001 §20. "Exhaustive" is bound-scoped, not unbounded.*