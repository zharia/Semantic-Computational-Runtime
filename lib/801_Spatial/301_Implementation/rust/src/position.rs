use crate::error::{SpatialError, SpatialResult};

/// Concrete numeric coordinate values expressed within a reference frame (Section 3).
#[derive(Debug, Clone, PartialEq)]
pub struct Coordinates {
    pub reference_frame_id: String,
    pub values: Vec<f64>,
}

impl Coordinates {
    pub fn new(reference_frame_id: impl Into<String>, values: Vec<f64>) -> Self {
        Self {
            reference_frame_id: reference_frame_id.into(),
            values,
        }
    }

    pub fn dim(&self) -> usize {
        self.values.len()
    }

    pub fn as_2d(&self) -> SpatialResult<[f64; 2]> {
        if self.values.len() == 2 {
            Ok([self.values[0], self.values[1]])
        } else {
            Err(SpatialError::DimensionMismatch {
                expected: 2,
                found: self.values.len(),
            })
        }
    }

    pub fn as_3d(&self) -> SpatialResult<[f64; 3]> {
        if self.values.len() == 3 {
            Ok([self.values[0], self.values[1], self.values[2]])
        } else {
            Err(SpatialError::DimensionMismatch {
                expected: 3,
                found: self.values.len(),
            })
        }
    }
}

/// A semantic spatial locus (Section 2 & SPATIAL-INV-004).
/// Strictly distinguishes the semantic concept of "Position" from its "Coordinates".
#[derive(Debug, Clone, PartialEq)]
pub struct Position {
    /// Semantic identifier or entity URI for which this is the position.
    pub entity_uri: String,
    /// Explicit coordinate representation.
    pub coordinates: Coordinates,
    /// Label or semantic landmark (e.g. "Origin", "TargetWaypoint", "DockingBay").
    pub landmark_label: Option<String>,
}

impl Position {
    pub fn new(entity_uri: impl Into<String>, coordinates: Coordinates) -> Self {
        Self {
            entity_uri: entity_uri.into(),
            coordinates,
            landmark_label: None,
        }
    }

    pub fn with_landmark(mut self, label: impl Into<String>) -> Self {
        self.landmark_label = Some(label.into());
        self
    }
}
