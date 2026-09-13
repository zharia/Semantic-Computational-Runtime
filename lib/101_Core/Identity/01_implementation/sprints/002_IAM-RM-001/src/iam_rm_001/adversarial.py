"""
IAM-RM-001 Adversarial Test Suite — 25 required scenarios (spec §24/§10).
Each scenario produces executable evidence.
"""

from __future__ import annotations
from typing import Dict, List, Tuple, Any
from .machine import IAMReferenceMachine, IAMError, InvalidRequestError
from .models import Region, DomainState, AuthorityState, VerificationContext, State
from .invariants import check_all_invariants


class AdversarialResult:
    def __init__(self, index: int, name: str, passed: bool, detail: str, invariants: List[str], trace: List[str]):
        self.index = index
        self.name = name
        self.passed = passed
        self.detail = detail
        self.invariants = invariants
        self.trace = trace


def _base() -> IAMReferenceMachine:
    m = IAMReferenceMachine()
    m.create_root("ROOT")
    m.create_space("S", "ROOT", Region(0, 256))
    m.activate_authority("AUTH_A", "ROOT")
    m.reserve_domain("dom_root_S", "DOM_A", Region(0, 128))
    m.commit_domain("DOM_A")
    m.delegate_domain("DOM_A", "AUTH_A")
    return m


