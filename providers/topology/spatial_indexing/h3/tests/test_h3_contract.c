// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

#include "../adapter/h3_c_api.h"

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <assert.h>

static void test_h3_latlng_roundtrip(void) {
    printf("[Test 1] H3 Lat/Lng Encoding & Decoding... ");
    H3LatLng coord = { 37.7749, -122.4194 }; // San Francisco
    H3Index cell = 0;
    int rc = h3_latlng_to_cell(coord, 8, &cell);
    assert(rc == H3_SUCCESS);
    assert(cell != 0);

    int res = h3_get_resolution(cell);
    assert(res == 8);

    H3LatLng center;
    rc = h3_cell_to_latlng(cell, &center);
    assert(rc == H3_SUCCESS);
    // Discretized center should be close to original coordinate
    assert(fabs(center.lat - coord.lat) < 1.0);
    assert(fabs(center.lon - coord.lon) < 1.0);
    printf("PASSED (Cell: 0x%llx, Res: %d)\n", (unsigned long long)cell, res);
}

static void test_h3_grid_disk(void) {
    printf("[Test 2] H3 Grid Disk Neighbors... ");
    H3LatLng coord = { 51.5074, -0.1278 }; // London
    H3Index cell = 0;
    int rc = h3_latlng_to_cell(coord, 7, &cell);
    assert(rc == H3_SUCCESS);

    // For k=1 on hexagonal grid, there are 1 + 6 = 7 cells
    H3Index disk[10];
    size_t count = 0;
    rc = h3_grid_disk(cell, 1, disk, 10, &count);
    assert(rc == H3_SUCCESS);
    assert(count == 7);
    printf("PASSED (Neighbor count for k=1: %zu)\n", count);
}

static void test_h3_hex_area(void) {
    printf("[Test 3] H3 Hexagon Area Resolution Hierarchy... ");
    double area_res0 = h3_get_hex_area_km2(0);
    double area_res1 = h3_get_hex_area_km2(1);
    double area_res8 = h3_get_hex_area_km2(8);

    assert(area_res0 > area_res1);
    assert(area_res1 > area_res8);
    assert(area_res8 > 0.0);
    printf("PASSED (Res 0: %.1f km2, Res 8: %.4f km2)\n", area_res0, area_res8);
}

static void test_h3_error_handling(void) {
    printf("[Test 4] H3 Error Handling and Preconditions... ");
    H3Index cell;
    H3LatLng invalid_coord = { 100.0, 0.0 }; // Latitude > 90
    int rc = h3_latlng_to_cell(invalid_coord, 8, &cell);
    assert(rc == H3_ERR_INVALID_COORDINATE);

    H3LatLng valid_coord = { 0.0, 0.0 };
    rc = h3_latlng_to_cell(valid_coord, 20, &cell); // Resolution > 15
    assert(rc == H3_ERR_INVALID_RESOLUTION);

    rc = h3_latlng_to_cell(valid_coord, 5, NULL);
    assert(rc == H3_ERR_NULL_POINTER);
    printf("PASSED\n");
}

int main(void) {
    printf("====================================\n");
    printf(" Running H3 Provider Contract Tests\n");
    printf("====================================\n");
    test_h3_latlng_roundtrip();
    test_h3_grid_disk();
    test_h3_hex_area();
    test_h3_error_handling();
    printf("\nAll H3 Contract Tests PASSED successfully.\n\n");
    return 0;
}
