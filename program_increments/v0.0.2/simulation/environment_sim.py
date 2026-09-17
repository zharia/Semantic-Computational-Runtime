#!/usr/bin/env python3
"""
SCR 3D Environment Simulation Runner.
Builds a stratified 3D geological landscape with mineral veins, fluid reservoirs,
and dynamic reactive entities, then simulates semantic transitions over time.
Outputs frame-by-frame voxel states and physical metrics for visual playback.
"""

import os
import sys
import json
import math

BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../../"))
M2_SRC = os.path.join(BASE_DIR, "program_increments/v0.0.2/milestones/002_VoxelMaterialBinding/src")
PHYS_SRC = os.path.join(BASE_DIR, "lib/501_Physics/Material")

sys.path.insert(0, M2_SRC)
sys.path.insert(0, PHYS_SRC)

from voxel_field import VoxelField, MaterialRegistry
from stc_engine import STCTransitionEngine
from constitutive_mechanics import ConstitutiveSolver

class EnvironmentSimulation:
    def __init__(self, dims=(24, 24, 16)):
        self.dims = dims
        self.field = VoxelField(dims)
        self.engine = STCTransitionEngine(self.field)
        self.solver = ConstitutiveSolver()
        self.frames = []
        self.event_log = []

    def build_initial_terrain(self):
        """Constructs a multi-layered geological landscape with subterranean features."""
        dx, dy, dz = self.dims

        # 1. Stratified bedrock and granite basement (z = 0..3)
        for x in range(dx):
            for y in range(dy):
                self.field.set_voxel(x, y, 0, "rock.bedrock")
                for z in range(1, 4):
                    self.field.set_voxel(x, y, z, "rock.granite")

        # 2. Limestone / Carbonate strata (z = 4..7)
        for x in range(dx):
            for y in range(dy):
                for z in range(4, 8):
                    self.field.set_voxel(x, y, z, "rock.limestone")

        # 3. Soil and surface topography (z = 8..11)
        for x in range(dx):
            for y in range(dy):
                # Sloping hillside
                hill_height = 8 + int(3.0 * math.sin(x / 4.0) * math.cos(y / 4.0) + 1.5)
                for z in range(8, min(dz, hill_height)):
                    self.field.set_voxel(x, y, z, "soil.dirt")
                if hill_height < dz:
                    self.field.set_voxel(x, y, hill_height, "bio.grass_block")

        # 4. Excavate a natural subterranean cavern (center: 12, 12, 5, radius: 4)
        for x in range(7, 17):
            for y in range(7, 17):
                for z in range(3, 8):
                    dist = math.sqrt((x - 12)**2 + (y - 12)**2 + (z - 5)**2)
                    if dist <= 3.8:
                        self.field.set_voxel(x, y, z, "air")

        # 5. Ore Veins inside the cavern walls
        self.field.set_voxel(8, 12, 4, "ore.gold_ore")
        self.field.set_voxel(8, 13, 4, "ore.gold_ore")
        self.field.set_voxel(16, 12, 5, "ore.iron_ore")
        self.field.set_voxel(16, 11, 5, "ore.iron_ore")
        self.field.set_voxel(12, 16, 4, "mineral.quartz")

        # 6. Water Pool on west side of cave floor (x=9..11, y=9..12, z=3..4)
        for x in range(9, 12):
            for y in range(9, 13):
                self.field.set_voxel(x, y, 3, "fluid.water")

        # 7. Hot Lava Pocket adjacent to water separated by thin wall at x=12
        for x in range(13, 15):
            for y in range(10, 12):
                self.field.set_voxel(x, y, 3, "fluid.lava")
                self.field.set_temperature(x, y, 3, 1473.15) # 1200 C

        # 8. Overhanging Loose Granular Sand column above cave ceiling
        for z in range(7, 11):
            self.field.set_voxel(12, 12, z, "granular.sand")

        # 9. Acid Reservoir in north limestone pocket
        for x in range(5, 7):
            for y in range(18, 20):
                self.field.set_voxel(x, y, 5, "fluid.acid")

        # 10. Energetic TNT block inside granite east wall
        self.field.set_voxel(19, 12, 3, "synthetic.tnt")

    def capture_frame(self, step_idx: int, description: str):
        """Snapshots the non-air voxel field state for 3D visualization."""
        dx, dy, dz = self.dims
        active_voxels = []
        counts = {}

        for x in range(dx):
            for y in range(dy):
                for z in range(dz):
                    mid = self.field.get_voxel(x, y, z)
                    if mid != "air":
                        temp = self.field.get_temperature(x, y, z)
                        active_voxels.append({
                            "x": x, "y": y, "z": z,
                            "id": mid,
                            "temp": round(temp, 1)
                        })
                        counts[mid] = counts.get(mid, 0) + 1

        frame_data = {
            "step": step_idx,
            "description": description,
            "voxel_count": len(active_voxels),
            "material_summary": counts,
            "voxels": active_voxels
        }
        self.frames.append(frame_data)
        print(f"Captured Frame {step_idx}: '{description}' — {len(active_voxels)} active voxels.")

    def run_simulation_sequence(self):
        """Executes a scripted multi-step physical-semantic simulation scenario."""
        print("=== SCR 3D Environment Simulation Starting ===")
        self.build_initial_terrain()
        self.capture_frame(0, "Initial Geological Landscape & Equilibrium")

        # Step 1: Lava-Water Barrier Breach & Quenching
        print("\n--- Step 1: Lava Breaches Barrier into Water Pool ---")
        # Turn wall at (12, 10, 3) and (12, 11, 3) into lava
        self.field.set_voxel(12, 10, 3, "fluid.lava")
        self.field.set_voxel(12, 11, 3, "fluid.lava")
        self.engine.step()
        self.event_log.append("Lava contacted water: Quenched into rock.obsidian + gas.steam.")
        self.capture_frame(1, "Lava-Water Contact: Obsidian Crust & Steam Generation")

        # Step 2: Acid Dissolution Carves Carbonate Channel
        print("\n--- Step 2: Acid Dissolves Adjacent Limestone Wall ---")
        # Spread acid contact
        self.field.set_voxel(7, 18, 5, "fluid.acid")
        self.engine.step()
        self.event_log.append("Acid dissolved adjacent limestone carbonate rock.")
        self.capture_frame(2, "Acid Dissolution: Cave Wall Excavation")

        # Step 3: Sand Column Destabilizes & Avalanches
        print("\n--- Step 3: Granular Sand Avalanche ---")
        # Step twice to let sand fall into the void of the cavern below
        self.engine.step()
        self.engine.step()
        self.event_log.append("Loose sand column experienced kinematic gravity, collapsing into cave floor.")
        self.capture_frame(3, "Kinematic Gravity: Sand Avalanche into Cavern")

        # Step 4: Explosive TNT Detonation & Shockwave Cratering
        print("\n--- Step 4: TNT Detonation & Shockwave Fracture ---")
        # Detonate TNT at (19, 12, 3) with 500,000 Joules
        self.engine.trigger_blast((19, 12, 3), blast_energy_j=500000.0)
        self.event_log.append("TNT detonated: Spherical shockwave blasted granite cavity.")
        self.capture_frame(4, "High Explosive Detonation: Granite Blast Cavity")

        # Step 5: Post-Blast Stabilization & Settlement
        print("\n--- Step 5: Post-Blast Stabilization ---")
        self.engine.step()
        self.capture_frame(5, "Final Stabilized Environment State")

    def export_simulation_data(self, output_path: str):
        """Saves the complete simulation trajectory to JSON."""
        # Include material metadata dictionary for client-side tooltips and shading
        catalog = self.solver.catalog
        meta_dict = {}
        for mat in catalog:
            mid = mat["id"]
            phys = mat.get("physical", {})
            opt = mat.get("optical", {})
            meta_dict[mid] = {
                "name": mat.get("name", mid),
                "category": mat.get("category", "generic"),
                "color": opt.get("albedo", [0.7, 0.7, 0.7]),
                "roughness": opt.get("roughness", 0.5),
                "metallic": opt.get("metallic", 0.0),
                "ior": opt.get("refractive_index", 1.5),
                "transmission": opt.get("transmission", 0.0),
                "emission": opt.get("emission", [0.0, 0.0, 0.0]),
                "density": phys.get("density_kg_m3", 2500),
                "youngs_gpa": phys.get("youngs_modulus_gpa", 10.0),
                "blast_res": phys.get("blast_resistance_j", 5000.0)
            }

        sim_package = {
            "dimensions": list(self.dims),
            "total_frames": len(self.frames),
            "materials_metadata": meta_dict,
            "events": self.event_log,
            "frames": self.frames
        }

        with open(output_path, "w") as f:
            json.dump(sim_package, f, indent=2)
        print(f"\nSimulation trajectory exported successfully to: {output_path}")

if __name__ == "__main__":
    sim = EnvironmentSimulation(dims=(24, 24, 16))
    sim.run_simulation_sequence()
    out_json = os.path.join(os.path.dirname(__file__), "simulation_data.json")
    sim.export_simulation_data(out_json)
