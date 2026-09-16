use scr_application::adapter::ApplicationAdapter;
use scr_application::module::ApplicationModule;
use scr_application::operation::SemanticOperation;
use scr_application::port::{ApplicationPort, PortKind};
use scr_application::provider::ApplicationProvider;
use scr_application::service::ApplicationService;

#[test]
fn test_hexagonal_port_adapter_provider_boundary() {
    let mut module = ApplicationModule::new("mod_storage", "StorageModule");

    // 1. Service with Operation
    let mut srv = ApplicationService::new("srv_state_store", "StateStoreService");
    let op_persist = SemanticOperation::new("op_persist", "PersistState", "Boolean")
        .with_parameter("state_blob", "Bytes", true);
    srv.register_operation(op_persist);
    module.register_service(srv);

    // 2. Outbound Port
    let port_store = ApplicationPort::new_outbound(
        "port_storage_out",
        "StorageOutboundPort",
        PortKind::Persistence,
        "kv_store_contract_v1",
    );
    module.register_port(port_store);

    // 3. Provider A: RocksDB
    let provider_rocks = ApplicationProvider::new("prv_rocks", "RocksDBProvider", "Persistence")
        .with_capability("DurableKV");

    // 4. Adapter A connecting Port to Provider A
    let adapter_rocks = ApplicationAdapter::new(
        "adp_rocks",
        "RocksDBAdapter",
        "port_storage_out",
        "rocksdb_c_api",
        Some(provider_rocks.id.clone()),
    );
    module.register_adapter(adapter_rocks);

    assert_eq!(module.adapters.len(), 1);
    assert_eq!(module.adapters.get("adp_rocks").unwrap().port_id, "port_storage_out");

    // 5. Provider Substitution: Swap with Provider B (LMDB) without modifying Service
    let provider_lmdb = ApplicationProvider::new("prv_lmdb", "LMDBProvider", "Persistence")
        .with_capability("DurableKV");
    let adapter_lmdb = ApplicationAdapter::new(
        "adp_lmdb",
        "LMDBAdapter",
        "port_storage_out",
        "lmdb_c_api",
        Some(provider_lmdb.id.clone()),
    );
    module.register_adapter(adapter_lmdb);

    assert_eq!(module.adapters.len(), 2);
    // Service remains completely unmodified and identical
    let srv_ref = module.services.get("srv_state_store").unwrap();
    assert!(srv_ref.operations.contains_key("op_persist"));
}
