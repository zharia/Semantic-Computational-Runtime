use scr_identity::coordinate::CoordinateRegion;
use scr_identity::error::IdentityError;
use scr_identity::invariants::InvariantChecker;
use scr_identity::machine::IAMMachine;

#[test]
fn test_counterexample_1_snapshot_historical_consistency_regression() {
    // Counterexample 1: Snapshot restore originally retained surviving post-snapshot coordinates
    // in H, but dropped their provenance and domain records, breaking IAM-I005, IAM-I007, and IAM-I017.
    // Rule IAM-R017 fixes this by carrying forward complete (P, D, B, M) records.

    let mut machine = IAMMachine::new("GENESIS-SCR-001");
    machine.create_root("root_1").unwrap();
    let space_reg = CoordinateRegion::new(0, 1000).unwrap();
    machine.create_space("space_1", "root_1", space_reg).unwrap();

    let reg_a = CoordinateRegion::new(0, 500).unwrap();
    machine
        .reserve_domain("dom_root_space_1", "dom_a", 10, reg_a)
        .unwrap();

    machine
        .create_authority("auth_1", "root_1", "cred://auth_1/v1", None)
        .unwrap();
    machine.delegate_domain("dom_a", "auth_1").unwrap();
    machine.activate_domain("dom_a").unwrap();

    // Baseline allocation before snapshot
    let sid_0 = machine.reserve_sid("dom_a", 5, "auth_1", 1, "tx_0").unwrap();
    machine.commit_sid("tx_0").unwrap();
    machine.bind_sid(sid_0, "entity_baseline").unwrap();

    // Take snapshot
    let snapshot = machine.snapshot();

    // Post-snapshot allocations
    let sid_1 = machine.reserve_sid("dom_a", 15, "auth_1", 1, "tx_post_1").unwrap();
    machine.commit_sid("tx_post_1").unwrap();
    machine.bind_sid(sid_1, "entity_post_snapshot").unwrap();
    machine.manifest_sid(sid_1, "handle://post_snap_buffer").unwrap();

    // Verify pre-recovery state passes all invariants
    InvariantChecker::assert_all(&machine.state, None).unwrap();

    // Perform rollback/recover to earlier snapshot
    machine.recover(snapshot).unwrap();

    // Under Rule IAM-R017 & IAM-I017:
    // 1. Historical monotonicity holds (sid_1 is preserved in H).
    assert!(machine.state.h.contains(&sid_1));
    assert!(machine.state.h.contains(&sid_0));

    // 2. Crucially, provenance for sid_1 was carried forward:
    assert!(machine.state.p.contains_key(&sid_1));

    // 3. Domain allocated indices record sid_1.index:
    let domain = machine.state.d.get("dom_a").unwrap();
    assert!(domain.allocated_indices.contains(&15));

    // 4. Binding and manifestation are preserved:
    assert!(machine.state.b.contains_key(&sid_1));
    assert!(machine.state.m.contains_key(&sid_1));

    // 5. Invariant IAM-I017 passes unconditionally!
    InvariantChecker::assert_i017_historical_consistency(&machine.state).unwrap();
    InvariantChecker::assert_all(&machine.state, None).unwrap();
}

