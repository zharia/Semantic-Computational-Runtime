use crate::identity::{RelationId, IncidenceId};
use std::collections::BTreeSet;

/// First-class Semantic Relation in \mathcal{H}.
///
/// Supports arbitrary cardinality, including nullary relations (|I(R)| = 0).
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Relation {
    id: RelationId,
    name: String,
    incidences: BTreeSet<IncidenceId>,
}

impl Relation {
    /// Create a new relation. Initially nullary (|I(R)| = 0).
    pub fn new<S: Into<String>>(id: RelationId, name: S) -> Self {
        Self {
            id,
            name: name.into(),
            incidences: BTreeSet::new(),
        }
    }

    pub fn id(&self) -> &RelationId {
        &self.id
    }

    pub fn name(&self) -> &str {
        &self.name
    }

    pub fn cardinality(&self) -> usize {
        self.incidences.len()
    }

    pub fn is_nullary(&self) -> bool {
        self.incidences.is_empty()
    }

    pub fn is_unary(&self) -> bool {
        self.incidences.len() == 1
    }

    pub fn is_binary(&self) -> bool {
        self.incidences.len() == 2
    }

    pub fn incidences(&self) -> &BTreeSet<IncidenceId> {
        &self.incidences
    }

    pub(crate) fn attach_incidence(&mut self, inc_id: IncidenceId) {
        self.incidences.insert(inc_id);
    }

    pub(crate) fn detach_incidence(&mut self, inc_id: &IncidenceId) {
        self.incidences.remove(inc_id);
    }
}
