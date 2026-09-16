use scr_representation::{
    SemanticValue, SchemaDescriptor, CanonicalSerializer, CanonicalDeserializer,
    HypergraphSerializer, RepresentationError,
};
use scr_hypergraph::{Hypergraph, ElementId, RelationId, IncidenceId, Role, Direction};
use std::collections::BTreeMap;

#[test]
fn test_scalar_type_preservation() {
    let schema = SchemaDescriptor::new("test.scalars", 1, 1, "Scalar test schema");

    let mut map = BTreeMap::new();
    map.insert("null_val".into(), SemanticValue::Null);
    map.insert("bool_true".into(), SemanticValue::Bool(true));
    map.insert("bool_false".into(), SemanticValue::Bool(false));
    map.insert("int_val".into(), SemanticValue::Int64(-9876543210));
    map.insert("float_val".into(), SemanticValue::Float64(3.141592653589793));
    map.insert("string_val".into(), SemanticValue::String("Semantic Computational Runtime".into()));
    map.insert("bytes_val".into(), SemanticValue::Bytes(vec![0xDE, 0xAD, 0xBE, 0xEF]));

    let original = SemanticValue::Map(map);

    let bytes = CanonicalSerializer::serialize(&schema, &original).unwrap();
    let (decoded_schema, reconstructed) = CanonicalDeserializer::deserialize(&bytes).unwrap();

    assert_eq!(decoded_schema.id.0, "test.scalars");
    assert_eq!(decoded_schema.version.0, 1);
    assert_eq!(original, reconstructed);
}

#[test]
fn test_canonical_determinism() {
    let schema = SchemaDescriptor::new("test.determinism", 1, 1, "Determinism test");

    // Insert keys in different orders
    let mut map1 = BTreeMap::new();
    map1.insert("alpha".into(), SemanticValue::Int64(1));
    map1.insert("beta".into(), SemanticValue::Int64(2));
    map1.insert("gamma".into(), SemanticValue::Int64(3));

    let mut map2 = BTreeMap::new();
    map2.insert("gamma".into(), SemanticValue::Int64(3));
    map2.insert("alpha".into(), SemanticValue::Int64(1));
    map2.insert("beta".into(), SemanticValue::Int64(2));

    let val1 = SemanticValue::Map(map1);
    let val2 = SemanticValue::Map(map2);

    let bytes1 = CanonicalSerializer::serialize(&schema, &val1).unwrap();
    let bytes2 = CanonicalSerializer::serialize(&schema, &val2).unwrap();

    assert_eq!(
        bytes1, bytes2,
        "Canonical serialization must produce bit-for-bit identical byte outputs"
    );
}

#[test]
fn test_floating_point_canonicalization() {
    let schema = SchemaDescriptor::new("test.float", 1, 1, "Float canonicalization");

    // -0.0 and +0.0 must serialize to identical canonical representations
    let v_pos_zero = SemanticValue::Float64(0.0);
    let v_neg_zero = SemanticValue::Float64(-0.0);

    let b_pos = CanonicalSerializer::serialize(&schema, &v_pos_zero).unwrap();
    let b_neg = CanonicalSerializer::serialize(&schema, &v_neg_zero).unwrap();

    assert_eq!(
        b_pos, b_neg,
        "Negative zero must normalize to positive zero in canonical serialization"
    );
}

#[test]
fn test_malformed_input_rejection() {
    // 1. Garbage header
    let garbage = b"BAD_MAGIC_HEADER_DATA";
    match CanonicalDeserializer::deserialize(garbage) {
        Err(RepresentationError::MalformedInput(reason)) => {
            assert!(reason.contains("Invalid magic header"));
        }
        _ => panic!("Expected MalformedInput for invalid magic"),
    }

    // 2. Truncated buffer
    let truncated = b"SCRS";
    assert!(CanonicalDeserializer::deserialize(truncated).is_err());
}

#[test]
fn test_hypergraph_lossless_roundtrip_with_nullary_relation() {
    let mut hg = Hypergraph::new();

    // 1. Element
    let e1 = ElementId::new("elem-alpha");
    hg.create_element(e1.clone(), "AlphaNode").unwrap();

    // 2. Unary Relation
    let r1 = RelationId::new("rel-unary");
    hg.create_relation(r1.clone(), "UnaryRelation").unwrap();
    hg.attach_incidence(
        IncidenceId::new("inc-1"),
        &e1,
        &r1,
        Role::Subject,
        Direction::Outgoing,
    ).unwrap();

    // 3. Nullary Relation (ZERO incidences - strict HGT-001 / Section 102_spec test!)
    let r_nullary = RelationId::new("rel-ambient-field");
    hg.create_relation(r_nullary.clone(), "AmbientGravityField").unwrap();

    assert_eq!(hg.element_count(), 1);
    assert_eq!(hg.relation_count(), 2);
    assert_eq!(hg.incidence_count(), 1);
    assert!(hg.get_relation(&r_nullary).unwrap().is_nullary());

    // Serialize to canonical bytes
    let bytes = HypergraphSerializer::to_bytes(&hg).unwrap();
    assert!(!bytes.is_empty());

    // Deserialize back into Hypergraph
    let reconstructed = HypergraphSerializer::from_bytes(&bytes).unwrap();

    assert_eq!(reconstructed.element_count(), 1);
    assert_eq!(reconstructed.relation_count(), 2);
    assert_eq!(reconstructed.incidence_count(), 1);

    // Verify nullary relation survived losslessly
    let rec_nullary = reconstructed.get_relation(&r_nullary).unwrap();
    assert_eq!(rec_nullary.name(), "AmbientGravityField");
    assert!(rec_nullary.is_nullary(), "Nullary relation must remain nullary after roundtrip");

    // Verify incidence survived with exact role and direction
    let rec_inc = reconstructed.get_incidence(&IncidenceId::new("inc-1")).unwrap();
    assert_eq!(rec_inc.role(), &Role::Subject);
    assert_eq!(rec_inc.direction(), Direction::Outgoing);
    assert_eq!(rec_inc.element(), &e1);
    assert_eq!(rec_inc.relation(), &r1);
}
