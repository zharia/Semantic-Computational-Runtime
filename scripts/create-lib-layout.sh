#!/usr/bin/env bash

set -euo pipefail

LIB="${1:-lib}"

echo "Creating library structure in: ${LIB}"

mkdir -p "$LIB"

create_tree() {
    local base="$1"
    shift

    for dir in "$@"; do
        mkdir -p "$LIB/$base/$dir"
    done
}

# Core
create_tree Core \
    IR Types Attributes Values Operations Interfaces Concepts Identity \
    Composition Contracts Capabilities Constraints Properties Relations \
    Effects State Context Semantics Verification Analysis Transforms Serialization

# Math
create_tree Math \
    IR Scalar Vector Matrix Tensor Polynomial Algebra Arithmetic Calculus \
    Differential Integral Probability Statistics Optimization Functions \
    Transforms Interpolation Approximation Numerical Symbolic Complex \
    Quaternion Dual AutomaticDifferentiation Random

# Data
create_tree Data \
    IR Types Values Scalar Vector Tensor Matrix Buffer Memory Collection \
    Sequence Table Record Object Sparse Dense Structured Unstructured \
    Serialization Compression Partitioning Sharding Locality Transfer

# Field
create_tree Field \
    IR Scalar Vector Tensor Discrete Continuous Spatial Temporal \
    Spatiotemporal Sampling Interpolation Extrapolation Gradient Divergence \
    Curl Laplacian Advection Diffusion Convolution Composition Transformation \
    Boundary InitialConditions Operators Solvers

# Graph
create_tree Graph \
    IR Node Edge Hyperedge Hypergraph Directed Undirected Weighted Typed \
    Attributed Hierarchical Multigraph Bipartite Connectivity Adjacency \
    Path Traversal Search Flow Matching Partitioning Clustering Embedding \
    Transformation Query Analysis Algorithms

# Geometry
create_tree Geometry \
    IR Point Vector Line Ray Segment Plane Curve Surface Solid Mesh Polygon \
    Polyhedron Primitive Transform Rotation Translation Scale Projection \
    Intersection Distance Proximity Containment Collision Tessellation \
    Triangulation Voronoi Delaunay Computational Parametric Implicit \
    SignedDistance CoordinateSystems

# Topology
create_tree Topology \
    IR PointSet Cell Complex Simplicial Cubical Cellular Manifold Boundary \
    Connectivity Adjacency Neighbourhood Homology Cohomology \
    EulerCharacteristic Genus Orientation Continuity Deformation \
    Transformation Preservation

# Spatial
create_tree Spatial \
    IR Coordinates ReferenceFrames CoordinateSystems Transformations \
    Position Orientation Distance Direction Neighbourhood Region Volume \
    Surface SpatialIndex Grid H3 Voxel Octree BVH KDTree RTree Locality \
    Proximity Navigation Pathfinding Geofencing

# Morphology
create_tree Morphology \
    IR Shape Form Structure Volume Surface Skeleton Boundary Feature \
    Primitive Composition Decomposition Transformation Deformation Growth \
    Fracture Erosion Aggregation Generation Reconstruction Representation \
    Mesh Voxel Implicit Particle Parametric Procedural Morphism \
    Correspondence Similarity

# Physics
create_tree Physics \
    IR Quantity Units Dimensions Constants Body Particle RigidBody SoftBody \
    Fluid Field Material Mass Energy Momentum Force Torque Gravity Friction \
    Pressure Temperature Entropy Charge Electromagnetic Thermodynamic \
    Kinematics Mechanics Constraints Collision Contact Actuation Sensors \
    Laws Equations Conservation Solvers Integrators

# Dynamics
create_tree Dynamics \
    IR State StateSpace PhaseSpace StateTransition DynamicsSystem \
    DynamicalSystem Continuous Discrete Hybrid Linear Nonlinear \
    Deterministic Stochastic Differential OrdinaryDifferential \
    PartialDifferential Difference Evolution Integration Time Timescale \
    Equilibrium Stability Attractor Oscillation Resonance Bifurcation Chaos \
    Coupling Feedback Synchronization Operators Solvers Integrators

# Simulation
create_tree Simulation \
    IR Model System Entity State Environment Scenario World Time Clock \
    Event Process Interaction Coupling Scheduling Execution Integration \
    Synchronization Checkpoint Snapshot Reproduction Determinism \
    Stochasticity Sampling Experiment Ensemble ParameterSweep Sensitivity \
    Calibration Validation Verification Observation Telemetry Replay \
    Distributed Parallel RealTime

