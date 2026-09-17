#ifndef CAVE_SPATIAL_SEMANTICS_HPP
#define CAVE_SPATIAL_SEMANTICS_HPP

#include <cmath>
#include <string>
#include <vector>
#include <algorithm>
#include <iostream>

/**
 * SCR Spatial Semantics Domain Specification (SCR-LIB-SPATIAL / PI-CAVE-001C).
 * Conforms to docs/114_SPATIAL_SEMANTICS.md and lib/801_Spatial/101_definition.md.
 *
 * S = (D, P, R, C, M, T, N, Q, X, Pr)
 * - D: Discrete Cartesian lattice Z^3 embedded in R^3 Euclidean metric space.
 * - P: Positions (Point3D in explicit ReferenceFrame).
 * - R: Spatial Relationships (Adjacency N6/N26, Containment, Occlusion, LineOfSight).
 * - C: Coordinate & Reference Systems (World, CaveLattice, PlayerBody, CameraEye).
 * - M: Metrics (Euclidean L2, Manhattan L1, Chebyshev L_inf).
 * - T: Topology & Adjacency (6-connectivity face-sharing, 26-connectivity).
 * - N: Neighbourhood & Locality (Voxel AABB bounding boxes, 3D stencils).
 * - Q: Spatial Queries (Amanatides-Woo DDA raymarching, AABB overlap/sweep tests).
 * - X: Spatial Transformations (SE(3) rigid transforms: translations + Quaternions).
 * - Pr: Semantic Provenance & Material Closures.
 */
namespace SCR::Spatial {

// Continuous 3D vector in Euclidean space
struct Vector3D {
    float x, y, z;

    Vector3D(float x = 0.0f, float y = 0.0f, float z = 0.0f) : x(x), y(y), z(z) {}

    Vector3D operator+(const Vector3D& o) const { return Vector3D(x + o.x, y + o.y, z + o.z); }
    Vector3D operator-(const Vector3D& o) const { return Vector3D(x - o.x, y - o.y, z - o.z); }
    Vector3D operator-() const { return Vector3D(-x, -y, -z); }
    Vector3D operator*(float s) const { return Vector3D(x * s, y * s, z * s); }
    Vector3D operator/(float s) const { return Vector3D(x / s, y / s, z / s); }

    Vector3D& operator+=(const Vector3D& o) { x += o.x; y += o.y; z += o.z; return *this; }
    Vector3D& operator-=(const Vector3D& o) { x -= o.x; y -= o.y; z -= o.z; return *this; }

    float lengthSq() const { return x * x + y * y + z * z; }
    float length() const { return std::sqrt(lengthSq()); }

    Vector3D normalized() const {
        float l = length();
        return l > 1e-6f ? (*this / l) : Vector3D(0, 0, 0);
    }

    float dot(const Vector3D& o) const { return x * o.x + y * o.y + z * o.z; }

    Vector3D cross(const Vector3D& o) const {
        return Vector3D(
            y * o.z - z * o.y,
            z * o.x - x * o.z,
            x * o.y - y * o.x
        );
    }
};

inline Vector3D operator*(float s, const Vector3D& v) {
    return v * s;
}

using Point3D = Vector3D;

// Discrete Lattice Coordinate (Z^3)
struct LatticeCoord3D {
    int x, y, z;

    LatticeCoord3D(int x = 0, int y = 0, int z = 0) : x(x), y(y), z(z) {}

    bool operator==(const LatticeCoord3D& o) const { return x == o.x && y == o.y && z == o.z; }
    bool operator!=(const LatticeCoord3D& o) const { return !(*this == o); }
    LatticeCoord3D operator+(const LatticeCoord3D& o) const { return LatticeCoord3D(x + o.x, y + o.y, z + o.z); }
    LatticeCoord3D operator-(const LatticeCoord3D& o) const { return LatticeCoord3D(x - o.x, y - o.y, z - o.z); }

    Point3D toContinuous(float voxel_size = 1.0f) const {
        return Point3D((x + 0.5f) * voxel_size, (y + 0.5f) * voxel_size, (z + 0.5f) * voxel_size);
    }

    static LatticeCoord3D fromContinuous(const Point3D& p, float voxel_size = 1.0f) {
        return LatticeCoord3D(
            (int)std::floor(p.x / voxel_size),
            (int)std::floor(p.y / voxel_size),
            (int)std::floor(p.z / voxel_size)
        );
    }
};

// Spatial Metrics (M)
inline float euclideanDistance(const Point3D& a, const Point3D& b) {
    return (a - b).length();
}

inline float manhattanDistance(const LatticeCoord3D& a, const LatticeCoord3D& b) {
    return std::abs(a.x - b.x) + std::abs(a.y - b.y) + std::abs(a.z - b.z);
}

inline int chebyshevDistance(const LatticeCoord3D& a, const LatticeCoord3D& b) {
    return std::max({std::abs(a.x - b.x), std::abs(a.y - b.y), std::abs(a.z - b.z)});
}

// Spatial Direction & Topological Adjacency (T, R)
enum class Direction6 {
    POS_X = 0, // East (+X)
    NEG_X = 1, // West (-X)
    POS_Y = 2, // Up (+Y)
    NEG_Y = 3, // Down (-Y)
    POS_Z = 4, // South (+Z)
    NEG_Z = 5  // North (-Z)
};

inline LatticeCoord3D getDirectionOffset(Direction6 dir) {
    switch (dir) {
        case Direction6::POS_X: return LatticeCoord3D(1, 0, 0);
        case Direction6::NEG_X: return LatticeCoord3D(-1, 0, 0);
        case Direction6::POS_Y: return LatticeCoord3D(0, 1, 0);
        case Direction6::NEG_Y: return LatticeCoord3D(0, -1, 0);
        case Direction6::POS_Z: return LatticeCoord3D(0, 0, 1);
        case Direction6::NEG_Z: return LatticeCoord3D(0, 0, -1);
    }
    return LatticeCoord3D(0, 0, 0);
}

inline Vector3D getDirectionNormal(Direction6 dir) {
    auto off = getDirectionOffset(dir);
    return Vector3D((float)off.x, (float)off.y, (float)off.z);
}

inline Direction6 getOppositeDirection(Direction6 dir) {
    switch (dir) {
        case Direction6::POS_X: return Direction6::NEG_X;
        case Direction6::NEG_X: return Direction6::POS_X;
        case Direction6::POS_Y: return Direction6::NEG_Y;
        case Direction6::NEG_Y: return Direction6::POS_Y;
        case Direction6::POS_Z: return Direction6::NEG_Z;
        case Direction6::NEG_Z: return Direction6::POS_Z;
    }
    return Direction6::POS_X;
}

// Spatial Unit Quaternion (X)
struct Quaternion {
    float w, x, y, z;

