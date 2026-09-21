# Development Agent Instruction

## 005 — ROS2 Provider Implementation

**Program Increment:** v0.0.4

**Predecessor:** v0.0.3/003 (Reference Implementation)

**Objective type:** Provider integration

---

# 1. Mission

Implement a second real provider using ROS2 (Robot Operating System), demonstrating SCR contracts work across heterogeneous execution substrates.

The ROS2 provider maps SCR semantic contracts into ROS2's transform system (tf2), node lifecycle, and message types.

---

# 2. Governing Principles

## 2.1 SCR is the semantic authority

SCR defines the semantic contracts. ROS2 is the execution provider.

The implementation must preserve the distinction between SCR semantic definitions and ROS2 execution behavior.

## 2.2 Integrate rather than replace

Use existing ROS2 types (geometry_msgs, tf2, lifecycle_msgs).

Do not create a parallel transform system.

## 2.3 Evidence before claims

Every result must be supported by executable tests against actual ROS2 runtime.

---

# 3. Scope

## 3.1 Required ROS2 Components

| Component | ROS2 Type | Purpose |
|-----------|-----------|---------|
| Node | rclcpp::Node | SCR entity lifecycle |
| TF2 | tf2::BufferCore | Transform storage |
| Transform | geometry_msgs::msg::TransformStamped | Spatial state |
| Lifecycle | lifecycle_msgs::msg::State | State management |

## 3.2 Required Behavior

1. Create ROS2 node from SCR SID
2. Store transform in tf2 buffer
3. Query transform via tf2
4. Map lifecycle states
5. Verify SID preserved across operations

## 3.3 Exclusions

- Full ROS2 ecosystem (no navigation, perception, planning)
- Multi-node distributed systems
- DDS transport configuration
- ROS2 launch system
- Parameter server

---

# 4. Implementation Requirements

## 4.1 SID → Node Mapping

```
SCR SID → rclcpp::Node name
```

Use node name as SCR SID representation.

## 4.2 Transform Mapping

```
SCR SimilarityTransform → geometry_msgs::msg::TransformStamped
```

Map SCR coordinate system to ROS2 (ROS2: +x forward, +y left, +z up).

## 4.3 Lifecycle Mapping

```
SCR Created → node construction
SCR Active → node activation
SCR Suspended → node deactivation
SCR Destroyed → node destruction
```

## 4.4 Observation Mapping

```
tf2::BufferCore::lookupTransform → SCR SimilarityTransform
```

---

# 5. Testing

## 5.1 Required Tests

| Test | What it exercises |
|------|-------------------|
| Node creation | SID → node name mapping |
| Transform storage | SimilarityTransform → tf2 |
| Transform query | tf2 → SCR observation |
| Lifecycle transitions | Created → Active → Destroyed |
| Identity preservation | SID preserved across operations |
| Coordinate conversion | SCR ↔ ROS2 coordinate systems |
| Failure: invalid transform | Error handling |
| Failure: lookup failure | Error handling |
| Conformance: round-trip | SCR → ROS2 → SCR preserves state |

## 5.2 Build Command

```bash
# Requires ROS2 installed
g++ -std=c++17 -o test_ros2_provider \
    scr_ros2_provider.cpp test_ros2_provider.cpp \
    $(ros2 pkg-prefix rclcpp)/include \
    $(ros2 pkg-prefix tf2)/include \
    $(ros2 pkg-prefix geometry_msgs)/include \
    -lrclcpp -ltf2 -lgeometry_msgs
```

---

# 6. Deliverables

1. `scr_ros2_provider.h` — ROS2 provider header
2. `scr_ros2_provider.cpp` — ROS2 provider implementation
3. `test_ros2_provider.cpp` — Tests (minimum 10)
4. Updated final report

---

# 7. Acceptance Criteria

- [ ] ROS2 provider implemented using rclcpp
- [ ] tf2 used for transform storage and queries
- [ ] geometry_msgs used for transform representation
- [ ] Node lifecycle mapped to SCR states
- [ ] Minimum 10 tests passing
- [ ] All existing tests still pass
- [ ] Documentation updated

---

# 8. Dependencies

- ROS2 must be installed (check with `which ros2`)
- If ROS2 not available, defer to v0.0.5 or implement with mock ROS2 types