# Neural
create_tree Neural \
    IR Tensor Parameter Variable Layer Model Network Sequential Graph \
    Convolution Pooling Normalization Activation Attention Transformer \
    Embedding Recurrent LSTM GRU Memory State Autoencoder Diffusion \
    Generative Probabilistic Differentiable Gradient Loss Inference Training \
    Quantization Pruning Compilation Optimization Distributed

# Learning
create_tree Learning \
    IR Dataset Sample Feature Label Representation Embedding Objective Loss \
    Gradient Optimizer LearningRate ParameterUpdate Supervised Unsupervised \
    SemiSupervised Reinforcement SelfSupervised Online Continual Transfer \
    MetaLearning ActiveLearning Evolutionary Bayesian Probabilistic \
    Adaptation Evaluation Validation Generalization

# Optimization
create_tree Optimization \
    IR Objective Variable Parameter Constraint Bound Feasible Linear \
    Nonlinear Convex NonConvex Discrete Continuous MixedInteger Gradient \
    GradientFree Stochastic Evolutionary Bayesian Search Scheduling \
    Allocation Resource MultiObjective Pareto Solver Strategy

# Agent
create_tree Agent \
    IR Identity State Belief Knowledge Goal Objective Intention Action \
    Behaviour Policy Capability Perception Cognition Decision Planning \
    Learning Memory Communication Interaction Coordination Cooperation \
    Competition Negotiation Adaptation Agency Autonomy MultiAgent Population

# Control
create_tree Control \
    IR System State Input Output Sensor Actuator Controller Policy Feedback \
    Feedforward ClosedLoop OpenLoop Stability Regulation Tracking Planning \
    Trajectory ModelPredictive Optimal Robust Adaptive Distributed Hybrid \
    EventDriven Signal ControlLaw

# Perception
create_tree Perception \
    IR Sensor Observation Measurement Signal Feature Descriptor Detection \
    Recognition Classification Segmentation Tracking Estimation \
    Reconstruction Fusion Spatial Temporal Multimodal Vision Audio \
    Proprioception Environment Scene Interpretation Attention

# Render
create_tree Render \
    IR Scene SceneGraph Object Geometry Material Texture Camera View \
    Projection Lighting Light Shadow Visibility Occlusion Animation Transform \
    Particle Volume Voxel Mesh Raster Vector RayTracing PathTracing Compute \
    GPU Frame RenderTarget RenderPass Pipeline Resource Stream Output

# Stream
create_tree Stream \
    IR Source Sink Channel Message Event Signal Flow Pipeline Operator \
    Transform Map Filter Reduce Join Merge Split Window Buffer Queue \
    Backpressure Scheduling Temporal Stateful Stateless Batch MicroBatch \
    Streaming Distributed Serialization Transport

# Cross-domain interfaces
create_tree Interfaces \
    Composable Transformable Spatial Temporal Stateful Stateless Dynamical \
    Differentiable Integrable Parallelizable Vectorizable Tileable Reducible \
    Streamable Renderable Distributable Deterministic Stochastic Serializable \
    Persistable Observable Controllable Optimizable Learnable Morphological

# Cross-domain transforms
create_tree Transforms \
    Canonicalization Composition Decomposition Fusion Tiling Vectorization \
    Parallelization Distribution Differentiation Specialization Lowering \
    Representation Scheduling Memory Hardware

# Analysis
create_tree Analysis \
    Semantics Dependency Dataflow ControlFlow Topology Geometry Locality \
    Parallelism Differentiability Determinism Complexity Cost Memory Resource \
    Scheduling Representation Equivalence Capability Compatibility

# Lowering
create_tree Lowering \
    Standard Arith Math SCF CF Tensor MemRef Linalg Vector GPU SPIRV LLVM \
    Async Bufferization Runtime External Native

# Providers
create_tree Providers \
    CPU GPU Accelerator Physics Numerical Geometry Spatial Rendering \
    Neural Storage Messaging Distributed External

echo
echo "=============================================="
echo "Semantic Computational Runtime"
echo "Library structure created successfully."
echo "=============================================="
echo
echo "Root: $LIB"
echo "Directories: $(find "$LIB" -type d | wc -l)"
echo

find "$LIB" -type d | sort
