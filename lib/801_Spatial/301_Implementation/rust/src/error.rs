use core::fmt;

/// Errors arising within the Spatial domain.
#[derive(Debug, Clone, PartialEq)]
pub enum SpatialError {
    /// The coordinates do not match the expected dimensionality of the spatial context.
    DimensionMismatch {
        expected: usize,
        found: usize,
    },
    /// Coordinate interpretation failed due to incompatible or undefined reference frame.
    IncompatibleReferenceFrame {
        source_frame: String,
        target_frame: String,
    },
    /// The requested distance metric is incompatible with the coordinate system or domain.
    IncompatibleMetric(String),
    /// A spatial transformation was applied across incompatible source/target contexts.
    InvalidTransformation(String),
    /// Out of bounds or invalid region.
    OutOfBounds(String),
    /// Hypergraph mapping failure.
    HypergraphMappingError(String),
}

impl fmt::Display for SpatialError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            SpatialError::DimensionMismatch { expected, found } => {
                write!(f, "Spatial dimension mismatch: expected {}, found {}", expected, found)
            }
            SpatialError::IncompatibleReferenceFrame { source_frame, target_frame } => {
                write!(
                    f,
                    "Incompatible reference frame: cannot transition from '{}' to '{}'",
                    source_frame, target_frame
                )
            }
            SpatialError::IncompatibleMetric(msg) => write!(f, "Incompatible metric: {}", msg),
            SpatialError::InvalidTransformation(msg) => write!(f, "Invalid spatial transformation: {}", msg),
            SpatialError::OutOfBounds(msg) => write!(f, "Spatial out of bounds: {}", msg),
            SpatialError::HypergraphMappingError(msg) => write!(f, "Hypergraph mapping error: {}", msg),
        }
    }
}

pub type SpatialResult<T> = Result<T, SpatialError>;
