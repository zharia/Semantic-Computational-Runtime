# Sprint 001 Record: Semantic Authority Model

## 1. Semantic Authority Classification

For each system, classify its role relative to SCR:

| System | Authority Classification | Justification |
|--------|------------------------|---------------|
| SCR | SCR-authoritative | Defines semantic meaning, composition, constraints |
| USD | External-standard-authoritative (within USD domain) | Legitimate authority for USD prim semantics |
| ROS 2 | External-standard-authoritative (within robotics domain) | Legitimate authority for ROS 2 node/topic semantics |
| MLIR | Representation-only | Compiler IR, not semantic authority |
| OpenVDB | Provider-specific (volumetric data) | Domain technology with own semantics |
| H3 | Provider-specific (spatial indexing) | Domain technology with own semantics |
| O3DE | Provider/execution | Runtime execution provider |
| AzFramework | Provider-specific (O3DE framework) | Framework implementation, not SCR authority |
| AzNetworking | Provider-specific (network transport) | Transport implementation |
| AzPhysics | Provider-specific (physics backend) | Physics implementation |
| Bullet3 | Provider-specific (physics backend) | Physics implementation |
| PhysX | Provider-specific (physics backend) | Physics implementation |
| Ogre3D | Provider-specific (rendering backend) | Rendering implementation |
| Mojo | Implementation-specific | Programming language, not semantic authority |

## 2. Authority Rules

1. SCR semantic definitions are the sole authority for SCR meaning.
2. External standards (USD, ROS 2) are authorities within their own domains.
3. Provider implementations (O3DE, Bullet, PhysX) implement contracts; they do not define them.
4. Framework code (AzFramework) is a provider-specific implementation.
5. Representation technologies (MLIR) are not semantic authorities.
6. No external system may silently redefine SCR semantics.

## 3. Verification

- No system listed as SCR-authoritative except SCR itself.
- All providers correctly classified as implementation-specific.
- All external standards correctly classified as domain-authoritative within their scope.
