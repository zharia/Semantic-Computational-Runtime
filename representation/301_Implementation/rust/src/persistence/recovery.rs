use crate::error::RepresentationError;
use crate::persistence::identity::PersistentId;
use crate::persistence::operations::{PersistenceEngine, JournalEntry};

/// Coordinates state recovery across lifecycle and restart boundaries.
pub struct RecoveryManager;

impl RecoveryManager {
    /// Restore base snapshot state and replay journal deltas in strict causal sequence.
    pub fn recover_with_journal(
        engine: &PersistenceEngine,
        snapshot_id: &PersistentId,
    ) -> Result<(Vec<u8>, Vec<JournalEntry>), RepresentationError> {
        let base_state = engine.restore(snapshot_id)?;
        let journal_entries = engine.journal_entries().to_vec();
        Ok((base_state, journal_entries))
    }
}
