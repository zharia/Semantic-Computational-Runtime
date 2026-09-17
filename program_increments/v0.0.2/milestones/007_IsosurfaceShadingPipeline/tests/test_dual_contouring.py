"""
Unit tests for Isosurface Mesher & Shading Pipeline (Milestone 007).
"""
import unittest
import os
import sys

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "../src")))
from dual_contouring import IsosurfaceMesher

class TestIsosurfaceMesher(unittest.TestCase):
    def setUp(self):
        self.mesher = IsosurfaceMesher()

    def test_solid_cube_surface(self):
        # 4x4x4 grid with a 2x2x2 solid block in the center
        grid = [[[0 for _ in range(4)] for _ in range(4)] for _ in range(4)]
        for x in (1, 2):
            for y in (1, 2):
                for z in (1, 2):
                    grid[x][y][z] = 1 # Granite

        vertices, triangles = self.mesher.extract_mesh(grid, (4, 4, 4))
        self.assertGreater(len(vertices), 0, "Should generate surface vertices on block boundary")
        # Ensure vertices have valid material ID
        for v in vertices:
            self.assertEqual(v.material_id, 1)

    def test_empty_grid_no_mesh(self):
        grid = [[[0 for _ in range(4)] for _ in range(4)] for _ in range(4)]
        vertices, triangles = self.mesher.extract_mesh(grid, (4, 4, 4))
        self.assertEqual(len(vertices), 0)
        self.assertEqual(len(triangles), 0)

if __name__ == "__main__":
    unittest.main()
