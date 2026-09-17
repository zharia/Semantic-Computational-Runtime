from std.python import Python, PythonObject
from std.collections import Dict

struct OgreRenderer:
    """
    Subordinate OGRE 3D Rendering Provider adapter for SCR Cave.
    Conforms to Cave Milestone 006 (PI-CAVE-001F).
    """
    var ctypes: PythonObject
    var ogre_lib: PythonObject
    var ctx: PythonObject
    var node_map: Dict[String, PythonObject]

    def __init__(out self) raises:
        self.ctypes = Python.import_module("ctypes")
        var so_path = "/home/kobus/Projects/Semantic-Computational-Runtime/providers/render/graphics/ogre/adapter/libscr_ogre_adapter.so"
        self.ogre_lib = self.ctypes.CDLL(so_path)
        
        self.ogre_lib.ogre_init_headless.restype = self.ctypes.c_void_p
        self.ogre_lib.ogre_create_quad.restype = self.ctypes.c_void_p
        self.ogre_lib.ogre_create_quad.argtypes = [
            self.ctypes.c_void_p, 
            self.ctypes.c_char_p, 
            self.ctypes.c_float, 
            self.ctypes.c_float
        ]
        self.ogre_lib.ogre_set_node_transform.argtypes = [
            self.ctypes.c_void_p,
            self.ctypes.c_float, self.ctypes.c_float, self.ctypes.c_float,
            self.ctypes.c_float, self.ctypes.c_float, self.ctypes.c_float, self.ctypes.c_float
        ]
        self.ogre_lib.ogre_set_node_transform.restype = self.ctypes.c_int
        self.ogre_lib.ogre_render_one_frame.argtypes = [self.ctypes.c_void_p]
        self.ogre_lib.ogre_render_one_frame.restype = self.ctypes.c_int
        self.ogre_lib.ogre_destroy_node.argtypes = [self.ctypes.c_void_p, self.ctypes.c_void_p]
        self.ogre_lib.ogre_shutdown.argtypes = [self.ctypes.c_void_p]
        
        self.ctx = self.ogre_lib.ogre_init_headless()
        self.node_map = Dict[String, PythonObject]()

    def create_surface_quad(mut self, surface_id: String, width: Float32, height: Float32) raises -> Bool:
        var expr = "b'" + surface_id + "'"
        var py_bytes = Python.evaluate(expr)
        var node = self.ogre_lib.ogre_create_quad(self.ctx, py_bytes, width, height)
        if not node:
            return False
        self.node_map[surface_id] = node
        return True

    def update_surface_transform(
        self, 
        surface_id: String, 
        px: Float32, py: Float32, pz: Float32, 
        qx: Float32, qy: Float32, qz: Float32, qw: Float32
    ) raises -> Int:
        if surface_id not in self.node_map:
            return -1
        var node = self.node_map[surface_id]
        var res = self.ogre_lib.ogre_set_node_transform(node, px, py, pz, qx, qy, qz, qw)
        return Int(py=res)

    def render_frame(self) raises -> Int:
        var res = self.ogre_lib.ogre_render_one_frame(self.ctx)
        return Int(py=res)

    def destroy_surface(mut self, surface_id: String) raises:
        if surface_id in self.node_map:
            var node = self.node_map[surface_id]
            self.ogre_lib.ogre_destroy_node(self.ctx, node)
            _ = self.node_map.pop(surface_id)

    def shutdown(mut self) raises:
        self.ogre_lib.ogre_shutdown(self.ctx)
