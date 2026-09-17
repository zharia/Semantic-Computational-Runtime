// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

#include "../adapter/cgal_c_api.h"

#include <iostream>
#include <vector>
#include <cassert>
#include <cmath>

static void test_cgal_convex_hull() {
    std::cout << "[Test 1] CGAL 2D Convex Hull Computation... ";
    // Square points plus an interior point
    CgalPoint2D pts[5] = {
        {0.0, 0.0},
        {1.0, 0.0},
        {1.0, 1.0},
        {0.0, 1.0},
        {0.5, 0.5} // interior point
    };

    size_t hull_indices[10];
    size_t hull_count = 0;
    int rc = cgal_convex_hull_2d(pts, 5, hull_indices, 10, &hull_count);
    assert(rc == CGAL_SUCCESS);
    assert(hull_count == 4); // The interior point should be excluded
    std::cout << "PASSED (Hull vertices: " << hull_count << ")\n";
}

static void test_cgal_delaunay_triangulation() {
    std::cout << "[Test 2] CGAL 2D Delaunay Triangulation... ";
    CgalPoint2D pts[4] = {
        {0.0, 0.0},
        {2.0, 0.0},
        {1.0, 1.5},
        {1.0, 0.5}
    };

    CgalTriangleIndices tris[10];
    size_t tri_count = 0;
    int rc = cgal_delaunay_triangulation_2d(pts, 4, tris, 10, &tri_count);
    assert(rc == CGAL_SUCCESS);
    assert(tri_count >= 2);
    std::cout << "PASSED (Triangles: " << tri_count << ")\n";
}

static void test_cgal_point_in_polygon_and_area() {
    std::cout << "[Test 3] CGAL Point in Polygon & Polygon Area... ";
    // Unit square with vertices counter-clockwise
    CgalPoint2D square[4] = {
        {0.0, 0.0},
        {1.0, 0.0},
        {1.0, 1.0},
        {0.0, 1.0}
    };

    double area = 0.0;
    int rc = cgal_polygon_area_2d(square, 4, &area);
    assert(rc == CGAL_SUCCESS);
    assert(std::abs(std::abs(area) - 1.0) < 1e-9);

    // Inside point
    int in_res = cgal_point_in_polygon_2d(square, 4, {0.5, 0.5});
    assert(in_res == 1);

    // Outside point
    int out_res = cgal_point_in_polygon_2d(square, 4, {1.5, 0.5});
    assert(out_res == -1);

    // Boundary point
    int bnd_res = cgal_point_in_polygon_2d(square, 4, {0.0, 0.5});
    assert(bnd_res == 0);

    std::cout << "PASSED\n";
}

static void test_cgal_error_handling() {
    std::cout << "[Test 4] CGAL Precondition and Error Handling... ";
    size_t count = 0;
    int rc = cgal_convex_hull_2d(nullptr, 2, nullptr, 0, &count);
    assert(rc == CGAL_ERR_NULL_POINTER);

    CgalPoint2D pt = {0.0, 0.0};
    size_t idx = 0;
    rc = cgal_convex_hull_2d(&pt, 1, &idx, 1, &count);
    assert(rc == CGAL_ERR_INSUFFICIENT_POINTS);

    std::cout << "PASSED\n";
}

int main() {
    std::cout << "======================================\n";
    std::cout << " Running CGAL Provider Contract Tests\n";
    std::cout << "======================================\n";
    test_cgal_convex_hull();
    test_cgal_delaunay_triangulation();
    test_cgal_point_in_polygon_and_area();
    test_cgal_error_handling();
    std::cout << "\nAll CGAL Contract Tests PASSED successfully.\n\n";
    return 0;
}
