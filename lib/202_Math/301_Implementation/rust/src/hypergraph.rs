// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

use crate::error::{MathError, Result};
use scr_hypergraph::{ElementId, Hypergraph, RelationId};

/// Projects mathematical structures and ambient mathematical axioms into the canonical SCR Hypergraph.
///
/// In accordance with:
/// - MATH-INV-016: Mathematics MUST conform to Core foundational semantics and hypergraph integration.
pub fn project_math_axioms_to_hypergraph(
    domain_name: &str,
    axiom_names: &[&str],
    hypergraph: &mut Hypergraph,
) -> Result<()> {
    // 1. Math Domain Node
    let domain_elem_id = ElementId(format!("elem:math_domain:{}", domain_name));
    if hypergraph.get_element(&domain_elem_id).is_none() {
        hypergraph
            .create_element(domain_elem_id, format!("MathDomain:{}", domain_name))
            .map_err(|e| MathError::SemanticInvalidity(e.to_string()))?;
    }

    // 2. Ambient Nullary Mathematical Axioms (Relations with 0 incidences)
    for axiom in axiom_names {
        let rel_id = RelationId(format!("rel:math_axiom:{}_{}", domain_name, axiom));
        if hypergraph.get_relation(&rel_id).is_none() {
            hypergraph
                .create_relation(rel_id, format!("MathematicalAxiom:{}", axiom))
                .map_err(|e| MathError::SemanticInvalidity(e.to_string()))?;
        }
    }

    Ok(())
}
