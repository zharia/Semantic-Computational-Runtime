use crate::error::{ApplicationError, ApplicationResult};
use std::collections::BTreeSet;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ApplicationPolicy {
    pub id: String,
    pub name: String,
    pub allowed_roles: BTreeSet<String>,
    pub is_mandatory: bool,
}

impl ApplicationPolicy {
    pub fn new(id: impl Into<String>, name: impl Into<String>, is_mandatory: bool) -> Self {
        Self {
            id: id.into(),
            name: name.into(),
            allowed_roles: BTreeSet::new(),
            is_mandatory,
        }
    }

    pub fn allow_role(mut self, role: impl Into<String>) -> Self {
        self.allowed_roles.insert(role.into());
        self
    }

    pub fn enforce(&self, caller_role: &str) -> ApplicationResult<()> {
        if !self.allowed_roles.contains(caller_role) {
            if self.is_mandatory {
                return Err(ApplicationError::PolicyViolation(format!(
                    "Mandatory policy '{}' violated: role '{}' not authorized",
                    self.name, caller_role
                )));
            }
        }
        Ok(())
    }
}
