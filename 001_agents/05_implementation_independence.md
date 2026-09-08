# 05 — Implementation Independence, Semantic vs Physical Representation

---

## Implementation Independence

SCR semantics must remain independent of implementation technology.

External technologies may be:

```
Provider
Adapter
Lowering Target
Execution Substrate
Storage Mechanism
Transport
Rendering Backend
Numerical Backend
```

They are not automatically semantic authorities.

This applies to technologies including:

```
Rust
C++
Python
LLVM
CUDA
ROCm
Vulkan
VulkanSceneGraph
Chrono
Eigen
CGAL
H3
OpenVDB
BLAS
AMQP implementations
```

and any future dependency.

The correct direction is:

```
SCR Semantic Contract
        ↓
SCR Interface / Provider Contract
        ↓
Adapter
        ↓
External Technology
```

Never:

```
External API
        ↓
SCR semantic definition
```

---

## Semantic vs Physical Representation

Always distinguish:

```
Semantic Object
      ≠
Language Representation
      ≠
IR Representation
      ≠
Memory Representation
      ≠
Device Representation
```

For example:

```
Semantic Position
      ≠
Rust Position Struct
      ≠
MLIR Value
      ≠
GPU Buffer
      ≠
Vulkan Resource
```

Representation transformations must preserve the applicable semantic contract.
