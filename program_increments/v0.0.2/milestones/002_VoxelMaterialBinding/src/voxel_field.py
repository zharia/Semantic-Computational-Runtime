"""
SCR Voxel Material Field Runtime (Pure Standard Library)
Encapsulates discrete spatial grid mapping to SCR Dual-Contract materials.
"""

import json
import os
import array
from typing import Tuple, Dict, Any

DEFAULT_CATALOG_PATH = os.path.abspath(
    os.path.join(os.path.dirname(__file__), "../../../../../lib/A01_Render/Material/materials_catalog.json")
)

class MaterialRegistry:
    """Manages bijective mapping between 16-bit discrete integers and SCR material contracts."""

    def __init__(self, catalog_path=DEFAULT_CATALOG_PATH):
        with open(catalog_path, "r") as f:
            data = json.load(f)
        
        self.id_to_int: Dict[str, int] = {}
        self.int_to_id: Dict[int, str] = {}
        self.materials: Dict[str, Dict[str, Any]] = {}

        # 0 is reserved for air / vacuum void
        self.id_to_int["air"] = 0
        self.int_to_id[0] = "air"
        self.materials["air"] = {
            "id": "air",
            "name": "Atmospheric Void / Air",
            "physical": {
                "density_kg_m3": 1.225,
                "mohs_hardness": 0.0,
                "blast_resistance_j": 100000.0,
                "thermal_conductivity_w_mk": 0.026,
                "specific_heat_j_kgk": 1005.0,
                "kinematic_gravity": False,
                "flammable": False
            }
        }

        for idx, mat in enumerate(data.get("materials", []), start=1):
            mid = mat["id"]
            self.id_to_int[mid] = idx
            self.int_to_id[idx] = mid
            self.materials[mid] = mat

    def get_code(self, material_id: str) -> int:
        return self.id_to_int.get(material_id, 0)

    def get_id(self, code: int) -> str:
        return self.int_to_id.get(code, "air")

    def get_physical(self, material_id: str) -> dict:
        return self.materials.get(material_id, {}).get("physical", {})


class VoxelField:
    """Discrete 3D grid holding material IDs, temperatures, and kinematic states."""

    def __init__(self, shape: Tuple[int, int, int] = (32, 32, 32), registry=None):
        self.shape = shape
        self.sx, self.sy, self.sz = shape
        self.total_voxels = self.sx * self.sy * self.sz
        self.registry = registry or MaterialRegistry()
        
        # Pure standard library buffers: unsigned 16-bit integer for materials ('H'), float for temp ('f')
        self.materials = array.array('H', [0] * self.total_voxels)
        self.temperature = array.array('f', [293.15] * self.total_voxels)

    def _idx(self, x: int, y: int, z: int) -> int:
        return (x * self.sy + y) * self.sz + z

    def set_voxel(self, x: int, y: int, z: int, material_id: str, temp_k: float = 293.15):
        if 0 <= x < self.sx and 0 <= y < self.sy and 0 <= z < self.sz:
            idx = self._idx(x, y, z)
            self.materials[idx] = self.registry.get_code(material_id)
            self.temperature[idx] = temp_k

    def get_voxel(self, x: int, y: int, z: int) -> str:
        if 0 <= x < self.sx and 0 <= y < self.sy and 0 <= z < self.sz:
            code = self.materials[self._idx(x, y, z)]
            return self.registry.get_id(code)
        return "air"

    def get_temperature(self, x: int, y: int, z: int) -> float:
        if 0 <= x < self.sx and 0 <= y < self.sy and 0 <= z < self.sz:
            return self.temperature[self._idx(x, y, z)]
        return 293.15

    def set_temperature(self, x: int, y: int, z: int, temp_k: float):
        if 0 <= x < self.sx and 0 <= y < self.sy and 0 <= z < self.sz:
            self.temperature[self._idx(x, y, z)] = temp_k

    def total_mass(self, voxel_volume_m3: float = 1.0) -> float:
        """Calculates exact total mass of all matter in the grid."""
        mass = 0.0
        code_counts = {}
        for code in self.materials:
            code_counts[code] = code_counts.get(code, 0) + 1
            
        for code, count in code_counts.items():
            mid = self.registry.get_id(code)
            density = self.registry.get_physical(mid).get("density_kg_m3", 0.0)
            mass += count * density * voxel_volume_m3
        return mass
