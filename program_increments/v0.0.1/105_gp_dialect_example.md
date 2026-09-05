//===----------------------------------------------------------------------===//
// SCR Dialect - Minimal v0.0.1 Golden Path
// File: SCRDialect.td
//
// Deliberately small dialect for the Semantic Computational Runtime.
// Only the concepts that existing MLIR dialects cannot express cleanly.
// Everything else (arith, control flow, memory) stays in upstream dialects.
//===----------------------------------------------------------------------===//

#ifndef SCR_DIALECT_TD
#define SCR_DIALECT_TD

include "mlir/IR/OpBase.td"
include "mlir/IR/AttrTypeBase.td"
include "mlir/Interfaces/SideEffectInterfaces.td"
include "mlir/IR/CommonTypeConstraints.td"

//===----------------------------------------------------------------------===//
// Dialect Definition
//===----------------------------------------------------------------------===//

def SCR_Dialect : Dialect {
  let name = "scr";
  let cppNamespace = "::mlir::scr";

  let summary = "Minimal Semantic Computational Runtime dialect (v0.0.1 Golden Path)";

  let description = [{
    The SCR dialect carries only the semantic concepts required by the
    v0.0.1 Golden Path particle simulation.

    Design rules:
      - IR represents meaning; it does not define meaning.
      - Prefer existing MLIR dialects (arith, scf, func, memref, tensor, llvm)
        for everything that does not need SCR semantics.
      - Every operation must answer:
          1. What semantic concept does it represent?
          2. Why can an existing MLIR op not represent it?
          3. What is its intended lowering path?

    Non-goals for v0.0.1:
      - Full hypergraph, morphology, fields, provenance, streams
      - GPU / distributed execution
      - Advanced physics or collision
      - Persistence or adaptive scheduling
  }];

  let useDefaultAttributePrinterParser = 1;
  let useDefaultTypePrinterParser = 1;
}

//===----------------------------------------------------------------------===//
// Types
//===----------------------------------------------------------------------===//

class SCR_Type<string name, string typeMnemonic, list<Trait> traits = []>
    : TypeDef<SCR_Dialect, name, traits> {
  let mnemonic = typeMnemonic;
}

def SCR_ParticleType : SCR_Type<"Particle", "particle"> {
  let summary = "Semantic particle (position + velocity)";
  let description = [{
    Represents a semantic particle entity.
    Position and velocity are carried as ordinary vector/tensor values
    from upstream dialects; this type exists to preserve the semantic
    identity of a particle across operations.
  }];
}

def SCR_SimulationStateType : SCR_Type<"SimulationState", "simulation_state"> {
  let summary = "Authoritative simulation state";
  let description = [{
    Represents the authoritative state of a simulation at a given
    simulation time. Contains simulation time and a collection of particles.
    Renderer state is a projection of this, never the source of truth.
  }];
}

//===----------------------------------------------------------------------===//
// Base Op Class
//===----------------------------------------------------------------------===//

class SCR_Op<string mnemonic, list<Trait> traits = []> :
    Op<SCR_Dialect, mnemonic, traits>;

//===----------------------------------------------------------------------===//
// Operations
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// scr.create_particle
//===----------------------------------------------------------------------===//

def SCR_CreateParticleOp : SCR_Op<"create_particle", [Pure]> {
  let summary = "Create a semantic particle from position and velocity";
  let description = [{
    Creates a !scr.particle from position and velocity values.
    The values themselves remain ordinary vectors; the result carries
    semantic particle identity.
  }];

  let arguments = (ins
    AnyVector:$position,
    AnyVector:$velocity
  );

  let results = (outs SCR_ParticleType:$result);

  let assemblyFormat = [{
    $position `,` $velocity attr-dict `:` type($position) `,` type($velocity)
  }];
}

//===----------------------------------------------------------------------===//
// scr.create_state
//===----------------------------------------------------------------------===//

def SCR_CreateStateOp : SCR_Op<"create_state", [Pure]> {
  let summary = "Create a simulation state from time and particles";
  let description = [{
    Builds an authoritative !scr.simulation_state from a simulation time
    and a collection of particles.
  }];

  let arguments = (ins
    F32:$time,
    Variadic<SCR_ParticleType>:$particles
  );

  let results = (outs SCR_SimulationStateType:$result);

  let assemblyFormat = [{
    $time `,` $particles attr-dict `:` type($time) `,` type($particles)
  }];
}

//===----------------------------------------------------------------------===//
// scr.step  (the central semantic operation)
//===----------------------------------------------------------------------===//

def SCR_StepOp : SCR_Op<"step"> {
  let summary = "Advance simulation state by dt";
  let description = [{
    The core semantic state-transition operation of the Golden Path.

      %state2 = scr.step %state, %dt
          : !scr.simulation_state, f32 -> !scr.simulation_state

    Meaning:
      Advance the authoritative simulation state by the given time
      increment according to the dynamics contract (simple Euler
      integration for v0.0.1).

    This operation must not be lowered directly into a renderer-specific
    or ad-hoc CPU implementation. It must go through a defined progressive
    lowering path (SCR → arith/scf/memref → llvm → CPU).
  }];

  let arguments = (ins
    SCR_SimulationStateType:$state,
    F32:$dt
  );

  let results = (outs SCR_SimulationStateType:$result);

  let assemblyFormat = [{
    $state `,` $dt attr-dict `:` type($state) `,` type($dt)
  }];

  // TODO: add verifier that dt > 0
}

//===----------------------------------------------------------------------===//
// scr.get_time
//===----------------------------------------------------------------------===//

def SCR_GetTimeOp : SCR_Op<"get_time", [Pure]> {
  let summary = "Extract simulation time from state";
  let description = [{
    Observer operation. Returns the simulation time contained in the
    authoritative simulation state. Does not modify state.
  }];

  let arguments = (ins SCR_SimulationStateType:$state);
  let results = (outs F32:$time);

  let assemblyFormat = [{
    $state attr-dict `:` type($state)
  }];
}

//===----------------------------------------------------------------------===//
// scr.get_particles
//===----------------------------------------------------------------------===//

def SCR_GetParticlesOp : SCR_Op<"get_particles", [Pure]> {
  let summary = "Extract particles from simulation state";
  let description = [{
    Observer operation. Returns the particles contained in the
    authoritative simulation state. Used by the render-projection layer.
    Does not modify state.
  }];

  let arguments = (ins SCR_SimulationStateType:$state);
  let results = (outs Variadic<SCR_ParticleType>:$particles);

  let assemblyFormat = [{
    $state attr-dict `:` type($state) `->` type($particles)
  }];
}

//===----------------------------------------------------------------------===//
// Optional: scr.project_to_render  (add only after simulation trunk works)
//===----------------------------------------------------------------------===//

// def SCR_ProjectToRenderOp : SCR_Op<"project_to_render", [Pure]> {
//   let summary = "Project simulation state into render state";
//   let description = [{
//     Converts authoritative simulation state into a form suitable for
//     the rendering layer. The renderer must never become the source of
//     truth for simulation state.
//   }];
//   let arguments = (ins SCR_SimulationStateType:$state);
//   let results = (outs AnyType:$render_state);  // keep concrete type minimal
// }

#endif // SCR_DIALECT_TD
