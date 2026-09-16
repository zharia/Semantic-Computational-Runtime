use crate::error::RepresentationError;
use crate::persistence::identity::PersistentId;
use crate::persistence::boundary::LifetimeBoundary;
use crate::persistence::durability::DurabilityLevel;
use crate::persistence::manifestation::{PersistentManifestation, CommitRecord};
use std::collections::BTreeMap;

/// Entry in an append-only persistence journal.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct JournalEntry {
    pub sequence: u64,
    pub entry_id: PersistentId,
    pub payload: Vec<u8>,
    pub timestamp_ns: u64,
}

/// Core persistence engine providing atomic persistence, snapshots, journals, and integrity validation.
#[derive(Debug, Default)]
pub struct PersistenceEngine {
    manifestations: BTreeMap<PersistentId, PersistentManifestation>,
    journal: Vec<JournalEntry>,
    next_sequence: u64,
}

impl PersistenceEngine {
    pub fn new() -> Self {
        Self::default()
    }

    /// Stage a new persistent manifestation.
    pub fn persist(
        &mut self,
        id: PersistentId,
        version: u32,
        boundary: LifetimeBoundary,
        durability: DurabilityLevel,
        payload: Vec<u8>,
    ) -> PersistentManifestation {
        let manifestation = PersistentManifestation::new(id.clone(), version, boundary, durability, payload);
        self.manifestations.insert(id, manifestation.clone());
        manifestation
    }

    /// Commit a previously staged manifestation to persistent durability.
    pub fn commit(&mut self, id: &PersistentId) -> Result<CommitRecord, RepresentationError> {
        let manifest = self.manifestations.get_mut(id).ok_or_else(|| {
            RepresentationError::EntityNotFound(id.0.clone())
        })?;

        manifest.committed = true;
        let record = CommitRecord {
            id: id.clone(),
            version: manifest.version,
            timestamp_ns: 1_000,
            checksum: manifest.checksum,
        };
        Ok(record)
    }

    /// Atomically create and commit a snapshot manifestation.
    pub fn snapshot(
        &mut self,
        id: PersistentId,
        version: u32,
        payload: Vec<u8>,
    ) -> CommitRecord {
        let mut manifest = PersistentManifestation::new(
            id.clone(),
            version,
            LifetimeBoundary::SystemRestart,
            DurabilityLevel::CommittedStorageDurability,
            payload,
        );
        manifest.committed = true;
        let checksum = manifest.checksum;
        self.manifestations.insert(id.clone(), manifest);

        CommitRecord {
            id,
            version,
            timestamp_ns: 2_000,
            checksum,
        }
    }

    /// Append a mutation delta to the persistent journal.
    pub fn journal_append(
        &mut self,
        entry_id: PersistentId,
        payload: Vec<u8>,
    ) -> JournalEntry {
        let entry = JournalEntry {
            sequence: self.next_sequence,
            entry_id,
            payload,
            timestamp_ns: 3_000 + self.next_sequence,
        };
        self.next_sequence += 1;
        self.journal.push(entry.clone());
        entry
    }

    /// Load a persistent manifestation by ID.
    pub fn load(&self, id: &PersistentId) -> Result<&PersistentManifestation, RepresentationError> {
        self.manifestations.get(id).ok_or_else(|| {
            RepresentationError::EntityNotFound(id.0.clone())
        })
    }

    /// Validate the integrity of a manifestation. Rejects corrupted data with IntegrityViolation.
    pub fn validate(&self, manifestation: &PersistentManifestation) -> Result<bool, RepresentationError> {
        if manifestation.verify_integrity() {
            Ok(true)
        } else {
            let actual = PersistentManifestation::calculate_checksum(
                &manifestation.id,
                manifestation.version,
                &manifestation.payload,
            );
            Err(RepresentationError::IntegrityViolation {
                expected_checksum: manifestation.checksum,
                computed_checksum: actual,
            })
        }
    }

    /// Restore the payload of a committed manifestation, strictly validating integrity first.
    pub fn restore(&self, id: &PersistentId) -> Result<Vec<u8>, RepresentationError> {
        let manifest = self.load(id)?;
        if !manifest.committed {
            return Err(RepresentationError::PersistenceFailure(format!(
                "Cannot restore uncommitted manifestation '{}'",
                id
            )));
        }
        self.validate(manifest)?;
        Ok(manifest.payload.clone())
    }

    pub fn journal_entries(&self) -> &[JournalEntry] {
        &self.journal
    }
}
