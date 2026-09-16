//! # Semantic Computational Runtime (SCR) — Interaction Domain
//!
//! Authoritative normative interaction foundation conforming to:
//! `lib/605_Interaction/101_definition.md` (`SCR-LIB-INTERACTION`, v0.0.1).
//!
//! The Interaction domain defines the semantic structures through which an
//! actor, observer, agent, process, device, or computational entity participates
//! in a computational field.

pub mod error;
pub mod actor;
pub mod input;
pub mod observation;
pub mod gesture;
pub mod composition;
pub mod context;
pub mod target;
pub mod intent;
pub mod mapping;
pub mod session;
pub mod feedback;
pub mod ergonomics;
pub mod hypergraph;

pub use error::{InteractionError, InteractionResult};
pub use actor::{Actor, ActorKind, Observer};
pub use input::{Input, InputModality, Pointer, PointerState};
pub use observation::InteractionObservation;
pub use gesture::{Gesture, GestureCandidate, GestureConstraint, GestureKind, GesturePath, GesturePhase, GestureWaypoint};
pub use composition::{CompositionOp, GestureChord, GestureSequence, InteractionExpression};
pub use context::{InteractionContext, InteractionMode};
pub use target::InteractionTarget;
pub use intent::{Intent, IntentKind};
pub use mapping::{Action, Command, InteractionMapping, Reversibility};
pub use session::{InteractionSession, SessionState};
pub use feedback::{Feedback, FeedbackType};
pub use ergonomics::{AccessibilityPreference, InteractionCost};
pub use hypergraph::project_interaction_to_hypergraph;
