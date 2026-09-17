"""
Unit tests for Physical Constitutive Mechanics Solver (Milestone 004).
"""
import unittest
import os
import sys

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "../src")))
from constitutive_solver import ConstitutiveSolver

class TestConstitutiveMechanics(unittest.TestCase):
    def setUp(self):
        self.solver = ConstitutiveSolver()

    def test_all_materials_loaded(self):
        self.assertEqual(len(self.solver.catalog), 96, "Expected 96 materials in catalog")

    def test_granite_elasticity(self):
        mat = self.solver.get_material("granite")
        moduli = self.solver.compute_elastic_moduli(mat)
        self.assertIsNotNone(moduli)
        self.assertGreater(moduli.bulk_K, 0)
        self.assertGreater(moduli.shear_G, 0)
        self.assertGreater(moduli.lame_lambda, 0)

        waves = self.solver.compute_wave_velocities(mat)
        self.assertIsNotNone(waves)
        # P-waves must travel strictly faster than S-waves
        self.assertGreater(waves.vp, waves.vs)
        self.assertGreater(waves.vs, 0)

    def test_hookean_stress_symmetry(self):
        mat = self.solver.get_material("iron")
        strain = [
            [0.001, 0.0005, 0.0],
            [0.0005, -0.0002, 0.0],
            [0.0, 0.0, 0.0]
        ]
        stress = self.solver.compute_stress_tensor(mat, strain)
        self.assertAlmostEqual(stress[0][1], stress[1][0], places=5)
        self.assertAlmostEqual(stress[0][2], stress[2][0], places=5)
        self.assertAlmostEqual(stress[1][2], stress[2][1], places=5)

    def test_mohr_coulomb_failure(self):
        mat = self.solver.get_material("sandstone")
        # Under high normal stress, required shear stress to fail increases
        tau_low = self.solver.mohr_coulomb_failure(mat, normal_stress=1e6)
        tau_high = self.solver.mohr_coulomb_failure(mat, normal_stress=1e7)
        self.assertGreater(tau_high, tau_low)

    def test_blast_cavity_scaling(self):
        mat_soft = self.solver.get_material("sand")
        mat_hard = self.solver.get_material("obsidian")
        r_soft = self.solver.compute_blast_radius(mat_soft, energy_tnt_joules=1e9)
        r_hard = self.solver.compute_blast_radius(mat_hard, energy_tnt_joules=1e9)
        self.assertGreater(r_soft, r_hard)

if __name__ == "__main__":
    unittest.main()
