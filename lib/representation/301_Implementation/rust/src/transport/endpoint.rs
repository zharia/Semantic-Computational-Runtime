use std::fmt;

/// Unique identifier for a transport endpoint within a computational context.
#[derive(Debug, Clone, PartialEq, Eq, Hash, PartialOrd, Ord)]
pub struct EndpointId(pub String);

impl EndpointId {
    pub fn new<S: Into<String>>(s: S) -> Self {
        Self(s.into())
    }
}

impl fmt::Display for EndpointId {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{}", self.0)
    }
}

/// Addressable locator for a transport endpoint (e.g. URI, domain route, or in-memory channel ID).
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct TransportAddress(pub String);

impl TransportAddress {
    pub fn new<S: Into<String>>(s: S) -> Self {
        Self(s.into())
    }
}

impl fmt::Display for TransportAddress {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{}", self.0)
    }
}
