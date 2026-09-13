"""
IAM-RM-001 Reference Machine Implementation.
Deterministic state transition engine implementing:
T : Σ × Event -> Σ | Error
"""

from __future__ import annotations
from typing import Optional, Tuple, List, Set, Dict, Any
from .models import (
    State, IdentitySpace, Domain, DomainState, Authority, AuthorityState,
    Region, ProvenanceRecord, SemanticBinding, ManifestationRecord,
    TransactionRecord, VerificationContext
)


class IAMError(Exception):
    """Base error for IAM Reference Machine."""
    pass


class InvalidRequestError(IAMError):
    """Invalid caller request (rejected legitimately by protocol)."""
    pass


class InvariantViolationError(IAMError):
    """Protocol violation or invariant failure."""
    pass


class IAMReferenceMachine:
    """
    Executable Reference Machine for IAM-001 (N=8 coordinate space [0, 256)).
    """

    def __init__(self, state: Optional[State] = None):
        self.state = state if state is not None else State()

    # --- Root & Identity Space Operations ---

    def create_root(self, root_id: str) -> State:
        """Create root authority and root domain covering [0, 256)."""
        new_state = self.state.clone()
        new_state.step += 1

        if root_id in new_state.A:
            raise InvalidRequestError(f"Root authority {root_id} already exists")

        root_auth = Authority(
            id=root_id,
            generation=1,
            state=AuthorityState.ACTIVE,
            credential_ref=f"cred://{root_id}/v1",
            root_id=root_id,
            parent_authority=None
        )
        new_state.A[root_id] = root_auth
        self.state = new_state
        return self.state

    def create_space(self, space_id: str, root_id: str, coordinate_space: Region = Region(0, 256)) -> State:
        """Create identity space and root domain."""
        new_state = self.state.clone()
        new_state.step += 1

        if root_id not in new_state.A:
            raise InvalidRequestError(f"Root authority {root_id} does not exist")
        if space_id in new_state.I:
            raise InvalidRequestError(f"IdentitySpace {space_id} already exists")

        space = IdentitySpace(
            id=space_id,
            root_authority=root_id,
            coordinate_space=coordinate_space,
            geometry="linear_interval",
            policy="durable_non_reuse"
        )
        new_state.I[space_id] = space

        # Create root domain for the space
        root_dom_id = f"dom_root_{space_id}"
        root_domain = Domain(
            id=root_dom_id,
            parent=None,
            region=coordinate_space,
            state=DomainState.ACTIVE,
            authority=root_id,
            generation=1
        )
        new_state.D[root_dom_id] = root_domain

        self.state = new_state
        return self.state

    # --- Domain Lifecycle Operations ---

    def reserve_domain(self, parent_dom_id: str, domain_id: str, region: Region) -> State:
        """
        Reserve a child domain within parent domain.
        Enforces:
        - parent exists and is ACTIVE or DELEGATED
        - region is sub-region of parent region (child ⊆ parent)
        - region does not overlap any active/reserved sibling domains (child_i ∩ child_j = ∅)
        """
        new_state = self.state.clone()
        new_state.step += 1

        if parent_dom_id not in new_state.D:
            raise InvalidRequestError(f"Parent domain {parent_dom_id} not found")
        if domain_id in new_state.D:
            raise InvalidRequestError(f"Domain {domain_id} already exists")

        parent = new_state.D[parent_dom_id]
        if parent.state not in (DomainState.ACTIVE, DomainState.DELEGATED):
            raise InvalidRequestError(f"Parent domain {parent_dom_id} is not in ACTIVE/DELEGATED state: {parent.state}")

        # Domain Containment Check: child ⊆ parent
        if not region.is_subset_of(parent.region):
            raise InvalidRequestError(f"Requested region {region} is not a subset of parent region {parent.region}")

        # Domain Disjointness Check: check against all other existing committed/reserved child domains of parent or intersecting tree
        for other_id, other_dom in new_state.D.items():
            if other_id == parent_dom_id:
                continue
            if other_dom.state in (DomainState.RESERVED, DomainState.DELEGATED, DomainState.ACTIVE):
                if other_dom.parent == parent_dom_id:
                    if region.overlaps(other_dom.region):
                        raise InvalidRequestError(f"Requested region {region} overlaps sibling domain {other_id} ({other_dom.region})")

        new_domain = Domain(
            id=domain_id,
            parent=parent_dom_id,
            region=region,
            state=DomainState.RESERVED,
            authority=None,
            generation=1
        )
        new_state.D[domain_id] = new_domain
        self.state = new_state
        return self.state

    def commit_domain(self, domain_id: str) -> State:
        """Commit a reserved domain -> transition to DELEGATED."""
        new_state = self.state.clone()
        new_state.step += 1

        if domain_id not in new_state.D:
            raise InvalidRequestError(f"Domain {domain_id} not found")
        dom = new_state.D[domain_id]
        if dom.state != DomainState.RESERVED:
            raise InvalidRequestError(f"Domain {domain_id} is in state {dom.state}, expected RESERVED")

        dom.state = DomainState.DELEGATED
        self.state = new_state
        return self.state

    def delegate_domain(self, domain_id: str, authority_id: str) -> State:
        """Delegate domain to an authority and activate."""
        new_state = self.state.clone()
        new_state.step += 1

        if domain_id not in new_state.D:
            raise InvalidRequestError(f"Domain {domain_id} not found")
        if authority_id not in new_state.A:
            raise InvalidRequestError(f"Authority {authority_id} not found")

        auth = new_state.A[authority_id]
        if auth.state != AuthorityState.ACTIVE:
            raise InvalidRequestError(f"Authority {authority_id} is not ACTIVE (state: {auth.state})")

        dom = new_state.D[domain_id]
        if dom.state not in (DomainState.DELEGATED, DomainState.RESERVED, DomainState.ACTIVE):
            raise InvalidRequestError(f"Domain {domain_id} cannot be delegated in state {dom.state}")

        dom.authority = authority_id
        dom.state = DomainState.ACTIVE
        self.state = new_state
        return self.state

    def revoke_domain(self, domain_id: str) -> State:
        """Revoke a domain."""
        new_state = self.state.clone()
        new_state.step += 1

        if domain_id not in new_state.D:
            raise InvalidRequestError(f"Domain {domain_id} not found")
        dom = new_state.D[domain_id]
        dom.state = DomainState.REVOKED
        self.state = new_state
        return self.state

    def retire_domain(self, domain_id: str) -> State:
        """Retire a domain (terminal state - cannot transition to FREE)."""
        new_state = self.state.clone()
        new_state.step += 1

        if domain_id not in new_state.D:
            raise InvalidRequestError(f"Domain {domain_id} not found")
        dom = new_state.D[domain_id]
        dom.state = DomainState.RETIRED
        self.state = new_state
        return self.state

    # --- Authority Lifecycle Operations ---

    def activate_authority(self, authority_id: str, root_id: str, parent_authority: Optional[str] = None) -> State:
        """Create and activate authority under a root."""
        new_state = self.state.clone()
        new_state.step += 1

        if authority_id in new_state.A:
            raise InvalidRequestError(f"Authority {authority_id} already exists")
        if root_id not in new_state.A:
            raise InvalidRequestError(f"Root {root_id} not found")

        if parent_authority and parent_authority not in new_state.A:
            raise InvalidRequestError(f"Parent authority {parent_authority} not found")

        auth = Authority(
            id=authority_id,
            generation=1,
            state=AuthorityState.ACTIVE,
            credential_ref=f"cred://{authority_id}/v1",
            root_id=root_id,
            parent_authority=parent_authority
        )
        new_state.A[authority_id] = auth
        self.state = new_state
        return self.state

    def rotate_authority(self, authority_id: str) -> State:
        """Rotate authority key/generation (fencing mechanism)."""
        new_state = self.state.clone()
        new_state.step += 1

        if authority_id not in new_state.A:
            raise InvalidRequestError(f"Authority {authority_id} not found")
        auth = new_state.A[authority_id]
        if auth.state != AuthorityState.ACTIVE:
            raise InvalidRequestError(f"Cannot rotate inactive authority {authority_id}")

        auth.generation += 1
        auth.credential_ref = f"cred://{authority_id}/v{auth.generation}"
        self.state = new_state
        return self.state

    def suspend_authority(self, authority_id: str) -> State:
        """Suspend authority."""
        new_state = self.state.clone()
        new_state.step += 1

        if authority_id not in new_state.A:
            raise InvalidRequestError(f"Authority {authority_id} not found")
        new_state.A[authority_id].state = AuthorityState.SUSPENDED
        self.state = new_state
        return self.state

    def revoke_authority(self, authority_id: str) -> State:
        """Revoke authority."""
        new_state = self.state.clone()
        new_state.step += 1

        if authority_id not in new_state.A:
            raise InvalidRequestError(f"Authority {authority_id} not found")
        new_state.A[authority_id].state = AuthorityState.REVOKED
        self.state = new_state
        return self.state

    # --- Allocation & Transaction Operations ---

    def reserve_sid(self, domain_id: str, authority_id: str, generation: int, sid: int, tx_id: str) -> State:
        """
        Reserve an SID prior to durable commit.
        Checks:
        - Domain exists and is ACTIVE
        - Authority assigned to domain and matches authority_id
        - Generation matches current authority generation (generation fencing)
        - SID in domain.region
        - SID NOT in historical allocation H (IAM-I010 Durable Non-Reuse)
        - SID not already reserved by another transaction
        """
        new_state = self.state.clone()
        new_state.step += 1

        # Check transaction idempotence table Q
        if tx_id in new_state.Q:
            rec = new_state.Q[tx_id]
            if rec.status == "COMMITTED" and rec.sid == sid:
                # Idempotent retry of committed tx
                return self.state
            if rec.status == "RESERVED" and rec.sid == sid:
                # Idempotent retry of reserved tx
                return self.state
            if rec.sid != sid:
                raise InvalidRequestError(
                    f"Transaction {tx_id} already bound to SID {rec.sid}; "
                    f"conflicting deterministic allocation for SID {sid}"
                )

        if domain_id not in new_state.D:
            raise InvalidRequestError(f"Domain {domain_id} not found")
        dom = new_state.D[domain_id]
        if dom.state != DomainState.ACTIVE:
            raise InvalidRequestError(f"Domain {domain_id} is not ACTIVE (state: {dom.state})")

        if dom.authority != authority_id:
            raise InvalidRequestError(f"Authority {authority_id} does not own domain {domain_id}")

        if authority_id not in new_state.A:
            raise InvalidRequestError(f"Authority {authority_id} not found")
        auth = new_state.A[authority_id]
        if auth.state != AuthorityState.ACTIVE:
            raise InvalidRequestError(f"Authority {authority_id} is not ACTIVE: {auth.state}")

        # Generation Fencing Check (IAM-I008)
        if generation != auth.generation:
            raise InvalidRequestError(f"Stale authority generation {generation}, current is {auth.generation}")

        # Allocation Containment Check (IAM-I004): SID ∈ delegated_domain
        if not dom.region.contains(sid):
            raise InvalidRequestError(f"SID {sid} is outside domain {domain_id} region {dom.region}")

        # Durable Non-Reuse Check (IAM-I010): SID ∉ historical_allocation_set
        if sid in new_state.H:
            raise InvalidRequestError(f"SID {sid} has already been historically allocated")

        # Active Reservation Check
        if sid in new_state.reservations and new_state.reservations[sid] != tx_id:
            raise InvalidRequestError(f"SID {sid} is already reserved by transaction {new_state.reservations[sid]}")

        # Record reservation in Q and reservations map
        new_state.reservations[sid] = tx_id
        new_state.Q[tx_id] = TransactionRecord(
            tx_id=tx_id,
            sid=sid,
            domain_id=domain_id,
            authority_id=authority_id,
            generation=generation,
            status="RESERVED"
        )

        self.state = new_state
        return self.state

    def commit_sid(self, domain_id: str, authority_id: str, generation: int, sid: int, tx_id: str) -> State:
        """
        Durable commit of reserved SID.
        Enforces atomicity, injectivity, non-reuse, provenance record creation.
        """
        new_state = self.state.clone()
        new_state.step += 1

        # Transaction Idempotence (IAM-I016)
        if tx_id in new_state.Q:
            rec = new_state.Q[tx_id]
            if rec.status == "COMMITTED":
                if rec.sid == sid:
                    # Idempotent success
                    return self.state
                else:
                    raise InvalidRequestError(f"Tx {tx_id} already committed with different SID {rec.sid}")

        if domain_id not in new_state.D:
            raise InvalidRequestError(f"Domain {domain_id} not found")
        dom = new_state.D[domain_id]
        if dom.state != DomainState.ACTIVE:
            raise InvalidRequestError(f"Domain {domain_id} is not ACTIVE")

        if dom.authority != authority_id:
            raise InvalidRequestError(f"Authority {authority_id} does not own domain {domain_id}")

        auth = new_state.A[authority_id]
        if auth.state != AuthorityState.ACTIVE:
            raise InvalidRequestError(f"Authority {authority_id} is not ACTIVE")

        # Generation Fencing Check
        if generation != auth.generation:
            raise InvalidRequestError(f"Stale authority generation {generation}, current is {auth.generation}")

        # Containment Check
        if not dom.region.contains(sid):
            raise InvalidRequestError(f"SID {sid} is outside domain {domain_id} region {dom.region}")

        # Non-Reuse Check (IAM-I010)
        if sid in new_state.H:
            raise InvalidRequestError(f"SID {sid} already historically allocated")

        # Must have reservation or allow direct commit
        if sid in new_state.reservations and new_state.reservations[sid] != tx_id:
            raise InvalidRequestError(f"SID {sid} reserved by another tx {new_state.reservations[sid]}")

        # Durable Allocation: Add to H (monotonic), add to domain allocated set
        new_state.H.add(sid)
        dom.allocated_sids.add(sid)

        # Clear reservation
        if sid in new_state.reservations:
            del new_state.reservations[sid]

        # Provenance Record Creation (IAM-I007)
        prov = ProvenanceRecord(
            sid=sid,
            genesis_id=new_state.genesis_id,
            root_id=auth.root_id,
            authority_id=authority_id,
            generation=generation,
            domain_id=domain_id,
            tx_id=tx_id
        )
        new_state.P[sid] = prov

        # Record committed transaction
        new_state.Q[tx_id] = TransactionRecord(
            tx_id=tx_id,
            sid=sid,
            domain_id=domain_id,
            authority_id=authority_id,
            generation=generation,
            status="COMMITTED"
        )

        self.state = new_state
        return self.state

    def allocate_sid(self, domain_id: str, authority_id: str, generation: int, sid: int, tx_id: str) -> State:
        """Atomic reservation + commit in one step."""
        self.reserve_sid(domain_id, authority_id, generation, sid, tx_id)
        return self.commit_sid(domain_id, authority_id, generation, sid, tx_id)

    # --- Binding & Manifestation Operations ---

    def bind_sid(self, sid: int, entity_id: str) -> State:
        """
        Bind an allocated SID to a semantic entity.
        Separated from allocation per spec §20 (IAM-I015).
        """
        new_state = self.state.clone()
        new_state.step += 1

        # SID must have been historically allocated
        if sid not in new_state.H:
            raise InvalidRequestError(f"Cannot bind unallocated SID {sid}")

        if sid in new_state.B:
            raise InvalidRequestError(f"SID {sid} is already bound to entity {new_state.B[sid].entity_id}")

        binding = SemanticBinding(
            sid=sid,
            entity_id=entity_id,
            created_at_step=new_state.step
        )
        new_state.B[sid] = binding
        self.state = new_state
        return self.state

    def manifest_sid(self, sid: int, runtime_handle: str) -> State:
        """
        Associate SID with a physical/runtime manifestation handle.
        Demonstrates Identity/Manifestation separation per spec §21 (IAM-I014).
        """
        new_state = self.state.clone()
        new_state.step += 1

        if sid not in new_state.H:
            raise InvalidRequestError(f"Cannot manifest unallocated SID {sid}")

        if sid not in new_state.M:
            new_state.M[sid] = []

        # Mark previous handles inactive if updating
        for prev in new_state.M[sid]:
            prev.active = False

        record = ManifestationRecord(
            sid=sid,
            runtime_handle=runtime_handle,
            active=True
        )
        new_state.M[sid].append(record)
        self.state = new_state
        return self.state

    def retire_sid(self, sid: int) -> State:
        """
        Retire an SID.
        The SID remains in H and can never be re-allocated (IAM-I010).
        """
        new_state = self.state.clone()
        new_state.step += 1

        if sid not in new_state.H:
            raise InvalidRequestError(f"Cannot retire unallocated SID {sid}")

        # Manifestations deactivated
        if sid in new_state.M:
            for handle in new_state.M[sid]:
                handle.active = False

        self.state = new_state
        return self.state

    # --- Snapshot & Recovery Operations ---

    def snapshot(self) -> Dict[str, Any]:
        """
        Produce a snapshot object.
        Captures H, D, A, P, B, M, Q at current state.
        """
        return {
            "step": self.state.step,
            "genesis_id": self.state.genesis_id,
            "H": set(self.state.H),
            "state_clone": self.state.clone()
        }

    def recover(self, snapshot_data: Dict[str, Any]) -> State:
        """
        Restore state from snapshot, enforcing Snapshot Safety (IAM-I012).
        If current H_live has SIDs beyond snapshot H_snap,
        the restored H MUST contain H_live ∪ H_snap to prevent resurrection/re-allocation.

        Snapshot safety requires more than H monotonicity: for every SID retained in
        H_restored but absent from the snapshot, its provenance record, binding,
        manifestation history, and domain allocation membership MUST also be carried
        forward; otherwise H and P/D would become inconsistent (IAM-I007, IAM-I005).
        """
        restored_state = snapshot_data["state_clone"].clone()

        # Enforce Snapshot Safety (IAM-I012): H_restored = H_live ∪ H_snapshot
        live_h = set(self.state.H)
        restored_state.H = live_h.union(set(snapshot_data["H"]))

        # Carry forward consistency structure for SIDs that survive only via live H.
        for sid in live_h:
            if sid not in restored_state.P and sid in self.state.P:
                restored_state.P[sid] = self.state.P[sid]
            if sid not in restored_state.B and sid in self.state.B:
                restored_state.B[sid] = self.state.B[sid]
            if sid not in restored_state.M and sid in self.state.M:
                restored_state.M[sid] = self.state.M[sid]

        # Carry forward domain allocation membership so IAM-I005 holds.
        for dom_id, live_dom in self.state.D.items():
            if dom_id in restored_state.D:
                restored_state.D[dom_id].allocated_sids |= live_dom.allocated_sids

        restored_state.step = max(self.state.step, snapshot_data["step"]) + 1
        self.state = restored_state
        return self.state

    # --- Contextual Verification ---

    def verify(self, context: VerificationContext, sid: int) -> bool:
        """
        Contextual verification: verify(context, sid).
        Checks:
        - SID is in historical allocation set H
        - Provenance record exists and chains back to context.root_id
        - Authority was active and generation matches
        - Domain matches and contains SID
        """
        if sid not in self.state.H:
            return False

        if sid not in self.state.P:
            return False

        prov = self.state.P[sid]

        # Verify root matches context
        if prov.root_id != context.root_id:
            return False

        # Verify domain contains SID
        if prov.domain_id not in self.state.D:
            return False
        dom = self.state.D[prov.domain_id]
        if not dom.region.contains(sid):
            return False

        # Verify authority chain
        if prov.authority_id not in self.state.A:
            return False
        auth = self.state.A[prov.authority_id]
        if auth.root_id != context.root_id:
            return False

        return True

    # --- General Transition Wrapper ---

    def transition(self, event_name: str, **kwargs) -> Tuple[Optional[State], Optional[str]]:
        """
        T : Σ × Event -> Σ | Error
        Returns (new_state, None) on success or (unmodified_state, error_msg) on failure.
        Ensures atomicity: failed transition does NOT mutate state (Σ' = Σ).
        """
        prev_state = self.state.clone()
        try:
            op = getattr(self, event_name, None)
            if not op:
                return prev_state, f"Unknown event {event_name}"
            new_st = op(**kwargs)
            return new_st, None
        except Exception as e:
            # Revert to exact prior state (Atomicity)
            self.state = prev_state
            return prev_state, str(e)
