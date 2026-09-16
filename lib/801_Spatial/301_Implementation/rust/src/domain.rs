/// Semantically explicit spatial dimensionality (Section 1 & SPATIAL-INV-003).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum Dimensionality {
    Dim1D,
    Dim2D,
    Dim3D,
    Dim4D,
    DimND(usize),
}

impl Dimensionality {
    pub fn dimensions(&self) -> usize {
        match self {
            Self::Dim1D => 1,
            Self::Dim2D => 2,
            Self::Dim3D => 3,
            Self::Dim4D => 4,
            Self::DimND(n) => *n,
        }
    }
}

/// The nature of the spatial continuum or substrate (Section 1).
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub enum SpatialDomainKind {
    ContinuousEuclidean,
    DiscreteGrid,
    GeospatialSurface,
    GraphTopology,
    Manifold,
    AbstractMetricSpace,
    Custom(String),
}

/// A declared spatial domain (Section 1 & Model S).
#[derive(Debug, Clone, PartialEq)]
pub struct SpatialDomain {
    pub id: String,
    pub kind: SpatialDomainKind,
    pub dimensionality: Dimensionality,
    pub description: String,
}

impl SpatialDomain {
    pub fn new(
        id: impl Into<String>,
        kind: SpatialDomainKind,
        dimensionality: Dimensionality,
    ) -> Self {
        Self {
            id: id.into(),
            kind,
            dimensionality,
            description: String::new(),
        }
    }

    pub fn with_description(mut self, desc: impl Into<String>) -> Self {
        self.description = desc.into();
        self
    }
}
