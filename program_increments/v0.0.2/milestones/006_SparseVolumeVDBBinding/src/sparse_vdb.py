"""
Sparse Volume VDB Binding for SCR Multi-Material Fields.
Implements hierarchical leaf node tree (mimicking OpenVDB) and
linear zero-copy buffer serialization (mimicking NanoVDB).
"""
import struct
from typing import Tuple, Dict, Optional, List

class VDBLeafNode:
    LEAF_DIM = 8
    TOTAL_VOXELS = 512

    def __init__(self, origin: Tuple[int, int, int], background_val: int = 0):
        self.origin = origin
        self.background_val = background_val
        self.data = [background_val] * self.TOTAL_VOXELS
        self.active_mask = [0] * 8  # 8 words x 64 bits = 512 bits

    def _index(self, lx: int, ly: int, lz: int) -> int:
        return (lx * 64) + (ly * 8) + lz

    def get_voxel(self, lx: int, ly: int, lz: int) -> int:
        return self.data[self._index(lx, ly, lz)]

    def set_voxel(self, lx: int, ly: int, lz: int, val: int):
        idx = self._index(lx, ly, lz)
        self.data[idx] = val
        word_idx = idx // 64
        bit_idx = idx % 64
        if val != self.background_val:
            self.active_mask[word_idx] |= (1 << bit_idx)
        else:
            self.active_mask[word_idx] &= ~(1 << bit_idx)

    def is_active(self, lx: int, ly: int, lz: int) -> bool:
        idx = self._index(lx, ly, lz)
        word_idx = idx // 64
        bit_idx = idx % 64
        return bool((self.active_mask[word_idx] >> bit_idx) & 1)

class SparseVDBTree:
    def __init__(self, background_val: int = 0):
        self.background_val = background_val
        self.leaves: Dict[Tuple[int, int, int], VDBLeafNode] = {}

    def _get_leaf_origin(self, x: int, y: int, z: int) -> Tuple[int, int, int]:
        return (x // 8 * 8, y // 8 * 8, z // 8 * 8)

    def get_voxel(self, x: int, y: int, z: int) -> int:
        lorigin = self._get_leaf_origin(x, y, z)
        if lorigin not in self.leaves:
            return self.background_val
        lx = x - lorigin[0]
        ly = y - lorigin[1]
        lz = z - lorigin[2]
        return self.leaves[lorigin].get_voxel(lx, ly, lz)

    def set_voxel(self, x: int, y: int, z: int, val: int):
        lorigin = self._get_leaf_origin(x, y, z)
        if lorigin not in self.leaves:
            if val == self.background_val:
                return
            self.leaves[lorigin] = VDBLeafNode(lorigin, self.background_val)
        lx = x - lorigin[0]
        ly = y - lorigin[1]
        lz = z - lorigin[2]
        self.leaves[lorigin].set_voxel(lx, ly, lz, val)

    def compute_bounding_box(self) -> Optional[Tuple[Tuple[int, int, int], Tuple[int, int, int]]]:
        if not self.leaves:
            return None
        min_x = min(o[0] for o in self.leaves.keys())
        min_y = min(o[1] for o in self.leaves.keys())
        min_z = min(o[2] for o in self.leaves.keys())
        max_x = max(o[0] + 7 for o in self.leaves.keys())
        max_y = max(o[1] + 7 for o in self.leaves.keys())
        max_z = max(o[2] + 7 for o in self.leaves.keys())
        return ((min_x, min_y, min_z), (max_x, max_y, max_z))

    def serialize_nanovdb(self) -> bytes:
        """
        Serializes tree to a linear binary NanoVDB-style buffer:
        Header (magic 'NVDB', num_leaves, background_val) + Leaf Table + Leaf Payloads.
        """
        magic = b"NVDB"
        num_leaves = len(self.leaves)
        header = struct.pack("<4sII", magic, num_leaves, self.background_val)
        
        leaf_table = bytearray()
        payloads = bytearray()
        
        for origin, leaf in self.leaves.items():
            ox, oy, oz = origin
            leaf_table.extend(struct.pack("<iii", ox, oy, oz))
            # 512 uint16 voxels = 1024 bytes
            payloads.extend(struct.pack(f"<{VDBLeafNode.TOTAL_VOXELS}H", *leaf.data))
            
        return bytes(header + leaf_table + payloads)
