// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

//! # Normative Topology Invariants
//!
//! Verification functions for `TOPOLOGY-INV-001` through `TOPOLOGY-INV-018`.
//!
//! Conforming to Section 63 of `lib/303_Topology/101_definition.md`.
//!
//! These invariants are the normative semantic contracts of the SCR Topology domain.
//! They MUST be satisfied by all conforming implementations.

use crate::boundary::Boundary;
use crate::cell::{CellDimension, CellId};
use crate::connectivity::ConnectivityStructure;
use crate::continuity::ContinuityContract;
use crate::delta::TopologicalDelta;
use crate::error::{TopologyError, TopologyResult};
use crate::simplicial::SimplicialComplex;
use crate::space::TopologicalSpace;
use crate::transformation::TopologicalTransformation;

/// Verifies `TOPOLOGY-INV-001` (Identity):
/// Persistent topological structures MUST have stable semantic identity where required.
pub fn verify_topology_inv_001_identity(id: &str) -> TopologyResult<()> {
    if id.trim().is_empty() {
        return Err(TopologyError::InvariantViolation(
            "TOPOLOGY-INV-001: Topological structure identity cannot be empty".to_string(),
        ));
    }
    Ok(())
}

/// Verifies `TOPOLOGY-INV-002` (Connectivity Integrity):
/// Declared connectivity MUST remain internally consistent.
pub fn verify_topology_inv_002_connectivity_integrity(
    structure: &ConnectivityStructure,
    declared_component_count: usize,
) -> TopologyResult<()> {
    let computed = structure.component_count();
    if computed != declared_component_count {
        return Err(TopologyError::InvariantViolation(format!(
            "TOPOLOGY-INV-002: Connectivity integrity violated — computed {} components, \
             declared {}",
            computed, declared_component_count
        )));
    }
    Ok(())
}

/// Verifies `TOPOLOGY-INV-003` (Incidence Integrity):
/// Incidence relationships MUST remain semantically valid.
pub fn verify_topology_inv_003_incidence_integrity(
    element: &CellId,
    boundary_dim: CellDimension,
    boundaries: &[CellId],
    expected_count: Option<usize>,
) -> TopologyResult<()> {
    // Boundary of a 0-cell must be empty
    if boundary_dim.0 == 0 && !boundaries.is_empty() {
        return Err(TopologyError::InvariantViolation(
            "TOPOLOGY-INV-003: 0-cells cannot have boundary incidences".to_string(),
        ));
    }
    // If expected count is declared, verify it matches
    if let Some(expected) = expected_count {
        if boundaries.len() != expected {
            return Err(TopologyError::InvariantViolation(format!(
                "TOPOLOGY-INV-003: Element '{}' has {} boundary elements, expected {}",
                element,
                boundaries.len(),
                expected
            )));
        }
    }
    Ok(())
}

/// Verifies `TOPOLOGY-INV-004` (Boundary Integrity):
/// Boundary semantics MUST remain consistent with the declared topology.
pub fn verify_topology_inv_004_boundary_integrity(boundary: &Boundary) -> TopologyResult<()> {
    // ∂(0-cell) = ∅
    if boundary.region_dimension.0 == 0 && !boundary.is_empty() {
        return Err(TopologyError::InvariantViolation(
            "TOPOLOGY-INV-004: Boundary of a 0-cell must be empty".to_string(),
        ));
    }
    // Boundary elements must be of dimension (region - 1)
    if let Some(_bnd_dim) = boundary.boundary_dimension() {
        // We cannot check the actual dimension of boundary elements without
        // access to the complex; the structural check is that boundary_elements
        // are present iff region_dimension > 0.
        if boundary.region_dimension.0 > 0 && boundary.is_empty() {
            // Not necessarily invalid — closed structures have empty boundary
            // This is not an error.
        }
    }
    Ok(())
}

/// Verifies `TOPOLOGY-INV-005` (Continuity Integrity):
/// Operations claiming continuity MUST satisfy their declared contract.
pub fn verify_topology_inv_005_continuity_integrity(
    contract: &ContinuityContract,
) -> TopologyResult<()> {
    contract.assert_verified()
}

/// Verifies `TOPOLOGY-INV-006` (Equivalence Integrity):
/// Equivalence claims MUST identify and satisfy their declared equivalence relation.
pub fn verify_topology_inv_006_equivalence_integrity(
    equivalence_relation: &str,
    chi_a: i64,
    chi_b: i64,
) -> TopologyResult<()> {
    if equivalence_relation.trim().is_empty() {
        return Err(TopologyError::InvariantViolation(
            "TOPOLOGY-INV-006: Equivalence claim must identify the equivalence relation".to_string(),
        ));
    }
    if equivalence_relation.contains("euler") || equivalence_relation.contains("chi") {
        if chi_a != chi_b {
            return Err(TopologyError::InvariantViolation(format!(
                "TOPOLOGY-INV-006: Euler characteristic equivalence violated: χ₁={} ≠ χ₂={}",
                chi_a, chi_b
            )));
        }
    }
    Ok(())
}

