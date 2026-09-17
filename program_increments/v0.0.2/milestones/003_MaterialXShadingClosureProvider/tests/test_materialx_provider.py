"""
Unit tests for MaterialX Shading Closure Provider (Milestone 003).
"""
import unittest
import os
import sys

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "../src")))
from materialx_provider import MaterialXProvider

class TestMaterialXProvider(unittest.TestCase):
    def setUp(self):
        self.provider = MaterialXProvider()

    def test_materials_count(self):
        mat_ids = self.provider.get_material_ids()
        self.assertEqual(len(mat_ids), 96, "Expected 96 materials in MaterialX document")

    def test_conductor_gold(self):
        shader = self.provider.get_shader_element("metal.gold")
        self.assertIsNotNone(shader)
        metalness = float(self.provider.get_shader_property("metal.gold", "metalness"))
        self.assertEqual(metalness, 1.0)
        roughness = float(self.provider.get_shader_property("metal.gold", "specular_roughness"))
        self.assertEqual(roughness, 0.18)

    def test_dielectric_water(self):
        shader = self.provider.get_shader_element("fluid.water")
        self.assertIsNotNone(shader)
        metalness = float(self.provider.get_shader_property("fluid.water", "metalness"))
        self.assertEqual(metalness, 0.0)
        ior = float(self.provider.get_shader_property("fluid.water", "specular_IOR"))
        self.assertEqual(ior, 1.333)
        transmission = float(self.provider.get_shader_property("fluid.water", "transmission"))
        self.assertEqual(transmission, 0.98)

    def test_emissive_lava(self):
        shader = self.provider.get_shader_element("lava")
        self.assertIsNotNone(shader)
        emission = self.provider.get_shader_property("lava", "emission_color")
        self.assertIsNotNone(emission)
        r, g, b = [float(x) for x in emission.split(", ")]
        self.assertGreater(r, 0.0)

if __name__ == "__main__":
    unittest.main()
