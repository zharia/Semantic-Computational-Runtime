# H3 Spatial Indexing Provider Contract

**Provider:** h3  
**Domain:** topology  
**Subdomain:** spatial_indexing  
**Version:** 0.1.0  
**Status:** Normative Contract  
**Governing Documents:** [`docs/architecture/103_provider_contracts.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/docs/architecture/103_provider_contracts.md)

---

## 1. Contract Overview

This document specifies the concrete Provider Contract implemented by the `h3` provider for the `topology/spatial_indexing` capability domain. It defines discrete hexagonal hierarchical spatial indexing, spatial containment, k-ring neighbor search, and coordinate resolution mapping.

---

## 2. Semantic Capabilities

* `[topology, spatial_indexing, geo_to_h3]` — Latitude/longitude to discrete hexagonal cell index.
* `[topology, spatial_indexing, h3_to_geo]` — Cell index to center geographic coordinates.
* `[topology, spatial_indexing, k_ring]` — Topological k-ring neighborhood expansion on discrete hexagonal lattice.
* `[topology, spatial_indexing, resolution_hierarchy]` — Hierarchical resolution scaling (levels 0-15).

---

## 3. Operations & Signatures

* `h3_latlng_to_cell(coord, resolution, out_index) -> int`
* `h3_cell_to_latlng(index, out_coord) -> int`
* `h3_get_resolution(index) -> int`
* `h3_grid_disk(origin, k, out_cells, max_cells, out_count) -> int`
* `h3_get_hex_area_km2(resolution) -> double`

---

## 4. Preconditions & Postconditions

1. **Precondition (Resolution Bounds):** Resolution must be between 0 and 15 inclusive. Violations return `H3_ERR_INVALID_RESOLUTION`.
2. **Precondition (Coordinate Bounds):** Latitude must lie in $[-90, 90]$ and longitude in $[-180, 180]$.
3. **Postcondition (Neighborhood Cardinality):** On planar discrete hexagonal topology, a distance-$k$ grid disk produces $1 + 3k(k+1)$ cells.

---

## 5. Failure Semantics & Error Codes

* `H3_SUCCESS = 0`
* `H3_ERR_NULL_POINTER = -1`
* `H3_ERR_INVALID_RESOLUTION = -2`
* `H3_ERR_INVALID_COORDINATE = -3`
* `H3_ERR_BUFFER_TOO_SMALL = -4`

---

## 6. Conformance Test Suite

The provider is validated against the conformance suite in `tests/test_h3_contract.c`.
