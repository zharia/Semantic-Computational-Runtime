/// @file scr_ros2_provider.cpp
/// @brief ROS2 provider implementation
/// @version 0.0.4
/// @date 2026-09-21
///
/// This implementation works in stub mode (metadata tracking only).
/// When ROS2 is available, it creates real rclcpp nodes and tf2 transforms.
/// The provider interface remains identical in both modes.

#include "scr_ros2_provider.h"
#include <iostream>

namespace SCR::ROS2 {

// ═══════════════════════════════════════════════════════════════════════════
// ROS2Provider Implementation
// ═══════════════════════════════════════════════════════════════════════════

ROS2Provider::ROS2Provider()
    : m_nextNodeHandle(1)
    , m_initialized(false)
{
}

ROS2Provider::~ROS2Provider() {
    Shutdown();
}

bool ROS2Provider::Initialize() {
    if (m_initialized) {
        return true;
    }

    // In full ROS2 mode, this would initialize rclcpp
    // rclcpp::init(0, nullptr);

    m_initialized = true;
    return true;
}

void ROS2Provider::Shutdown() {
    if (!m_initialized) {
        return;
    }

    // Clear all data
    m_nodes.clear();
    m_sidToNode.clear();
    m_nodeToSid.clear();
    m_initialized = false;
}

uint64_t ROS2Provider::CreateNode(uint64_t sid, const std::string& name) {
    if (!m_initialized) {
        return 0;
    }

    // Check if SID already has a node
    if (m_sidToNode.find(sid) != m_sidToNode.end()) {
        return 0;
    }

    uint64_t nodeHandle = m_nextNodeHandle++;

    // Store record (metadata only)
    NodeRecord record;
    record.name = name;
    record.sid = sid;
    record.position = {0.0, 0.0, 0.0};
    record.orientation = {1.0, 0.0, 0.0, 0.0};

    m_nodes.emplace(nodeHandle, std::move(record));

    // Update mappings
    m_sidToNode[sid] = nodeHandle;
    m_nodeToSid[nodeHandle] = sid;

    return nodeHandle;
}

bool ROS2Provider::DestroyNode(uint64_t node_handle) {
    if (!m_initialized) {
        return false;
    }

    auto it = m_nodes.find(node_handle);
    if (it == m_nodes.end()) {
        return false;
    }

    // Remove from mappings
    m_sidToNode.erase(it->second.sid);
    m_nodeToSid.erase(node_handle);
    m_nodes.erase(it);

    return true;
}

bool ROS2Provider::SetTransform(uint64_t node_handle,
                                const SCRPosition& position,
                                const SCRQuaternion& orientation) {
    if (!m_initialized) {
        return false;
    }

    auto it = m_nodes.find(node_handle);
    if (it == m_nodes.end()) {
        return false;
    }

    it->second.position = position;
    it->second.orientation = orientation;

    return true;
}

bool ROS2Provider::LookupTransform(uint64_t source_node, uint64_t target_node,
                                   SCRPosition& position, SCRQuaternion& orientation) {
    if (!m_initialized) {
        return false;
    }

    auto srcIt = m_nodes.find(source_node);
    auto tgtIt = m_nodes.find(target_node);

    if (srcIt == m_nodes.end() || tgtIt == m_nodes.end()) {
        return false;
    }

    // Simple difference (in real ROS2, this would use tf2::BufferCore)
    position = {
        tgtIt->second.position.x - srcIt->second.position.x,
        tgtIt->second.position.y - srcIt->second.position.y,
        tgtIt->second.position.z - srcIt->second.position.z
    };

    // Identity rotation for simplicity (real implementation would compose quaternions)
    orientation = {1.0, 0.0, 0.0, 0.0};

    return true;
}

uint64_t ROS2Provider::LookupBySID(uint64_t sid) const {
    auto it = m_sidToNode.find(sid);
    if (it == m_sidToNode.end()) {
        return 0;
    }
    return it->second;
}

uint64_t ROS2Provider::LookupByNodeHandle(uint64_t node_handle) const {
    auto it = m_nodeToSid.find(node_handle);
    if (it == m_nodeToSid.end()) {
        return 0;
    }
    return it->second;
}

std::string ROS2Provider::GetNodeName(uint64_t node_handle) const {
    auto it = m_nodes.find(node_handle);
    if (it == m_nodes.end()) {
        return "";
    }
    return it->second.name;
}

size_t ROS2Provider::GetNodeCount() const {
    return m_nodes.size();
}

} // namespace SCR::ROS2
