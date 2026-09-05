**`scr.step` Lowering Logic (v0.0.1 Golden Path)**

### Semantic Meaning (must be preserved)

```mlir
%state2 = scr.step %state, %dt
    : !scr.simulation_state, f32 -> !scr.simulation_state
```

Means:

> Advance the *authoritative* simulation state by the time increment `dt` according to the dynamics contract.

For v0.0.1 the dynamics contract is simple Euler integration:

```
velocity remains unchanged   (or optional: velocity' = velocity + acceleration * dt)
position' = position + velocity * dt
simulation_time' = simulation_time + dt
```

The output must still be a valid `!scr.simulation_state`. The renderer must never become the source of truth.

### Recommended Progressive Lowering

```
scr.step
    ↓  (SCR conversion patterns)
arith + scf + (memref or tensor)   ← mid-level structured form
    ↓
llvm dialect
    ↓
CPU native code
```

Do **not** lower `scr.step` directly into a hand-written C++/Rust loop or into the renderer.

### Concrete Lowering Strategy

#### Phase 1 – Expand into explicit particle update (SCR → mid-level)

Conceptual expansion of one `scr.step`:

```mlir
// Pseudocode of the intended expansion
%old_time     = scr.get_time %state
%particles    = scr.get_particles %state

%new_time = arith.addf %old_time, %dt : f32

%new_particles = scf.for %i = ... iter_args(%p_list = ...) -> ... {
  %p     = ... extract particle i ...
  %pos   = ... extract position from %p ...
  %vel   = ... extract velocity from %p ...

  // Core Euler step
  %delta = arith.mulf %vel, %dt : vector<3xf32>   // or tensor
  %new_pos = arith.addf %pos, %delta : vector<3xf32>

  %new_p = scr.create_particle %new_pos, %vel
      : vector<3xf32>, vector<3xf32> -> !scr.particle

  // yield updated list
  ...
}

%state2 = scr.create_state %new_time, %new_particles
    : f32, ... -> !scr.simulation_state
```

Key points:

- The loop is expressed with `scf.for` (or `scf.forall` later).
- Arithmetic uses the `arith` dialect.
- Particle reconstruction still goes through `scr.create_particle` so that semantic identity is maintained until a later stage if desired.
- The final result is still typed as `!scr.simulation_state`.

#### Phase 2 – Eliminate remaining SCR ops

After the expansion above, a second conversion can lower:

- `scr.create_particle` → simple struct / pair of vectors (or a memref of structs)
- `scr.create_state` / `scr.get_*` → ordinary data structure manipulation
- Eventually everything becomes `memref`/`tensor` + `arith` + `scf` + `func`

#### Phase 3 – Standard MLIR path to CPU

```
arith / scf / memref / func
    ↓
llvm dialect
    ↓
LLVM IR → object code / JIT / AOT
```

### Implementation Notes for the Conversion Pattern

In a `DialectConversion` / `RewritePattern`:

1. Match `scr.step`.
2. Extract `dt` and the incoming state.
3. Emit:
   - `scr.get_time` + `arith.addf` for the new time
   - `scr.get_particles`
   - An `scf.for` (or equivalent) that updates every particle
   - The Euler arithmetic (`arith.mulf` + `arith.addf`)
   - `scr.create_particle` for each updated particle
   - `scr.create_state` to rebuild the result state
4. Replace the original `scr.step` with the new `!scr.simulation_state` value.

Mark the pattern as a legalization / conversion pattern that converts *from* the SCR dialect *to* a mix of SCR + upstream dialects, then run a subsequent full conversion that eliminates the remaining SCR ops.

### Invariants the Lowering Must Preserve

- Input state is not mutated in place if the dialect treats states as SSA values (prefer functional style for v0.0.1).
- `dt` must be treated as a pure time increment (no hidden frame-time coupling inside the op).
- Simulation time and wall-clock / render time remain distinct.
- The output of the lowered form must still be usable by `scr.get_particles` / `scr.get_time` until those ops themselves are lowered.

### Minimal Euler Rule (canonical for v0.0.1)

```text
for each particle p in state:
    p.position = p.position + p.velocity * dt

state.time = state.time + dt
```

Acceleration support can be added later as an optional second term; it is not required for the Golden Path success criterion.

This lowering keeps the semantic operation intact at the SCR level while giving a clear, progressive path to ordinary CPU execution.
