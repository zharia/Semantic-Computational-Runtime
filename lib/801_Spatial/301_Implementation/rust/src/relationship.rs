/// Qualitative and topological spatial relationships (Section 11 & SPATIAL-INV-005).
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub enum SpatialRelationship {
    /// Region A completely encloses Region/Entity B.
    Contains,
    /// Region/Entity A is completely inside Region B.
    Within,
    /// Two regions share interior points.
    Intersects,
    /// Two regions share only boundary points.
    Touches,
    /// Two entities or regions share no points.
    Disjoint,
    /// Entity A is directly adjacent to Entity B.
    Adjacent,
    /// Directional relationship: Above / Below.
    Above,
    Below,
    /// Directional relationship: North / South / East / West.
    NorthOf,
    SouthOf,
    EastOf,
    WestOf,
}
