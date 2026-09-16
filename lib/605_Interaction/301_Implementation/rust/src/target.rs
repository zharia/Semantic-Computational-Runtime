/// Target recipient of an interaction (Section 29 & INT-022).
#[derive(Debug, Clone, PartialEq)]
pub enum InteractionTarget {
    /// Targeted semantic entity URI.
    Entity { uri: String },
    /// Targeted hypergraph element ID.
    HypergraphElement { element_id: String },
    /// Targeted 3D coordinate point.
    SpatialCoordinate([f64; 3]),
    /// Targeted spatial bounding volume [min, max].
    SpatialRegion { min: [f64; 3], max: [f64; 3] },
    /// Global target (environment / viewport).
    Global,
}
