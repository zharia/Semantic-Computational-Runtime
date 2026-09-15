"""
Runner for IAM-001 Verification Closure Suite.
Executes all verification suites and writes:
reports/verification_closure_evidence.json
"""

import os, sys, json
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "src"))

from closure_verification import execute_complete_verification_closure

def main():
    print("=================================================================")
    print("  SCR IAM-001 Verification Closure & Falsification Suite")
    print("=================================================================\n")

    evidence = execute_complete_verification_closure()

    print(f"1. Baseline Adversarial Suite: {evidence['baseline_adversarial']['passed']}/{evidence['baseline_adversarial']['total']} PASS")
    print(f"2. IAM-I017 Adversarial Suite: {evidence['i017_adversarial']['passed']}/{evidence['i017_adversarial']['total']} PASS")
    print(f"3. 18-Stage Temporal Exploration: {evidence['temporal_exploration']['traces_executed']} traces, {evidence['temporal_exploration']['total_transitions']} transitions, {evidence['temporal_exploration']['invariant_violations']} violations")
    print(f"4. 8-Property Recovery Resilience: {'PASS' if evidence['recovery_resilience']['all_passed'] else 'FAIL'}")
    print(f"5. Generation Fencing & Non-Reuse: {'PASS' if evidence['generation_fencing']['all_passed'] else 'FAIL'}")
    print(f"6. Concurrency Disjoint/Shared Checks: Disjoint={evidence['concurrency']['disjoint']['all_succeeded']}, SharedReject={evidence['concurrency']['shared']['same_sid_second_tx_rejected']}")
    print(f"7. Multi-Root Independence Model: {'PASS' if evidence['multi_root']['passed'] else 'FAIL'}")
    print(f"8. Derived Deterministic Allocation: {'PASS' if evidence['derived_allocation']['passed'] else 'FAIL'}")
    print(f"\nFinal Readiness Verdict: {evidence['execution_metadata']['readiness_verdict']}")
    print(f"Execution time: {evidence['execution_metadata']['total_elapsed_seconds']}s")

    report_dir = os.path.join(os.path.dirname(__file__), "reports")
    os.makedirs(report_dir, exist_ok=True)
    evidence_path = os.path.join(report_dir, "verification_closure_evidence.json")
    with open(evidence_path, "w") as f:
        json.dump(evidence, f, indent=2, default=str)

    print(f"\nWrote verification closure evidence to {evidence_path}")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
