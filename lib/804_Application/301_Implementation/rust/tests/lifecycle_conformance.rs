use scr_application::error::ApplicationError;
use scr_application::lifecycle::{ApplicationLifecycle, LifecycleState};

#[test]
fn test_valid_lifecycle_progression() {
    let mut lc = ApplicationLifecycle::new();
    assert_eq!(lc.state, LifecycleState::Created);
    assert_eq!(lc.version, 1);

    // Created -> Initialized
    lc.transition_to(LifecycleState::Initialized).unwrap();
    assert_eq!(lc.state, LifecycleState::Initialized);
    assert_eq!(lc.version, 2);

    // Initialized -> Configured
    lc.transition_to(LifecycleState::Configured).unwrap();
    assert_eq!(lc.state, LifecycleState::Configured);
    assert_eq!(lc.version, 3);

    // Configured -> Active
    lc.transition_to(LifecycleState::Active).unwrap();
    assert!(lc.is_active());
    assert_eq!(lc.version, 4);

    // Active -> Suspended -> Active
    lc.transition_to(LifecycleState::Suspended).unwrap();
    assert_eq!(lc.state, LifecycleState::Suspended);
    lc.transition_to(LifecycleState::Active).unwrap();
    assert!(lc.is_active());

    // Active -> Draining -> Terminated
    lc.transition_to(LifecycleState::Draining).unwrap();
    assert_eq!(lc.state, LifecycleState::Draining);
    lc.transition_to(LifecycleState::Terminated).unwrap();
    assert!(lc.is_terminated());
}

#[test]
fn test_illegal_lifecycle_transitions_rejected() {
    let mut lc = ApplicationLifecycle::new();

    // Cannot jump from Created to Active directly
    let res = lc.transition_to(LifecycleState::Active);
    match res {
        Err(ApplicationError::IllegalLifecycleTransition { from, to }) => {
            assert_eq!(from, "Created");
            assert_eq!(to, "Active");
        }
        other => panic!("Expected IllegalLifecycleTransition, got {:?}", other),
    }

    // Advance to Terminated
    lc.transition_to(LifecycleState::Initialized).unwrap();
    lc.transition_to(LifecycleState::Configured).unwrap();
    lc.transition_to(LifecycleState::Active).unwrap();
    lc.transition_to(LifecycleState::Draining).unwrap();
    lc.transition_to(LifecycleState::Terminated).unwrap();

    // Terminal immutability: Cannot transition out of Terminated
    let res_term = lc.transition_to(LifecycleState::Active);
    assert!(matches!(res_term, Err(ApplicationError::ApplicationTerminated(_))));
}
