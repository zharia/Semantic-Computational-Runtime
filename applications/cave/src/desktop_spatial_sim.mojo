"""
Semantic Spatial Desktop Simulation (Cave PI-CAVE-001F).
Demonstrates SCR semantic authority in Mojo driving the subordinate
OGRE 3D graphics rendering provider for a desktop environment.
"""

from std.collections import List
from scr_kernel.field import SemanticField
from scr_kernel.entity import Entity
from scr_kernel.entity_definition import EntityDefinition
from scr_kernel.relationship import Relationship
from scr_kernel.transformation import Transformation, SET_INT, INCREMENT
from scr_kernel.value import Value
from applications.cave.src.ogre_renderer import OgreRenderer

@fieldwise_init
struct SpatialPose(Copyable, Movable):
    var px: Float32
    var py: Float32
    var pz: Float32
    var qx: Float32
    var qy: Float32
    var qz: Float32
    var qw: Float32

@fieldwise_init
struct DesktopSurface(Copyable, Movable):
    var id: String
    var title: String
    var width: Float32
    var height: Float32
    var pose: SpatialPose

def run_desktop_simulation() raises:
    print("================================================================================")
    print(" CAVE: Semantic Spatial Desktop Simulation (Mojo + SCR Kernel + OGRE 3D)")
    print("================================================================================")

    # 1. Initialize Semantic Field (SCR Kernel Authority)
    var field = SemanticField()

    var workspace = Entity("workspace_0", "Workspace")
    workspace.set("active_surfaces", Value(3))
    field.add_entity(workspace)

    # 2. Define Semantic Desktop Surfaces
    var surfaces = List[DesktopSurface]()
    surfaces.append(DesktopSurface(
        "surface_terminal", 
        "Wayland Terminal (Alacritty)", 
        1.4, 0.9, 
        SpatialPose(-1.1, 0.4, -2.4, 0.0, 0.0, 0.0, 1.0)
    ))
    surfaces.append(DesktopSurface(
        "surface_cad_viewer", 
        "3D Material Voxel Inspector", 
        1.4, 0.9, 
        SpatialPose(1.1, 0.4, -2.4, 0.0, 0.0, 0.0, 1.0)
    ))
    surfaces.append(DesktopSurface(
        "surface_dock", 
        "Desktop Spatial Dock / HUD", 
        2.2, 0.4, 
        SpatialPose(0.0, -0.7, -1.8, 0.2588, 0.0, 0.0, 0.9659)
    ))

    # Register each surface as an entity in the Semantic Field
    for i in range(len(surfaces)):
        var s = surfaces[i].copy()
        var ent = Entity(s.id, "SurfaceEntity")
        ent.set("width_mm", Value(Int(s.width * 1000.0)))
        ent.set("height_mm", Value(Int(s.height * 1000.0)))
        ent.set("z_order", Value(i + 1))
        field.add_entity(ent)
        field.add_relationship(Relationship("rel_" + s.id, "contains", "workspace_0", s.id))

    print("SCR Semantic Field initialized:", len(surfaces), "surfaces registered under workspace_0.")

    # 3. Bootstrap Subordinate OGRE 3D Rendering Provider
    print("\nBootstrapping subordinate OGRE 3D Graphics Provider...")
    var renderer = OgreRenderer()

    # Manifest semantic surfaces into OGRE scene node quads
    for i in range(len(surfaces)):
        var s = surfaces[i].copy()
        var ok = renderer.create_surface_quad(s.id, s.width, s.height)
        if ok:
            var p = s.pose.copy()
            _ = renderer.update_surface_transform(s.id, p.px, p.py, p.pz, p.qx, p.qy, p.qz, p.qw)
            print("  [Manifested]", s.title, "-> OGRE SceneNode quad at (", p.px, ",", p.py, ",", p.pz, ")")

    # Render Frame 0: Initial Layout
    var f0 = renderer.render_frame()
    print("-> Frame 0 rendered: Initial Spatial Desktop Layout (Status:", f0, ")")

    # 4. Simulation Step 1: User Focuses & Translates Terminal
    print("\n--- Timestep 1: User Drags Terminal to Center ---")
    field.execute(Transformation(SET_INT, "surface_terminal", "z_order", 10))
    var p_term = SpatialPose(-0.3, 0.5, -2.0, 0.0, 0.0, 0.0, 1.0)
    _ = renderer.update_surface_transform("surface_terminal", p_term.px, p_term.py, p_term.pz, p_term.qx, p_term.qy, p_term.qz, p_term.qw)
    var f1 = renderer.render_frame()
    print("-> Frame 1 rendered: Terminal translated to (", p_term.px, ",", p_term.py, ",", p_term.pz, ") (Status:", f1, ")")

    # 5. Simulation Step 2: User Rotates CAD Viewer in 3D Space
    print("\n--- Timestep 2: User Rotates 3D CAD Viewer by 45 deg Y-Axis ---")
    var p_cad = SpatialPose(1.3, 0.5, -2.2, 0.0, 0.3827, 0.0, 0.9239)
    _ = renderer.update_surface_transform("surface_cad_viewer", p_cad.px, p_cad.py, p_cad.pz, p_cad.qx, p_cad.qy, p_cad.qz, p_cad.qw)
    var f2 = renderer.render_frame()
    print("-> Frame 2 rendered: CAD Viewer rotated 45 deg on Y-axis (Status:", f2, ")")

    # 6. Simulation Step 3: Minimize Dock and Recenter Workspace
    print("\n--- Timestep 3: Spatial Dock Auto-Hides ---")
    var p_dock_hidden = SpatialPose(0.0, -1.4, -1.8, 0.2588, 0.0, 0.0, 0.9659)
    _ = renderer.update_surface_transform("surface_dock", p_dock_hidden.px, p_dock_hidden.py, p_dock_hidden.pz, p_dock_hidden.qx, p_dock_hidden.qy, p_dock_hidden.qz, p_dock_hidden.qw)
    var f3 = renderer.render_frame()
    print("-> Frame 3 rendered: Dock hidden below viewport (Status:", f3, ")")

    # 7. Clean Shutdown
    print("\nCleaning up OGRE scene nodes and shutting down provider context...")
    for i in range(len(surfaces)):
        renderer.destroy_surface(surfaces[i].id)
    renderer.shutdown()

    print("================================================================================")
    print(" Simulation Completed Successfully: Meaning and Manifestation Separated!")
    print("================================================================================")

def main() raises:
    run_desktop_simulation()
