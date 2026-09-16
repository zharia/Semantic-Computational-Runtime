use scr_hypergraph::Hypergraph;
use scr_interaction::*;

#[test]
fn test_int_002_device_independence_and_distinction_chain() {
    // INT-002: Device independence
    // INT-003, INT-004, INT-005, INT-006: Chain of distinction:
    // Input != Observation != Gesture != Intent != Action
    let pointer = Pointer::new("ptr:mouse", [100.0, 200.0, 0.0], PointerState::PrimaryDown);
    let input = Input::pointer_event("inp:001", 1_000_000, pointer);
    assert_eq!(input.modality, InputModality::Pointer);

    let obs = InteractionObservation::new(
        "obs:001",
        "actor:craig",
        input,
        "scr://devices/pointer/mouse",
        1_000_050,
    );
    assert_eq!(obs.actor_id, "actor:craig");

    let gesture = Gesture::new("gest:tap", GestureKind::Tap)
        .with_phase(GesturePhase::Stroke)
        .with_confidence(0.98);
    assert_eq!(gesture.kind, GestureKind::Tap);

    let intent = Intent::new(
        "intent:select_node",
        IntentKind::Select,
        InteractionTarget::Entity {
            uri: "scr://graph/node-42".into(),
        },
    );
    assert_eq!(intent.kind, IntentKind::Select);

    let mapping = InteractionMapping::new(
        "map:select",
        "scr://ops/graph/select_entity",
        Reversibility::Reversible,
    );
    let ctx = InteractionContext::new("ctx:graph_editor", InteractionMode::Selection, "actor:craig");
    let action = mapping.resolve(&intent, &ctx).expect("Mapping resolution should succeed");

    assert_eq!(action.operation_uri, "scr://ops/graph/select_entity");
    assert_eq!(action.reversibility, Reversibility::Reversible);
}

#[test]
fn test_int_008_009_010_sequence_chord_non_equivalence() {
    // INT-008: Sequence semantics (temporal ordering)
    // INT-009: Chord semantics (concurrency)
    // INT-010: Sequence != Chord
    let g1 = Gesture::new("g1", GestureKind::PressAndHold);
    let g2 = Gesture::new("g2", GestureKind::Drag);

    let seq = GestureSequence::new("seq:hold_drag", vec![g1.clone(), g2.clone()]);
    let chord = GestureChord::new("chord:hold_drag", vec![g1, g2]);

    assert_eq!(seq.len(), 2);
    assert_eq!(chord.len(), 2);

    let expr_seq = InteractionExpression::Sequence(vec![
        InteractionExpression::Atomic(seq.elements[0].clone()),
        InteractionExpression::Atomic(seq.elements[1].clone()),
    ]);
    let expr_chord = InteractionExpression::Chord(vec![
        InteractionExpression::Atomic(chord.elements[0].clone()),
        InteractionExpression::Atomic(chord.elements[1].clone()),
    ]);

    assert!(expr_seq.is_sequence());
    assert!(!expr_seq.is_chord());

    assert!(expr_chord.is_chord());
    assert!(!expr_chord.is_sequence());

    // Strict semantic non-equivalence
    assert_ne!(expr_seq, expr_chord);
}

#[test]
fn test_int_014_015_016_session_lifecycle_commitment_and_cancellation() {
    // INT-014: Session integrity
    // INT-015: Cancellation guarantees no state modification
    // INT-016: Commitment triggers explicit action
    let mut session = InteractionSession::new("sess:001", "actor:user1", "ctx:editor");
    assert_eq!(session.state, SessionState::Idle);

    session.begin().expect("Session begin should succeed");
    assert_eq!(session.state, SessionState::Active);

    let action = Action::new(
        "act:001",
        "scr://ops/delete_geometry",
        "intent:delete",
        Reversibility::Irreversible,
    );
    session.stage_action(action.clone()).expect("Staging action should succeed");
    assert!(session.pending_action.is_some());

    // Scenario A: Cancellation
    let mut cancel_session = session.clone();
    let cancel_res = cancel_session.cancel("User pressed Escape");
    assert!(cancel_res.is_err());
    assert_eq!(cancel_session.state, SessionState::Cancelled);
    assert!(cancel_session.pending_action.is_none()); // Discarded!
    assert!(cancel_session.committed_actions.is_empty()); // No committed actions!

    // Scenario B: Commitment
    let committed_action = session.commit().expect("Commit should succeed");
    assert_eq!(session.state, SessionState::Committed);
    assert!(session.pending_action.is_none());
    assert_eq!(session.committed_actions.len(), 1);
    assert_eq!(committed_action, Some(action));
}

#[test]
fn test_int_020_024_hypergraph_projection_and_nullary_relations() {
    // INT-020: Canonical hypergraph authority
    // INT-024: Nullary relation integrity (|I(R)| = 0)
    let actor = Actor::new("craig", ActorKind::Human);
    let gesture = Gesture::new("gest:pinch", GestureKind::Pinch);
    let intent = Intent::new(
        "intent:zoom",
        IntentKind::Scale,
        InteractionTarget::Entity {
            uri: "scr://viewport/camera_0".into(),
        },
    );

    let nullary_assertions = vec![
        "InteractionModalityActive".into(),
        "ErgonomicThresholdSatisfied".into(),
    ];

    let mut hg = Hypergraph::new();
    project_interaction_to_hypergraph(
        "int:001",
        &actor,
        &gesture,
        &intent,
        &nullary_assertions,
        &mut hg,
    )
    .expect("Hypergraph projection must succeed");

    // Elements: Actor, Gesture, Intent, Target = 4 elements
    assert_eq!(hg.element_count(), 4);
    // Relations: 1 InteractionExecution relation + 2 Nullary relations = 3 relations
    assert_eq!(hg.relation_count(), 3);
    // Incidences: Actor (1) + Gesture (1) + Intent (1) + Target (1) = 4 incidences
    // Nullary relations have exactly 0 incidences (|I(R)| = 0)
    assert_eq!(hg.incidence_count(), 4);
}

#[test]
fn test_int_030_human_machine_equivalence() {
    // INT-030: Equivalent semantic interaction from human vs autonomous agent
    let human = Actor::new("human:operator", ActorKind::Human);
    let agent = Actor::new("agent:optimizer", ActorKind::Agent);

    let gesture_human = Gesture::new("g:voice", GestureKind::VoiceTrigger);
    let gesture_agent = Gesture::new("g:cmd", GestureKind::SemanticTrigger);

    let target = InteractionTarget::Entity {
        uri: "scr://scene/simulation_grid".into(),
    };

    let intent_human = Intent::new("intent:step_h", IntentKind::Trigger, target.clone())
        .with_param("step_count", 1.0);
    let intent_agent = Intent::new("intent:step_a", IntentKind::Trigger, target)
        .with_param("step_count", 1.0);

    let mapping = InteractionMapping::new(
        "map:sim_step",
        "scr://ops/simulation/step",
        Reversibility::Reversible,
    );
    let ctx = InteractionContext::new("ctx:sim", InteractionMode::SimulationControl, "system");

    let action_human = mapping.resolve(&intent_human, &ctx).unwrap();
    let action_agent = mapping.resolve(&intent_agent, &ctx).unwrap();

    // Semantic operation URI and parameters are strictly identical
    assert_eq!(action_human.operation_uri, action_agent.operation_uri);
    assert_eq!(action_human.payload, action_agent.payload);
    assert_ne!(human.kind, agent.kind);
    assert_ne!(gesture_human.kind, gesture_agent.kind);
}
