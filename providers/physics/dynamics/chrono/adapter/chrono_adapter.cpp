// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

#include "chrono_c_api.h"

#include <unordered_map>
#include <memory>
#include <vector>
#include <cmath>
#include <new>

#if defined(__has_include)
#if __has_include(<chrono/physics/ChSystemNSC.h>) && __has_include(<chrono/physics/ChBodyEasy.h>)
#include <chrono/physics/ChSystemNSC.h>
#include <chrono/physics/ChBodyEasy.h>
#define SCR_HAS_NATIVE_CHRONO 1
#else
#define SCR_HAS_NATIVE_CHRONO 0
#endif
#else
#define SCR_HAS_NATIVE_CHRONO 0
#endif

struct InternalRigidBody {
    uint64_t id;
    double mass;
    double inv_mass;
    ChronoVec3 inertia;
    ChronoVec3 pos;
    ChronoVec3 vel;
    ChronoVec3 accum_force;

#if SCR_HAS_NATIVE_CHRONO
    std::shared_ptr<chrono::ChBody> native_body;
#endif
};

struct InternalSystem {
    ChronoVec3 gravity;
    uint64_t next_body_id;
    std::unordered_map<uint64_t, InternalRigidBody> bodies;

#if SCR_HAS_NATIVE_CHRONO
    std::unique_ptr<chrono::ChSystemNSC> native_system;
#endif

    InternalSystem() : next_body_id(1) {
        gravity.x = 0.0;
        gravity.y = -9.81;
        gravity.z = 0.0;
#if SCR_HAS_NATIVE_CHRONO
        native_system = std::make_unique<chrono::ChSystemNSC>();
        native_system->SetGravitationalAcceleration(chrono::ChVector3d(gravity.x, gravity.y, gravity.z));
#endif
    }
};

