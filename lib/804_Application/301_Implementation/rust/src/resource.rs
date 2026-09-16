use crate::error::{ApplicationError, ApplicationResult};

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ApplicationResource {
    pub id: String,
    pub resource_type: String,
    pub quota_limit: u64,
    pub current_usage: u64,
}

impl ApplicationResource {
    pub fn new(id: impl Into<String>, resource_type: impl Into<String>, quota_limit: u64) -> Self {
        Self {
            id: id.into(),
            resource_type: resource_type.into(),
            quota_limit,
            current_usage: 0,
        }
    }

    pub fn allocate(&mut self, amount: u64) -> ApplicationResult<()> {
        if self.current_usage + amount > self.quota_limit {
            return Err(ApplicationError::ResourceExhausted(format!(
                "Resource {} ({}) quota exceeded: requested {}, available {}",
                self.id,
                self.resource_type,
                amount,
                self.quota_limit.saturating_sub(self.current_usage)
            )));
        }
        self.current_usage += amount;
        Ok(())
    }

    pub fn release(&mut self, amount: u64) {
        self.current_usage = self.current_usage.saturating_sub(amount);
    }
}
