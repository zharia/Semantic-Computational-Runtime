use crate::identity::ElementId;
use std::collections::BTreeSet;
use crate::identity::IncidenceId;

/// First-class Semantic Element in \mathcal{H}.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Element {
    id: ElementId,
    name: String,
    incidences: BTreeSet<IncidenceId>,
}

impl Element {
    pub fn new<S: Into<String>>(id: ElementId, name: S) -> Self {
        Self {
            id,
            name: name.into(),
            incidences: BTreeSet::new(),
        }
    }

    pub fn id(&self) -> &ElementId {
        &self.id
    }

    pub fn name(&self) -> &str {
        &self.name
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
