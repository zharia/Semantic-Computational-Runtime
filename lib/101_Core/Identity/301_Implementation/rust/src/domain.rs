use crate::coordinate::CoordinateRegion;
use crate::error::IdentityError;
use std::collections::BTreeSet;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum DomainState {
    Free,
    Reserved,
    Delegated,
    Active,
    Revoked,
    Retired,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Domain {
    pub id: String,
    pub numeric_id: u64,
    pub parent: Option<String>,
    pub region: CoordinateRegion,
    pub state: DomainState,
    pub authority: Option<String>,
    pub generation: u32,
    pub allocated_indices: BTreeSet<u32>,
}

impl Domain {
    pub fn new(
        id: impl Into<String>,
        numeric_id: u64,
        parent: Option<String>,
        region: CoordinateRegion,
        authority: Option<String>,
    ) -> Self {
        Self {
            id: id.into(),
            numeric_id,
            parent,
            region,
            state: DomainState::Reserved,
            authority,
            generation: 1,
            allocated_indices: BTreeSet::new(),
        }
    }

    pub fn is_active(&self) -> bool {
        self.state == DomainState::Active
    }

    pub fn contains_index(&self, index: u32) -> bool {
        self.region.contains(index as u64)
    }

    pub fn record_allocation(&mut self, index: u32) -> Result<(), IdentityError> {
        if !self.contains_index(index) {
            return Err(IdentityError::RegionOutOfBounds {
                index: index as u64,
                low: self.region.low,
                high: self.region.high,
            });
        }
        self.allocated_indices.insert(index);
        Ok(())
    }
}
