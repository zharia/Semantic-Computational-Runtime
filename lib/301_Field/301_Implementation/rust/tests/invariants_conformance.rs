use scr_field::boundary::BoundaryCondition;
use scr_field::domain::{FieldDomain, FieldDomainKind};
use scr_field::field::Field;
use scr_field::hypergraph::project_field_to_hypergraph;
use scr_field::operators::linear_combination;
use scr_field::value::{FieldValue, ValueSpace};
use scr_hypergraph::{ElementId, Hypergraph};

#[test]
fn test_field_invariants_conformance() {
    // FIELD-INV-001: Domain Identity
    let domain = FieldDomain::new_2d("domain_planar", -10.0, 10.0, -10.0, 10.0).unwrap();
    assert_eq!(domain.dimension, 2);
    assert_eq!(domain.kind, FieldDomainKind::ContinuousEuclidean);
    assert!(domain.contains(&[0.0, 0.0]));
    assert!(!domain.contains(&[15.0, 0.0]));

    // FIELD-INV-002: Value Identity
    let val_scalar = FieldValue::Scalar(42.0);
    assert_eq!(val_scalar.space(), ValueSpace::ScalarSpace);
    let val_vec3 = FieldValue::Vector3([1.0, 2.0, 3.0]);
    assert_eq!(val_vec3.space(), ValueSpace::VectorSpace(3));

    // FIELD-INV-003: Domain/Value Coherence
    let analytic_field = Field::new_analytic(
        "temperature_field",
        domain.clone(),
        ValueSpace::ScalarSpace,
        |p: &[f64]| {
            // Temperature profile: T(x, y) = 100 - (x^2 + y^2)
            Ok(FieldValue::Scalar(100.0 - (p[0] * p[0] + p[1] * p[1])))
        },
    );
    let eval_origin = analytic_field.evaluate(&[0.0, 0.0]).unwrap();
    assert_eq!(eval_origin, FieldValue::Scalar(100.0));
    assert_eq!(eval_origin.space(), ValueSpace::ScalarSpace);

    // Dimension mismatch must be caught
    let err_eval = analytic_field.evaluate(&[0.0, 0.0, 0.0]);
    assert!(err_eval.is_err());

    // FIELD-INV-004: Representation Independence
    // The same semantic field evaluated via discrete grid approximates the analytic ground truth
    let grid_res = [21, 21];
    let mut grid_values = Vec::with_capacity(21 * 21);
    for y_idx in 0..21 {
        for x_idx in 0..21 {
            let x = -10.0 + (x_idx as f64) * 1.0;
            let y = -10.0 + (y_idx as f64) * 1.0;
            grid_values.push(100.0 - (x * x + y * y));
        }
    }
    let grid_field = Field::new_grid_2d("temp_grid", domain.clone(), grid_res, grid_values).unwrap();

    // Compare analytic vs grid at an interior point (x=3.5, y=2.5)
    let test_point = [3.5, 2.5];
    let analytic_val = analytic_field.evaluate(&test_point).unwrap().as_scalar().unwrap();
    let grid_val = grid_field.evaluate(&test_point).unwrap().as_scalar().unwrap();
    let diff = (analytic_val - grid_val).abs();
    // Bilinear interpolation on quadratic surface has small bounded error <= 0.5
    assert!(diff < 0.6, "Discretization error {} exceeds tolerance", diff);

    // FIELD-INV-006: Boundary Semantics & Coordinate Integrity
    let mut clamped_field = analytic_field.clone();
    clamped_field.boundary = BoundaryCondition::Clamped;
    // Querying at (15.0, 0.0) outside [-10, 10] gets clamped to (10.0, 0.0) -> T = 100 - 100 = 0.0
    let clamped_val = clamped_field.evaluate(&[15.0, 0.0]).unwrap().as_scalar().unwrap();
    assert_eq!(clamped_val, 0.0);

    // FIELD-INV-013: Composition Integrity
    let field_b = Field::new_analytic("ambient", domain.clone(), ValueSpace::ScalarSpace, |_| {
        Ok(FieldValue::Scalar(10.0))
    });
    let composite = linear_combination(&analytic_field, 1.0, &field_b, 0.5).unwrap();
    let comp_val = composite.evaluate(&[0.0, 0.0]).unwrap().as_scalar().unwrap();
    // 100.0 * 1.0 + 10.0 * 0.5 = 105.0
    assert_eq!(comp_val, 105.0);

    // FIELD-INV-015: Hypergraph Identity
    let mut graph = Hypergraph::new();
    project_field_to_hypergraph(&analytic_field, &mut graph).unwrap();
    let fld_elem = ElementId("elem:field:temperature_field".to_string());
    assert!(graph.get_element(&fld_elem).is_some());
    let dom_elem = ElementId("elem:domain:domain_planar".to_string());
    assert!(graph.get_element(&dom_elem).is_some());
}
