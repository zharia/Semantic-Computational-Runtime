use scr_identity::coordinate::CoordinateRegion;
use scr_identity::invariants::InvariantChecker;
use scr_identity::machine::IAMMachine;

#[test]
fn test_all_17_normative_invariants_conformance() {
    let mut machine = IAMMachine::new("GENESIS-SCR-001");

    // 1. IAM-I001: Root Uniqueness & Space Creation
    machine.create_root("root_prime").unwrap();
    InvariantChecker::assert_i001_root_uniqueness(&machine.state).unwrap();

    let space_reg = CoordinateRegion::new(0, 1000).unwrap();
    machine.create_space("space_0", "root_prime", space_reg).unwrap();

    // 2. IAM-I002 & IAM-I003: Domain Containment & Disjointness
    let reg_a = CoordinateRegion::new(0, 500).unwrap();
    let reg_b = CoordinateRegion::new(500, 1000).unwrap();

    machine
        .reserve_domain("dom_root_space_0", "dom_a", 1, reg_a)
        .unwrap();
    machine
        .reserve_domain("dom_root_space_0", "dom_b", 2, reg_b)
        .unwrap();

    InvariantChecker::assert_i002_domain_disjointness(&machine.state).unwrap();
    InvariantChecker::assert_i003_domain_containment(&machine.state).unwrap();

    // 3. Authorities & Delegation
    machine
        .create_authority("auth_alpha", "root_prime", "cred://alpha/v1", None)
        .unwrap();
    machine.delegate_domain("dom_a", "auth_alpha").unwrap();
    machine.activate_domain("dom_a").unwrap();

    // 4. Reserve & Commit Allocations
    let prev_state = machine.snapshot();

    let tx_1 = "tx-alloc-001";
    let sid_1 = machine.reserve_sid("dom_a", 10, "auth_alpha", 1, tx_1).unwrap();
    assert_eq!(sid_1.domain_id, 1);
    assert_eq!(sid_1.index, 10);
    assert_eq!(sid_1.generation, 1);

    let committed_sid = machine.commit_sid(tx_1).unwrap();
    assert_eq!(committed_sid, sid_1);

    let tx_2 = "tx-alloc-002";
    let sid_2 = machine.reserve_sid("dom_a", 20, "auth_alpha", 1, tx_2).unwrap();
    let committed_sid_2 = machine.commit_sid(tx_2).unwrap();
    assert_eq!(committed_sid_2, sid_2);

    // 5. IAM-I004: Allocation Containment
    InvariantChecker::assert_i004_allocation_containment(&machine.state).unwrap();

    // 6. IAM-I005: Allocation Injectivity
    InvariantChecker::assert_i005_allocation_injectivity(&machine.state).unwrap();

    // 7. IAM-I006: Authority Containment
    InvariantChecker::assert_i006_authority_containment(&machine.state).unwrap();

    // 8. IAM-I007: Cryptographic Provenance
    InvariantChecker::assert_i007_cryptographic_provenance(&machine.state).unwrap();

    // 9. IAM-I008: Generation Validity
    InvariantChecker::assert_i008_generation_validity(&machine.state).unwrap();

    // 10. IAM-I009: Historical Monotonicity
    InvariantChecker::assert_i009_historical_monotonicity(&machine.state, &prev_state).unwrap();

    // 11. IAM-I010: Durable Non-Reuse
    InvariantChecker::assert_i010_durable_non_reuse(&machine.state).unwrap();

    // 12. IAM-I014 & IAM-I015: Manifestation & Binding Separation
    machine.bind_sid(sid_1, "entity_sensor_temperature").unwrap();
    machine.manifest_sid(sid_1, "handle://gpu_buffer/0xdeadbeef").unwrap();
    InvariantChecker::assert_i014_manifestation_separation(&machine.state).unwrap();
    InvariantChecker::assert_i015_binding_separation(&machine.state).unwrap();

    // 13. IAM-I016: Transaction Idempotence
    let idempotent_replay = machine.commit_sid(tx_1).unwrap();
    assert_eq!(idempotent_replay, sid_1);
    InvariantChecker::assert_i016_transaction_idempotence(&machine.state).unwrap();

    // 14. IAM-I017: Historical Consistency
    InvariantChecker::assert_i017_historical_consistency(&machine.state).unwrap();

    // 15. IAM-I011 & IAM-I012: Snapshot Safety and Crash Monotonicity
    let snapshot = machine.snapshot();
    let pre_crash = machine.snapshot();
    machine.recover(snapshot).unwrap();

    InvariantChecker::assert_i011_crash_monotonicity(&machine.state, &pre_crash).unwrap();
    InvariantChecker::assert_i012_snapshot_safety(&machine.state).unwrap();
    InvariantChecker::assert_i013_contextual_resolution(&machine.state).unwrap();

    // Full Audit
    InvariantChecker::assert_all(&machine.state, Some(&pre_crash)).unwrap();
}
