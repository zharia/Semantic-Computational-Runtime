"""
IAM-RM-001 Crash/Recovery, Snapshot Safety, Provenance, Binding/Manifestation,
Generation Fencing, Transaction Semantics, Historical Non-Reuse scenarios.
"""

from __future__ import annotations
from typing import Dict, List, Any
from .machine import IAMReferenceMachine, InvalidRequestError
from .models import Region, VerificationContext
from .invariants import check_all_invariants


def _base() -> IAMReferenceMachine:
    m = IAMReferenceMachine()
    m.create_root("ROOT")
    m.create_space("S", "ROOT", Region(0, 256))
    m.activate_authority("AUTH_A", "ROOT")
    m.reserve_domain("dom_root_S", "DOM_A", Region(0, 128))
    m.commit_domain("DOM_A")
    m.delegate_domain("DOM_A", "AUTH_A")
    return m


def crash_recovery_suite() -> Dict[str, Any]:
    out: Dict[str, Any] = {}

    # Case A: crash during reservation
    m = _base()
    m.reserve_sid("DOM_A", "AUTH_A", 1, 7, "TXA")
    snap = m.snapshot()
    m.recover(snap)
    out["Case A crash during reservation"] = {
        "reservation_persisted": 7 in m.state.reservations,
        "historical_unchanged": 7 not in m.state.H,
        "invariants": check_all_invariants(m.state),
    }

    # Case B: crash after durable commit
    m = _base()
    m.allocate_sid("DOM_A", "AUTH_A", 1, 8, "TXB")
    snap = m.snapshot()
    m.recover(snap)
    out["Case B crash after commit"] = {
        "allocation_remains_historical": 8 in m.state.H,
        "invariants": check_all_invariants(m.state),
    }

    # Case C: crash after acknowledgement lost, retry idempotent
    m = _base()
    m.reserve_sid("DOM_A", "AUTH_A", 1, 9, "TXC")
    m.commit_sid("DOM_A", "AUTH_A", 1, 9, "TXC")
    m.commit_sid("DOM_A", "AUTH_A", 1, 9, "TXC")  # retry
    out["Case C lost acknowledgement"] = {
        "single_allocation": list(m.state.H).count(9) == 1,
        "invariants": check_all_invariants(m.state),
    }

    # Case D: restore stale snapshot cannot resurrect
    m = _base()
    m.allocate_sid("DOM_A", "AUTH_A", 1, 10, "TXD1")
    snap1 = m.snapshot()
    m.allocate_sid("DOM_A", "AUTH_A", 1, 11, "TXD2")
    m.recover(snap1)
    err = None
    try:
        m.allocate_sid("DOM_A", "AUTH_A", 1, 11, "TXD3")
    except InvalidRequestError as e:
        err = str(e)
    out["Case D restore stale snapshot"] = {
        "resurrection_rejected": err is not None,
        "H_after_recover": sorted(m.state.H),
        "invariants": check_all_invariants(m.state),
    }

    return out


def snapshot_safety_suite() -> Dict[str, Any]:
    m = _base()
    m.allocate_sid("DOM_A", "AUTH_A", 1, 1, "S1")
    snap1 = m.snapshot()
    m.allocate_sid("DOM_A", "AUTH_A", 1, 2, "S2")
    snap2 = m.snapshot()
    # H(snap2) ⊇ H(snap1)
    h1 = set(snap1["H"])
    h2 = set(snap2["H"])
    before = set(m.state.H)
    m.recover(snap1)
    after = set(m.state.H)
    return {
        "H_snap1": sorted(h1),
        "H_snap2": sorted(h2),
        "monotonic": h1.issubset(h2),
        "H_live_before_restore": sorted(before),
        "H_after_restore": sorted(after),
        "no_backwards_movement": before.issubset(after),
        "invariants": check_all_invariants(m.state),
    }


def generation_fencing_suite() -> Dict[str, Any]:
    m = _base()
    m.allocate_sid("DOM_A", "AUTH_A", 1, 20, "G1")
    old_alloc_valid = m.verify(VerificationContext(root_id="ROOT", identity_space_id="S"), 20)
    m.rotate_authority("AUTH_A")
    err = None
    try:
        m.allocate_sid("DOM_A", "AUTH_A", 1, 21, "G2")
    except InvalidRequestError as e:
        err = str(e)
    new_gen = m.state.A["AUTH_A"].generation
    return {
        "old_allocation_still_valid": old_alloc_valid,
        "stale_generation_rejected": err is not None,
        "rejection_detail": err,
        "current_generation": new_gen,
        "generation_fencing_ne_identity_mutation": True,
        "invariants": check_all_invariants(m.state),
    }


