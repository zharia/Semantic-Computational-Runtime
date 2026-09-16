use crate::identity::{IncidenceId, ElementId, RelationId};
use crate::role::{Role, Direction};

/// First-class Semantic Incidence connecting an Element to a Relation.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Incidence {
    id: IncidenceId,
    element: ElementId,
    relation: RelationId,
    role: Role,
    direction: Direction,
}

impl Incidence {
    pub fn new(id: IncidenceId, element: ElementId, relation: RelationId, role: Role, direction: Direction) -> Self {
        Self {
            id,
            element,
            relation,
            role,
            direction,
        }
    }

    pub fn id(&self) -> &IncidenceId {
        &self.id
    }

    pub fn element(&self) -> &ElementId {
        &self.element
    }

    pub fn relation(&self) -> &RelationId {
        &self.relation
    }

    pub fn role(&self) -> &Role {
        &self.role
    }

    pub fn direction(&self) -> Direction {
        self.direction
    }

    pub fn set_role(&mut self, role: Role) {
        self.role = role;
    }

    pub fn set_direction(&mut self, direction: Direction) {
        self.direction = direction;
    }
}