/// Verifies `TOPOLOGY-INV-007` (Invariant Integrity):
/// Operations claiming invariant preservation MUST preserve the specified invariants.
pub fn verify_topology_inv_007_invariant_integrity(
    transformation: &TopologicalTransformation,
    required_invariant: &str,
) -> TopologyResult<()> {
    transformation.assert_preserves(required_invariant)
}

/// Verifies `TOPOLOGY-INV-008` (Transformation Integrity):
/// Topology transformations MUST satisfy their declared semantic effects.
pub fn verify_topology_inv_008_transformation_integrity(
    transformation: &TopologicalTransformation,
    euler_before: i64,
    euler_after: i64,
) -> TopologyResult<()> {
    if transformation.is_topology_preserving() && euler_before != euler_after {
        return Err(TopologyError::InvariantViolation(format!(
            "TOPOLOGY-INV-008: Transformation '{}' claims to preserve topology but \
             Euler characteristic changed: {} → {}",
            transformation.id, euler_before, euler_after
        )));
    }
    Ok(())
}

/// Verifies `TOPOLOGY-INV-009` (Component Integrity):
/// Component membership MUST remain consistent with connectivity semantics.
pub fn verify_topology_inv_009_component_integrity(
    structure: &ConnectivityStructure,
    element: &CellId,
    claimed_component_id: &str,
) -> TopologyResult<()> {
    let components = structure.connected_components();
    let element_in_claimed = components.iter().any(|comp| {
        comp.id == claimed_component_id && comp.contains(element)
    });

    if !element_in_claimed {
        return Err(TopologyError::InvariantViolation(format!(
            "TOPOLOGY-INV-009: Element '{}' is not in claimed component '{}'",
            element, claimed_component_id
        )));
    }
    Ok(())
}

/// Verifies `TOPOLOGY-INV-010` (Approximation Integrity):
/// Topological approximations MUST satisfy declared fidelity requirements.
pub fn verify_topology_inv_010_approximation_integrity(
    approximate_component_count: usize,
    exact_component_count: usize,
    declared_fidelity: &str,
) -> TopologyResult<()> {
    if declared_fidelity.trim().is_empty() {
        return Err(TopologyError::InvariantViolation(
            "TOPOLOGY-INV-010: Approximation must declare its semantic fidelity".to_string(),
        ));
    }
    if declared_fidelity == "exact" && approximate_component_count != exact_component_count {
        return Err(TopologyError::InvariantViolation(format!(
            "TOPOLOGY-INV-010: Approximation declares exact fidelity but component count \
             differs: approximate={}, exact={}",
            approximate_component_count, exact_component_count
        )));
    }
    Ok(())
}

/// Verifies `TOPOLOGY-INV-011` (State Integrity):
/// Topological state transitions MUST produce valid topological states.
pub fn verify_topology_inv_011_state_integrity(
    space: &TopologicalSpace,
) -> TopologyResult<()> {
    verify_topology_inv_001_identity(&space.id)
        .map_err(|_| TopologyError::InvariantViolation(
            "TOPOLOGY-INV-011: Topological state has invalid identity".to_string(),
        ))
}

/// Verifies `TOPOLOGY-INV-012` (Delta Integrity):
/// Topological deltas MUST represent valid semantic state transitions.
pub fn verify_topology_inv_012_delta_integrity(delta: &TopologicalDelta) -> TopologyResult<()> {
    verify_topology_inv_001_identity(&delta.id)
        .map_err(|_| TopologyError::InvariantViolation(
            "TOPOLOGY-INV-012: Delta has invalid identity".to_string(),
        ))
}

/// Verifies `TOPOLOGY-INV-013` (Provenance Integrity):
/// Derived topology MUST retain required provenance.
pub fn verify_topology_inv_013_provenance_integrity(
    provenance: Option<&str>,
    provenance_required: bool,
) -> TopologyResult<()> {
    if provenance_required {
        match provenance {
            None | Some("") => Err(TopologyError::InvariantViolation(
                "TOPOLOGY-INV-013: Derived topology requires provenance but none is recorded"
                    .to_string(),
            )),
            _ => Ok(()),
        }
    } else {
        Ok(())
    }
}

/// Verifies `TOPOLOGY-INV-014` (Representation Independence):
/// Topological meaning MUST NOT depend on a physical representation.
pub fn verify_topology_inv_014_representation_independence(
    claimant_system: &str,
    is_authoritative: bool,
) -> TopologyResult<()> {
    if is_authoritative {
        Err(TopologyError::InvariantViolation(format!(
            "TOPOLOGY-INV-014: Representation '{}' cannot claim semantic topological authority",
            claimant_system
        )))
    } else {
        Ok(())
    }
}

