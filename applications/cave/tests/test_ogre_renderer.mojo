from applications.cave.src.ogre_renderer import OgreRenderer

def main() raises:
    print("Initializing OgreRenderer in Mojo...")
    var renderer = OgreRenderer()
    
    var ok = renderer.create_surface_quad("terminal_win", 1.2, 0.8)
    if ok:
        print("Created surface quad 'terminal_win'")
    else:
        print("Failed to create quad")
        
    var t_res = renderer.update_surface_transform(
        "terminal_win", 
        0.5, 1.0, -2.0, 
        0.0, 0.0, 0.0, 1.0
    )
    print("Updated transform status:", t_res)
    
    var frame_res = renderer.render_frame()
    print("Rendered frame status:", frame_res)
    
    renderer.destroy_surface("terminal_win")
    renderer.shutdown()
    print("OgreRenderer test completed successfully!")
