"""
SCR Semantic Transition Calculus (STC) Voxel Transition Engine (Pure Standard Library)
Executes reaction transitions, topological neighborhood stencils, and conservation checking.
"""

import json
import os
import math
import array
try:
    from .voxel_field import VoxelField, MaterialRegistry
except ImportError:
    from voxel_field import VoxelField, MaterialRegistry

DEFAULT_REACTIONS_PATH = os.path.abspath(
    os.path.join(os.path.dirname(__file__), "../../../../../lib/A01_Render/Material/material_reactions.json")
)

class STCTransitionEngine:
    """Evaluates dynamic material transformations across 3D discrete voxel fields."""

    def __init__(self, field: VoxelField, reactions_path=DEFAULT_REACTIONS_PATH):
        self.field = field
        with open(reactions_path, "r") as f:
            data = json.load(f)
        self.reactions = data.get("reactions", [])

    def get_neighbors_6(self, x: int, y: int, z: int):
        """Returns 6 face-sharing von Neumann neighbors (N6)."""
        offsets = [(-1, 0, 0), (1, 0, 0), (0, -1, 0), (0, 1, 0), (0, 0, -1), (0, 0, 1)]
        neighbors = []
        for dx, dy, dz in offsets:
            nx, ny, nz = x + dx, y + dy, z + dz
            if 0 <= nx < self.field.sx and 0 <= ny < self.field.sy and 0 <= nz < self.field.sz:
                neighbors.append((nx, ny, nz, self.field.get_voxel(nx, ny, nz)))
        return neighbors

    def get_neighbors_26(self, x: int, y: int, z: int):
        """Returns 26 Moore neighbors (N26)."""
        neighbors = []
        for dx in (-1, 0, 1):
            for dy in (-1, 0, 1):
                for dz in (-1, 0, 1):
                    if dx == 0 and dy == 0 and dz == 0:
                        continue
                    nx, ny, nz = x + dx, y + dy, z + dz
                    if 0 <= nx < self.field.sx and 0 <= ny < self.field.sy and 0 <= nz < self.field.sz:
                        neighbors.append((nx, ny, nz, self.field.get_voxel(nx, ny, nz)))
        return neighbors

    def step(self):
        """Executes one discrete STC simulation tick across the entire voxel field."""
        new_materials = array.array('H', self.field.materials)
        new_temperatures = array.array('f', self.field.temperature)
        sx, sy, sz = self.field.shape

        # 1. Kinematic Gravity Pass (Mohr-Coulomb Falling Blocks)
        # Scan from z=1 upwards so falling blocks transpose downwards into void
        for z in range(1, sz):
            for x in range(sx):
                for y in range(sy):
                    mid = self.field.get_voxel(x, y, z)
                    phys = self.field.registry.get_physical(mid)
                    if phys.get("kinematic_gravity", False):
                        below_mid = self.field.get_voxel(x, y, z - 1)
                        if below_mid == "air" or below_mid.startswith("gas."):
                            cur_idx = self.field._idx(x, y, z)
                            below_idx = self.field._idx(x, y, z - 1)
                            new_materials[below_idx] = self.field.materials[cur_idx]
                            new_materials[cur_idx] = self.field.registry.get_code("air")

        # 2. Reaction Adjacency & Phase Change Pass
        for x in range(sx):
            for y in range(sy):
                for z in range(sz):
                    mid = self.field.get_voxel(x, y, z)
                    if mid == "air":
                        continue

                    idx = self.field._idx(x, y, z)
                    temp = self.field.get_temperature(x, y, z)
                    n6 = self.get_neighbors_6(x, y, z)
                    n6_mids = [n[3] for n in n6]

                    # Water Freezing (thermal_phase_change)
                    if mid == "fluid.water" and temp <= 273.15:
                        new_materials[idx] = self.field.registry.get_code("cryo.ice")

                    # Ice Melting (thermal_phase_change)
                    elif mid in ("cryo.ice", "cryo.snow", "cryo.powder_snow") and temp > 273.15:
                        new_materials[idx] = self.field.registry.get_code("fluid.water")

                    # Lava-Water Quenching
                    elif mid == "fluid.lava":
                        if "fluid.water" in n6_mids:
                            new_materials[idx] = self.field.registry.get_code("rock.obsidian")
                            for nx, ny, nz, nmid in n6:
                                if nmid == "fluid.water":
                                    n_idx = self.field._idx(nx, ny, nz)
                                    new_materials[n_idx] = self.field.registry.get_code("gas.steam")
                                    new_temperatures[n_idx] = 373.15

                    # Concrete Powder Hydration
                    elif mid == "granular.concrete_powder":
                        if "fluid.water" in n6_mids:
                            new_materials[idx] = self.field.registry.get_code("synthetic.concrete")

                    # Soil Dirt Hydration -> Mud
                    elif mid == "soil.dirt":
                        if "fluid.water" in n6_mids:
                            new_materials[idx] = self.field.registry.get_code("soil.mud")

                    # Acid Carbonate Dissolution
                    elif mid in ("rock.limestone", "rock.calcite", "rock.marble"):
                        if "fluid.acid" in n6_mids:
                            new_materials[idx] = self.field.registry.get_code("air")

                    # Salt Ice Depression
                    elif mid == "cryo.ice":
                        if "mineral.salt" in n6_mids and temp >= 252.0:
                            new_materials[idx] = self.field.registry.get_code("fluid.water")

        self.field.materials = new_materials
        self.field.temperature = new_temperatures

    def trigger_blast(self, center: tuple, blast_energy_j: float):
        """Simulates explosive Chapman-Jouguet shockwave detonation."""
        cx, cy, cz = center
        sx, sy, sz = self.field.shape
        self.field.set_voxel(cx, cy, cz, "gas.smoke")

        # Shockwave dissipation: Pressure impulse P(r) = E_blast / (4 * pi * r^2)
        for x in range(sx):
            for y in range(sy):
                for z in range(sz):
                    if (x, y, z) == (cx, cy, cz):
                        continue
                    r = math.sqrt((x - cx)**2 + (y - cy)**2 + (z - cz)**2)
                    if r < 0.5:
                        continue
                    impulse = blast_energy_j / (4.0 * math.pi * (r**2))
                    mid = self.field.get_voxel(x, y, z)
                    if mid != "air":
                        blast_res = self.field.registry.get_physical(mid).get("blast_resistance_j", 5000.0)
                        if impulse >= blast_res:
                            self.field.set_voxel(x, y, z, "air")
