use scr_field::domain::FieldDomain;
use scr_field::field::Field;
use scr_field::hypergraph::project_field_to_hypergraph;
use scr_field::value::{FieldValue, ValueSpace};
use scr_hypergraph::{ElementId, Hypergraph, RelationId};

#[test]
fn test_hypergraph_field_projection() {
    let domain = FieldDomain::new_2d("dom_hg_field", 0.0, 100.0, 0.0, 100.0).unwrap();
    let field = Field::new_analytic(
        "pressure_hg",
        domain,
        ValueSpace::ScalarSpace,
        |p: &[f64]| Ok(FieldValue::Scalar(1013.25 + 0.1 * p[0])),
    );

    let mut graph = Hypergraph::new();
    project_field_to_hypergraph(&field, &mut graph).unwrap();

    // Verify Field element
    let fld_elem = ElementId("elem:field:pressure_hg".to_string());
    assert!(graph.get_element(&fld_elem).is_some());

    // Verify Domain element
    let dom_elem = ElementId("elem:domain:dom_hg_field".to_string());
    assert!(graph.get_element(&dom_elem).is_some());

    // Verify Relations
    let dom_rel = RelationId("rel:field_domain:pressure_hg".to_string());
    assert!(graph.get_relation(&dom_rel).is_some());

    let val_rel = RelationId("rel:field_valspace:pressure_hg".to_string());
    assert!(graph.get_relation(&val_rel).is_some());
}
