use crate::authority::Authority;
use crate::coordinate::{CoordinateRegion, SidCoordinate};
use crate::domain::{Domain, DomainState};
use crate::error::IdentityError;
use crate::models::{
    IdentitySpace, ManifestationRecord, ProvenanceRecord, SemanticBinding, State,
    TransactionRecord, TransactionStatus,
};

/// Deterministic state transition engine for the SCR Identity Address Space.
#[derive(Debug, Clone)]
pub struct IAMMachine {
    pub state: State,
}

impl IAMMachine {
    pub fn new(genesis_id: impl Into<String>) -> Self {
        Self {
            state: State::new(genesis_id),
        }
    }

    pub fn from_state(state: State) -> Self {
        Self { state }
    }

    // --- Root Authority & Identity Space Lifecycle ---

    pub fn create_root(&mut self, root_id: &str) -> Result<(), IdentityError> {
        self.state.step += 1;
        if self.state.a.contains_key(root_id) {
            return Err(IdentityError::RootAlreadyExists(root_id.to_string()));
        }

        let root_authority = Authority::new(
            root_id,
            root_id,
            format!("cred://{}/v1", root_id),
            None,
        );
        self.state.a.insert(root_id.to_string(), root_authority);
        Ok(())
    }

    pub fn create_space(
        &mut self,
        space_id: &str,
        root_id: &str,
        coordinate_space: CoordinateRegion,
    ) -> Result<(), IdentityError> {
        self.state.step += 1;
        if !self.state.a.contains_key(root_id) {
            return Err(IdentityError::RootNotFound(root_id.to_string()));
        }
        if self.state.i.contains_key(space_id) {
            return Err(IdentityError::SpaceAlreadyExists(space_id.to_string()));
        }

        let space = IdentitySpace {
            id: space_id.to_string(),
            root_authority: root_id.to_string(),
            coordinate_space,
            geometry: "linear_interval".to_string(),
            policy: "durable_non_reuse".to_string(),
        };
        self.state.i.insert(space_id.to_string(), space);

        // Create root domain for the space (numeric_id = 0)
        let root_dom_id = format!("dom_root_{}", space_id);
        let mut root_domain = Domain::new(
            &root_dom_id,
            0,
            None,
            coordinate_space,
            Some(root_id.to_string()),
        );
        root_domain.state = DomainState::Active;
        self.state.d.insert(root_dom_id, root_domain);

        Ok(())
    }

    // --- Domain Lifecycle Operations ---

    pub fn reserve_domain(
        &mut self,
        parent_dom_id: &str,
        domain_id: &str,
        numeric_id: u64,
        region: CoordinateRegion,
    ) -> Result<(), IdentityError> {
        self.state.step += 1;
        if self.state.d.contains_key(domain_id) {
            return Err(IdentityError::DomainAlreadyExists(domain_id.to_string()));
        }

        let parent = self
            .state
            .d
            .get(parent_dom_id)
            .ok_or_else(|| IdentityError::DomainNotFound(parent_dom_id.to_string()))?;

        // Invariant IAM-I003: Child region must be strictly contained within parent region
        if !region.is_subset_of(&parent.region) {
            return Err(IdentityError::RegionNotContainedInParent {
                child: domain_id.to_string(),
                parent: parent_dom_id.to_string(),
            });
        }

        // Invariant IAM-I002: Sibling domains must be pairwise disjoint
        for (other_id, other_dom) in &self.state.d {
            if other_dom.parent.as_deref() == Some(parent_dom_id) && other_dom.region.overlaps(&region) {
                return Err(IdentityError::RegionOverlap {
                    domain_a: domain_id.to_string(),
                    domain_b: other_id.clone(),
                });
            }
        }

        let domain = Domain::new(
            domain_id,
            numeric_id,
            Some(parent_dom_id.to_string()),
            region,
            None,
        );
        self.state.d.insert(domain_id.to_string(), domain);
        Ok(())
    }

