from std.python import Python

def main() raises:
    var ctypes = Python.import_module("ctypes")
    var so_path = "/home/kobus/Projects/Semantic-Computational-Runtime/providers/render/graphics/ogre/adapter/libscr_ogre_adapter.so"
    var ogre_lib = ctypes.CDLL(so_path)
    
    ogre_lib.ogre_init_headless.restype = ctypes.c_void_p
    ogre_lib.ogre_create_quad.restype = ctypes.c_void_p
    ogre_lib.ogre_create_quad.argtypes = [ctypes.c_void_p, ctypes.c_char_p, ctypes.c_float, ctypes.c_float]
    ogre_lib.ogre_set_node_transform.argtypes = [
        ctypes.c_void_p,
        ctypes.c_float, ctypes.c_float, ctypes.c_float,
        ctypes.c_float, ctypes.c_float, ctypes.c_float, ctypes.c_float
    ]
    ogre_lib.ogre_set_node_transform.restype = ctypes.c_int
    ogre_lib.ogre_render_one_frame.argtypes = [ctypes.c_void_p]
    ogre_lib.ogre_render_one_frame.restype = ctypes.c_int
    ogre_lib.ogre_destroy_node.argtypes = [ctypes.c_void_p, ctypes.c_void_p]
    ogre_lib.ogre_shutdown.argtypes = [ctypes.c_void_p]
    
    var ctx = ogre_lib.ogre_init_headless()
    print("OGRE Context created from Mojo:", ctx)
    
    var name_bytes = Python.evaluate("b'surface_01'")
    var quad = ogre_lib.ogre_create_quad(ctx, name_bytes, 1920.0, 1080.0)
    print("OGRE Surface Quad created from Mojo:", quad)
    
    var res = ogre_lib.ogre_set_node_transform(quad, 0.0, 1.5, -3.0, 0.0, 0.0, 0.0, 1.0)
    print("OGRE Transform updated:", res)
    
    var frame_res = ogre_lib.ogre_render_one_frame(ctx)
    print("OGRE Frame Rendered:", frame_res)
    
    ogre_lib.ogre_destroy_node(ctx, quad)
    ogre_lib.ogre_shutdown(ctx)
    print("OGRE Shutdown cleanly from Mojo!")
