use crate::position::{Coordinates, Position};

/// Instantaneous spatial velocity vector (Section 25).
#[derive(Debug, Clone, PartialEq)]
pub struct SpatialVelocity {
    pub reference_frame_id: String,
    pub linear: Vec<f64>,
    pub angular: Option<Vec<f64>>,
}

/// A spatial trajectory waypoint with temporal timestamp (Section 25 & SPATIAL-INV-011).
#[derive(Debug, Clone, PartialEq)]
pub struct TrajectoryWaypoint {
    pub timestamp_ns: u64,
    pub coordinates: Coordinates,
}

/// Dynamic spatial state distinguishing motion from static positioning (Section 25 & SPATIAL-INV-011).
#[derive(Debug, Clone, PartialEq)]
pub struct DynamicSpatialState {
    pub entity_uri: String,
    pub current_position: Position,
    pub velocity: Option<SpatialVelocity>,
    pub trajectory: Vec<TrajectoryWaypoint>,
    pub timestamp_ns: u64,
}

impl DynamicSpatialState {
    pub fn new(
        entity_uri: impl Into<String>,
        current_position: Position,
        timestamp_ns: u64,
    ) -> Self {
        Self {
            entity_uri: entity_uri.into(),
            current_position,
            velocity: None,
            trajectory: Vec::new(),
            timestamp_ns,
        }
    }

    pub fn with_velocity(mut self, velocity: SpatialVelocity) -> Self {
        self.velocity = Some(velocity);
        self
    }

    pub fn record_waypoint(&mut self, timestamp_ns: u64, coordinates: Coordinates) {
        self.trajectory.push(TrajectoryWaypoint {
            timestamp_ns,
            coordinates,
        });
        self.timestamp_ns = timestamp_ns;
    }
}
