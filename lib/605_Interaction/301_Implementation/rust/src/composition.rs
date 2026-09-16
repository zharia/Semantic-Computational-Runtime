use crate::gesture::Gesture;

/// An ordered temporal sequence of gestures (Section 20 & INT-008).
/// Invariant INT-008: Temporal ordering is strictly preserved.
#[derive(Debug, Clone, PartialEq)]
pub struct GestureSequence {
    pub id: String,
    pub elements: Vec<Gesture>,
}

impl GestureSequence {
    pub fn new(id: impl Into<String>, elements: Vec<Gesture>) -> Self {
        Self {
            id: id.into(),
            elements,
        }
    }

    pub fn len(&self) -> usize {
        self.elements.len()
    }

    pub fn is_empty(&self) -> bool {
        self.elements.is_empty()
    }
}

/// A concurrent combination of simultaneously active gestures (Section 21 & INT-009).
/// Invariant INT-009: Concurrency is strictly preserved.
#[derive(Debug, Clone, PartialEq)]
pub struct GestureChord {
    pub id: String,
    pub elements: Vec<Gesture>,
}

impl GestureChord {
    pub fn new(id: impl Into<String>, elements: Vec<Gesture>) -> Self {
        Self {
            id: id.into(),
            elements,
        }
    }

    pub fn len(&self) -> usize {
        self.elements.len()
    }

    pub fn is_empty(&self) -> bool {
        self.elements.is_empty()
    }
}

/// Composition operator kind (Section 23).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum CompositionOp {
    Sequence,
    Chord,
    Alternative,
    Optional,
    Repetition,
}

/// Algebraic interaction expression supporting regular composition operators (Section 19 & INT-011).
#[derive(Debug, Clone, PartialEq)]
pub enum InteractionExpression {
    /// Atomic gesture.
    Atomic(Gesture),
    /// Temporal sequence A followed by B (Section 20).
    Sequence(Vec<InteractionExpression>),
    /// Concurrent chord A simultaneously with B (Section 21).
    Chord(Vec<InteractionExpression>),
    /// Alternative A | B (Section 24).
    Alternative(Vec<InteractionExpression>),
    /// Optional A? (Section 25).
    Optional(Box<InteractionExpression>),
    /// Repetition A* (Section 26).
    Repetition(Box<InteractionExpression>),
}

impl InteractionExpression {
    pub fn is_chord(&self) -> bool {
        matches!(self, InteractionExpression::Chord(_))
    }

    pub fn is_sequence(&self) -> bool {
        matches!(self, InteractionExpression::Sequence(_))
    }
}
