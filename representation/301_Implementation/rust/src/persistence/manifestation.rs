use crate::persistence::identity::PersistentId;
use crate::persistence::boundary::LifetimeBoundary;
use crate::persistence::durability::DurabilityLevel;

/// Concrete manifestation of persistent state carrying verification checksums and durability metadata.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct PersistentManifestation {
    pub id: PersistentId,
    pub version: u32,
    pub boundary: LifetimeBoundary,
    pub durability: DurabilityLevel,
    pub payload: Vec<u8>,
    pub checksum: u64,
    pub committed: bool,
}

impl PersistentManifestation {
    pub fn new(
        id: PersistentId,
        version: u32,
        boundary: LifetimeBoundary,
        durability: DurabilityLevel,
        payload: Vec<u8>,
    ) -> Self {
        let checksum = Self::calculate_checksum(&id, version, &payload);
        Self {
            id,
            version,
            boundary,
            durability,
            payload,
            checksum,
            committed: false,
        }
    }

    /// Calculate deterministic 64-bit FNV-1a hash over ID, version, and payload.
    pub fn calculate_checksum(id: &PersistentId, version: u32, payload: &[u8]) -> u64 {
        const FNV_OFFSET: u64 = 0xcbf29ce484222325;
        const FNV_PRIME: u64 = 0x100000001b3;

        let mut hash = FNV_OFFSET;
        for byte in id.0.as_bytes() {
            hash ^= *byte as u64;
            hash = hash.wrapping_mul(FNV_PRIME);
        }
        for byte in &version.to_le_bytes() {
            hash ^= *byte as u64;
            hash = hash.wrapping_mul(FNV_PRIME);
        }
        for byte in payload {
            hash ^= *byte as u64;
            hash = hash.wrapping_mul(FNV_PRIME);
        }
        hash
    }

    /// Check if the manifest payload matches its recorded integrity checksum.
    pub fn verify_integrity(&self) -> bool {
        self.checksum == Self::calculate_checksum(&self.id, self.version, &self.payload)
    }
}

/// A formal record certifying that a persistent manifestation was committed to storage.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct CommitRecord {
    pub id: PersistentId,
    pub version: u32,
    pub timestamp_ns: u64,
    pub checksum: u64,
}
