use crate::error::IdentityError;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum AuthorityState {
    Active,
    Suspended,
    Revoked,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Authority {
    pub id: String,
    pub generation: u32,
    pub state: AuthorityState,
    pub credential_ref: String,
    pub root_id: String,
    pub parent_authority: Option<String>,
}

impl Authority {
    pub fn new(
        id: impl Into<String>,
        root_id: impl Into<String>,
        credential_ref: impl Into<String>,
        parent_authority: Option<String>,
    ) -> Self {
        Self {
            id: id.into(),
            generation: 1,
            state: AuthorityState::Active,
            credential_ref: credential_ref.into(),
            root_id: root_id.into(),
            parent_authority,
        }
    }

    pub fn is_active(&self) -> bool {
        self.state == AuthorityState::Active
    }

    /// Rotate authority generation. Fences off any allocators using stale generations.
    pub fn rotate(&mut self) -> Result<u32, IdentityError> {
        if self.state != AuthorityState::Active {
            return Err(IdentityError::AuthoritySuspendedOrRevoked(self.id.clone()));
        }
        self.generation = self
            .generation
            .checked_add(1)
            .ok_or_else(|| IdentityError::InvalidRequest("Authority generation overflow".into()))?;
        Ok(self.generation)
    }

    pub fn suspend(&mut self) {
        if self.state != AuthorityState::Revoked {
            self.state = AuthorityState::Suspended;
        }
    }

    pub fn activate(&mut self) -> Result<(), IdentityError> {
        if self.state == AuthorityState::Revoked {
            return Err(IdentityError::AuthoritySuspendedOrRevoked(format!(
                "Cannot reactivate revoked authority {}",
                self.id
            )));
        }
        self.state = AuthorityState::Active;
        Ok(())
    }

    pub fn revoke(&mut self) {
        self.state = AuthorityState::Revoked;
    }
}
