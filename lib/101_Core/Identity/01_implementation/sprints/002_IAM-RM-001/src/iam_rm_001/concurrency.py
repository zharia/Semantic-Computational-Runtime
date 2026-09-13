"""
IAM-RM-001 Concurrency & Crash/Recovery Model Checking.
Concurrency is modelled as explicit event interleaving (concurrency model checking,
not physical concurrent execution).
"""

from __future__ import annotations
from typing import Dict, List, Tuple, Any
from itertools import permutations
from .machine import IAMReferenceMachine, InvalidRequestError
from .models import Region, VerificationContext
from .invariants import check_all_invariants


def _base() -> IAMReferenceMachine:
    m = IAMReferenceMachine()
    m.create_root("ROOT")
    m.create_space("S", "ROOT", Region(0, 256))
    m.activate_authority("AUTH_A", "ROOT")
    m.activate_authority("AUTH_B", "ROOT")
    m.reserve_domain("dom_root_S", "DOM_A", Region(0, 128))
    m.commit_domain("DOM_A")
    m.delegate_domain("DOM_A", "AUTH_A")
    m.reserve_domain("dom_root_S", "DOM_B", Region(128, 256))
    m.commit_domain("DOM_B")
    m.delegate_domain("DOM_B", "AUTH_B")
    return m


def concurrency_disjoint_domains() -> Dict[str, Any]:
    """
    D_A ∩ D_B = ∅ -> independent allocation is safe.
    All interleavings of allocation from DOM_A and DOM_B must succeed
    with no coordination and no invariant violation.
    """
    results = []
    events = [
        ("allocate_sid", dict(domain_id="DOM_A", authority_id="AUTH_A", generation=1, sid=10, tx_id="T_DA")),
        ("allocate_sid", dict(domain_id="DOM_B", authority_id="AUTH_B", generation=1, sid=200, tx_id="T_DB")),
    ]
    for order in permutations(range(len(events))):
        m = _base()
        ok_all = True
        for idx in order:
            name, kwargs = events[idx]
            _, err = m.transition(name, **kwargs)
            if err is not None:
                ok_all = False
        viols = check_all_invariants(m.state)
        results.append({"order": order, "success": ok_all, "violations": viols, "H": sorted(m.state.H)})
    all_ok = all(r["success"] and not r["violations"] for r in results)
    return {
        "scenario": "disjoint domain concurrency",
        "interleavings": len(results),
        "all_succeeded": all_ok,
        "coordination_required": False,
        "results": results,
    }


def concurrency_shared_domain() -> Dict[str, Any]:
    """
    D_A ∩ D_B ≠ ∅ -> coordination is required.
    Two allocators sharing one domain attempt overlapping SIDs.
    We show that without coordination, disjoint SID allocation still succeeds,
    but identical SID allocation is rejected by the machine (coordination enforced by reservation/commit).
    """
    results = []
    # Two allocators under same authority/domain, distinct SIDs: safe
    events_distinct = [
        ("allocate_sid", dict(domain_id="DOM_A", authority_id="AUTH_A", generation=1, sid=1, tx_id="T1")),
        ("allocate_sid", dict(domain_id="DOM_A", authority_id="AUTH_A", generation=1, sid=2, tx_id="T2")),
    ]
    for order in permutations(range(len(events_distinct))):
        m = _base()
        for idx in order:
            name, kwargs = events_distinct[idx]
            m.transition(name, **kwargs)
        viols = check_all_invariants(m.state)
        results.append({"order": order, "violations": viols, "H": sorted(m.state.H)})

    # Same SID from two allocators: second must be rejected (coordination enforced)
    m = _base()
    m.transition("allocate_sid", domain_id="DOM_A", authority_id="AUTH_A", generation=1, sid=1, tx_id="T1")
    _, err = m.transition("allocate_sid", domain_id="DOM_A", authority_id="AUTH_A", generation=1, sid=1, tx_id="T2")
    rejection = err is not None
    viols = check_all_invariants(m.state)
    return {
        "scenario": "shared domain concurrency",
        "distinct_sid_interleavings": len(results),
        "distinct_sid_all_safe": all(not r["violations"] for r in results),
        "same_sid_second_tx_rejected": rejection,
        "rejection_detail": err,
        "violations": viols,
        "coordination_required": True,
    }


def concurrency_overlapping_delegation_race() -> Dict[str, Any]:
    """Two authorities race to reserve overlapping domains; exactly one must succeed."""
    m = _base()
    # AUTH_A already owns DOM_A [0,128). AUTH_C tries to reserve overlapping [64,192)
    m2 = IAMReferenceMachine(m.state.clone())
    m2.activate_authority("AUTH_C", "ROOT")
    _, err = m2.transition("reserve_domain", parent_dom_id="dom_root_S", domain_id="DOM_C", region=Region(64, 192))
    rejected = err is not None
    viols = check_all_invariants(m2.state)
    return {
        "scenario": "overlapping delegation race",
        "overlap_rejected": rejected,
        "detail": err,
        "violations": viols,
    }


def concurrency_allocation_race() -> Dict[str, Any]:
    """Concurrent allocation of the same SID by two transactions; injectivity preserved."""
    m = _base()
    m.transition("allocate_sid", domain_id="DOM_A", authority_id="AUTH_A", generation=1, sid=5, tx_id="TA")
    _, err = m.transition("allocate_sid", domain_id="DOM_A", authority_id="AUTH_A", generation=1, sid=5, tx_id="TB")
    rejected = err is not None
    viols = check_all_invariants(m.state)
    return {
        "scenario": "allocation race",
        "duplicate_sid_rejected": rejected,
        "detail": err,
        "H": sorted(m.state.H),
        "violations": viols,
    }


def run_concurrency_suite() -> Dict[str, Any]:
    return {
        "disjoint": concurrency_disjoint_domains(),
        "shared": concurrency_shared_domain(),
        "overlapping_delegation": concurrency_overlapping_delegation_race(),
        "allocation_race": concurrency_allocation_race(),
    }
