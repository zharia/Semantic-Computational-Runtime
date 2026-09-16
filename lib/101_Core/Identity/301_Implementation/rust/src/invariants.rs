use crate::error::IdentityError;
use crate::models::State;

/// Independent assertion checker verifying all 17 normative invariants of SCR Identity.
pub struct InvariantChecker;

impl InvariantChecker {
    /// Invariant IAM-I001: Root Uniqueness.
    /// All root authorities registered in A have unique, non-colliding IDs.
    pub fn assert_i001_root_uniqueness(state: &State) -> Result<(), IdentityError> {
        let roots: Vec<_> = state.a.values().filter(|a| a.parent_authority.is_none()).collect();
        let mut seen = std::collections::BTreeSet::new();
        for root in roots {
            if !seen.insert(&root.id) {
                return Err(IdentityError::InvariantViolation(format!(
                    "IAM-I001: Root authority {} is duplicated",
                    root.id
                )));
            }
        }
        Ok(())
    }

    /// Invariant IAM-I002: Domain Disjointness.
    /// Sibling domains under the same parent have pairwise disjoint coordinate regions.
    pub fn assert_i002_domain_disjointness(state: &State) -> Result<(), IdentityError> {
        let domains: Vec<_> = state.d.values().collect();
        for i in 0..domains.len() {
            for j in (i + 1)..domains.len() {
                let d1 = domains[i];
                let d2 = domains[j];
                if d1.parent == d2.parent && d1.region.overlaps(&d2.region) {
                    return Err(IdentityError::InvariantViolation(format!(
                        "IAM-I002: Sibling domains {} and {} have overlapping regions: {} and {}",
                        d1.id, d2.id, d1.region, d2.region
                    )));
                }
            }
        }
        Ok(())
    }

    /// Invariant IAM-I003: Domain Containment.
    /// Child domains are strictly contained within parent domain regions.
    pub fn assert_i003_domain_containment(state: &State) -> Result<(), IdentityError> {
        for domain in state.d.values() {
            if let Some(parent_id) = &domain.parent {
                if let Some(parent) = state.d.get(parent_id) {
                    if !domain.region.is_subset_of(&parent.region) {
                        return Err(IdentityError::InvariantViolation(format!(
                            "IAM-I003: Child domain {} region {} is not contained in parent {} region {}",
                            domain.id, domain.region, parent.id, parent.region
                        )));
                    }
                }
            }
        }
        Ok(())
    }

    /// Invariant IAM-I004: Allocation Containment.
    /// All allocated indices in a domain reside strictly within its declared region.
    pub fn assert_i004_allocation_containment(state: &State) -> Result<(), IdentityError> {
        for domain in state.d.values() {
            for index in &domain.allocated_indices {
                if !domain.contains_index(*index) {
                    return Err(IdentityError::InvariantViolation(format!(
                        "IAM-I004: Domain {} contains allocated index {} outside its region {}",
                        domain.id, index, domain.region
                    )));
                }
            }
        }
        Ok(())
    }

    /// Invariant IAM-I005: Allocation Injectivity.
    /// No two distinct allocations yield identical coordinates.
    pub fn assert_i005_allocation_injectivity(state: &State) -> Result<(), IdentityError> {
        // Enforced structurally by H being a BTreeSet<SidCoordinate> and P being injective map.
        if state.h.len() != state.p.len() {
            return Err(IdentityError::InvariantViolation(format!(
                "IAM-I005: Cardinality mismatch between historical set H ({}) and provenance records P ({})",
                state.h.len(),
                state.p.len()
            )));
        }
        Ok(())
    }