    pub fn delegate_domain(
        &mut self,
        domain_id: &str,
        authority_id: &str,
    ) -> Result<(), IdentityError> {
        self.state.step += 1;
        let auth = self
            .state
            .a
            .get(authority_id)
            .ok_or_else(|| IdentityError::AuthorityNotFound(authority_id.to_string()))?;

        if !auth.is_active() {
            return Err(IdentityError::AuthoritySuspendedOrRevoked(
                authority_id.to_string(),
            ));
        }

        let domain = self
            .state
            .d
            .get_mut(domain_id)
            .ok_or_else(|| IdentityError::DomainNotFound(domain_id.to_string()))?;

        domain.authority = Some(authority_id.to_string());
        domain.generation = auth.generation;
        domain.state = DomainState::Delegated;
        Ok(())
    }

    pub fn activate_domain(&mut self, domain_id: &str) -> Result<(), IdentityError> {
        self.state.step += 1;
        let domain = self
            .state
            .d
            .get_mut(domain_id)
            .ok_or_else(|| IdentityError::DomainNotFound(domain_id.to_string()))?;

        if domain.state != DomainState::Delegated {
            return Err(IdentityError::InvalidRequest(format!(
                "Domain {} must be in Delegated state to be activated (current: {:?})",
                domain_id, domain.state
            )));
        }

        domain.state = DomainState::Active;
        Ok(())
    }

    pub fn revoke_domain(&mut self, domain_id: &str) -> Result<(), IdentityError> {
        self.state.step += 1;
        let domain = self
            .state
            .d
            .get_mut(domain_id)
            .ok_or_else(|| IdentityError::DomainNotFound(domain_id.to_string()))?;

        domain.state = DomainState::Revoked;
        Ok(())
    }

    pub fn retire_domain(&mut self, domain_id: &str) -> Result<(), IdentityError> {
        self.state.step += 1;
        let domain = self
            .state
            .d
            .get_mut(domain_id)
            .ok_or_else(|| IdentityError::DomainNotFound(domain_id.to_string()))?;

        domain.state = DomainState::Retired;
        Ok(())
    }

    // --- Authority Lifecycle Operations ---

    pub fn create_authority(
        &mut self,
        authority_id: &str,
        root_id: &str,
        credential_ref: &str,
        parent_authority: Option<String>,
    ) -> Result<(), IdentityError> {
        self.state.step += 1;
        if self.state.a.contains_key(authority_id) {
            return Err(IdentityError::AuthorityAlreadyExists(
                authority_id.to_string(),
            ));
        }
        if !self.state.a.contains_key(root_id) {
            return Err(IdentityError::RootNotFound(root_id.to_string()));
        }

        let authority = Authority::new(authority_id, root_id, credential_ref, parent_authority);
        self.state.a.insert(authority_id.to_string(), authority);
        Ok(())
    }

    pub fn rotate_authority(&mut self, authority_id: &str) -> Result<u32, IdentityError> {
        self.state.step += 1;
        let authority = self
            .state
            .a
            .get_mut(authority_id)
            .ok_or_else(|| IdentityError::AuthorityNotFound(authority_id.to_string()))?;

        authority.rotate()
    }

    pub fn suspend_authority(&mut self, authority_id: &str) -> Result<(), IdentityError> {
        self.state.step += 1;
        let authority = self
            .state
            .a
            .get_mut(authority_id)
            .ok_or_else(|| IdentityError::AuthorityNotFound(authority_id.to_string()))?;

        authority.suspend();
        Ok(())
    }

    pub fn activate_authority(&mut self, authority_id: &str) -> Result<(), IdentityError> {
        self.state.step += 1;
        let authority = self
            .state
            .a
            .get_mut(authority_id)
            .ok_or_else(|| IdentityError::AuthorityNotFound(authority_id.to_string()))?;

        authority.activate()
    }

    pub fn revoke_authority(&mut self, authority_id: &str) -> Result<(), IdentityError> {
        self.state.step += 1;
        let authority = self
            .state
            .a
            .get_mut(authority_id)
            .ok_or_else(|| IdentityError::AuthorityNotFound(authority_id.to_string()))?;

        authority.revoke();
        Ok(())
    }

    // --- Allocation Lifecycle Operations ---

