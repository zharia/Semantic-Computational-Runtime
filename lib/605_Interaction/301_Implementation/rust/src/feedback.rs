/// Type of feedback communicated during interaction (Section 69).
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum FeedbackType {
    Preview,
    Recognition,
    Confirmation,
    Result,
    Cancellation,
}

/// Semantic feedback returned to an actor or observer (Section 38 & INT-017).
#[derive(Debug, Clone, PartialEq)]
pub struct Feedback {
    pub id: String,
    pub session_id: String,
    pub feedback_type: FeedbackType,
    pub semantic_message: String,
    pub payload: Vec<(String, f64)>,
}

impl Feedback {
    pub fn new(
        id: impl Into<String>,
        session_id: impl Into<String>,
        feedback_type: FeedbackType,
        semantic_message: impl Into<String>,
    ) -> Self {
        Self {
            id: id.into(),
            session_id: session_id.into(),
            feedback_type,
            semantic_message: semantic_message.into(),
            payload: Vec::new(),
        }
    }

    pub fn preview(session_id: impl Into<String>, message: impl Into<String>) -> Self {
        Self::new("fb:prev", session_id, FeedbackType::Preview, message)
    }

    pub fn result(session_id: impl Into<String>, message: impl Into<String>) -> Self {
        Self::new("fb:res", session_id, FeedbackType::Result, message)
    }

    pub fn cancellation(session_id: impl Into<String>, reason: impl Into<String>) -> Self {
        Self::new("fb:cancel", session_id, FeedbackType::Cancellation, reason)
    }
}