    Quaternion(float w = 1.0f, float x = 0.0f, float y = 0.0f, float z = 0.0f)
        : w(w), x(x), y(y), z(z) {}

    static Quaternion fromAxisAngle(const Vector3D& axis, float radians) {
        float half = radians * 0.5f;
        float s = std::sin(half);
        Vector3D a = axis.normalized();
        return Quaternion(std::cos(half), a.x * s, a.y * s, a.z * s);
    }

    static Quaternion fromEuler(float pitch, float yaw, float roll) {
        // Compose intrinsic Euler angles: Yaw (around Y), then Pitch (around X), then Roll (around Z)
        float cy = std::cos(yaw * 0.5f);
        float sy = std::sin(yaw * 0.5f);
        float cp = std::cos(pitch * 0.5f);
        float sp = std::sin(pitch * 0.5f);
        float cr = std::cos(roll * 0.5f);
        float sr = std::sin(roll * 0.5f);

        return Quaternion(
            cy * cp * cr + sy * sp * sr, // w
            cy * sp * cr + sy * cp * sr, // x (Pitch around X)
            sy * cp * cr - cy * sp * sr, // y (Yaw around Y)
            cy * cp * sr - sy * sp * cr  // z (Roll around Z)
        );
    }

    Quaternion operator*(const Quaternion& o) const {
        return Quaternion(
            w * o.w - x * o.x - y * o.y - z * o.z,
            w * o.x + x * o.w + y * o.z - z * o.y,
            w * o.y - x * o.z + y * o.w + z * o.x,
            w * o.z + x * o.y - y * o.x + z * o.w
        );
    }

    Vector3D rotate(const Vector3D& v) const {
        Vector3D qv(x, y, z);
        Vector3D uv = qv.cross(v);
        Vector3D uuv = qv.cross(uv);
        return v + ((uv * w) + uuv) * 2.0f;
    }
};

// Spatial Rigid Transform SE(3) (X)
struct TransformSE3 {
    Point3D translation;
    Quaternion rotation;

    TransformSE3(const Point3D& t = Point3D(0, 0, 0), const Quaternion& r = Quaternion())
        : translation(t), rotation(r) {}

    Point3D transformPoint(const Point3D& p) const {
        return translation + rotation.rotate(p);
    }

    Vector3D transformVector(const Vector3D& v) const {
        return rotation.rotate(v);
    }

    TransformSE3 compose(const TransformSE3& child) const {
        return TransformSE3(
            transformPoint(child.translation),
            rotation * child.rotation
        );
    }
};

// Axis-Aligned Bounding Box (AABB) (N, Q)
struct AABB3D {
    Point3D min;
    Point3D max;

    AABB3D() : min(0,0,0), max(0,0,0) {}
    AABB3D(const Point3D& min, const Point3D& max) : min(min), max(max) {}

    bool intersects(const AABB3D& o) const {
        return (min.x <= o.max.x && max.x >= o.min.x) &&
               (min.y <= o.max.y && max.y >= o.min.y) &&
               (min.z <= o.max.z && max.z >= o.min.z);
    }

    bool contains(const Point3D& p) const {
        return (p.x >= min.x && p.x <= max.x) &&
               (p.y >= min.y && p.y <= max.y) &&
               (p.z >= min.z && p.z <= max.z);
    }
};

// Continuous Ray (Q)
struct Ray3D {
    Point3D origin;
    Vector3D direction;

    Ray3D(const Point3D& o, const Vector3D& d) : origin(o), direction(d.normalized()) {}

    Point3D pointAt(float t) const {
        return origin + direction * t;
    }
};

// Reference Frame Hierarchy (C)
struct ReferenceFrame {
    std::string frame_id;
    std::string parent_frame_id;
    TransformSE3 local_transform;

    ReferenceFrame(const std::string& id = "world", const std::string& parent = "",
                   const TransformSE3& local = TransformSE3())
        : frame_id(id), parent_frame_id(parent), local_transform(local) {}

    Point3D transformPointToParent(const Point3D& p) const {
        return local_transform.transformPoint(p);
    }

    Vector3D transformVectorToParent(const Vector3D& v) const {
        return local_transform.transformVector(v);
    }
};

} // namespace SCR::Spatial

#endif // CAVE_SPATIAL_SEMANTICS_HPP
