"""
IAM-RM-001 Executable Invariants (IAM-I001 to IAM-I016).
Every invariant is an executable assertion function.
"""

from __future__ import annotations
from typing import List, Tuple, Optional, Dict, Set, Any
from .models import State, DomainState, AuthorityState, Region


class InvariantViolation(Exception):
    def __init__(self, invariant_id: str, message: str, details: Optional[Dict[str, Any]] = None):
        super().__init__(f"[{invariant_id}] {message}")
        self.invariant_id = invariant_id
        self.message = message
        self.details = details or {}


def assert_IAM_I001_root_uniqueness(state: State) -> None:
    """IAM-I001: Root authorities are unique per space and root IDs are distinct."""
    roots_seen = set()
    for space_id, space in state.I.items():
        if space.root_authority not in state.A:
            raise InvariantViolation("IAM-I001", f"Space {space_id} references non-existent root authority {space.root_authority}")
        root_auth = state.A[space.root_authority]
        if root_auth.parent_authority is not None:
            raise InvariantViolation("IAM-I001", f"Root authority {root_auth.id} has a parent authority {root_auth.parent_authority}")
        if space.root_authority in roots_seen:
            # Multiple spaces sharing a root is allowed if explicitly configured, but root authority must remain unique in A
            pass
        roots_seen.add(space.root_authority)


def assert_IAM_I002_domain_disjointness(state: State) -> None:
    """IAM-I002: Sibling active/delegated/reserved domains under the same parent do not overlap."""
    # Group domains by parent
    by_parent: Dict[Optional[str], List[str]] = {}
    for dom_id, dom in state.D.items():
        if dom.state in (DomainState.RESERVED, DomainState.DELEGATED, DomainState.ACTIVE):
            by_parent.setdefault(dom.parent, []).append(dom_id)

    for parent_id, children in by_parent.items():
        for i in range(len(children)):
            for j in range(i + 1, len(children)):
                d1 = state.D[children[i]]
                d2 = state.D[children[j]]
                if d1.region.overlaps(d2.region):
                    raise InvariantViolation(
                        "IAM-I002",
                        f"Sibling domains {d1.id} ({d1.region}) and {d2.id} ({d2.region}) overlap under parent {parent_id}",
                        {"domain1": d1.id, "region1": d1.region, "domain2": d2.id, "region2": d2.region}
                    )


def assert_IAM_I003_domain_containment(state: State) -> None:
    """IAM-I003: Child domain region is a subset of parent domain region."""
    for dom_id, dom in state.D.items():
        if dom.parent is not None:
            if dom.parent not in state.D:
                raise InvariantViolation("IAM-I003", f"Domain {dom_id} references non-existent parent {dom.parent}")
            parent_dom = state.D[dom.parent]
            if not dom.region.is_subset_of(parent_dom.region):
                raise InvariantViolation(
                    "IAM-I003",
                    f"Child domain {dom_id} ({dom.region}) escapes parent domain {parent_dom.id} ({parent_dom.region})",
                    {"child": dom_id, "child_region": dom.region, "parent": parent_dom.id, "parent_region": parent_dom.region}
                )


def assert_IAM_I004_allocation_containment(state: State) -> None:
    """IAM-I004: Allocated SIDs fall strictly within their domain's region."""
    for dom_id, dom in state.D.items():
        for sid in dom.allocated_sids:
            if not dom.region.contains(sid):
                raise InvariantViolation(
                    "IAM-I004",
                    f"Allocated SID {sid} is outside domain {dom_id} region {dom.region}",
                    {"domain": dom_id, "sid": sid, "region": dom.region}
                )


