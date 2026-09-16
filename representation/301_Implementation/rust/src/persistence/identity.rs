use std::fmt;

/// Unique identifier for a persistent entity or manifestation.
#[derive(Debug, Clone, PartialEq, Eq, Hash, PartialOrd, Ord)]
pub struct PersistentId(pub String);

impl PersistentId {
    pub fn new<S: Into<String>>(s: S) -> Self {
        Self(s.into())
    }
}

impl fmt::Display for PersistentId {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{}", self.0)
    }
}

/// Persistent reference binding a persistent ID to a specific content version and integrity checksum.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct PersistenceRef {
    pub id: PersistentId,
    pub version: u32,
    pub checksum: u64,
}

impl PersistenceRef {
    pub fn new(id: PersistentId, version: u32, checksum: u64) -> Self {
        Self {
            id,
            version,
            checksum,
        }
    }
}
