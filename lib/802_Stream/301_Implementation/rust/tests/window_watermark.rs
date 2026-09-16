// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

use scr_stream::{
    ElementPayload, ProvenanceRecord, StreamElement, StreamElementId, StreamWindow, Watermark,
};

#[test]
fn test_window_assignment_and_watermark_closure() {
    // Window spanning [1000, 2000)
    let mut window = StreamWindow::new("win-1000-2000", 1000, 2000);

    let elem1 = StreamElement::new(
        StreamElementId::new("e1"),
        "Event",
        ElementPayload::Scalar(10.0),
        ProvenanceRecord::root("source"),
    );

    let elem2 = StreamElement::new(
        StreamElementId::new("e2"),
        "Event",
        ElementPayload::Scalar(20.0),
        ProvenanceRecord::root("source"),
    );

    // Assign elem1 at t=1500 (inside bounds)
    assert!(window.assign(elem1, 1500).is_ok());
    assert_eq!(window.len(), 1);

    // Try assigning outside window bounds (t=2500)
    assert!(window.assign(elem2.clone(), 2500).is_err());

    // Watermark advances to 1800 (window stays open)
    let mut wm = Watermark::new(1800);
    assert!(!window.evaluate_watermark(wm));
    assert!(!window.is_closed);

    // Assign elem2 at t=1900
    assert!(window.assign(elem2, 1900).is_ok());
    assert_eq!(window.len(), 2);

    // Watermark advances to 2000 (window boundary reached, closes window)
    wm.advance_to(2000).unwrap();
    assert!(window.evaluate_watermark(wm));
    assert!(window.is_closed);

    // Late arriving element rejected because window is closed
    let elem_late = StreamElement::new(
        StreamElementId::new("e_late"),
        "Event",
        ElementPayload::Scalar(15.0),
        ProvenanceRecord::root("source"),
    );
    assert!(window.assign(elem_late, 1600).is_err());
}
