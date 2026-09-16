use crate::authority::Authority;
use crate::coordinate::{CoordinateRegion, SidCoordinate};
use crate::domain::Domain;
use std::collections::{BTreeMap, BTreeSet};

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct IdentitySpace {
    pub id: String,
    pub root_authority: String,
    pub coordinate_space: CoordinateRegion,
    pub geometry: String,
    pub policy: String,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ProvenanceRecord {
    pub sid: SidCoordinate,
    pub genesis_id: String,
    pub root_id: String,
    pub authority_id: String,
    pub generation: u32,
    pub domain_id: String,
    pub tx_id: String,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SemanticBinding {
    pub sid: SidCoordinate,
    pub entity_id: String,
    pub created_at_step: u64,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ManifestationRecord {
    pub sid: SidCoordinate,
    pub runtime_handle: String,
    pub active: bool,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum TransactionStatus {
    Reserved,
    Committed,
    Failed,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct TransactionRecord {
    pub tx_id: String,
    pub sid: SidCoordinate,
    pub domain_id: String,
    pub authority_id: String,
    pub generation: u32,
    pub status: TransactionStatus,
}

/// Formal State Model: Σ = (I, D, A, H, P, B, M, Q)
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct State {
    /// I: Identity Spaces
    pub i: BTreeMap<String, IdentitySpace>,
    /// D: Allocation Domains
    pub d: BTreeMap<String, Domain>,
    /// A: Authorities
    pub a: BTreeMap<String, Authority>,
    /// H: Historical Allocation Set (Monotonically non-decreasing)
    pub h: BTreeSet<SidCoordinate>,
    /// P: Cryptographic Provenance Records (sid -> ProvenanceRecord)
    pub p: BTreeMap<SidCoordinate, ProvenanceRecord>,
    /// B: Semantic Bindings (sid -> SemanticBinding)
    pub b: BTreeMap<SidCoordinate, SemanticBinding>,
    /// M: Manifestations (sid -> Vec<ManifestationRecord>)
    pub m: BTreeMap<SidCoordinate, Vec<ManifestationRecord>>,
    /// Q: Transaction Records (tx_id -> TransactionRecord)
    pub q: BTreeMap<String, TransactionRecord>,
    /// Active Reservations: sid -> tx_id
    pub reservations: BTreeMap<SidCoordinate, String>,
    /// Global logical step counter
    pub step: u64,
    /// Genesis ID
    pub genesis_id: String,
}

impl State {
    pub fn new(genesis_id: impl Into<String>) -> Self {
        Self {
            i: BTreeMap::new(),
            d: BTreeMap::new(),
            a: BTreeMap::new(),
            h: BTreeSet::new(),
            p: BTreeMap::new(),
            b: BTreeMap::new(),
            m: BTreeMap::new(),
            q: BTreeMap::new(),
            reservations: BTreeMap::new(),
            step: 0,
            genesis_id: genesis_id.into(),
        }
    }
}
