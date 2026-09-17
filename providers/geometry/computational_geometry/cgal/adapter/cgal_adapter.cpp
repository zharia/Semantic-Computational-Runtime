// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

#include "cgal_c_api.h"

#include <vector>
#include <algorithm>
#include <cmath>
#include <cstring>

#if defined(__has_include)
#if __has_include(<CGAL/Exact_predicates_inexact_constructions_kernel.h>) && __has_include(<CGAL/Delaunay_triangulation_2.h>)
#include <CGAL/Exact_predicates_inexact_constructions_kernel.h>
#include <CGAL/Delaunay_triangulation_2.h>
#include <CGAL/convex_hull_2.h>
#define SCR_HAS_NATIVE_CGAL 1
#else
#define SCR_HAS_NATIVE_CGAL 0
#endif
#else
#define SCR_HAS_NATIVE_CGAL 0
#endif

extern "C" {

#if !SCR_HAS_NATIVE_CGAL
// Robust reference 2D computational geometry implementations

static double cross_product_2d(CgalPoint2D a, CgalPoint2D b, CgalPoint2D c) {
    return (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x);
}

// Circumcircle check for Delaunay triangulation
static bool in_circumcircle(CgalPoint2D a, CgalPoint2D b, CgalPoint2D c, CgalPoint2D d) {
    double ax = a.x - d.x, ay = a.y - d.y;
    double bx = b.x - d.x, by = b.y - d.y;
    double cx = c.x - d.x, cy = c.y - d.y;

    double det = (ax * ax + ay * ay) * (bx * cy - cx * by)
               - (bx * bx + by * by) * (ax * cy - cx * ay)
               + (cx * cx + cy * cy) * (ax * by - bx * ay);

    double orientation = (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x);
    if (orientation < 0) det = -det;
    return det > 1e-11;
}
#endif

int cgal_convex_hull_2d(
    const CgalPoint2D* points,
    size_t num_points,
    size_t* out_hull_indices,
    size_t max_hull_indices,
    size_t* out_hull_count
) {
    if (!points || !out_hull_indices || !out_hull_count) return CGAL_ERR_NULL_POINTER;
    if (num_points < 3) return CGAL_ERR_INSUFFICIENT_POINTS;

#if SCR_HAS_NATIVE_CGAL
    // Native CGAL 2D Convex Hull
    typedef CGAL::Exact_predicates_inexact_constructions_kernel K;
    typedef K::Point_2 Point_2;
    std::vector<Point_2> cgal_pts;
    cgal_pts.reserve(num_points);
    for (size_t i = 0; i < num_points; ++i) {
        cgal_pts.emplace_back(points[i].x, points[i].y);
    }
    std::vector<Point_2> result;
    CGAL::convex_hull_2(cgal_pts.begin(), cgal_pts.end(), std::back_inserter(result));
    size_t count = std::min(result.size(), max_hull_indices);
    for (size_t i = 0; i < count; ++i) {
        for (size_t j = 0; j < num_points; ++j) {
            if (std::abs(points[j].x - result[i].x()) < 1e-9 &&
                std::abs(points[j].y - result[i].y()) < 1e-9) {
                out_hull_indices[i] = j;
                break;
            }
        }
    }
    *out_hull_count = count;
    return CGAL_SUCCESS;
#else
    // Monotone chain algorithm (Andrew's variant)
    std::vector<size_t> idx(num_points);
    for (size_t i = 0; i < num_points; ++i) idx[i] = i;

    std::sort(idx.begin(), idx.end(), [points](size_t i1, size_t i2) {
        if (std::abs(points[i1].x - points[i2].x) > 1e-12)
            return points[i1].x < points[i2].x;
        return points[i1].y < points[i2].y;
    });

    std::vector<size_t> hull;
    // Lower hull
    for (size_t i = 0; i < num_points; ++i) {
        while (hull.size() >= 2 &&
               cross_product_2d(points[hull[hull.size() - 2]],
                                points[hull.back()],
                                points[idx[i]]) <= 1e-11) {
            hull.pop_back();
        }
        hull.push_back(idx[i]);
    }
    // Upper hull
    size_t lower_size = hull.size();
    for (size_t i = num_points - 1; i > 0; --i) {
        size_t p = idx[i - 1];
        while (hull.size() > lower_size &&
               cross_product_2d(points[hull[hull.size() - 2]],
                                points[hull.back()],
                                points[p]) <= 1e-11) {
            hull.pop_back();
        }
        hull.push_back(p);
    }
    hull.pop_back(); // Remove duplicate starting point

    size_t count = std::min(hull.size(), max_hull_indices);
    for (size_t i = 0; i < count; ++i) {
        out_hull_indices[i] = hull[i];
    }
    *out_hull_count = count;
    return CGAL_SUCCESS;
#endif
}

int cgal_delaunay_triangulation_2d(
    const CgalPoint2D* points,
    size_t num_points,
    CgalTriangleIndices* out_triangles,
    size_t max_triangles,
    size_t* out_triangle_count
) {
    if (!points || !out_triangles || !out_triangle_count) return CGAL_ERR_NULL_POINTER;
    if (num_points < 3) return CGAL_ERR_INSUFFICIENT_POINTS;

#if SCR_HAS_NATIVE_CGAL
    typedef CGAL::Exact_predicates_inexact_constructions_kernel K;
    typedef CGAL::Delaunay_triangulation_2<K> Delaunay;
    typedef K::Point_2 Point_2;
    std::vector<std::pair<Point_2, size_t>> pts;
    pts.reserve(num_points);
    for (size_t i = 0; i < num_points; ++i) {
        pts.emplace_back(Point_2(points[i].x, points[i].y), i);
    }
    Delaunay dt;
    dt.insert(pts.begin(), pts.end());

    size_t count = 0;
    for (auto fit = dt.finite_faces_begin(); fit != dt.finite_faces_end() && count < max_triangles; ++fit) {
        out_triangles[count].i0 = fit->vertex(0)->info();
        out_triangles[count].i1 = fit->vertex(1)->info();
        out_triangles[count].i2 = fit->vertex(2)->info();
        count++;
    }
    *out_triangle_count = count;
    return CGAL_SUCCESS;
#else
    // Bowyer-Watson / naive empty circumcircle for reference verification
    std::vector<CgalTriangleIndices> triangles;
    for (size_t i = 0; i < num_points; ++i) {
        for (size_t j = i + 1; j < num_points; ++j) {
            for (size_t k = j + 1; k < num_points; ++k) {
                double cp = cross_product_2d(points[i], points[j], points[k]);
                if (std::abs(cp) < 1e-11) continue; // Collinear

                bool is_delaunay = true;
                for (size_t p = 0; p < num_points; ++p) {
                    if (p == i || p == j || p == k) continue;
                    if (in_circumcircle(points[i], points[j], points[k], points[p])) {
                        is_delaunay = false;
                        break;
                    }
                }
                if (is_delaunay) {
                    CgalTriangleIndices tri;
                    if (cp > 0) {
                        tri.i0 = i; tri.i1 = j; tri.i2 = k;
                    } else {
                        tri.i0 = i; tri.i1 = k; tri.i2 = j;
                    }
                    triangles.push_back(tri);
                }
            }
        }
    }
    size_t count = std::min(triangles.size(), max_triangles);
    for (size_t i = 0; i < count; ++i) {
        out_triangles[i] = triangles[i];
    }
    *out_triangle_count = count;
    return CGAL_SUCCESS;
#endif
}

int cgal_point_in_polygon_2d(
    const CgalPoint2D* polygon_vertices,
    size_t num_vertices,
    CgalPoint2D query_point
) {
    if (!polygon_vertices) return CGAL_ERR_NULL_POINTER;
    if (num_vertices < 3) return CGAL_ERR_INSUFFICIENT_POINTS;

    // Ray casting algorithm
    bool inside = false;
    for (size_t i = 0, j = num_vertices - 1; i < num_vertices; j = i++) {
        double xi = polygon_vertices[i].x, yi = polygon_vertices[i].y;
        double xj = polygon_vertices[j].x, yj = polygon_vertices[j].y;

        // Check if point is exactly on vertex
        if (std::abs(xi - query_point.x) < 1e-11 && std::abs(yi - query_point.y) < 1e-11) {
            return 0; // On boundary
        }

        // Check if point lies on edge
        double cp = cross_product_2d(polygon_vertices[j], polygon_vertices[i], query_point);
        if (std::abs(cp) < 1e-11) {
            if (query_point.x >= std::min(xi, xj) - 1e-11 && query_point.x <= std::max(xi, xj) + 1e-11 &&
                query_point.y >= std::min(yi, yj) - 1e-11 && query_point.y <= std::max(yi, yj) + 1e-11) {
                return 0; // On boundary
            }
        }

        bool intersect = ((yi > query_point.y) != (yj > query_point.y)) &&
                         (query_point.x < (xj - xi) * (query_point.y - yi) / (yj - yi) + xi);
        if (intersect) inside = !inside;
    }
    return inside ? 1 : -1;
}

int cgal_polygon_area_2d(
    const CgalPoint2D* polygon_vertices,
    size_t num_vertices,
    double* out_area
) {
    if (!polygon_vertices || !out_area) return CGAL_ERR_NULL_POINTER;
    if (num_vertices < 3) return CGAL_ERR_INSUFFICIENT_POINTS;

    // Shoelace formula
    double area = 0.0;
    for (size_t i = 0, j = num_vertices - 1; i < num_vertices; j = i++) {
        area += (polygon_vertices[j].x * polygon_vertices[i].y) -
                (polygon_vertices[i].x * polygon_vertices[j].y);
    }
    *out_area = 0.5 * area;
    return CGAL_SUCCESS;
}

} // extern "C"
