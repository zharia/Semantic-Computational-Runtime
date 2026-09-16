/// Explicit coordinate system representation (Section 3).
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub enum CoordinateSystem {
    Cartesian1D,
    Cartesian2D,
    Cartesian3D,
    Polar,
    Spherical,
    Cylindrical,
    GeospatialWGS84,
    DiscreteGrid2D,
    DiscreteGrid3D,
    Custom(String),
}

/// An explicit declared reference frame (Section 4 & SPATIAL-INV-002).
#[derive(Debug, Clone, PartialEq)]
pub struct ReferenceFrame {
    pub id: String,
    pub domain_id: String,
    pub coordinate_system: CoordinateSystem,
    pub parent_frame_id: Option<String>,
    pub origin_offset: Vec<f64>,
}

impl ReferenceFrame {
    pub fn new(
        id: impl Into<String>,
        domain_id: impl Into<String>,
        coordinate_system: CoordinateSystem,
    ) -> Self {
        Self {
            id: id.into(),
            domain_id: domain_id.into(),
            coordinate_system,
            parent_frame_id: None,
            origin_offset: Vec::new(),
        }
    }

    pub fn with_parent(
        mut self,
        parent_id: impl Into<String>,
        offset: Vec<f64>,
    ) -> Self {
        self.parent_frame_id = Some(parent_id.into());
        self.origin_offset = offset;
        self
    }
}
