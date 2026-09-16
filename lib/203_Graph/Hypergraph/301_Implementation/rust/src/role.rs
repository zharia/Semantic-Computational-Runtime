use std::fmt;

/// Semantic relational role associated with an incidence.
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub enum Role {
    Input,
    Output,
    Parameter,
    Subject,
    Object,
    Operand,
    Constraint,
    Cause,
    Effect,
    Source,
    Target,
    Custom(String),
}

impl fmt::Display for Role {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::Input => write!(f, "Input"),
            Self::Output => write!(f, "Output"),
            Self::Parameter => write!(f, "Parameter"),
            Self::Subject => write!(f, "Subject"),
            Self::Object => write!(f, "Object"),
            Self::Operand => write!(f, "Operand"),
            Self::Constraint => write!(f, "Constraint"),
            Self::Cause => write!(f, "Cause"),
            Self::Effect => write!(f, "Effect"),
            Self::Source => write!(f, "Source"),
            Self::Target => write!(f, "Target"),
            Self::Custom(s) => write!(f, "Custom({})", s),
        }
    }
}

/// Directional orientation of an incidence relative to the relation.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Default)]
pub enum Direction {
    #[default]
    Undirected,
    Ingoing,
    Outgoing,
}

impl fmt::Display for Direction {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::Undirected => write!(f, "--"),
            Self::Ingoing => write!(f, "->"),
            Self::Outgoing => write!(f, "<-"),
        }
    }
}