def run_all_adversarial() -> List[AdversarialResult]:
    results: List[AdversarialResult] = []

    # 1. normal allocation
    m = _base()
    m.allocate_sid("DOM_A", "AUTH_A", 1, 42, "TX1")
    ok = 42 in m.state.H and check_all_invariants(m.state) == []
    results.append(AdversarialResult(1, "normal allocation", ok, f"H={m.state.H}", ["I004", "I005", "I007"], []))

    # 2. overlapping domain
    m = _base()
    err = None
    try:
        m.reserve_domain("dom_root_S", "DOM_B", Region(64, 192))
    except InvalidRequestError as e:
        err = str(e)
    ok = err is not None and check_all_invariants(m.state) == []
    results.append(AdversarialResult(2, "overlapping domain", ok, f"rejected: {err}", ["I002"], []))

    # 3. nested domain (legal: subset)
    m = _base()
    m.reserve_domain("DOM_A", "DOM_A1", Region(0, 64))
    m.commit_domain("DOM_A1")
    ok = check_all_invariants(m.state) == []
    results.append(AdversarialResult(3, "nested domain", ok, "legal subset accepted", ["I003"], []))

    # 4. out-of-domain allocation
    m = _base()
    err = None
    try:
        m.allocate_sid("DOM_A", "AUTH_A", 1, 200, "TX2")
    except InvalidRequestError as e:
        err = str(e)
    ok = err is not None and check_all_invariants(m.state) == []
    results.append(AdversarialResult(4, "out-of-domain allocation", ok, f"rejected: {err}", ["I004"], []))

    # 5. stale authority
    m = _base()
    m.rotate_authority("AUTH_A")  # now generation 2
    err = None
    try:
        m.allocate_sid("DOM_A", "AUTH_A", 1, 10, "TX3")  # stale gen 1
    except InvalidRequestError as e:
        err = str(e)
    ok = err is not None and check_all_invariants(m.state) == []
    results.append(AdversarialResult(5, "stale authority", ok, f"rejected: {err}", ["I008"], []))

    # 6. authority rotation
    m = _base()
    m.rotate_authority("AUTH_A")
    ok = m.state.A["AUTH_A"].generation == 2 and check_all_invariants(m.state) == []
    results.append(AdversarialResult(6, "authority rotation", ok, f"gen={m.state.A['AUTH_A'].generation}", ["I008"], []))

    # 7. revoked authority
    m = _base()
    m.revoke_authority("AUTH_A")
    err = None
    try:
        m.allocate_sid("DOM_A", "AUTH_A", 1, 10, "TX4")
    except InvalidRequestError as e:
        err = str(e)
    ok = err is not None and check_all_invariants(m.state) == []
    results.append(AdversarialResult(7, "revoked authority", ok, f"rejected: {err}", ["I006"], []))

    # 8. duplicate commit
    m = _base()
    m.allocate_sid("DOM_A", "AUTH_A", 1, 42, "TX5")
    m.allocate_sid("DOM_A", "AUTH_A", 1, 42, "TX5")  # idempotent duplicate
    ok = len(m.state.H) == 1 and check_all_invariants(m.state) == []
    results.append(AdversarialResult(8, "duplicate commit", ok, f"H={m.state.H}", ["I016"], []))

    # 9. SID reuse after retirement
    m = _base()
    m.allocate_sid("DOM_A", "AUTH_A", 1, 42, "TX6")
    m.retire_sid(42)
    err = None
    try:
        m.allocate_sid("DOM_A", "AUTH_A", 1, 42, "TX7")
    except InvalidRequestError as e:
        err = str(e)
    ok = err is not None and check_all_invariants(m.state) == []
    results.append(AdversarialResult(9, "SID reuse after retirement", ok, f"rejected: {err}", ["I010"], []))

    # 10. snapshot rollback
    m = _base()
    m.allocate_sid("DOM_A", "AUTH_A", 1, 1, "TX8")
    snap = m.snapshot()
    m.allocate_sid("DOM_A", "AUTH_A", 1, 2, "TX9")
    m.recover(snap)
    err = None
    try:
        m.allocate_sid("DOM_A", "AUTH_A", 1, 2, "TX10")
    except InvalidRequestError as e:
        err = str(e)
    ok = err is not None and 2 in m.state.H and check_all_invariants(m.state) == []
    results.append(AdversarialResult(10, "snapshot rollback", ok, f"resurrect rejected: {err}; H={m.state.H}", ["I012"], []))

    # 11. crash during reservation
    m = _base()
    m.reserve_sid("DOM_A", "AUTH_A", 1, 7, "TX11")
    snap = m.snapshot()
    m.recover(snap)  # reservation may disappear; H unchanged
    ok = 7 not in m.state.H and check_all_invariants(m.state) == []
    results.append(AdversarialResult(11, "crash during reservation", ok, f"H={m.state.H}", ["I011"], []))

    # 12. crash after commit
    m = _base()
    m.allocate_sid("DOM_A", "AUTH_A", 1, 7, "TX12")
    snap = m.snapshot()
    m.recover(snap)
    ok = 7 in m.state.H and check_all_invariants(m.state) == []
    results.append(AdversarialResult(12, "crash after commit", ok, f"H={m.state.H}", ["I011"], []))

    # 13. lost acknowledgement (reserve+commit, retry)
    m = _base()
    m.reserve_sid("DOM_A", "AUTH_A", 1, 7, "TX13")
    m.commit_sid("DOM_A", "AUTH_A", 1, 7, "TX13")  # ack lost
    m.commit_sid("DOM_A", "AUTH_A", 1, 7, "TX13")  # retry
    ok = len([s for s in m.state.H if s == 7]) == 1 and check_all_invariants(m.state) == []
    results.append(AdversarialResult(13, "lost acknowledgement", ok, f"H={m.state.H}", ["I016"], []))

    # 14. retry after commit
    m = _base()
    m.allocate_sid("DOM_A", "AUTH_A", 1, 7, "TX14")
    m.allocate_sid("DOM_A", "AUTH_A", 1, 7, "TX14")
    ok = len(m.state.H) == 1 and check_all_invariants(m.state) == []
    results.append(AdversarialResult(14, "retry after commit", ok, f"H={m.state.H}", ["I016"], []))

    # 15. concurrent sibling delegation (non-overlapping)
    m = _base()
    m.reserve_domain("dom_root_S", "DOM_B", Region(128, 256))
    m.commit_domain("DOM_B")
    m.activate_authority("AUTH_B", "ROOT")
    m.delegate_domain("DOM_B", "AUTH_B")
    ok = check_all_invariants(m.state) == []
    results.append(AdversarialResult(15, "concurrent sibling delegation", ok, "disjoint siblings accepted", ["I002"], []))

    # 16. concurrent allocation (shared domain, sequential serialisation required)
    m = _base()
    m.allocate_sid("DOM_A", "AUTH_A", 1, 10, "TX16a")
    m.allocate_sid("DOM_A", "AUTH_A", 1, 11, "TX16b")
    ok = {10, 11}.issubset(m.state.H) and check_all_invariants(m.state) == []
    results.append(AdversarialResult(16, "concurrent allocation", ok, f"H={m.state.H}", ["I005"], []))

    # 17. malicious allocation outside domain
    m = _base()
    err = None
    try:
        m.allocate_sid("DOM_A", "AUTH_A", 1, 999, "TX17")
    except InvalidRequestError as e:
        err = str(e)
    ok = err is not None and check_all_invariants(m.state) == []
    results.append(AdversarialResult(17, "malicious allocation outside domain", ok, f"rejected: {err}", ["I004"], []))

    # 18. stale process after key rotation
    m = _base()
    m.rotate_authority("AUTH_A")
    err = None
    try:
        m.allocate_sid("DOM_A", "AUTH_A", 1, 10, "TX18")
    except InvalidRequestError as e:
        err = str(e)
    ok = err is not None and check_all_invariants(m.state) == []
    results.append(AdversarialResult(18, "stale process after key rotation", ok, f"rejected: {err}", ["I008"], []))

    # 19. abandoned domain (reserved but never committed)
    m = _base()
    m.reserve_domain("dom_root_S", "DOM_ABANDON", Region(128, 192))
    # abandoned: never committed; attempting allocation must fail (not ACTIVE)
    err = None
    try:
        m.allocate_sid("DOM_ABANDON", "AUTH_A", 1, 130, "TX19")
    except InvalidRequestError as e:
        err = str(e)
    ok = err is not None and check_all_invariants(m.state) == []
    results.append(AdversarialResult(19, "abandoned domain", ok, f"rejected: {err}", ["I006"], []))

    # 20. exhausted domain
    m = _base()
    m.reserve_domain("DOM_A", "DOM_TINY", Region(0, 2))
    m.commit_domain("DOM_TINY")
    m.delegate_domain("DOM_TINY", "AUTH_A")
    m.allocate_sid("DOM_TINY", "AUTH_A", 1, 0, "TX20a")
    m.allocate_sid("DOM_TINY", "AUTH_A", 1, 1, "TX20b")
    err = None
    try:
        m.allocate_sid("DOM_TINY", "AUTH_A", 1, 2, "TX20c")
    except InvalidRequestError as e:
        err = str(e)
    ok = err is not None and check_all_invariants(m.state) == []
    results.append(AdversarialResult(20, "exhausted domain", ok, f"rejected: {err}", ["I004"], []))

    # 21. fragmented domain
    m = _base()
    m.reserve_domain("DOM_A", "DOM_F1", Region(0, 32))
    m.commit_domain("DOM_F1")
    m.reserve_domain("DOM_A", "DOM_F2", Region(64, 96))
    m.commit_domain("DOM_F2")
    ok = check_all_invariants(m.state) == []
    results.append(AdversarialResult(21, "fragmented domain", ok, "disjoint fragments accepted", ["I002"], []))

    # 22. deep delegation
    m = _base()
    parent = "DOM_A"
    for i in range(1, 4):
        did = f"DOM_D{i}"
        # region halves within parent
        pd = m.state.D[parent]
        r = Region(pd.region.low, (pd.region.low + pd.region.high) // 2)
        m.reserve_domain(parent, did, r)
        m.commit_domain(did)
        m.delegate_domain(did, "AUTH_A")
        parent = did
    ok = check_all_invariants(m.state) == []
    results.append(AdversarialResult(22, "deep delegation", ok, "depth 3 accepted", ["I003"], []))

    # 23. invalid provenance (verify with wrong root context)
    m = _base()
    m.allocate_sid("DOM_A", "AUTH_A", 1, 5, "TX23")
    ctx = VerificationContext(root_id="WRONG_ROOT", identity_space_id="S")
    ok = m.verify(ctx, 5) is False and check_all_invariants(m.state) == []
    results.append(AdversarialResult(23, "invalid provenance", ok, "wrong root rejected", ["I007"], []))

    # 24. corrupted provenance (remove P record)
    m = _base()
    m.allocate_sid("DOM_A", "AUTH_A", 1, 5, "TX24")
    del m.state.P[5]
    viols = check_all_invariants(m.state)
    ok = any(v[0] == "IAM-I007" for v in viols)
    results.append(AdversarialResult(24, "corrupted provenance", ok, f"detected: {viols}", ["I007"], []))

    # 25. conflicting deterministic allocation (same tx, different SID)
    m = _base()
    m.allocate_sid("DOM_A", "AUTH_A", 1, 5, "TX25")
    err = None
    try:
        m.allocate_sid("DOM_A", "AUTH_A", 1, 6, "TX25")  # same tx different sid
    except InvalidRequestError as e:
        err = str(e)
    ok = err is not None and check_all_invariants(m.state) == []
    results.append(AdversarialResult(25, "conflicting deterministic allocation", ok, f"rejected: {err}", ["I016"], []))

    return results
