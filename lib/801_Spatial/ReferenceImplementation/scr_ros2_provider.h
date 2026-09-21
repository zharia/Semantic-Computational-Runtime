#pragma once

/// @file scr_ros2_provider.h
/// @brief ROS2 provider for SCR spatial semantics
/// @version 0.0.4
/// @date 2026-09-21
///
/// Provider Specification:
///   Maps SCR spatial semantics to ROS2 tf2 transforms.
///   Provides SCR SID → ROS2 node name manifestation.
///   Maps SCR coordinate system to ROS2 tf2 transform tree.
///
/// Dependencies:
///   ROS2 Humble (via Docker container)
///   - rclcpp
///   - tf2
///   - geometry_msgs

#include <cstdint>
#include <string>
#include <unordered_map>

namespace SCR::ROS2 {

/// @brief ROS2 coordinate system
///   ROS2: +X forward, +Z up, +Y left (right-handed)
///   SCR:  +Z forward, +Y up, +X right (right-handed)
///
/// Mapping matrix:
///   ROS2.x = SCR.z
///   ROS2.y = -SCR.x
///   ROS2.z = SCR.y

/// @brief 3D position in SCR canonical coordinates
struct SCRPosition {
    double x = 0.0;  ///< +X right
    double y = 0.0;  ///< +Y up
    double z = 0.0;  ///< +Z forward
};

/// @brief 3D position in ROS2 coordinates
struct ROS2Position {
    double x = 0.0;  ///< +X forward
    double y = 0.0;  ///< +Y left
    double z = 0.0;  ///< +Z up
};

/// @brief Quaternion in SCR canonical format (Hamilton, scalar-first)
struct SCRQuaternion {
    double w = 1.0;  ///< Scalar part
    double x = 0.0;  ///< i component
    double y = 0.0;  ///< j component
    double z = 0.0;  ///< k component
};

/// @brief Quaternion in ROS2 format (scalar-last)
struct ROS2Quaternion {
    double x = 0.0;  ///< i component
    double y = 0.0;  ///< j component
    double z = 0.0;  ///< k component
    double w = 1.0;  ///< Scalar part
};

/// @brief Convert SCR position to ROS2 position
/// @param scr SCR canonical position
/// @return ROS2 position
inline ROS2Position scrToROS2(const SCRPosition& scr) {
    return {scr.z, -scr.x, scr.y};
}

/// @brief Convert ROS2 position to SCR position
/// @param ros2 ROS2 position
/// @return SCR canonical position
inline SCRPosition ros2ToSCR(const ROS2Position& ros2) {
    return {-ros2.y, ros2.z, ros2.x};
}

/// @brief Convert SCR quaternion to ROS2 quaternion
/// @param scr SCR quaternion (Hamilton, scalar-first)
/// @return ROS2 quaternion (scalar-last)
inline ROS2Quaternion scrToROS2Quat(const SCRQuaternion& scr) {
    return {scr.x, scr.y, scr.z, scr.w};
}

/// @brief Convert ROS2 quaternion to SCR quaternion
/// @param ros2 ROS2 quaternion (scalar-last)
/// @return SCR quaternion (Hamilton, scalar-first)
inline SCRQuaternion ros2ToSCRQuat(const ROS2Quaternion& ros2) {
    return {ros2.w, ros2.x, ros2.y, ros2.z};
}

/// @brief ROS2 Provider
/// @details Maps SCR spatial semantics to ROS2 tf2 transforms.
///
/// Architecture:
///   SCR Semantic Definition → SCR Position → ROS2 Provider → tf2 Transform
///
/// The provider maintains a bidirectional mapping between SCR SIDs and
/// ROS2 node names, allowing any SCR entity to be manifested as a ROS2 node.
class ROS2Provider {
public:
    ROS2Provider();
    ~ROS2Provider();

    /// @brief Initialize the provider (must be called before use)
    /// @return true if initialization succeeded
    bool Initialize();

    /// @brief Shutdown the provider (cleanup resources)
    void Shutdown();

    /// @brief Create a ROS2 node from SCR metadata
    /// @param sid SCR semantic identifier
    /// @param name Node name
    /// @return ROS2 node handle (0 on failure)
    uint64_t CreateNode(uint64_t sid, const std::string& name);

    /// @brief Destroy a ROS2 node
    /// @param node_handle ROS2 node handle
    /// @return true if destruction succeeded
    bool DestroyNode(uint64_t node_handle);

    /// @brief Set transform for a node
    /// @param node_handle ROS2 node handle
    /// @param position SCR position
    /// @param orientation SCR quaternion
    /// @return true if set succeeded
    bool SetTransform(uint64_t node_handle, 
                      const SCRPosition& position,
                      const SCRQuaternion& orientation);

    /// @brief Look up transform between two nodes
    /// @param source_node Source node handle
    /// @param target_node Target node handle
    /// @param [out] position Output SCR position
    /// @param [out] orientation Output SCR quaternion
    /// @return true if lookup succeeded
    bool LookupTransform(uint64_t source_node, uint64_t target_node,
                         SCRPosition& position, SCRQuaternion& orientation);

    /// @brief Look up ROS2 node handle from SCR SID
    /// @param sid SCR semantic identifier
    /// @return ROS2 node handle (0 if not found)
    uint64_t LookupBySID(uint64_t sid) const;

    /// @brief Look up SCR SID from ROS2 node handle
    /// @param node_handle ROS2 node handle
    /// @return SCR SID (0 if not found)
    uint64_t LookupByNodeHandle(uint64_t node_handle) const;

    /// @brief Get node name
    /// @param node_handle ROS2 node handle
    /// @return Node name (empty if not found)
    std::string GetNodeName(uint64_t node_handle) const;

    /// @brief Get number of managed nodes
    /// @return Node count
    size_t GetNodeCount() const;

private:
    struct NodeRecord {
        std::string name;
        uint64_t sid;
        SCRPosition position;
        SCRQuaternion orientation;
    };

    std::unordered_map<uint64_t, NodeRecord> m_nodes;
    std::unordered_map<uint64_t, uint64_t> m_sidToNode;
    std::unordered_map<uint64_t, uint64_t> m_nodeToSid;
    uint64_t m_nextNodeHandle;
    bool m_initialized;
};

} // namespace SCR::ROS2