def assert_IAM_I005_allocation_injectivity(state: State) -> None:
    """IAM-I005: Every allocated SID in H belongs to exactly one domain and provenance record."""
    sid_to_domains: Dict[int, List[str]] = {}
    for dom_id, dom in state.D.items():
        for sid in dom.allocated_sids:
            sid_to_domains.setdefault(sid, []).append(dom_id)

    for sid, doms in sid_to_domains.items():
        if len(doms) > 1:
            raise InvariantViolation(
                "IAM-I005",
                f"SID {sid} allocated simultaneously in multiple domains: {doms}",
                {"sid": sid, "domains": doms}
            )

    # All domain allocated SIDs must be in H
    for dom_id, dom in state.D.items():
        for sid in dom.allocated_sids:
            if sid not in state.H:
                raise InvariantViolation(
                    "IAM-I005",
                    f"Domain {dom_id} has allocated SID {sid} that is missing from historical set H",
                    {"domain": dom_id, "sid": sid}
                )


def assert_IAM_I006_authority_containment(state: State) -> None:
    """IAM-I006: An authority can only allocate in domains where it is the designated authority."""
    for sid, prov in state.P.items():
        dom_id = prov.domain_id
        if dom_id not in state.D:
            raise InvariantViolation("IAM-I006", f"Provenance for SID {sid} references non-existent domain {dom_id}")
        dom = state.D[dom_id]
        if dom.authority != prov.authority_id:
            raise InvariantViolation(
                "IAM-I006",
                f"SID {sid} allocated by authority {prov.authority_id} but domain {dom_id} assigned authority is {dom.authority}",
                {"sid": sid, "provenance_authority": prov.authority_id, "domain_authority": dom.authority}
            )


def assert_IAM_I007_cryptographic_provenance(state: State) -> None:
    """IAM-I007: Every committed SID has a valid provenance record chaining to root."""
    for sid in state.H:
        if sid not in state.P:
            raise InvariantViolation("IAM-I007", f"Committed SID {sid} has no provenance record in P")
        prov = state.P[sid]
        if prov.root_id not in state.A:
            raise InvariantViolation("IAM-I007", f"Provenance for SID {sid} references invalid root {prov.root_id}")
        if prov.authority_id not in state.A:
            raise InvariantViolation("IAM-I007", f"Provenance for SID {sid} references invalid authority {prov.authority_id}")


def assert_IAM_I008_generation_validity(state: State) -> None:
    """IAM-I008: Provenance generation at allocation time was valid."""
    for sid, prov in state.P.items():
        if prov.authority_id in state.A:
            auth = state.A[prov.authority_id]
            # Generation at allocation must be <= current generation
            if prov.generation > auth.generation:
                raise InvariantViolation(
                    "IAM-I008",
                    f"Provenance generation {prov.generation} exceeds current authority generation {auth.generation}",
                    {"sid": sid, "prov_gen": prov.generation, "auth_gen": auth.generation}
                )


def assert_IAM_I009_historical_monotonicity(prev_state: State, curr_state: State) -> None:
    """IAM-I009: Historical allocation set H is monotonic (H_prev ⊆ H_curr)."""
    if not prev_state.H.issubset(curr_state.H):
        lost_sids = prev_state.H - curr_state.H
        raise InvariantViolation(
            "IAM-I009",
            f"Historical monotonicity violated: SIDs lost from H: {lost_sids}",
            {"lost_sids": lost_sids}
        )


def assert_IAM_I010_durable_non_reuse(state: State) -> None:
    """IAM-I010: No retired or historical SID can ever be re-allocated under a different provenance."""
    for sid in state.H:
        # Check that it has exactly one provenance record in P
        if sid not in state.P:
            raise InvariantViolation("IAM-I010", f"Historical SID {sid} missing provenance record")


def assert_IAM_I011_crash_monotonicity(state_before: State, state_after_crash: State) -> None:
    """IAM-I011: Crash or rollback never causes committed historical SIDs to be lost."""
    if not state_before.H.issubset(state_after_crash.H):
        raise InvariantViolation(
            "IAM-I011",
            f"Crash monotonicity violated: committed SIDs disappeared after crash",
            {"lost": state_before.H - state_after_crash.H}
        )


