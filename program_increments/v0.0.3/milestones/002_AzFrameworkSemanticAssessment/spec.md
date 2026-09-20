# Milestone 002: AzFramework Semantic Assessment

## 1. Scope & Objective
Systematically assess AzFramework, AzCore, AzNetworking, Multiplayer, AzPhysics, and SceneAPI as sources of industry-aligned semantic concepts. Map O3DE concepts to SCR semantics without making O3DE the authority.

## 2. Deliverables
- AzFramework semantic archaeology table
- Entity/component mapping (O3DE → SCR)
- Spatial/context mapping
- Physics/asset mapping
- Gap analysis (what SCR needs vs what exists)

## 3. Formal Invariants
1. O3DE concepts provide evidence for SCR semantics, not definitions.
2. AZ::EntityId is a provider mapping, not SCR identity.
3. AzPhysics is a provider implementation, not SCR physics semantics.

## 4. Exit Criteria
- [ ] Comprehensive assessment table covering AzCore/AzFramework/AzNetworking/Multiplayer/AzPhysics/SceneAPI
- [ ] Entity/component semantics mapped
- [ ] Spatial semantics mapped
- [ ] Physics semantics mapped
- [ ] Asset/resource semantics mapped
- [ ] Gap analysis produced

## 5. Dependencies
- Milestone 001 (semantic authority model)
