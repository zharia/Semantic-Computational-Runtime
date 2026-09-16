use crate::identity::{ElementId, RelationId, IncidenceId};
use crate::element::Element;
use crate::relation::Relation;
use crate::incidence::Incidence;
use crate::role::{Role, Direction};
use crate::error::HypergraphError;

use std::collections::BTreeMap;

/// Canonical Carrier for a Semantic Hypergraph \mathcal{H} = (E, R, I, \rho).
#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct Hypergraph {
    elements: BTreeMap<ElementId, Element>,
    relations: BTreeMap<RelationId, Relation>,
    incidences: BTreeMap<IncidenceId, Incidence>,
}

impl Hypergraph {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn element_count(&self) -> usize {
        self.elements.len()
    }

    pub fn relation_count(&self) -> usize {
        self.relations.len()
    }

    pub fn incidence_count(&self) -> usize {
        self.incidences.len()
    }

    pub fn is_empty(&self) -> bool {
        self.elements.is_empty() && self.relations.is_empty()
    }

    // ------------------------------------------------------------------------
    // Elements
    // ------------------------------------------------------------------------

    pub fn create_element<S: Into<String>>(&mut self, id: ElementId, name: S) -> Result<&Element, HypergraphError> {
        if self.elements.contains_key(&id) {
            return Err(HypergraphError::DuplicateElement(id.0));
        }
        let element = Element::new(id.clone(), name);
        self.elements.insert(id.clone(), element);
        Ok(self.elements.get(&id).unwrap())
    }

    pub fn get_element(&self, id: &ElementId) -> Option<&Element> {
        self.elements.get(id)
    }

    pub fn remove_element(&mut self, id: &ElementId) -> Result<Element, HypergraphError> {
        let elem = self.elements.remove(id)
            .ok_or_else(|| HypergraphError::ElementNotFound(id.0.clone()))?;

        // Detach all incident relations
        for inc_id in elem.incidences() {
            if let Some(inc) = self.incidences.remove(inc_id) {
                if let Some(rel) = self.relations.get_mut(inc.relation()) {
                    rel.detach_incidence(inc_id);
                }
            }
        }

        Ok(elem)
    }

    // ------------------------------------------------------------------------
    // Relations
    // ------------------------------------------------------------------------

    pub fn create_relation<S: Into<String>>(&mut self, id: RelationId, name: S) -> Result<&Relation, HypergraphError> {
        if self.relations.contains_key(&id) {
            return Err(HypergraphError::DuplicateRelation(id.0));
        }
        let relation = Relation::new(id.clone(), name);
        self.relations.insert(id.clone(), relation);
        Ok(self.relations.get(&id).unwrap())
    }

    pub fn get_relation(&self, id: &RelationId) -> Option<&Relation> {
        self.relations.get(id)
    }

    pub fn remove_relation(&mut self, id: &RelationId) -> Result<Relation, HypergraphError> {
        let rel = self.relations.remove(id)
            .ok_or_else(|| HypergraphError::RelationNotFound(id.0.clone()))?;

        // Detach all incident elements
        for inc_id in rel.incidences() {
            if let Some(inc) = self.incidences.remove(inc_id) {
                if let Some(elem) = self.elements.get_mut(inc.element()) {
                    elem.detach_incidence(inc_id);
                }
            }
        }

        Ok(rel)
    }

    // ------------------------------------------------------------------------
    // Incidences
    // ------------------------------------------------------------------------

    pub fn attach_incidence(
        &mut self,
        id: IncidenceId,
        elem_id: &ElementId,
        rel_id: &RelationId,
        role: Role,
        direction: Direction,
    ) -> Result<&Incidence, HypergraphError> {
        if self.incidences.contains_key(&id) {
            return Err(HypergraphError::DuplicateIncidence(id.0));
        }
        if !self.elements.contains_key(elem_id) {
            return Err(HypergraphError::ElementNotFound(elem_id.0.clone()));
        }
        if !self.relations.contains_key(rel_id) {
            return Err(HypergraphError::RelationNotFound(rel_id.0.clone()));
        }

        let inc = Incidence::new(id.clone(), elem_id.clone(), rel_id.clone(), role, direction);
        self.incidences.insert(id.clone(), inc);

        self.elements.get_mut(elem_id).unwrap().attach_incidence(id.clone());
        self.relations.get_mut(rel_id).unwrap().attach_incidence(id.clone());

        Ok(self.incidences.get(&id).unwrap())
    }

    pub fn detach_incidence(&mut self, id: &IncidenceId) -> Result<Incidence, HypergraphError> {
        let inc = self.incidences.remove(id)
            .ok_or_else(|| HypergraphError::IncidenceNotFound(id.0.clone()))?;

        if let Some(elem) = self.elements.get_mut(inc.element()) {
            elem.detach_incidence(id);
        }
        if let Some(rel) = self.relations.get_mut(inc.relation()) {
            rel.detach_incidence(id);
        }

        Ok(inc)
    }

    pub fn get_incidence(&self, id: &IncidenceId) -> Option<&Incidence> {
        self.incidences.get(id)
    }

    pub fn relation_participants(&self, rel_id: &RelationId) -> Result<Vec<(ElementId, Role, Direction)>, HypergraphError> {
        let rel = self.relations.get(rel_id)
            .ok_or_else(|| HypergraphError::RelationNotFound(rel_id.0.clone()))?;

        let mut out = Vec::new();
        for inc_id in rel.incidences() {
            if let Some(inc) = self.incidences.get(inc_id) {
                out.push((inc.element().clone(), inc.role().clone(), inc.direction()));
            }
        }
        Ok(out)
    }

    pub fn elements(&self) -> impl Iterator<Item = &Element> {
        self.elements.values()
    }

    pub fn relations(&self) -> impl Iterator<Item = &Relation> {
        self.relations.values()
    }

    pub fn incidences(&self) -> impl Iterator<Item = &Incidence> {
        self.incidences.values()
    }
}
