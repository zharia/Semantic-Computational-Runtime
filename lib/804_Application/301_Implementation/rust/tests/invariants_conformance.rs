use scr_application::binding::{ArtifactKind, ExecutableArtifact, ExecutionContract, ImplementationBinding};
use scr_application::controller::ApplicationController;
use scr_application::lifecycle::{ApplicationLifecycle, LifecycleState};
use scr_application::module::ApplicationModule;
use scr_application::operation::SemanticOperation;
use scr_application::policy::ApplicationPolicy;
use scr_application::port::{ApplicationPort, PortKind};
use scr_application::provider::ApplicationProvider;
use scr_application::service::ApplicationService;
use scr_application::state::ApplicationState;

#[test]
fn test_architectural_invariants_conformance() {
    // A1: Semantic Primacy & A8: Implementation Separation
    // Semantic operation exists independently of concrete executable technology
    let op = SemanticOperation::new("op_render_frame", "RenderFrame", "FrameBuffer")
        .with_parameter("viewport_id", "String", true)
        .with_idempotence(true);
    assert_eq!(op.id, "op_render_frame");

    // A9: Binding Explicitness & A11: Language Independence
    // The operation binds to Mojo, MLIR, and WASM implementations via explicit bindings
    let artifact_mojo = ExecutableArtifact {
        id: "art_mojo_renderer".to_string(),
        kind: ArtifactKind::Mojo,
        uri: "mojo://renderer/render_frame.mojo".to_string(),
    };
    let artifact_wasm = ExecutableArtifact {
        id: "art_wasm_renderer".to_string(),
        kind: ArtifactKind::Wasm,
        uri: "wasm://renderer/render_frame.wasm".to_string(),
    };
    let contract = ExecutionContract::new_deterministic("cdecl");

    let binding_mojo = ImplementationBinding::new(
        "bnd_mojo",
        &op.id,
        artifact_mojo,
        contract.clone(),
        "render_frame_entry",
    );
    let binding_wasm = ImplementationBinding::new(
        "bnd_wasm",
        &op.id,
        artifact_wasm,
        contract,
        "render_frame_wasm_entry",
    );
    assert_eq!(binding_mojo.operation_id, op.id);
    assert_eq!(binding_wasm.operation_id, op.id);
    assert_ne!(binding_mojo.artifact.kind, binding_wasm.artifact.kind);

    // A3: Modular Composition & A4: Service Independence
    let mut module = ApplicationModule::new("mod_compositor", "CompositorModule");
    let mut srv = ApplicationService::new("srv_compositor", "CompositorService");
    srv.register_operation(op.clone());
    module.register_service(srv);

    // A5: Port Boundary
    let port_in = ApplicationPort::new_inbound("port_cmd", "CommandPort", PortKind::Command, "json_rpc");
    let port_out = ApplicationPort::new_outbound("port_gpu", "GpuPort", PortKind::Display, "dmabuf_v1");
    module.register_port(port_in);
    module.register_port(port_out);

    assert_eq!(module.services.len(), 1);
    assert_eq!(module.ports.len(), 2);

    // A7: Provider Substitution
    let provider_opengl = ApplicationProvider::new("prv_gl", "OpenGLProvider", "Rendering")
        .with_capability("HardwareAcceleration");
    let provider_vulkan = ApplicationProvider::new("prv_vk", "VulkanProvider", "Rendering")
        .with_capability("HardwareAcceleration");
    assert!(provider_opengl.has_capability("HardwareAcceleration"));
    assert!(provider_vulkan.has_capability("HardwareAcceleration"));

    // A13: Controller Boundary
    let mut controller = ApplicationController::new("ctl_input", "InputController", "srv_compositor");
    controller.handled_commands.insert("ResizeWindow".to_string());
    assert!(controller.can_handle_command("ResizeWindow"));
    assert!(!controller.can_handle_command("UnknownCmd"));
    let target = controller.dispatch_command("ResizeWindow").unwrap();
    assert_eq!(target, "srv_compositor");

    // A14: State Authority
    let mut app_state = ApplicationState::new();
    app_state.set_attribute("surface_count", "3");
    assert_eq!(app_state.get_attribute("surface_count"), Some(&"3".to_string()));
    assert_eq!(app_state.version, 2);

    // A15: Authorization Separation
    let policy = ApplicationPolicy::new("pol_admin", "AdminOnly", true)
        .allow_role("Administrator");
    assert!(policy.enforce("Administrator").is_ok());
    assert!(policy.enforce("Guest").is_err());

    // A16: Lifecycle & Version Monotonicity
    let mut lifecycle = ApplicationLifecycle::new();
    assert_eq!(lifecycle.state, LifecycleState::Created);
    assert_eq!(lifecycle.version, 1);
    lifecycle.transition_to(LifecycleState::Initialized).unwrap();
    assert_eq!(lifecycle.version, 2);
}
