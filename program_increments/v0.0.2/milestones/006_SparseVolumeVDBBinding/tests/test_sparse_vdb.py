"""
Unit tests for Sparse Volume VDB Binding (Milestone 006).
"""
import unittest
import os
import sys

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "../src")))
from sparse_vdb import SparseVDBTree, VDBLeafNode

class TestSparseVDB(unittest.TestCase):
    def setUp(self):
        self.tree = SparseVDBTree(background_val=0)

    def test_sparse_allocation(self):
        # Empty tree should have 0 leaves
        self.assertEqual(len(self.tree.leaves), 0)
        # Setting a background voxel should not allocate
        self.tree.set_voxel(10, 10, 10, 0)
        self.assertEqual(len(self.tree.leaves), 0)
        # Setting non-background voxel should allocate exactly one 8x8x8 leaf
        self.tree.set_voxel(10, 10, 10, 42)
        self.assertEqual(len(self.tree.leaves), 1)
        self.assertEqual(self.tree.get_voxel(10, 10, 10), 42)
        self.assertEqual(self.tree.get_voxel(11, 10, 10), 0)

    def test_bounding_box(self):
        self.tree.set_voxel(0, 0, 0, 1)
        self.tree.set_voxel(20, 25, 30, 2)
        bbox = self.tree.compute_bounding_box()
        self.assertIsNotNone(bbox)
        min_pt, max_pt = bbox
        self.assertEqual(min_pt, (0, 0, 0))
        self.assertEqual(max_pt, (23, 31, 31))

    def test_nanovdb_serialization(self):
        self.tree.set_voxel(5, 5, 5, 100)
        buf = self.tree.serialize_nanovdb()
        self.assertTrue(buf.startswith(b"NVDB"))
        # Header (12 bytes) + 1 leaf table (12 bytes) + 1024 bytes leaf payload = 1048 bytes
        self.assertEqual(len(buf), 12 + 12 + 1024)

if __name__ == "__main__":
    unittest.main()
