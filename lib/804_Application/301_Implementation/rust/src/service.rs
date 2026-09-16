use crate::error::{ApplicationError, ApplicationResult};
use crate::operation::SemanticOperation;
use std::collections::BTreeMap;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ApplicationService {
    pub id: String,
    pub name: String,
    pub description: String,
    pub operations: BTreeMap<String, SemanticOperation>,
    pub required_capabilities: Vec<String>,
}

impl ApplicationService {
    pub fn new(id: impl Into<String>, name: impl Into<String>) -> Self {
        Self {
            id: id.into(),
            name: name.into(),
            description: String::new(),
            operations: BTreeMap::new(),
            required_capabilities: Vec::new(),
        }
    }

    pub fn register_operation(&mut self, op: SemanticOperation) {
        self.operations.insert(op.id.clone(), op);
    }

    pub fn get_operation(&self, op_id: &str) -> ApplicationResult<&SemanticOperation> {
        self.operations
            .get(op_id)
            .ok_or_else(|| ApplicationError::OperationNotFound(op_id.to_string()))
    }
}
