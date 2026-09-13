"""
IAM-RM-001 Models: State Σ = (I, D, A, H, P, B, M, Q)
Formal State representations for Identity Address Space Reference Machine.
"""

from __future__ import annotations
from dataclasses import dataclass, field
from enum import Enum
from typing import Dict, List, Optional, Set, Tuple, Any
import copy


class DomainState(Enum):
    FREE = "FREE"
    RESERVED = "RESERVED"
    DELEGATED = "DELEGATED"
    ACTIVE = "ACTIVE"
    REVOKED = "REVOKED"
    RETIRED = "RETIRED"


class AuthorityState(Enum):
    ACTIVE = "ACTIVE"
    SUSPENDED = "SUSPENDED"
    REVOKED = "REVOKED"


@dataclass(frozen=True)
class Region:
    """Interval [low, high) on the coordinate space."""
    low: int
    high: int

    def __post_init__(self):
        if self.low >= self.high:
            raise ValueError(f"Invalid region: low ({self.low}) must be < high ({self.high})")

    def contains(self, sid: int) -> bool:
        return self.low <= sid < self.high

    def is_subset_of(self, other: Region) -> bool:
        return self.low >= other.low and self.high <= other.high

    def overlaps(self, other: Region) -> bool:
        return max(self.low, other.low) < min(self.high, other.high)

    def intersection(self, other: Region) -> Optional[Region]:
        l = max(self.low, other.low)
        h = min(self.high, other.high)
        if l < h:
            return Region(l, h)
        return None

    def size(self) -> int:
        return self.high - self.low

    def __repr__(self) -> str:
        return f"[{self.low}, {self.high})"


@dataclass
class IdentitySpace:
    id: str
    root_authority: str
    coordinate_space: Region
    geometry: str = "linear_interval"
    policy: str = "durable_non_reuse"


@dataclass
class Domain:
    id: str
    parent: Optional[str]
    region: Region
    state: DomainState
    authority: Optional[str]
    generation: int = 1
    allocated_sids: Set[int] = field(default_factory=set)


@dataclass
class Authority:
    id: str
    generation: int
    state: AuthorityState
    credential_ref: str
    root_id: str
    parent_authority: Optional[str] = None


@dataclass
class ProvenanceRecord:
    sid: int
    genesis_id: str
    root_id: str
    authority_id: str
    generation: int
    domain_id: str
    tx_id: str


@dataclass
class SemanticBinding:
    sid: int
    entity_id: str
    created_at_step: int


@dataclass
class ManifestationRecord:
    sid: int
    runtime_handle: str
    active: bool = True


@dataclass
class TransactionRecord:
    tx_id: str
    sid: int
    domain_id: str
    authority_id: str
    generation: int
    status: str  # "RESERVED", "COMMITTED", "FAILED"


@dataclass
class VerificationContext:
    root_id: str
    identity_space_id: str
    geometry: str = "linear_interval"
    verification_policy: str = "strict_provenance"
    history_view: Set[int] = field(default_factory=set)


@dataclass
class State:
    """
    Formal State Model: Σ = (I, D, A, H, P, B, M, Q)
    """
    # I: Identity Spaces
    I: Dict[str, IdentitySpace] = field(default_factory=dict)
    # D: Allocation Domains
    D: Dict[str, Domain] = field(default_factory=dict)
    # A: Authorities
    A: Dict[str, Authority] = field(default_factory=dict)
    # H: Historical Allocation State (Monotonic set of SIDs allocated)
    H: Set[int] = field(default_factory=set)
    # P: Cryptographic Provenance (SID -> ProvenanceRecord)
    P: Dict[int, ProvenanceRecord] = field(default_factory=dict)
    # B: Semantic Bindings (SID -> SemanticBinding)
    B: Dict[int, SemanticBinding] = field(default_factory=dict)
    # M: Manifestations (SID -> List[ManifestationRecord])
    M: Dict[int, List[ManifestationRecord]] = field(default_factory=dict)
    # Q: Outstanding Reservations & Transactions (tx_id -> TransactionRecord)
    Q: Dict[str, TransactionRecord] = field(default_factory=dict)

    # Active reservations: sid -> tx_id
    reservations: Dict[int, str] = field(default_factory=dict)
    
    # Global step counter
    step: int = 0
    # Genesis ID
    genesis_id: str = "GENESIS-001"

    def clone(self) -> State:
        return copy.deepcopy(self)