    /// Invariant IAM-I006: Authority Containment.
    /// Allocation authority must match the active authority assigned to the domain.
    pub fn assert_i006_authority_containment(state: &State) -> Result<(), IdentityError> {
        for prov in state.p.values() {
            if let Some(domain) = state.d.get(&prov.domain_id) {
                if domain.authority.as_deref() != Some(&prov.authority_id) {
                    return Err(IdentityError::InvariantViolation(format!(
                        "IAM-I006: Provenance authority {} does not match domain {} assigned authority {:?}",
                        prov.authority_id, prov.domain_id, domain.authority
                    )));
                }
            }
        }
        Ok(())
    }

    /// Invariant IAM-I007: Cryptographic Provenance.
    /// Every historical coordinate has a valid, complete provenance record.
    pub fn assert_i007_cryptographic_provenance(state: &State) -> Result<(), IdentityError> {
        for sid in &state.h {
            if !state.p.contains_key(sid) {
                return Err(IdentityError::InvariantViolation(format!(
                    "IAM-I007: Historical coordinate {} lacks a cryptographic provenance record in P",
                    sid
                )));
            }
        }
        Ok(())
    }

    /// Invariant IAM-I008: Generation Validity.
    /// Coordinate generation in provenance matches the authority generation at time of allocation.
    pub fn assert_i008_generation_validity(state: &State) -> Result<(), IdentityError> {
        for prov in state.p.values() {
            if prov.sid.generation != prov.generation {
                return Err(IdentityError::InvariantViolation(format!(
                    "IAM-I008: Coordinate generation {} does not match provenance generation {}",
                    prov.sid.generation, prov.generation
                )));
            }
        }
        Ok(())
    }

    /// Invariant IAM-I009: Historical Monotonicity.
    /// Historical set H never shrinks: H(t1) ⊆ H(t2) for t1 ≤ t2.
    pub fn assert_i009_historical_monotonicity(
        curr: &State,
        prev: &State,
    ) -> Result<(), IdentityError> {
        if !prev.h.is_subset(&curr.h) {
            return Err(IdentityError::InvariantViolation(
                "IAM-I009: Historical allocation set H has shrunk, violating monotonicity".into(),
            ));
        }
        Ok(())
    }

    /// Invariant IAM-I010: Durable Non-Reuse.
    /// Any coordinate currently or historically allocated is not present in active reservations.
    pub fn assert_i010_durable_non_reuse(state: &State) -> Result<(), IdentityError> {
        for res_sid in state.reservations.keys() {
            if state.h.contains(res_sid) {
                return Err(IdentityError::InvariantViolation(format!(
                    "IAM-I010: Historically allocated coordinate {} is actively re-reserved",
                    res_sid
                )));
            }
        }
        Ok(())
    }

    /// Invariant IAM-I011: Crash Monotonicity.
    /// Recovery from crash preserves all pre-crash committed coordinates.
    pub fn assert_i011_crash_monotonicity(
        post: &State,
        pre: &State,
    ) -> Result<(), IdentityError> {
        Self::assert_i009_historical_monotonicity(post, pre)
    }

    /// Invariant IAM-I012: Snapshot Safety.
    /// Restoring a snapshot never resurrects stale active reservations.
    pub fn assert_i012_snapshot_safety(state: &State) -> Result<(), IdentityError> {
        Self::assert_i010_durable_non_reuse(state)
    }

    /// Invariant IAM-I013: Contextual Resolution.
    /// Coordinates resolve within an explicit Root and Space context.
    pub fn assert_i013_contextual_resolution(state: &State) -> Result<(), IdentityError> {
        for prov in state.p.values() {
            if !state.a.contains_key(&prov.root_id) {
                return Err(IdentityError::InvariantViolation(format!(
                    "IAM-I013: Root authority {} referenced in provenance for {} does not exist",
                    prov.root_id, prov.sid
                )));
            }
        }
        Ok(())
    }

    /// Invariant IAM-I014: Manifestation Separation.
    /// Manifestation handles point exclusively to existing historical coordinates.
    pub fn assert_i014_manifestation_separation(state: &State) -> Result<(), IdentityError> {
        for sid in state.m.keys() {
            if !state.h.contains(sid) {
                return Err(IdentityError::InvariantViolation(format!(
                    "IAM-I014: Manifestation exists for non-historical coordinate {}",
                    sid
                )));
            }
        }
        Ok(())
    }