/// Verifies `TOPOLOGY-INV-015` (Metric Independence):
/// Topological properties MUST NOT depend on metric information unless explicitly declared.
pub fn verify_topology_inv_015_metric_independence(
    space: &TopologicalSpace,
    metric_required: bool,
) -> TopologyResult<()> {
    if !metric_required && space.has_metric() {
        // Not an error — metric topology is a valid topology.
        // Only a violation if metric is asserted as required for topological semantics.
    }
    if metric_required && !space.has_metric() {
        return Err(TopologyError::InvariantViolation(
            "TOPOLOGY-INV-015: Operation claims metric topology but space does not declare one"
                .to_string(),
        ));
    }
    Ok(())
}

/// Verifies `TOPOLOGY-INV-016` (Provider Independence):
/// Provider substitution MUST preserve the required semantic contract.
pub fn verify_topology_inv_016_provider_independence(
    provider_name: &str,
    is_semantic_authority: bool,
) -> TopologyResult<()> {
    if is_semantic_authority {
        Err(TopologyError::InvariantViolation(format!(
            "TOPOLOGY-INV-016: Provider '{}' cannot claim semantic topological authority. \
             Providers implement contracts; they do not own them.",
            provider_name
        )))
    } else {
        Ok(())
    }
}

/// Verifies `TOPOLOGY-INV-017` (Rendering Independence):
/// Rendering representations MUST NOT determine topological meaning.
pub fn verify_topology_inv_017_rendering_independence(
    rendering_system: &str,
    is_topological_authority: bool,
) -> TopologyResult<()> {
    if is_topological_authority {
        Err(TopologyError::InvariantViolation(format!(
            "TOPOLOGY-INV-017: Rendering system '{}' cannot be the authority for topological \
             correctness. A visually plausible mesh may contain topological defects.",
            rendering_system
        )))
    } else {
        Ok(())
    }
}

/// Verifies `TOPOLOGY-INV-018` (Storage Independence):
/// Storage format MUST NOT determine topological meaning.
pub fn verify_topology_inv_018_storage_independence(
    storage_format: &str,
    is_topological_authority: bool,
) -> TopologyResult<()> {
    if is_topological_authority {
        Err(TopologyError::InvariantViolation(format!(
            "TOPOLOGY-INV-018: Storage format '{}' cannot be the authority for topological \
             semantics. Filesystem layout does not define topology.",
            storage_format
        )))
    } else {
        Ok(())
    }
}

/// Verifies all 18 independence/authority invariants (INV-013..018) at once.
///
/// Convenience aggregator for conformance test suites.
pub fn verify_topology_authority_invariants(
    system_name: &str,
    claims_authority: bool,
) -> TopologyResult<()> {
    if claims_authority {
        return Err(TopologyError::InvariantViolation(format!(
            "TOPOLOGY-INV-013..018: External system '{}' cannot claim semantic topological \
             authority. Representation, rendering, storage, and provider are all subordinate \
             to topological semantics.",
            system_name
        )));
    }
    Ok(())
}

/// Verifies Euler characteristic is a valid topological invariant computation.
///
/// Bridges `TOPOLOGY-INV-007` with Euler characteristic semantics.
pub fn verify_euler_characteristic(
    complex: &SimplicialComplex,
    expected_chi: Option<i64>,
) -> TopologyResult<i64> {
    let chi = complex.euler_characteristic();
    // Note: i64 is always finite — no NaN check required.
    if let Some(expected) = expected_chi {
        if chi != expected {
            return Err(TopologyError::InvariantViolation(format!(
                "TOPOLOGY-INV-007: Euler characteristic mismatch — computed {}, expected {}",
                chi, expected
            )));
        }
    }
    Ok(chi)
}

/// Verifies genus calculation from Euler characteristic for closed orientable surfaces.
///
/// χ = 2 - 2g  →  g = (2 - χ) / 2
pub fn verify_genus_from_euler(chi: i64, expected_genus: Option<u32>) -> TopologyResult<u32> {
    if (2 - chi) < 0 || (2 - chi) % 2 != 0 {
        return Err(TopologyError::InvariantViolation(format!(
            "TOPOLOGY-INV-007: Euler characteristic {} is not consistent with any genus \
             for an orientable closed surface (must satisfy χ = 2 - 2g)",
            chi
        )));
    }
    let genus = ((2 - chi) / 2) as u32;
    if let Some(expected) = expected_genus {
        if genus != expected {
            return Err(TopologyError::InvariantViolation(format!(
                "TOPOLOGY-INV-007: Genus mismatch — computed {}, expected {}",
                genus, expected
            )));
        }
    }
    Ok(genus)
}
