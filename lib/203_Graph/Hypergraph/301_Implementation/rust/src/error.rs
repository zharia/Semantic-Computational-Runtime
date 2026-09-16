use std::fmt;

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum HypergraphError {
    ElementNotFound(String),
    RelationNotFound(String),
    IncidenceNotFound(String),
    DuplicateElement(String),
    DuplicateRelation(String),
    DuplicateIncidence(String),
    InvalidCardinality { expected: usize, found: usize },
    InvalidProjection(String),
}

impl fmt::Display for HypergraphError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::ElementNotFound(id) => write!(f, "Element not found: {}", id),
            Self::RelationNotFound(id) => write!(f, "Relation not found: {}", id),
            Self::IncidenceNotFound(id) => write!(f, "Incidence not found: {}", id),
            Self::DuplicateElement(id) => write!(f, "Duplicate element: {}", id),
            Self::DuplicateRelation(id) => write!(f, "Duplicate relation: {}", id),
            Self::DuplicateIncidence(id) => write!(f, "Duplicate incidence: {}", id),
            Self::InvalidCardinality { expected, found } => {
                write!(f, "Invalid relation cardinality: expected {}, found {}", expected, found)
            }
            Self::InvalidProjection(reason) => write!(f, "Projection error: {}", reason),
        }
    }
}

impl std::error::Error for HypergraphError {}