#[test]
fn test_counterexample_2_transaction_rebind_rejection_regression() {
    // Counterexample 2: Caller re-uses an existing tx_id with a different coordinate,
    // attempting to mutate or re-bind transaction identity.
    // Rule IAM-R018 strictly rejects this with TransactionRebound.

    let mut machine = IAMMachine::new("GENESIS-SCR-001");
    machine.create_root("root_tx").unwrap();
    let space_reg = CoordinateRegion::new(0, 1000).unwrap();
    machine.create_space("space_tx", "root_tx", space_reg).unwrap();

    let reg = CoordinateRegion::new(0, 500).unwrap();
    machine
        .reserve_domain("dom_root_space_tx", "dom_tx", 20, reg)
        .unwrap();

    machine
        .create_authority("auth_tx", "root_tx", "cred://auth_tx/v1", None)
        .unwrap();
    machine.delegate_domain("dom_tx", "auth_tx").unwrap();
    machine.activate_domain("dom_tx").unwrap();

    let tx_id = "tx-shared-uuid";

    // First reservation with index 42
    let sid_1 = machine.reserve_sid("dom_tx", 42, "auth_tx", 1, tx_id).unwrap();
    assert_eq!(sid_1.index, 42);

    // Adversarial replay: Attempt to re-use same tx_id for a different index 99
    let rebind_attempt = machine.reserve_sid("dom_tx", 99, "auth_tx", 1, tx_id);

    match rebind_attempt {
        Err(IdentityError::TransactionRebound { tx_id: id, .. }) => {
            assert_eq!(id, tx_id);
        }
        other => panic!("Expected TransactionRebound error, got {:?}", other),
    }

    // However, idempotent re-reservation of the SAME coordinate under the SAME tx succeeds:
    let idempotent = machine.reserve_sid("dom_tx", 42, "auth_tx", 1, tx_id).unwrap();
    assert_eq!(idempotent, sid_1);
}

#[test]
fn test_authority_generation_fencing_attack() {
    // Rotating authority must invalidate and reject any requests using stale generations.

    let mut machine = IAMMachine::new("GENESIS-SCR-001");
    machine.create_root("root_gen").unwrap();
    let space_reg = CoordinateRegion::new(0, 1000).unwrap();
    machine.create_space("space_gen", "root_gen", space_reg).unwrap();

    let reg = CoordinateRegion::new(0, 500).unwrap();
    machine
        .reserve_domain("dom_root_space_gen", "dom_gen", 30, reg)
        .unwrap();

    machine
        .create_authority("auth_gen", "root_gen", "cred://auth_gen/v1", None)
        .unwrap();
    machine.delegate_domain("dom_gen", "auth_gen").unwrap();
    machine.activate_domain("dom_gen").unwrap();

    // Authority starts at generation 1
    let sid_g1 = machine.reserve_sid("dom_gen", 1, "auth_gen", 1, "tx_g1").unwrap();
    machine.commit_sid("tx_g1").unwrap();
    assert_eq!(sid_g1.generation, 1);

    // Rotate authority to generation 2
    let new_gen = machine.rotate_authority("auth_gen").unwrap();
    assert_eq!(new_gen, 2);

    // Stale allocator attack: Attempt to reserve using generation 1
    let stale_attempt = machine.reserve_sid("dom_gen", 2, "auth_gen", 1, "tx_stale");
    match stale_attempt {
        Err(IdentityError::GenerationMismatch { expected: 2, provided: 1 }) => (),
        other => panic!("Expected GenerationMismatch(expected=2, provided=1), got {:?}", other),
    }

    // Correct generation 2 succeeds
    let sid_g2 = machine.reserve_sid("dom_gen", 2, "auth_gen", 2, "tx_fresh").unwrap();
    assert_eq!(sid_g2.generation, 2);
    machine.commit_sid("tx_fresh").unwrap();
}

#[test]
fn test_overlapping_sibling_domain_rejection() {
    let mut machine = IAMMachine::new("GENESIS-SCR-001");
    machine.create_root("root_overlap").unwrap();
    let space_reg = CoordinateRegion::new(0, 1000).unwrap();
    machine.create_space("space_ov", "root_overlap", space_reg).unwrap();

    let reg_1 = CoordinateRegion::new(0, 500).unwrap();
    machine
        .reserve_domain("dom_root_space_ov", "dom_1", 1, reg_1)
        .unwrap();

    // Overlapping sibling domain [400, 600) must be rejected
    let reg_overlap = CoordinateRegion::new(400, 600).unwrap();
    let overlap_res = machine.reserve_domain("dom_root_space_ov", "dom_conflict", 2, reg_overlap);

    match overlap_res {
        Err(IdentityError::RegionOverlap { .. }) => (),
        other => panic!("Expected RegionOverlap error, got {:?}", other),
    }
}
