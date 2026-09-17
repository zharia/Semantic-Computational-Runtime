// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

#include "h3_c_api.h"

#include <math.h>
#include <stdlib.h>
#include <string.h>

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

#if defined(__has_include)
#if __has_include(<h3/h3api.h>)
#include <h3/h3api.h>
#define SCR_HAS_NATIVE_H3 1
#else
#define SCR_HAS_NATIVE_H3 0
#endif
#else
#define SCR_HAS_NATIVE_H3 0
#endif

// Approximate area table for resolutions 0 to 15 (km^2)
static const double HEX_AREAS_KM2[16] = {
    4250546.848, 607220.978, 86745.854, 12392.265,
    1770.3235, 252.90336, 36.12905, 5.161293,
    0.7373276, 0.1053325, 0.0150475, 0.0021496,
    0.0003071, 0.0000439, 0.0000063, 0.0000009
};

#if !SCR_HAS_NATIVE_H3
// Reference discrete spherical-to-hexagonal addressing schema
// Format: [1-bit unused][4-bit res][7-bit base cell][26-bit q_coord][26-bit r_coord]
static H3Index pack_ref_h3(int res, int base, int32_t q, int32_t r) {
    uint64_t ures = ((uint64_t)res & 0x0F) << 59;
    uint64_t ubase = ((uint64_t)base & 0x7F) << 52;
    uint64_t uq = ((uint64_t)(q + (1 << 25)) & 0x3FFFFFF) << 26;
    uint64_t ur = ((uint64_t)(r + (1 << 25)) & 0x3FFFFFF);
    return ures | ubase | uq | ur;
}

static void unpack_ref_h3(H3Index idx, int* res, int* base, int32_t* q, int32_t* r) {
    if (res) *res = (int)((idx >> 59) & 0x0F);
    if (base) *base = (int)((idx >> 52) & 0x7F);
    if (q) *q = (int32_t)(((idx >> 26) & 0x3FFFFFF) - (1 << 25));
    if (r) *r = (int32_t)((idx & 0x3FFFFFF) - (1 << 25));
}
#endif

int h3_latlng_to_cell(
    H3LatLng coord,
    int resolution,
    H3Index* out_index
) {
    if (!out_index) return H3_ERR_NULL_POINTER;
    if (resolution < 0 || resolution > 15) return H3_ERR_INVALID_RESOLUTION;
    if (coord.lat < -90.0 || coord.lat > 90.0 || coord.lon < -180.0 || coord.lon > 180.0) {
        return H3_ERR_INVALID_COORDINATE;
    }

#if SCR_HAS_NATIVE_H3
    LatLng ll;
    ll.lat = coord.lat * M_PI / 180.0;
    ll.lng = coord.lon * M_PI / 180.0;
    H3Error err = latLngToCell(&ll, resolution, out_index);
    return (err == E_SUCCESS) ? H3_SUCCESS : H3_ERR_INVALID_COORDINATE;
#else
    double scale = pow(3.0, (double)resolution / 2.0) * 100.0;
    // Equal-area cylindrical projection mapped to axial hex coordinates
    double x = (coord.lon / 180.0) * scale;
    double y = sin(coord.lat * (M_PI / 180.0)) * scale;

    // Hex axial rounding
    double q = (sqrt(3.0) / 3.0 * x - 1.0 / 3.0 * y);
    double r = (2.0 / 3.0 * y);
    int32_t rx = (int32_t)round(q);
    int32_t ry = (int32_t)round(r);

    int base_cell = (int)(fmod(fabs(coord.lon) + fabs(coord.lat), 122.0));
    *out_index = pack_ref_h3(resolution, base_cell, rx, ry);
    return H3_SUCCESS;
#endif
}

int h3_cell_to_latlng(
    H3Index index,
    H3LatLng* out_coord
) {
    if (!out_coord) return H3_ERR_NULL_POINTER;

#if SCR_HAS_NATIVE_H3
    LatLng ll;
    H3Error err = cellToLatLng(index, &ll);
    if (err != E_SUCCESS) return H3_ERR_INVALID_COORDINATE;
    out_coord->lat = ll.lat * 180.0 / M_PI;
    out_coord->lon = ll.lng * 180.0 / M_PI;
    return H3_SUCCESS;
#else
    int res = 0, base = 0;
    int32_t q = 0, r = 0;
    unpack_ref_h3(index, &res, &base, &q, &r);

    double scale = pow(3.0, (double)res / 2.0) * 100.0;
    if (scale <= 0.0) scale = 1.0;

    double x = sqrt(3.0) * (double)q + sqrt(3.0) / 2.0 * (double)r;
    double y = 1.5 * (double)r;

    double lon = (x / scale) * 180.0;
    double sin_lat = y / scale;
    if (sin_lat > 1.0) sin_lat = 1.0;
    if (sin_lat < -1.0) sin_lat = -1.0;
    double lat = asin(sin_lat) * (180.0 / M_PI);

    out_coord->lat = lat;
    out_coord->lon = lon;
    return H3_SUCCESS;
#endif
}

int h3_get_resolution(
    H3Index index
) {
#if SCR_HAS_NATIVE_H3
    return getResolution(index);
#else
    int res = 0;
    unpack_ref_h3(index, &res, NULL, NULL, NULL);
    return res;
#endif
}

int h3_grid_disk(
    H3Index origin,
    int k,
    H3Index* out_cells,
    size_t max_cells,
    size_t* out_count
) {
    if (!out_cells || !out_count) return H3_ERR_NULL_POINTER;
    if (k < 0) return H3_ERR_INVALID_RESOLUTION;

#if SCR_HAS_NATIVE_H3
    int64_t max_grid = 0;
    maxGridDiskSize(k, &max_grid);
    if ((size_t)max_grid > max_cells) return H3_ERR_BUFFER_TOO_SMALL;
    H3Error err = gridDisk(origin, k, out_cells);
    if (err != E_SUCCESS) return H3_ERR_BUFFER_TOO_SMALL;
    *out_count = (size_t)max_grid;
    return H3_SUCCESS;
#else
    int res = 0, base = 0;
    int32_t q0 = 0, r0 = 0;
    unpack_ref_h3(origin, &res, &base, &q0, &r0);

    size_t count = 0;
    for (int dq = -k; dq <= k; ++dq) {
        for (int dr = -k; dr <= k; ++dr) {
            int ds = -dq - dr;
            if (abs(dq) <= k && abs(dr) <= k && abs(ds) <= k) {
                if (count < max_cells) {
                    out_cells[count] = pack_ref_h3(res, base, q0 + dq, r0 + dr);
                    count++;
                }
            }
        }
    }
    *out_count = count;
    return H3_SUCCESS;
#endif
}

double h3_get_hex_area_km2(
    int resolution
) {
    if (resolution < 0 || resolution > 15) return 0.0;
    return HEX_AREAS_KM2[resolution];
}