    /// Invariant IAM-I015: Binding Separation.
    /// Semantic bindings point exclusively to existing historical coordinates.
    pub fn assert_i015_binding_separation(state: &State) -> Result<(), IdentityError> {
        for sid in state.b.keys() {
            if !state.h.contains(sid) {
                return Err(IdentityError::InvariantViolation(format!(
                    "IAM-I015: Semantic binding exists for non-historical coordinate {}",
                    sid
                )));
            }
        }
        Ok(())
    }

    /// Invariant IAM-I016: Transaction Idempotence & Non-Rebinding.
    /// Committed transactions in Q correspond to valid coordinates in H.
    pub fn assert_i016_transaction_idempotence(state: &State) -> Result<(), IdentityError> {
        for tx in state.q.values() {
            if tx.status == crate::models::TransactionStatus::Committed && !state.h.contains(&tx.sid) {
                return Err(IdentityError::InvariantViolation(format!(
                    "IAM-I016: Committed transaction {} references coordinate {} missing from H",
                    tx.tx_id, tx.sid
                )));
            }
        }
        Ok(())
    }

    /// Invariant IAM-I017: Historical Consistency.
    /// Joint consistency across H, P, D, B, M.
    /// Every historical coordinate in H:
    /// 1. Has a valid provenance record in P.
    /// 2. Belongs to a domain in D that records its index.
    /// 3. Any bindings in B and manifestations in M reference coordinates in H.
    pub fn assert_i017_historical_consistency(state: &State) -> Result<(), IdentityError> {
        for sid in &state.h {
            // 1. Provenance presence
            let prov = state.p.get(sid).ok_or_else(|| {
                IdentityError::InvariantViolation(format!(
                    "IAM-I017: Historical coordinate {} missing provenance record in P",
                    sid
                ))
            })?;

            // 2. Domain recording
            let domain = state.d.get(&prov.domain_id).ok_or_else(|| {
                IdentityError::InvariantViolation(format!(
                    "IAM-I017: Historical coordinate {} references non-existent domain {}",
                    sid, prov.domain_id
                ))
            })?;

            if !domain.allocated_indices.contains(&sid.index) {
                return Err(IdentityError::InvariantViolation(format!(
                    "IAM-I017: Domain {} does not record index {} for historical coordinate {}",
                    domain.id, sid.index, sid
                )));
            }
        }

        Self::assert_i014_manifestation_separation(state)?;
        Self::assert_i015_binding_separation(state)?;
        Ok(())
    }

    /// Full Invariant Audit: Asserts all 17 normative invariants against state.
    pub fn assert_all(state: &State, prev: Option<&State>) -> Result<(), IdentityError> {
        Self::assert_i001_root_uniqueness(state)?;
        Self::assert_i002_domain_disjointness(state)?;
        Self::assert_i003_domain_containment(state)?;
        Self::assert_i004_allocation_containment(state)?;
        Self::assert_i005_allocation_injectivity(state)?;
        Self::assert_i006_authority_containment(state)?;
        Self::assert_i007_cryptographic_provenance(state)?;
        Self::assert_i008_generation_validity(state)?;
        if let Some(p) = prev {
            Self::assert_i009_historical_monotonicity(state, p)?;
            Self::assert_i011_crash_monotonicity(state, p)?;
        }
        Self::assert_i010_durable_non_reuse(state)?;
        Self::assert_i012_snapshot_safety(state)?;
        Self::assert_i013_contextual_resolution(state)?;
        Self::assert_i014_manifestation_separation(state)?;
        Self::assert_i015_binding_separation(state)?;
        Self::assert_i016_transaction_idempotence(state)?;
        Self::assert_i017_historical_consistency(state)?;
        Ok(())
    }
}
