"""
MaterialX Shading Closure Provider for SCR Unified Materials.
"""
import os
import xml.etree.ElementTree as ET

class MaterialXProvider:
    def __init__(self, mtlx_path=None):
        if mtlx_path is None:
            mtlx_path = os.path.join(
                os.path.dirname(__file__),
                "../../../../../lib/A01_Render/Material/providers/unified_materials.mtlx"
            )
        self.mtlx_path = os.path.abspath(mtlx_path)
        self.tree = ET.parse(self.mtlx_path)
        self.root = self.tree.getroot()
        # Extract namespace if present
        self.ns = ""
        if self.root.tag.startswith("{"):
            self.ns = self.root.tag.split("}")[0] + "}"

    def _tag(self, name):
        return f"{self.ns}{name}"

    def get_material_ids(self):
        materials = []
        for elem in self.root.findall(self._tag("surfacematerial")):
            name = elem.get("name", "")
            if name.startswith("M_"):
                materials.append(name[2:])
            else:
                materials.append(name)
        return materials

    def get_material_element(self, mat_id):
        safe_id = mat_id.replace(".", "_")
        candidates = {mat_id, safe_id, f"M_{mat_id}", f"M_{safe_id}"}
        for elem in self.root.findall(self._tag("surfacematerial")):
            name = elem.get("name", "")
            if name in candidates or name.replace("M_", "").endswith(f"_{safe_id}"):
                return elem
        return None

    def get_shader_element(self, mat_id):
        safe_id = mat_id.replace(".", "_")
        candidates = {mat_id, safe_id, f"SR_{mat_id}", f"SR_{safe_id}"}
        for elem in self.root.findall(self._tag("standard_surface")):
            name = elem.get("name", "")
            if name in candidates or name.replace("SR_", "").endswith(f"_{safe_id}"):
                return elem
        return None

    def get_shader_property(self, mat_id, prop_name):
        shader = self.get_shader_element(mat_id)
        if shader is None:
            return None
        for inp in shader.findall(self._tag("input")):
            if inp.get("name") == prop_name:
                return inp.get("value")
        return None
