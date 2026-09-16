/// Explicit representation of spatial uncertainty (Section 24 & SPATIAL-INV-015).
#[derive(Debug, Clone, PartialEq)]
pub enum SpatialUncertainty {
    /// Perfectly deterministic / nominal spatial state.
    Certain,
    /// Radial error bounds in declared units (e.g. GPS error margin in meters).
    ErrorRadius(f64),
    /// Full N-dimensional covariance matrix.
    Covariance(Vec<Vec<f64>>),
    /// Qualitative or fuzzy uncertainty label.
    Qualitative(String),
}

impl SpatialUncertainty {
    pub fn is_certain(&self) -> bool {
        matches!(self, Self::Certain)
    }
}
