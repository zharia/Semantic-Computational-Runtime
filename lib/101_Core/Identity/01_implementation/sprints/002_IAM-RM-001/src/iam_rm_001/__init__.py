"""
IAM-RM-001 Identity Address Space Reference Machine.
"""

from .models import (
    State, IdentitySpace, Domain, DomainState, Authority, AuthorityState,
    Region, ProvenanceRecord, SemanticBinding, ManifestationRecord,
    TransactionRecord, VerificationContext
)
from .machine import IAMReferenceMachine, IAMError, InvalidRequestError, InvariantViolationError
from .invariants import check_all_invariants, InvariantViolation

__all__ = [
    "State", "IdentitySpace", "Domain", "DomainState", "Authority", "AuthorityState",
    "Region", "ProvenanceRecord", "SemanticBinding", "ManifestationRecord",
    "TransactionRecord", "VerificationContext",
    "IAMReferenceMachine", "IAMError", "InvalidRequestError", "InvariantViolationError",
    "check_all_invariants", "InvariantViolation",
]
