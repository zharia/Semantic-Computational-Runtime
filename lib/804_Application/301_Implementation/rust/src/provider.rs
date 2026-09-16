use std::collections::BTreeSet;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ApplicationProvider {
    pub id: String,
    pub name: String,
    pub capabilities: BTreeSet<String>,
    pub provider_type: String,
    pub is_active: bool,
}

impl ApplicationProvider {
    pub fn new(
        id: impl Into<String>,
        name: impl Into<String>,
        provider_type: impl Into<String>,
    ) -> Self {
        Self {
            id: id.into(),
            name: name.into(),
            capabilities: BTreeSet::new(),
            provider_type: provider_type.into(),
            is_active: true,
        }
    }

    pub fn with_capability(mut self, cap: impl Into<String>) -> Self {
        self.capabilities.insert(cap.into());
        self
    }

    pub fn has_capability(&self, cap: &str) -> bool {
        self.capabilities.contains(cap)
    }
}
