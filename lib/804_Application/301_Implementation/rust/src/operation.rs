use crate::error::{ApplicationError, ApplicationResult};

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct OperationParameter {
    pub name: String,
    pub param_type: String,
    pub required: bool,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SemanticOperation {
    pub id: String,
    pub name: String,
    pub description: String,
    pub is_idempotent: bool,
    pub parameters: Vec<OperationParameter>,
    pub return_type: String,
    pub preconditions: Vec<String>,
    pub postconditions: Vec<String>,
}

impl SemanticOperation {
    pub fn new(
        id: impl Into<String>,
        name: impl Into<String>,
        return_type: impl Into<String>,
    ) -> Self {
        Self {
            id: id.into(),
            name: name.into(),
            description: String::new(),
            is_idempotent: false,
            parameters: Vec::new(),
            return_type: return_type.into(),
            preconditions: Vec::new(),
            postconditions: Vec::new(),
        }
    }

    pub fn with_parameter(
        mut self,
        name: impl Into<String>,
        param_type: impl Into<String>,
        required: bool,
    ) -> Self {
        self.parameters.push(OperationParameter {
            name: name.into(),
            param_type: param_type.into(),
            required,
        });
        self
    }

    pub fn with_precondition(mut self, cond: impl Into<String>) -> Self {
        self.preconditions.push(cond.into());
        self
    }

    pub fn with_postcondition(mut self, cond: impl Into<String>) -> Self {
        self.postconditions.push(cond.into());
        self
    }

    pub fn with_idempotence(mut self, idempotent: bool) -> Self {
        self.is_idempotent = idempotent;
        self
    }

    pub fn validate_parameters(&self, provided_args: &[(&str, &str)]) -> ApplicationResult<()> {
        for param in &self.parameters {
            if param.required {
                let found = provided_args.iter().any(|(k, _)| *k == param.name);
                if !found {
                    return Err(ApplicationError::PreconditionFailed(format!(
                        "Missing required parameter '{}' for operation '{}'",
                        param.name, self.name
                    )));
                }
            }
        }
        Ok(())
    }
}
