// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

#ifndef SCR_CHRONO_C_API_H
#define SCR_CHRONO_C_API_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#define CHRONO_SUCCESS 0
#define CHRONO_ERR_NULL_HANDLE -1
#define CHRONO_ERR_INVALID_PARAMETER -2
#define CHRONO_ERR_BODY_NOT_FOUND -3
#define CHRONO_ERR_COMPUTATION_FAILED -4

typedef void* ChronoSystemHandle;
typedef uint64_t ChronoBodyId;

typedef struct {
    double x;
    double y;
    double z;
} ChronoVec3;

/**
 * Creates a physical multibody system.
 */
ChronoSystemHandle chrono_system_create(void);

/**
 * Destroys a physical multibody system and releases associated bodies.
 */
void chrono_system_destroy(ChronoSystemHandle sys);

/**
 * Sets uniform gravitational acceleration in the system.
 */
int chrono_system_set_gravity(ChronoSystemHandle sys, double gx, double gy, double gz);

/**
 * Creates and registers a rigid body in the physical system.
 * @param sys System handle
 * @param mass Mass in kg (must be > 0.0)
 * @param ixx Moment of inertia about x-axis
 * @param iyy Moment of inertia about y-axis
 * @param izz Moment of inertia about z-axis
 * @param pos Initial world-space position
 * @param out_body_id Output identifier for the rigid body
 */
int chrono_body_create(
    ChronoSystemHandle sys,
    double mass,
    double ixx, double iyy, double izz,
    ChronoVec3 pos,
    ChronoBodyId* out_body_id
);

/**
 * Sets linear velocity for a registered rigid body.
 */
int chrono_body_set_velocity(
    ChronoSystemHandle sys,
    ChronoBodyId body_id,
    ChronoVec3 vel
);

/**
 * Applies a world-space force to the center of mass of a rigid body for the current timestep.
 */
int chrono_body_apply_force(
    ChronoSystemHandle sys,
    ChronoBodyId body_id,
    ChronoVec3 force
);

/**
 * Gets the current world-space position of a rigid body.
 */
int chrono_body_get_position(
    ChronoSystemHandle sys,
    ChronoBodyId body_id,
    ChronoVec3* out_pos
);

/**
 * Gets the current linear velocity of a rigid body.
 */
int chrono_body_get_velocity(
    ChronoSystemHandle sys,
    ChronoBodyId body_id,
    ChronoVec3* out_vel
);

/**
 * Advances the multibody system state forward in time by dt seconds.
 */
int chrono_system_step(
    ChronoSystemHandle sys,
    double dt
);

#ifdef __cplusplus
}
#endif

#endif // SCR_CHRONO_C_API_H
