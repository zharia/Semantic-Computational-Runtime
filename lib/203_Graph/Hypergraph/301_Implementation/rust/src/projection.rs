use crate::identity::{ElementId, RelationId};
use crate::role::Role;
use crate::hypergraph::Hypergraph;
use crate::error::HypergraphError;
use std::collections::BTreeSet;

/// Projection of \mathcal{H} into an Ordinary Graph G = (V, E)
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct OrdinaryGraph {
    pub vertices: BTreeSet<ElementId>,
    pub edges: Vec<(ElementId, ElementId, RelationId)>,
}

/// Isomorphic bipartite graph G = (V_E \cup V_R, E_I)
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct BipartiteGraph {
    pub element_vertices: BTreeSet<ElementId>,
    pub relation_vertices: BTreeSet<RelationId>,
    pub incidences: Vec<(ElementId, RelationId, Role)>,
}

/// 2-Clique expansion graph disclosing information loss
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct CliqueGraph {
    pub vertices: BTreeSet<ElementId>,
    pub edges: BTreeSet<(ElementId, ElementId)>,
    pub information_lost: Vec<String>,
}

impl Hypergraph {
    /// Project into an ordinary binary graph. Fails if any relation is not strictly binary.
    pub fn to_ordinary_graph(&self) -> Result<OrdinaryGraph, HypergraphError> {
        let mut vertices = BTreeSet::new();
        for elem in self.elements() {
            vertices.insert(elem.id().clone());
        }

        let mut edges = Vec::new();
        for rel in self.relations() {
            let participants = self.relation_participants(rel.id())?;
            if participants.len() != 2 {
                return Err(HypergraphError::InvalidCardinality {
                    expected: 2,
                    found: participants.len(),
                });
            }
            let u = participants[0].0.clone();
            let v = participants[1].0.clone();
            edges.push((u, v, rel.id().clone()));
        }

        Ok(OrdinaryGraph { vertices, edges })
    }

    /// Project isomorphically into a bipartite incidence graph
    pub fn to_bipartite_graph(&self) -> BipartiteGraph {
        let mut element_vertices = BTreeSet::new();
        for elem in self.elements() {
            element_vertices.insert(elem.id().clone());
        }

        let mut relation_vertices = BTreeSet::new();
        for rel in self.relations() {
            relation_vertices.insert(rel.id().clone());
        }

        let mut incidences = Vec::new();
        for inc in self.incidences() {
            incidences.push((inc.element().clone(), inc.relation().clone(), inc.role().clone()));
        }

        BipartiteGraph {
            element_vertices,
            relation_vertices,
            incidences,
        }
    }

    /// Project into a 2-clique expansion graph, formally disclosing information loss
    pub fn to_clique_expansion(&self) -> CliqueGraph {
        let mut vertices = BTreeSet::new();
        for elem in self.elements() {
            vertices.insert(elem.id().clone());
        }

        let mut edges = BTreeSet::new();
        for rel in self.relations() {
            if let Ok(participants) = self.relation_participants(rel.id()) {
                let n = participants.len();
                for i in 0..n {
                    for j in (i + 1)..n {
                        let a = &participants[i].0;
                        let b = &participants[j].0;
                        if a < b {
                            edges.insert((a.clone(), b.clone()));
                        } else {
                            edges.insert((b.clone(), a.clone()));
                        }
                    }
                }
            }
        }

        let information_lost = vec![
            "Relation identities are collapsed into pairwise edges".into(),
            "Multi-way simultaneous association cardinality > 2 is lost".into(),
            "Nullary relations (|I(R)| = 0) cannot be represented".into(),
            "Unary self-relation semantics are omitted".into(),
            "Specific incidence roles and direction orientations are lost".into(),
        ];

        CliqueGraph {
            vertices,
            edges,
            information_lost,
        }
    }
}
