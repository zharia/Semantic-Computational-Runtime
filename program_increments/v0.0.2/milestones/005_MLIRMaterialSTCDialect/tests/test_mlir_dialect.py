"""
Unit tests for MLIR Material & STC Dialect Compiler (Milestone 005).
"""
import unittest
import os
import sys

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "../src")))
from dialect_compiler import MLIRCompiler

class TestMLIRDialect(unittest.TestCase):
    def setUp(self):
        self.compiler = MLIRCompiler()

    def test_scf_lowering_structure(self):
        lowered = self.compiler.lower_stc_to_scf([16, 16, 16], "lava_water_quenching")
        self.assertEqual(lowered["dialect"], "scf")
        self.assertEqual(lowered["op"], "scf.parallel")
        self.assertEqual(lowered["bounds"]["upper"], [16, 16, 16])
        self.assertEqual(len(lowered["body"]), 3)

    def test_gpu_lowering_dispatch(self):
        lowered = self.compiler.lower_stc_to_gpu([32, 32, 32], block_size=(8, 8, 8))
        self.assertEqual(lowered["dialect"], "gpu")
        self.assertEqual(lowered["grid_dims"], [4, 4, 4])
        self.assertEqual(lowered["block_dims"], [8, 8, 8])

    def test_tablegen_file_exists(self):
        td_path = os.path.abspath(os.path.join(os.path.dirname(__file__), "../src/dialect/SCRMaterialOps.td"))
        self.assertTrue(os.path.exists(td_path), "TableGen definition file must exist")
        with open(td_path, "r") as f:
            content = f.read()
        self.assertIn("MaterialLookupOp", content)
        self.assertIn("EvalHookeanStressOp", content)
        self.assertIn("STCLoadStencilOp", content)

if __name__ == "__main__":
    unittest.main()
