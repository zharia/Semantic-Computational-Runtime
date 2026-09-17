"""
Unit & Integration Test Suite for Milestone 002:
Voxel Material Binding & STC Transition Engine (Pure Standard Library)
"""

import sys
import os
import unittest

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "../src")))
from voxel_field import VoxelField, MaterialRegistry
from stc_engine import STCTransitionEngine

class TestSTCVoxelTransitions(unittest.TestCase):

    def setUp(self):
        self.registry = MaterialRegistry()
        self.field = VoxelField(shape=(16, 16, 16), registry=self.registry)
        self.engine = STCTransitionEngine(self.field)

    def test_material_registry_completeness(self):
        """Verify all 96 materials have unique integer codes."""
        self.assertGreaterEqual(len(self.registry.id_to_int), 96)
        self.assertEqual(self.registry.get_id(0), "air")
        # Ensure round-trip fidelity
        for mid, code in self.registry.id_to_int.items():
            self.assertEqual(self.registry.get_id(code), mid)

    def test_water_freezing_and_melting(self):
        """Verify water freezes below 273.15 K and melts above 273.15 K."""
        self.field.set_voxel(5, 5, 5, "fluid.water", temp_k=260.0) # sub-zero
        self.engine.step()
        self.assertEqual(self.field.get_voxel(5, 5, 5), "cryo.ice")

        # Melt back to water
        self.field.set_temperature(5, 5, 5, 300.0)
        self.engine.step()
        self.assertEqual(self.field.get_voxel(5, 5, 5), "fluid.water")

    def test_lava_water_quenching(self):
        """Verify adjacent lava and water quench into obsidian and steam."""
        self.field.set_voxel(8, 8, 8, "fluid.lava", temp_k=1400.0)
        self.field.set_voxel(8, 8, 9, "fluid.water", temp_k=293.15) # Face adjacent (+z)

        self.engine.step()

        self.assertEqual(self.field.get_voxel(8, 8, 8), "rock.obsidian")
        self.assertEqual(self.field.get_voxel(8, 8, 9), "gas.steam")

    def test_falling_sand_kinematics(self):
        """Verify sand falls downwards into empty void."""
        self.field.set_voxel(4, 4, 3, "soil.sand")
        self.field.set_voxel(4, 4, 2, "air")

        self.engine.step()

        # Sand should have dropped to z=2, leaving air at z=3
        self.assertEqual(self.field.get_voxel(4, 4, 2), "soil.sand")
        self.assertEqual(self.field.get_voxel(4, 4, 3), "air")

    def test_concrete_powder_hydration(self):
        """Verify concrete powder solidifies into structural concrete in contact with water."""
        self.field.set_voxel(2, 2, 2, "granular.concrete_powder")
        self.field.set_voxel(2, 2, 3, "fluid.water")

        self.engine.step()

        self.assertEqual(self.field.get_voxel(2, 2, 2), "synthetic.concrete")

    def test_acid_limestone_dissolution(self):
        """Verify acid dissolves adjacent limestone block."""
        self.field.set_voxel(6, 6, 6, "rock.limestone")
        self.field.set_voxel(6, 6, 7, "fluid.acid")

        self.engine.step()

        self.assertEqual(self.field.get_voxel(6, 6, 6), "air")

    def test_blast_shockwave_fracture(self):
        """Verify high explosive detonation fractures adjacent low-resistance materials."""
        self.field.set_voxel(8, 8, 8, "synthetic.explosive")
        self.field.set_voxel(8, 8, 9, "synthetic.glass") # distance r=1 -> impulse = 50000 / (4*pi) ~ 3978 J > 1500 J
        self.field.set_voxel(8, 8, 10, "rock.obsidian") # distance r=2 -> impulse = 50000 / (16*pi) ~ 994 J < 12000 J

        self.engine.trigger_blast((8, 8, 8), blast_energy_j=50000.0)

        self.assertEqual(self.field.get_voxel(8, 8, 8), "gas.smoke")
        self.assertEqual(self.field.get_voxel(8, 8, 9), "air") # Fractured
        self.assertEqual(self.field.get_voxel(8, 8, 10), "rock.obsidian") # Survives

if __name__ == "__main__":
    unittest.main()