extern "C" {

ChronoSystemHandle chrono_system_create(void) {
    auto* sys = new (std::nothrow) InternalSystem();
    return static_cast<ChronoSystemHandle>(sys);
}

void chrono_system_destroy(ChronoSystemHandle sys) {
    if (!sys) return;
    delete static_cast<InternalSystem*>(sys);
}

int chrono_system_set_gravity(ChronoSystemHandle sys, double gx, double gy, double gz) {
    if (!sys) return CHRONO_ERR_NULL_HANDLE;
    auto* system = static_cast<InternalSystem*>(sys);
    system->gravity.x = gx;
    system->gravity.y = gy;
    system->gravity.z = gz;

#if SCR_HAS_NATIVE_CHRONO
    if (system->native_system) {
        system->native_system->SetGravitationalAcceleration(chrono::ChVector3d(gx, gy, gz));
    }
#endif
    return CHRONO_SUCCESS;
}

int chrono_body_create(
    ChronoSystemHandle sys,
    double mass,
    double ixx, double iyy, double izz,
    ChronoVec3 pos,
    ChronoBodyId* out_body_id
) {
    if (!sys || !out_body_id) return CHRONO_ERR_NULL_HANDLE;
    if (mass <= 0.0) return CHRONO_ERR_INVALID_PARAMETER;

    auto* system = static_cast<InternalSystem*>(sys);
    uint64_t body_id = system->next_body_id++;

    InternalRigidBody body;
    body.id = body_id;
    body.mass = mass;
    body.inv_mass = 1.0 / mass;
    body.inertia = { ixx, iyy, izz };
    body.pos = pos;
    body.vel = { 0.0, 0.0, 0.0 };
    body.accum_force = { 0.0, 0.0, 0.0 };

#if SCR_HAS_NATIVE_CHRONO
    if (system->native_system) {
        auto ch_body = std::make_shared<chrono::ChBody>();
        ch_body->SetMass(mass);
        ch_body->SetInertiaXX(chrono::ChVector3d(ixx, iyy, izz));
        ch_body->SetPos(chrono::ChVector3d(pos.x, pos.y, pos.z));
        system->native_system->AddBody(ch_body);
        body.native_body = ch_body;
    }
#endif

    system->bodies[body_id] = body;
    *out_body_id = body_id;
    return CHRONO_SUCCESS;
}

int chrono_body_set_velocity(
    ChronoSystemHandle sys,
    ChronoBodyId body_id,
    ChronoVec3 vel
) {
    if (!sys) return CHRONO_ERR_NULL_HANDLE;
    auto* system = static_cast<InternalSystem*>(sys);
    auto it = system->bodies.find(body_id);
    if (it == system->bodies.end()) return CHRONO_ERR_BODY_NOT_FOUND;

    it->second.vel = vel;
#if SCR_HAS_NATIVE_CHRONO
    if (it->second.native_body) {
        it->second.native_body->SetPosDt(chrono::ChVector3d(vel.x, vel.y, vel.z));
    }
#endif
    return CHRONO_SUCCESS;
}

int chrono_body_apply_force(
    ChronoSystemHandle sys,
    ChronoBodyId body_id,
    ChronoVec3 force
) {
    if (!sys) return CHRONO_ERR_NULL_HANDLE;
    auto* system = static_cast<InternalSystem*>(sys);
    auto it = system->bodies.find(body_id);
    if (it == system->bodies.end()) return CHRONO_ERR_BODY_NOT_FOUND;

    it->second.accum_force.x += force.x;
    it->second.accum_force.y += force.y;
    it->second.accum_force.z += force.z;

#if SCR_HAS_NATIVE_CHRONO
    if (it->second.native_body) {
        it->second.native_body->AccumulateForce(chrono::ChVector3d(force.x, force.y, force.z),
                                                it->second.native_body->GetPos(), false);
    }
#endif
    return CHRONO_SUCCESS;
}

int chrono_body_get_position(
    ChronoSystemHandle sys,
    ChronoBodyId body_id,
    ChronoVec3* out_pos
) {
    if (!sys || !out_pos) return CHRONO_ERR_NULL_HANDLE;
    auto* system = static_cast<InternalSystem*>(sys);
    auto it = system->bodies.find(body_id);
    if (it == system->bodies.end()) return CHRONO_ERR_BODY_NOT_FOUND;

#if SCR_HAS_NATIVE_CHRONO
    if (it->second.native_body) {
        auto p = it->second.native_body->GetPos();
        out_pos->x = p.x();
        out_pos->y = p.y();
        out_pos->z = p.z();
        return CHRONO_SUCCESS;
    }
#endif
    *out_pos = it->second.pos;
    return CHRONO_SUCCESS;
}

int chrono_body_get_velocity(
    ChronoSystemHandle sys,
    ChronoBodyId body_id,
    ChronoVec3* out_vel
) {
    if (!sys || !out_vel) return CHRONO_ERR_NULL_HANDLE;
    auto* system = static_cast<InternalSystem*>(sys);
    auto it = system->bodies.find(body_id);
    if (it == system->bodies.end()) return CHRONO_ERR_BODY_NOT_FOUND;

#if SCR_HAS_NATIVE_CHRONO
    if (it->second.native_body) {
        auto v = it->second.native_body->GetPosDt();
        out_vel->x = v.x();
        out_vel->y = v.y();
        out_vel->z = v.z();
        return CHRONO_SUCCESS;
    }
#endif
    *out_vel = it->second.vel;
    return CHRONO_SUCCESS;
}

int chrono_system_step(
    ChronoSystemHandle sys,
    double dt
) {
    if (!sys) return CHRONO_ERR_NULL_HANDLE;
    if (dt <= 0.0) return CHRONO_ERR_INVALID_PARAMETER;
    auto* system = static_cast<InternalSystem*>(sys);

#if SCR_HAS_NATIVE_CHRONO
    if (system->native_system) {
        system->native_system->DoStepDynamics(dt);
        // Sync back positions
        for (auto& pair : system->bodies) {
            if (pair.second.native_body) {
                auto p = pair.second.native_body->GetPos();
                auto v = pair.second.native_body->GetPosDt();
                pair.second.pos = { p.x(), p.y(), p.z() };
                pair.second.vel = { v.x(), v.y(), v.z() };
            }
        }
        return CHRONO_SUCCESS;
    }
#endif

    // Symplectic Euler integration
    for (auto& pair : system->bodies) {
        auto& body = pair.second;
        // Total acceleration = gravity + applied forces / mass
        double ax = system->gravity.x + body.accum_force.x * body.inv_mass;
        double ay = system->gravity.y + body.accum_force.y * body.inv_mass;
        double az = system->gravity.z + body.accum_force.z * body.inv_mass;

        body.vel.x += ax * dt;
        body.vel.y += ay * dt;
        body.vel.z += az * dt;

        body.pos.x += body.vel.x * dt;
        body.pos.y += body.vel.y * dt;
        body.pos.z += body.vel.z * dt;

        // Clear transient accumulated force
        body.accum_force = { 0.0, 0.0, 0.0 };
    }
    return CHRONO_SUCCESS;
}

} // extern "C"
