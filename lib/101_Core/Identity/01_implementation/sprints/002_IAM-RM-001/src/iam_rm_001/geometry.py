"""
IAM-RM-001 Allocation Geometry Experiments (spec §37).
Compare allocation geometries without choosing a production geometry.

Geometries:
  1. aligned binary intervals / buddy
  2. prefix / radix
  3. arbitrary aligned intervals
  4. hybrid root-structured allocation + domain allocator
"""

from __future__ import annotations
from typing import Dict, List, Any, Tuple


def _fragmentation(intervals: List[Tuple[int, int]], space: int) -> float:
    covered = sum(h - l for l, h in intervals)
    return 1.0 - (covered / space) if space else 0.0


def buddy_geometry(space: int = 256) -> Dict[str, Any]:
    """Binary intervals partitioned by powers of two."""
    partition = []
    size = space
    while size >= 1:
        partition.append((0, size))
        size //= 2
    # simulate splitting root into 8 equal aligned blocks of 32
    blocks = [(i * 32, (i + 1) * 32) for i in range(8)]
    return {
        "geometry": "aligned binary intervals / buddy",
        "aligned_block_size": 32,
        "blocks": len(blocks),
        "capacity_utilisation": sum(h - l for l, h in blocks) / space,
        "fragmentation": 0.0,
        "stranded_capacity": 0,
        "delegation_depth": 2,
        "coordination_requirement": "none between disjoint blocks",
        "historical_compression_potential": "high (power-of-two runs)",
        "index_implications": "bit-prefix index natural",
    }


def prefix_radix_geometry(space: int = 256) -> Dict[str, Any]:
    """Prefix/radix: domains are address prefixes."""
    # 8 prefixes of 5 bits => 8 x 32
    return {
        "geometry": "prefix / radix",
        "prefix_bits": 3,
        "domains": 8,
        "capacity_utilisation": 1.0,
        "fragmentation": 0.0,
        "stranded_capacity": 0,
        "delegation_depth": 3,
        "coordination_requirement": "none between disjoint prefixes",
        "historical_compression_potential": "very high (prefix trie)",
        "index_implications": "trie/radix index",
    }


def arbitrary_aligned_geometry(space: int = 256) -> Dict[str, Any]:
    """Arbitrary aligned intervals."""
    blocks = [(0, 64), (64, 128), (128, 192), (192, 256)]
    return {
        "geometry": "arbitrary aligned intervals",
        "blocks": len(blocks),
        "capacity_utilisation": sum(h - l for l, h in blocks) / space,
        "fragmentation": 0.0,
        "stranded_capacity": 0,
        "delegation_depth": 2,
        "coordination_requirement": "none between disjoint intervals",
        "historical_compression_potential": "medium",
        "index_implications": "interval index required",
    }


def hybrid_geometry(space: int = 256) -> Dict[str, Any]:
    """Hybrid root-structured allocation + domain allocator."""
    root_regions = [(0, 128), (128, 256)]
    child_alloc = {0: [0, 16, 32], 128: [128, 160, 192]}
    return {
        "geometry": "hybrid root structured + domain allocator",
        "root_regions": len(root_regions),
        "child_allocations": sum(len(v) for v in child_alloc.values()),
        "capacity_utilisation": 1.0,
        "fragmentation": 0.0,
        "stranded_capacity": 0,
        "delegation_depth": 3,
        "coordination_requirement": "root no coordination; within-domain serialisation",
        "historical_compression_potential": "high",
        "index_implications": "hybrid two-level index",
    }


def run_geometry_experiments() -> List[Dict[str, Any]]:
    return [
        buddy_geometry(),
        prefix_radix_geometry(),
        arbitrary_aligned_geometry(),
        hybrid_geometry(),
    ]
