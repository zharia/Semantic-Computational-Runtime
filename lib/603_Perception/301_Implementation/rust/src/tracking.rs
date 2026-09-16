use crate::uncertainty::Uncertainty;
use crate::provenance::PerceptualProvenance;

/// A waypoint in a temporal trajectory.
#[derive(Debug, Clone, PartialEq)]
pub struct TrackWaypoint {
    pub timestamp_ns: u64,
    pub coordinates: [f64; 3],
    /// Whether this waypoint was directly observed or predicted (PERCEPTION-INV-024).
    pub is_predicted: bool,
    pub uncertainty: Uncertainty,
}

/// A tracking sequence representing temporal correspondence (Section 18).
#[derive(Debug, Clone, PartialEq)]
pub struct Track {
    pub id: String,
    /// Inferred correspondence label or cluster.
    pub correspondence_label: String,
    /// Associated persistent identity if verified (INV-010).
    pub verified_identity: Option<String>,
    /// Chronological waypoints.
    pub trajectory: Vec<TrackWaypoint>,
    /// Full provenance.
    pub provenance: PerceptualProvenance,
}

impl Track {
    pub fn new(
        id: impl Into<String>,
        correspondence_label: impl Into<String>,
        provenance: PerceptualProvenance,
    ) -> Self {
        Self {
            id: id.into(),
            correspondence_label: correspondence_label.into(),
            verified_identity: None,
            trajectory: Vec::new(),
            provenance,
        }
    }

    pub fn with_observed_waypoint(
        mut self,
        timestamp_ns: u64,
        coordinates: [f64; 3],
        uncertainty: Uncertainty,
    ) -> Self {
        self.trajectory.push(TrackWaypoint {
            timestamp_ns,
            coordinates,
            is_predicted: false,
            uncertainty,
        });
        self
    }

    pub fn with_predicted_waypoint(
        mut self,
        timestamp_ns: u64,
        coordinates: [f64; 3],
        uncertainty: Uncertainty,
    ) -> Self {
        self.trajectory.push(TrackWaypoint {
            timestamp_ns,
            coordinates,
            is_predicted: true,
            uncertainty,
        });
        self
    }
}
