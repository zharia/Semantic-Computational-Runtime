/// Phase of gesture execution (Section 17).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum GesturePhase {
    Rest,
    Preparation,
    Stroke,
    Hold,
    Retraction,
}

/// Category or kind of semantic gesture (Section 13).
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub enum GestureKind {
    Point,
    Tap,
    DoubleTap,
    PressAndHold,
    Drag,
    Swipe,
    Pinch,
    Rotate,
    SpatialWave,
    SpatialGrab,
    SpatialRelease,
    VoiceTrigger,
    SemanticTrigger,
    Custom(String),
}

/// A spatial/temporal trajectory waypoint in a gesture path (Section 16).
#[derive(Debug, Clone, PartialEq)]
pub struct GestureWaypoint {
    pub timestamp_ns: u64,
    pub position: [f64; 3],
}

/// The spatial/temporal path traced by a gesture (Section 16).
#[derive(Debug, Clone, PartialEq, Default)]
pub struct GesturePath {
    pub waypoints: Vec<GestureWaypoint>,
}

impl GesturePath {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn add_waypoint(&mut self, timestamp_ns: u64, position: [f64; 3]) {
        self.waypoints.push(GestureWaypoint {
            timestamp_ns,
            position,
        });
    }

    pub fn duration_ns(&self) -> u64 {
        if self.waypoints.len() < 2 {
            return 0;
        }
        self.waypoints.last().unwrap().timestamp_ns - self.waypoints.first().unwrap().timestamp_ns
    }
}

/// Constraints bounding valid gesture execution (Section 18).
#[derive(Debug, Clone, PartialEq)]
pub struct GestureConstraint {
    pub max_duration_ns: Option<u64>,
    pub min_duration_ns: Option<u64>,
    pub max_displacement: Option<f64>,
}

/// A gesture candidate under recognition evaluation (Section 14 & INT-004).
#[derive(Debug, Clone, PartialEq)]
pub struct GestureCandidate {
    pub candidate_kind: GestureKind,
    pub path: GesturePath,
    pub recognition_score: f64,
}

/// A recognized semantic gesture (Section 13 & INT-003, INT-005).
#[derive(Debug, Clone, PartialEq)]
pub struct Gesture {
    pub id: String,
    pub kind: GestureKind,
    pub phase: GesturePhase,
    pub path: GesturePath,
    pub confidence: f64,
}

impl Gesture {
    pub fn new(id: impl Into<String>, kind: GestureKind) -> Self {
        Self {
            id: id.into(),
            kind,
            phase: GesturePhase::Stroke,
            path: GesturePath::new(),
            confidence: 1.0,
        }
    }

    pub fn with_phase(mut self, phase: GesturePhase) -> Self {
        self.phase = phase;
        self
    }

    pub fn with_path(mut self, path: GesturePath) -> Self {
        self.path = path;
        self
    }

    pub fn with_confidence(mut self, confidence: f64) -> Self {
        self.confidence = confidence.clamp(0.0, 1.0);
        self
    }
}