    /// Atomic reservation of a coordinate within an active domain.
    pub fn reserve_sid(
        &mut self,
        domain_id: &str,
        index: u32,
        authority_id: &str,
        generation: u32,
        tx_id: &str,
    ) -> Result<SidCoordinate, IdentityError> {
        self.state.step += 1;

        // Domain validation
        let domain = self
            .state
            .d
            .get(domain_id)
            .ok_or_else(|| IdentityError::DomainNotFound(domain_id.to_string()))?;

        if domain.state != DomainState::Active {
            return Err(IdentityError::InvalidRequest(format!(
                "Domain {} is not in Active state (current: {:?})",
                domain_id, domain.state
            )));
        }

        // Invariant IAM-I004: Index must be within domain region
        if !domain.contains_index(index) {
            return Err(IdentityError::RegionOutOfBounds {
                index: index as u64,
                low: domain.region.low,
                high: domain.region.high,
            });
        }

        // Authority validation
        let authority = self
            .state
            .a
            .get(authority_id)
            .ok_or_else(|| IdentityError::AuthorityNotFound(authority_id.to_string()))?;

        if !authority.is_active() {
            return Err(IdentityError::AuthoritySuspendedOrRevoked(
                authority_id.to_string(),
            ));
        }

        // Invariant IAM-I006: Authority must match domain's assigned authority
        if domain.authority.as_deref() != Some(authority_id) {
            return Err(IdentityError::AuthorityMismatch {
                domain_authority: domain
                    .authority
                    .clone()
                    .unwrap_or_else(|| "none".to_string()),
                provided_authority: authority_id.to_string(),
            });
        }

        // Invariant IAM-I008: Generation validity
        if authority.generation != generation {
            return Err(IdentityError::GenerationMismatch {
                expected: authority.generation,
                provided: generation,
            });
        }

        let sid = SidCoordinate::new(domain.numeric_id, index, generation);

        // Invariant IAM-I010: Durable non-reuse
        if self.state.h.contains(&sid) {
            return Err(IdentityError::CoordinateAlreadyAllocated(sid.to_string()));
        }

        // Rule IAM-R018: Transaction Immutability & Non-Rebinding
        if let Some(existing_tx) = self.state.q.get(tx_id) {
            if existing_tx.sid != sid {
                return Err(IdentityError::TransactionRebound {
                    tx_id: tx_id.to_string(),
                    existing_sid: existing_tx.sid.to_string(),
                    attempted_sid: sid.to_string(),
                });
            }
            // Idempotent re-reservation of same coordinate under same tx
            return Ok(sid);
        }

        // Active reservation conflict
        if let Some(res_tx) = self.state.reservations.get(&sid) {
            if res_tx != tx_id {
                return Err(IdentityError::CoordinateCurrentlyReserved(sid.to_string()));
            }
        }

        // Record reservation
        let tx = TransactionRecord {
            tx_id: tx_id.to_string(),
            sid,
            domain_id: domain_id.to_string(),
            authority_id: authority_id.to_string(),
            generation,
            status: TransactionStatus::Reserved,
        };

        self.state.q.insert(tx_id.to_string(), tx);
        self.state.reservations.insert(sid, tx_id.to_string());

        Ok(sid)
    }

    /// Commit an existing reservation, appending the coordinate to historical set H.
    pub fn commit_sid(&mut self, tx_id: &str) -> Result<SidCoordinate, IdentityError> {
        self.state.step += 1;

        let tx = self
            .state
            .q
            .get(tx_id)
            .ok_or_else(|| IdentityError::TransactionNotFound(tx_id.to_string()))?
            .clone();

        // Invariant IAM-I016: Transaction Idempotence
        if tx.status == TransactionStatus::Committed {
            if self.state.h.contains(&tx.sid) {
                return Ok(tx.sid);
            }
            return Err(IdentityError::InvariantViolation(format!(
                "Transaction {} marked committed but coordinate {} not found in H",
                tx_id, tx.sid
            )));
        }

        let sid = tx.sid;
        let domain_id = tx.domain_id.clone();
        let authority_id = tx.authority_id.clone();
        let generation = tx.generation;

        // Retrieve domain and authority
        let domain = self
            .state
            .d
            .get_mut(&domain_id)
            .ok_or_else(|| IdentityError::DomainNotFound(domain_id.clone()))?;
        domain.record_allocation(sid.index)?;

        let auth = self
            .state
            .a
            .get(&authority_id)
            .ok_or_else(|| IdentityError::AuthorityNotFound(authority_id.clone()))?;
        let root_id = auth.root_id.clone();

        // Invariant IAM-I009: Monotonic historical set append
        self.state.h.insert(sid);

        // Invariant IAM-I007: Cryptographic provenance
        let provenance = ProvenanceRecord {
            sid,
            genesis_id: self.state.genesis_id.clone(),
            root_id,
            authority_id,
            generation,
            domain_id,
            tx_id: tx_id.to_string(),
        };
        self.state.p.insert(sid, provenance);

        // Update transaction status
        if let Some(t) = self.state.q.get_mut(tx_id) {
            t.status = TransactionStatus::Committed;
        }

        // Release reservation
        self.state.reservations.remove(&sid);

        Ok(sid)
    }