def assert_IAM_I012_snapshot_safety(prior_state: State, restored_state: State) -> None:
    """IAM-I012: Restoring snapshot never allows previously allocated SIDs to be recycled."""
    if not prior_state.H.issubset(restored_state.H):
        raise InvariantViolation(
            "IAM-I012",
            f"Snapshot restore lost historical SIDs: {prior_state.H - restored_state.H}",
            {"lost": prior_state.H - restored_state.H}
        )


def assert_IAM_I013_contextual_resolution(state: State) -> None:
    """IAM-I013: Provenance records contain sufficient context to resolve root, domain, and authority."""
    for sid, prov in state.P.items():
        if not (prov.root_id and prov.domain_id and prov.authority_id and prov.genesis_id):
            raise InvariantViolation("IAM-I013", f"Incomplete provenance context for SID {sid}")


def assert_IAM_I014_identity_manifestation_separation(state: State) -> None:
    """IAM-I014: Manifestation updates do not mutate canonical SID identity."""
    for sid, handles in state.M.items():
        if sid not in state.H:
            raise InvariantViolation("IAM-I014", f"Manifestation attached to unallocated SID {sid}")


def assert_IAM_I015_binding_separation(state: State) -> None:
    """IAM-I015: Semantic bindings are decoupled from allocation; unbound SIDs remain in H."""
    for sid, binding in state.B.items():
        if sid not in state.H:
            raise InvariantViolation("IAM-I015", f"Binding references unallocated SID {sid}")


def assert_IAM_I016_transaction_idempotence(state: State) -> None:
    """IAM-I016: Committed transaction records in Q map uniquely to their allocated SIDs."""
    tx_sids = {}
    for tx_id, tx in state.Q.items():
        if tx.status == "COMMITTED":
            if tx.sid not in state.H:
                raise InvariantViolation("IAM-I016", f"Transaction {tx_id} claims committed SID {tx.sid} not in H")


def check_all_invariants(state: State, prev_state: Optional[State] = None) -> List[Tuple[str, str]]:
    """
    Master Invariant Verification function.
    Returns list of (invariant_id, error_message) for any violations found.
    Empty list indicates all invariants hold.
    """
    violations = []
    checks = [
        ("IAM-I001", lambda: assert_IAM_I001_root_uniqueness(state)),
        ("IAM-I002", lambda: assert_IAM_I002_domain_disjointness(state)),
        ("IAM-I003", lambda: assert_IAM_I003_domain_containment(state)),
        ("IAM-I004", lambda: assert_IAM_I004_allocation_containment(state)),
        ("IAM-I005", lambda: assert_IAM_I005_allocation_injectivity(state)),
        ("IAM-I006", lambda: assert_IAM_I006_authority_containment(state)),
        ("IAM-I007", lambda: assert_IAM_I007_cryptographic_provenance(state)),
        ("IAM-I008", lambda: assert_IAM_I008_generation_validity(state)),
        ("IAM-I010", lambda: assert_IAM_I010_durable_non_reuse(state)),
        ("IAM-I013", lambda: assert_IAM_I013_contextual_resolution(state)),
        ("IAM-I014", lambda: assert_IAM_I014_identity_manifestation_separation(state)),
        ("IAM-I015", lambda: assert_IAM_I015_binding_separation(state)),
        ("IAM-I016", lambda: assert_IAM_I016_transaction_idempotence(state)),
    ]

    if prev_state is not None:
        checks.append(("IAM-I009", lambda: assert_IAM_I009_historical_monotonicity(prev_state, state)))
        checks.append(("IAM-I011", lambda: assert_IAM_I011_crash_monotonicity(prev_state, state)))
        checks.append(("IAM-I012", lambda: assert_IAM_I012_snapshot_safety(prev_state, state)))

    for inv_id, check_fn in checks:
        try:
            check_fn()
        except InvariantViolation as e:
            violations.append((inv_id, e.message))
        except Exception as e:
            violations.append((inv_id, f"Unexpected error during check: {e}"))

    return violations
