use scr_representation::{
    PersistenceEngine, PersistentId, LifetimeBoundary, DurabilityLevel,
    PersistentManifestation, RecoveryManager, RepresentationError,
};

#[test]
fn test_persistence_staging_and_commit() {
    let mut engine = PersistenceEngine::new();
    let id = PersistentId::new("perm-state-001");
    let payload = b"Authoritative SCR State".to_vec();

    // 1. Stage uncommitted manifestation
    let manifest = engine.persist(
        id.clone(),
        1,
        LifetimeBoundary::SystemRestart,
        DurabilityLevel::CommittedStorageDurability,
        payload.clone(),
    );
    assert!(!manifest.committed);
    assert!(manifest.verify_integrity());

    // Restoring uncommitted manifestation must fail
    assert!(engine.restore(&id).is_err());

    // 2. Commit manifestation
    let commit_rec = engine.commit(&id).unwrap();
    assert_eq!(commit_rec.id, id);
    assert_eq!(commit_rec.version, 1);

    // 3. Restore committed manifestation
    let restored = engine.restore(&id).unwrap();
    assert_eq!(restored, payload);
}

#[test]
fn test_persistence_integrity_and_corruption_detection() {
    let id = PersistentId::new("tamper-test");
    let payload = vec![0x10, 0x20, 0x30, 0x40];

    let mut manifest = PersistentManifestation::new(
        id,
        1,
        LifetimeBoundary::ExecutionSession,
        DurabilityLevel::ProcessBoundaryDurability,
        payload,
    );
    assert!(manifest.verify_integrity());

    // Simulate bit flip / physical media corruption
    manifest.payload[0] ^= 0xFF;
    assert!(!manifest.verify_integrity(), "Tampered payload must fail checksum verification");

    let engine = PersistenceEngine::new();
    match engine.validate(&manifest) {
        Err(RepresentationError::IntegrityViolation { expected_checksum, computed_checksum }) => {
            assert_ne!(expected_checksum, computed_checksum);
        }
        _ => panic!("Expected IntegrityViolation"),
    }
}

#[test]
fn test_snapshot_and_journal_recovery() {
    let mut engine = PersistenceEngine::new();
    let snapshot_id = PersistentId::new("snap-epoch-1");
    let initial_state = b"Initial Base State".to_vec();

    // 1. Take committed base snapshot
    engine.snapshot(snapshot_id.clone(), 1, initial_state.clone());

    // 2. Append sequence of journal deltas
    engine.journal_append(PersistentId::new("delta-1"), b"+Element(e1)".to_vec());
    engine.journal_append(PersistentId::new("delta-2"), b"+Relation(r1)".to_vec());
    engine.journal_append(PersistentId::new("delta-3"), b"+Incidence(i1)".to_vec());

    // 3. Simulate process restart and recover state
    let (base_recovered, journal_recovered) =
        RecoveryManager::recover_with_journal(&engine, &snapshot_id).unwrap();

    assert_eq!(base_recovered, initial_state);
    assert_eq!(journal_recovered.len(), 3);
    assert_eq!(journal_recovered[0].sequence, 0);
    assert_eq!(journal_recovered[1].sequence, 1);
    assert_eq!(journal_recovered[2].sequence, 2);
    assert_eq!(journal_recovered[0].payload, b"+Element(e1)");
}
