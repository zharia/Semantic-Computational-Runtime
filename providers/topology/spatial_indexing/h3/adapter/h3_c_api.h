// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

#ifndef SCR_H3_C_API_H
#define SCR_H3_C_API_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#define H3_SUCCESS 0
#define H3_ERR_NULL_POINTER -1
#define H3_ERR_INVALID_RESOLUTION -2
#define H3_ERR_INVALID_COORDINATE -3
#define H3_ERR_BUFFER_TOO_SMALL -4

typedef uint64_t H3Index;

typedef struct {
    double lat; // degrees [-90.0, 90.0]
    double lon; // degrees [-180.0, 180.0]
} H3LatLng;

/**
 * Encodes latitude/longitude coordinates to an H3 index at a specified resolution (0-15).
 */
int h3_latlng_to_cell(
    H3LatLng coord,
    int resolution,
    H3Index* out_index
);

/**
 * Decodes an H3 cell index to center latitude/longitude coordinates.
 */
int h3_cell_to_latlng(
    H3Index index,
    H3LatLng* out_coord
);

/**
 * Returns the resolution of an H3 cell index (0-15).
 */
int h3_get_resolution(
    H3Index index
);

/**
 * Returns all neighboring cells within grid distance k of the origin cell.
 * @param origin Origin cell index
 * @param k Ring distance (k >= 0)
 * @param out_cells Preallocated buffer for output cell indices
 * @param max_cells Buffer capacity
 * @param out_count Pointer receiving actual number of neighbor cells
 */
int h3_grid_disk(
    H3Index origin,
    int k,
    H3Index* out_cells,
    size_t max_cells,
    size_t* out_count
);

/**
 * Returns the average cell area in square kilometers for a given resolution.
 */
double h3_get_hex_area_km2(
    int resolution
);

#ifdef __cplusplus
}
#endif

#endif // SCR_H3_C_API_H
