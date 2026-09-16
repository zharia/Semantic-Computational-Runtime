use std::collections::BTreeMap;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ApplicationState {
    pub version: u64,
    pub entities: BTreeMap<String, String>,
    pub attributes: BTreeMap<String, String>,
}

impl ApplicationState {
    pub fn new() -> Self {
        Self {
            version: 1,
            entities: BTreeMap::new(),
            attributes: BTreeMap::new(),
        }
    }

    pub fn set_attribute(&mut self, key: impl Into<String>, value: impl Into<String>) {
        self.attributes.insert(key.into(), value.into());
        self.version += 1;
    }

    pub fn get_attribute(&self, key: &str) -> Option<&String> {
        self.attributes.get(key)
    }

    pub fn register_entity(&mut self, entity_id: impl Into<String>, entity_type: impl Into<String>) {
        self.entities.insert(entity_id.into(), entity_type.into());
        self.version += 1;
    }
}

impl Default for ApplicationState {
    fn default() -> Self {
        Self::new()
    }
}
