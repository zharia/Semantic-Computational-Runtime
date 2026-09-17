// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

#ifndef SCR_CGAL_C_API_H
#define SCR_CGAL_C_API_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#define CGAL_SUCCESS 0
#define CGAL_ERR_NULL_POINTER -1
#define CGAL_ERR_INSUFFICIENT_POINTS -2
#define CGAL_ERR_DEGENERATE_INPUT -3
#define CGAL_ERR_COMPUTATION_FAILED -4

typedef struct {
    double x;
    double y;
} CgalPoint2D;

typedef struct {
    size_t i0;
    size_t i1;
    size_t i2;
} CgalTriangleIndices;

/**
 * Computes the 2D Delaunay Triangulation for a set of points.
 * @param points Array of input points
 * @param num_points Number of points (must be >= 3)
 * @param out_triangles Preallocated buffer for output triangle indices
 * @param max_triangles Capacity of out_triangles buffer
 * @param out_triangle_count Pointer receiving actual number of triangles
 */
int cgal_delaunay_triangulation_2d(
    const CgalPoint2D* points,
    size_t num_points,
    CgalTriangleIndices* out_triangles,
    size_t max_triangles,
    size_t* out_triangle_count
);

/**
 * Computes the 2D Convex Hull for a set of points.
 * @param points Array of input points
 * @param num_points Number of points (must be >= 3)
 * @param out_hull_indices Preallocated buffer for vertex indices of the hull in counter-clockwise order
 * @param max_hull_indices Capacity of out_hull_indices buffer
 * @param out_hull_count Pointer receiving actual number of hull vertices
 */
int cgal_convex_hull_2d(
    const CgalPoint2D* points,
    size_t num_points,
    size_t* out_hull_indices,
    size_t max_hull_indices,
    size_t* out_hull_count
);

/**
 * Tests whether a query point lies inside, on boundary, or outside a simple polygon.
 * @return 1 for strictly inside, 0 for on boundary, -1 for outside, or negative error code
 */
int cgal_point_in_polygon_2d(
    const CgalPoint2D* polygon_vertices,
    size_t num_vertices,
    CgalPoint2D query_point
);

/**
 * Computes the signed area of a 2D polygon.
 */
int cgal_polygon_area_2d(
    const CgalPoint2D* polygon_vertices,
    size_t num_vertices,
    double* out_area
);

#ifdef __cplusplus
}
#endif

#endif // SCR_CGAL_C_API_H
