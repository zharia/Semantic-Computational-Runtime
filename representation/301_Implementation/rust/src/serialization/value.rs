use std::collections::BTreeMap;

/// Structural representation value before encoding or after decoding.
///
/// BTreeMap is used for associative collections to ensure strictly deterministic,
/// canonical key ordering independent of insertion sequence.
#[derive(Debug, Clone, PartialEq)]
pub enum SemanticValue {
    Null,
    Bool(bool),
    Int64(i64),
    Float64(f64),
    String(String),
    Bytes(Vec<u8>),
    Array(Vec<SemanticValue>),
    Map(BTreeMap<String, SemanticValue>),
    EntityRef(String),
}

impl SemanticValue {
    pub fn is_null(&self) -> bool {
        matches!(self, Self::Null)
    }

    pub fn as_str(&self) -> Option<&str> {
        match self {
            Self::String(s) => Some(s),
            _ => None,
        }
    }

    pub fn as_i64(&self) -> Option<i64> {
        match self {
            Self::Int64(i) => Some(*i),
            _ => None,
        }
    }

    pub fn as_bool(&self) -> Option<bool> {
        match self {
            Self::Bool(b) => Some(*b),
            _ => None,
        }
    }

    pub fn as_array(&self) -> Option<&[SemanticValue]> {
        match self {
            Self::Array(arr) => Some(arr),
            _ => None,
        }
    }

    pub fn as_map(&self) -> Option<&BTreeMap<String, SemanticValue>> {
        match self {
            Self::Map(m) => Some(m),
            _ => None,
        }
    }
}
