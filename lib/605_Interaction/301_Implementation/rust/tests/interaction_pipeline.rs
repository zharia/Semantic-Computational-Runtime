use scr_hypergraph::Hypergraph;
use scr_interaction::*;

#[test]
fn test_end_to_end_multimodal_interaction_pipeline() {
    // 1. Participant Definition (Subdomain Actor)
    let actor = Actor::new("actor:spatial_operator", ActorKind::Human)
        .with_authority("auth:scene:manipulate");
    let observer = Observer::new("observer:display_wall", ActorKind::Machine);
    assert_eq!(observer.kind, ActorKind::Machine);

    // 2. Multimodal Inputs (Subdomains Input & Observation)
    // Primary Spatial pointer input + Secondary Voice command trigger
    let spatial_pointer = Pointer::new("ptr:hand_r", [1.2, 0.5, -0.3], PointerState::Dragging);
    let input_spatial = Input::pointer_event("inp:hand_move", 1_700_000_000, spatial_pointer);
    let input_voice = Input::semantic_event("inp:voice_cmd", 1_700_000_005, vec![42.0]); // "Translate"

    let obs_spatial = InteractionObservation::new(
        "obs:spatial_01",
        &actor.id,
        input_spatial,
        "scr://sensors/optitrack_hand",
        1_700_000_000,
    );
    let obs_voice = InteractionObservation::new(
        "obs:voice_01",
        &actor.id,
        input_voice,
        "scr://sensors/microphone_array",
        1_700_000_005,
    );
    assert_eq!(obs_spatial.actor_id, obs_voice.actor_id);

    // 3. Gestures & Composition (Subdomains Gesture & Composition)
    let mut drag_path = GesturePath::new();
    drag_path.add_waypoint(1_700_000_000, [1.2, 0.5, -0.3]);
    drag_path.add_waypoint(1_700_000_050, [1.5, 0.8, -0.3]);

    let gesture_drag = Gesture::new("g:spatial_drag", GestureKind::Drag)
        .with_phase(GesturePhase::Stroke)
        .with_path(drag_path)
        .with_confidence(0.95);

    let gesture_voice = Gesture::new("g:voice_trigger", GestureKind::VoiceTrigger)
        .with_phase(GesturePhase::Stroke)
        .with_confidence(0.99);

    // Concurrent Multimodal Chord (Voice + Hand Drag) (INT-009, INT-029)
    let chord = GestureChord::new(
        "chord:voice_and_drag",
        vec![gesture_drag.clone(), gesture_voice.clone()],
    );
    assert_eq!(chord.len(), 2);

    // 4. Context & Intent (Subdomains Context, Target & Intent)
    let context = InteractionContext::new(
        "ctx:cave_workspace",
        InteractionMode::Manipulation,
        &actor.id,
    )
    .with_frame("cave_origin")
    .with_param("grid_snap", "true");

    let target = InteractionTarget::Entity {
        uri: "scr://cave/objects/voxel_volume_01".into(),
    };

    let intent = Intent::new("intent:translate_volume", IntentKind::Translate, target)
        .with_confidence(0.97)
        .with_param("delta_x", 0.3)
        .with_param("delta_y", 0.3)
        .with_param("delta_z", 0.0);
    assert_eq!(intent.confidence, 0.97);

    // 5. Mapping & Session Execution (Subdomains Mapping & Session)
    let mapping = InteractionMapping::new(
        "map:translate_entity",
        "scr://ops/spatial/translate",
        Reversibility::Reversible,
    );

    let mut session = InteractionSession::new("sess:cave_01", &actor.id, &context.id);
    session.begin().expect("Session begin must succeed");

    // Resolve Intent to Action under Context
    let action = mapping.resolve(&intent, &context).expect("Action resolution must succeed");
    session.stage_action(action.clone()).expect("Staging action must succeed");

    // Emit Preview Feedback (Subdomain Feedback)
    let fb_preview = Feedback::preview(&session.id, "Staged translation of voxel_volume_01 by [0.3, 0.3, 0.0]");
    assert_eq!(fb_preview.feedback_type, FeedbackType::Preview);

    // Commit Session (INT-016)
    let committed = session.commit().expect("Commit must succeed");
    assert_eq!(committed, Some(action.clone()));

    // Emit Result Feedback
    let fb_result = Feedback::result(&session.id, "Translation applied successfully");
    assert_eq!(fb_result.feedback_type, FeedbackType::Result);

    // 6. Project into Canonical Hypergraph (Section 53 & INT-020, INT-024)
    let mut hypergraph = Hypergraph::new();
    let nullary_assertions = vec!["SessionCommittedSuccessfully".into()];

    project_interaction_to_hypergraph(
        "int:cave_manip_01",
        &actor,
        &gesture_drag,
        &intent,
        &nullary_assertions,
        &mut hypergraph,
    )
    .expect("Projection to canonical hypergraph must succeed");

    // Elements: Actor, Gesture, Intent, Target = 4 elements
    assert_eq!(hypergraph.element_count(), 4);
    // Relations: 1 InteractionExecution relation + 1 Nullary relation = 2 relations
    assert_eq!(hypergraph.relation_count(), 2);
    // Incidences: 4 directed incidences on the interaction execution relation
    assert_eq!(hypergraph.incidence_count(), 4);
}