    // --- Binding & Manifestation Lifecycle ---

    pub fn bind_sid(
        &mut self,
        sid: SidCoordinate,
        entity_id: &str,
    ) -> Result<(), IdentityError> {
        self.state.step += 1;
        if !self.state.h.contains(&sid) {
            return Err(IdentityError::CoordinateNotFound(sid.to_string()));
        }

        let binding = SemanticBinding {
            sid,
            entity_id: entity_id.to_string(),
            created_at_step: self.state.step,
        };
        self.state.b.insert(sid, binding);
        Ok(())
    }

    pub fn manifest_sid(
        &mut self,
        sid: SidCoordinate,
        runtime_handle: &str,
    ) -> Result<(), IdentityError> {
        self.state.step += 1;
        if !self.state.h.contains(&sid) {
            return Err(IdentityError::CoordinateNotFound(sid.to_string()));
        }

        let record = ManifestationRecord {
            sid,
            runtime_handle: runtime_handle.to_string(),
            active: true,
        };
        self.state.m.entry(sid).or_default().push(record);
        Ok(())
    }

    // --- Durability, Snapshot & Recovery (Rules IAM-R017, IAM-R018) ---

    pub fn snapshot(&self) -> State {
        self.state.clone()
    }

    /// Restore state from a snapshot enforcing Rule IAM-R017 / IAM-I017.
    ///
    /// Preserves monotonic union: H_restored = H_live ∪ H_snapshot.
    /// Crucially, for all s ∈ H_live \ H_snapshot, this carry-forwards
    /// provenance, domain records, bindings, and manifestations so that no
    /// historical coordinate is ever orphaned.
    pub fn recover(&mut self, snapshot: State) -> Result<(), IdentityError> {
        let live_h = self.state.h.clone();
        let live_p = self.state.p.clone();
        let live_b = self.state.b.clone();
        let live_m = self.state.m.clone();
        let live_q = self.state.q.clone();

        // Start with snapshot state
        let mut restored = snapshot;
        restored.step = std::cmp::max(self.state.step, restored.step) + 1;

        // Union of historical allocations (IAM-I011, IAM-I012)
        for sid in &live_h {
            restored.h.insert(*sid);
        }

        // Rule IAM-R017 carry-forward for surviving post-snapshot allocations:
        for sid in &live_h {
            if !restored.p.contains_key(sid) {
                if let Some(prov) = live_p.get(sid) {
                    restored.p.insert(*sid, prov.clone());

                    // Ensure domain knows about this allocation
                    if let Some(dom) = restored.d.get_mut(&prov.domain_id) {
                        dom.allocated_indices.insert(sid.index);
                    }
                }
            }

            if !restored.b.contains_key(sid) {
                if let Some(binding) = live_b.get(sid) {
                    restored.b.insert(*sid, binding.clone());
                }
            }

            if !restored.m.contains_key(sid) {
                if let Some(manifestations) = live_m.get(sid) {
                    restored.m.insert(*sid, manifestations.clone());
                }
            }
        }

        // Carry forward committed transactions for surviving SIDs
        for (tx_id, tx) in live_q {
            if tx.status == TransactionStatus::Committed && !restored.q.contains_key(&tx_id) {
                restored.q.insert(tx_id, tx);
            }
        }

        self.state = restored;
        Ok(())
    }
}
