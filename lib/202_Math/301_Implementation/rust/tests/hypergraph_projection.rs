// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

use scr_hypergraph::{ElementId, Hypergraph, RelationId};
use scr_math::project_math_axioms_to_hypergraph;

#[test]
fn test_hypergraph_math_projection() {
    let mut hg = Hypergraph::new();
    let axioms = ["Linearity", "Homogeneity", "Distributivity"];

    project_math_axioms_to_hypergraph("AbstractAlgebra", &axioms, &mut hg).unwrap();

    // Verify domain node
    assert!(hg.get_element(&ElementId("elem:math_domain:AbstractAlgebra".into())).is_some());

    // Verify nullary axiom relations
    for axiom in &axioms {
        let rel_id = RelationId(format!("rel:math_axiom:AbstractAlgebra_{}", axiom));
        let rel = hg.get_relation(&rel_id).unwrap();
        assert!(rel.is_nullary());
        assert_eq!(rel.cardinality(), 0);
    }
}
