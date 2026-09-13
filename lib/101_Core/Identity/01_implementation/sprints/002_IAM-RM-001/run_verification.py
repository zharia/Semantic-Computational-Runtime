"""
IAM-RM-001 Verification Runner.
Executes: unit scenarios, executable invariants, exhaustive N=8 exploration,
25 adversarial scenarios, crash/recovery, snapshot safety, concurrency,
provenance, binding/manifestation, geometry experiments.
Emits machine-readable JSON evidence.
"""

from __future__ import annotations
import sys, json, os, time
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "src"))

from iam_rm_001.explorer import StateExplorer
from iam_rm_001.adversarial import run_all_adversarial
from iam_rm_001.scenarios import run_scenario_suites
from iam_rm_001.concurrency import run_concurrency_suite
from iam_rm_001.geometry import run_geometry_experiments


def main() -> int:
    out = {}
    t0 = time.time()

    print("== Exhaustive N=8 exploration ==")
    explorer = StateExplorer(n_bits=8, max_depth=3, max_states=20000)
    er = explorer.explore(seed=0)
    out["exploration"] = {
        "n": 8,
        "states_explored": er.states_explored,
        "transitions_attempted": er.transitions_attempted,
        "transitions_legal": er.transitions_legal,
        "transitions_illegal": er.transitions_illegal,
        "max_depth": er.max_depth,
        "pruned": er.pruned,
        "boundary_reason": er.boundary_reason,
        "invariant_violations": er.invariant_violations,
        "elapsed_seconds": er.elapsed_seconds,
        "seeds_used": er.seeds_used,
    }
    print(f"  states={er.states_explored} legal={er.transitions_legal} "
          f"illegal={er.transitions_illegal} violations={len(er.invariant_violations)} "
          f"boundary={er.boundary_reason} ({er.elapsed_seconds:.2f}s)")

    print("== 25 adversarial scenarios ==")
    adv = run_all_adversarial()
    out["adversarial"] = [
        {"index": r.index, "name": r.name, "passed": r.passed, "detail": r.detail,
         "invariants": r.invariants, "trace": r.trace}
        for r in adv
    ]
    adv_pass = sum(1 for r in adv if r.passed)
    print(f"  {adv_pass}/{len(adv)} passed")
    for r in adv:
        if not r.passed:
            print(f"  FAIL #{r.index} {r.name}: {r.detail}")

    print("== Scenario suites ==")
    scen = run_scenario_suites()
    out["scenarios"] = scen
    print("  crash/recovery, snapshot, generation, tx idempotence, non-reuse, provenance, binding/manifestation")

    print("== Concurrency model checking ==")
    conc = run_concurrency_suite()
    out["concurrency"] = conc
    print(f"  disjoint all_succeeded={conc['disjoint']['all_succeeded']} "
          f"shared same_sid_rejected={conc['shared']['same_sid_second_tx_rejected']}")
    print(f"  overlapping_delegation_rejected={conc['overlapping_delegation']['overlap_rejected']} "
          f"allocation_race_rejected={conc['allocation_race']['duplicate_sid_rejected']}")

    print("== Allocation geometry experiments ==")
    geo = run_geometry_experiments()
    out["geometry"] = geo
    for g in geo:
        print(f"  {g['geometry']}: util={g['capacity_utilisation']} frag={g['fragmentation']}")

    out["elapsed_seconds"] = time.time() - t0

    report_path = os.path.join(os.path.dirname(__file__), "reports", "verification_evidence.json")
    os.makedirs(os.path.dirname(report_path), exist_ok=True)
    with open(report_path, "w") as f:
        json.dump(out, f, indent=2, default=str)
    print(f"\nWrote {report_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
