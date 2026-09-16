use std::fmt;

/// Unique semantic identifier for a serialization schema.
#[derive(Debug, Clone, PartialEq, Eq, Hash, PartialOrd, Ord)]
pub struct SchemaId(pub String);

impl SchemaId {
    pub fn new<S: Into<String>>(s: S) -> Self {
        Self(s.into())
    }
}

impl fmt::Display for SchemaId {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{}", self.0)
    }
}

/// Schema version number.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, PartialOrd, Ord)]
pub struct SchemaVersion(pub u32);

/// Format encoding specification version.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, PartialOrd, Ord)]
pub struct FormatVersion(pub u32);

/// Full schema descriptor for serialization and deserialization validation.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SchemaDescriptor {
    pub id: SchemaId,
    pub version: SchemaVersion,
    pub format_version: FormatVersion,
    pub description: String,
}

impl SchemaDescriptor {
    pub fn new<S: Into<String>, D: Into<String>>(
        id: S,
        version: u32,
        format_version: u32,
        description: D,
    ) -> Self {
        Self {
            id: SchemaId::new(id),
            version: SchemaVersion(version),
            format_version: FormatVersion(format_version),
            description: description.into(),
        }
    }
}