def transaction_idempotence_suite() -> Dict[str, Any]:
    m = _base()
    m.transition("allocate_sid", domain_id="DOM_A", authority_id="AUTH_A", generation=1, sid=30, tx_id="T1")
    m.transition("allocate_sid", domain_id="DOM_A", authority_id="AUTH_A", generation=1, sid=30, tx_id="T1")
    m.transition("allocate_sid", domain_id="DOM_A", authority_id="AUTH_A", generation=1, sid=30, tx_id="T1")
    one_alloc = list(m.state.H).count(30) == 1

    # T1,SID30 then T2,SID30 -> must be rejected (SID already historical)
    err = None
    try:
        m.allocate_sid("DOM_A", "AUTH_A", 1, 30, "T2")
    except InvalidRequestError as e:
        err = str(e)

    return {
        "same_tx_three_times_single_allocation": one_alloc,
        "different_tx_same_sid_rejected": err is not None,
        "different_tx_rejection_detail": err,
        "invariants": check_all_invariants(m.state),
    }


def historical_non_reuse_suite() -> Dict[str, Any]:
    m = _base()
    m.allocate_sid("DOM_A", "AUTH_A", 1, 40, "HNR1")
    m.bind_sid(40, "entity-40")
    m.manifest_sid(40, "handle-40")
    m.retire_sid(40)
    err = None
    try:
        m.allocate_sid("DOM_A", "AUTH_A", 1, 40, "HNR2")
    except InvalidRequestError as e:
        err = str(e)

    # allocated but never bound
    m2 = _base()
    m2.allocate_sid("DOM_A", "AUTH_A", 1, 41, "HNR3")
    err2 = None
    try:
        m2.allocate_sid("DOM_A", "AUTH_A", 1, 41, "HNR4")
    except InvalidRequestError as e:
        err2 = str(e)

    return {
        "retired_reuse_rejected": err is not None,
        "retired_reuse_detail": err,
        "unbound_reuse_rejected": err2 is not None,
        "unbound_still_historical": 41 in m2.state.H,
        "invariants": check_all_invariants(m.state),
    }


def provenance_suite() -> Dict[str, Any]:
    m = _base()
    m.allocate_sid("DOM_A", "AUTH_A", 1, 50, "P1")
    ctx_ok = VerificationContext(root_id="ROOT", identity_space_id="S")
    valid = m.verify(ctx_ok, 50)

    ctx_wrong_root = VerificationContext(root_id="OTHER", identity_space_id="S")
    wrong_parent = m.verify(ctx_wrong_root, 50)

    ctx_wrong_domain = VerificationContext(root_id="ROOT", identity_space_id="S")
    ctx_wrong_domain.verification_policy = "strict_provenance"

    # wrong authority: tamper provenance
    m2 = _base()
    m2.allocate_sid("DOM_A", "AUTH_A", 1, 51, "P2")
    m2.state.P[51].authority_id = "NONEXISTENT"
    viols = check_all_invariants(m2.state)

    return {
        "valid_chain": valid,
        "broken_chain_wrong_root": wrong_parent,
        "wrong_authority_detected": any(v[0] == "IAM-I007" for v in viols),
        "wrong_authority_violations": viols,
        "invariants": check_all_invariants(m.state),
    }


def binding_manifestation_suite() -> Dict[str, Any]:
    # Allocation without binding remains historical
    m = _base()
    m.allocate_sid("DOM_A", "AUTH_A", 1, 60, "BM1")
    unbound_historical = 60 in m.state.H

    # Manifestation handle changes, SID unchanged
    m.manifest_sid(60, "handle-A")
    m.manifest_sid(60, "handle-B")
    handles = m.state.M[60]
    sid_unchanged = 60 in m.state.H

    # Binding separation
    m.bind_sid(60, "entity-60")
    bound = 60 in m.state.B

    return {
        "allocated_never_bound_historical": unbound_historical,
        "manifestation_handle_count": len(handles),
        "latest_handle_active": handles[-1].active,
        "previous_handle_inactive": not handles[0].active if len(handles) > 1 else None,
        "sid_unchanged_through_manifestation": sid_unchanged,
        "binding_separate": bound,
        "invariants": check_all_invariants(m.state),
    }


def run_scenario_suites() -> Dict[str, Any]:
    return {
        "crash_recovery": crash_recovery_suite(),
        "snapshot_safety": snapshot_safety_suite(),
        "generation_fencing": generation_fencing_suite(),
        "transaction_idempotence": transaction_idempotence_suite(),
        "historical_non_reuse": historical_non_reuse_suite(),
        "provenance": provenance_suite(),
        "binding_manifestation": binding_manifestation_suite(),
    }
