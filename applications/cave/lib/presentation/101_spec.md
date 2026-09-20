# SCR Presentation Domain — 101 Specification

## Purpose
Define the consumer domain that turns RenderWorld into a concrete presented frame.

## Owns
Observers/cameras, viewports, render scheduling, visibility, LOD application, render caches, GPU resources, compositor and screen-space effects.

## Does not own
Authoritative simulation state, fluid/rigid-body dynamics, simulation causality or authoritative simulation time.

## RenderWorld
Consumes a versioned projection and builds provider-specific state. It must track provenance and tolerate disposal/reconstruction.

## Observer
A semantic observer may describe position, orientation, view/projection parameters, viewport, temporal request and visibility requirements. Concrete OGRE camera objects remain local.

## Screen-space effects
SSDM, SSR, SSAO, motion blur and temporal reconstruction are presentation operations. They must not mutate World.

## Failure
Presentation restart must reconstruct from snapshot/projection. Simulation remains independent.
