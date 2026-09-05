# Getting Started

## Semantic Computational Runtime

This guide sets up a complete development environment for the **Semantic Computational Runtime (SCR)**.

SCR is an **MLIR extension ecosystem for computational semantics**. The development environment therefore starts with LLVM/MLIR itself and progressively adds the Rust, Python, compiler, testing, and optional provider infrastructure required by the project.

The objective of this guide is not merely to install dependencies.

By the end, you should be able to:

* build LLVM/MLIR
* execute MLIR tools
* run the MLIR test suite
* create and verify an SCR dialect
* compile an SCR project written in C++
* interact with MLIR from Rust
* interact with MLIR from Python
* parse and manipulate semantic MLIR
* run SCR-specific lit/FileCheck tests
* lower semantic operations through MLIR
* eventually attach external computational providers
* validate CPU/GPU compilation independently of the semantic layer

---

# 1. Development Philosophy

SCR is built **on top of MLIR**.

There should therefore be no independent SCR compiler infrastructure duplicating MLIR functionality.

The architecture is:

```text
                     SCR
                      │
        ┌─────────────┴─────────────┐
        │                           │
 Semantic Dialects            Semantic Runtime
        │                           │
        └─────────────┬─────────────┘
                      │
                     MLIR
                      │
          ┌───────────┼───────────┐
          │           │           │
        LLVM         GPU        SPIR-V
          │           │           │
          └───────────┼───────────┘
                      │
                  Hardware
```

MLIR provides:

* IR
* SSA
* types
* attributes
* operations
* regions
* dialects
* interfaces
* verification
* rewriting
* transformations
* dialect conversion
* serialization
* compiler infrastructure
* target-specific lowering

SCR provides the semantic layer.

---

# 2. Recommended Development Platform

The reference development environment should initially be:

```text
Linux
x86_64
Ubuntu LTS
Git
Clang
LLD
CMake
Ninja
Python 3
Rust
LLVM/MLIR
```

Other platforms should eventually be supported, but Linux should be treated as the primary development and CI environment initially.

MLIR's own getting-started documentation assumes a working C++ toolchain, Git, Ninja, and CMake.

---

# 3. Hardware

A reasonable development workstation:

```text
CPU:       8+ cores
RAM:       32 GB recommended
Storage:   100+ GB free SSD space
GPU:       optional initially
```

A GPU is **not required** to begin developing SCR.

However, GPU support becomes important once the compiler/runtime work reaches:

```text
vectorization
GPU dialects
SPIR-V
CUDA/ROCm
GPU scheduling
heterogeneous execution
```

LLVM itself can consume substantial storage during development, particularly with debug builds. An SSD and substantial RAM are recommended.

---

# 4. System Packages

On Ubuntu:

```bash
sudo apt update

sudo apt install -y \
    git \
    curl \
    wget \
    build-essential \
    clang \
    lld \
    cmake \
    ninja-build \
    python3 \
    python3-dev \
    python3-venv \
    python3-pip \
    pkg-config \
    ccache \
    zlib1g-dev \
    libxml2-dev \
    libedit-dev \
    libncurses-dev
```

Verify:

```bash
git --version
clang --version
clang++ --version
ld.lld --version
cmake --version
ninja --version
python3 --version
```

CMake 3.20 is the minimum documented by LLVM; using a current CMake supplied by a current Ubuntu release is preferable.

---

# 5. Rust

Rust will be the primary systems-language environment for the SCR runtime and much of the surrounding infrastructure.

Install Rust using `rustup`:

```bash
curl --proto '=https' --tlsv1.2 -sSf \
    https://sh.rustup.rs | sh
```

Restart the shell or load the environment:

```bash
source "$HOME/.cargo/env"
```

Verify:

```bash
rustc --version
cargo --version
rustup --version
```

Install useful development components:

```bash
rustup component add rustfmt
rustup component add clippy
```

Verify:

```bash
cargo fmt --version
cargo clippy --version
```

---

# 6. Python

Python serves two purposes:

1. MLIR's Python bindings and tooling
2. SCR's high-level Python API

Create a dedicated environment:

```bash
python3 -m venv .venv
source .venv/bin/activate
```

Upgrade packaging tools:

```bash
python -m pip install --upgrade pip setuptools wheel
```

Useful development packages:

```bash
pip install \
    pytest \
    pytest-cov \
    numpy \
    networkx
```

MLIR provides official Python bindings. Its documentation recommends using a virtual environment and installing the dependencies listed in MLIR's Python requirements.

---

# 7. Obtain LLVM/MLIR

SCR should initially track a **specific LLVM release**, rather than blindly tracking LLVM `main`.

This is important because the MLIR C API and downstream Rust bindings are version-sensitive.

Clone LLVM:

```bash
git clone https://github.com/llvm/llvm-project.git
cd llvm-project
```

For a reproducible development environment, check out the LLVM version selected by the SCR project.

For example:

```bash
git checkout <SCR_LLVM_VERSION>
```

The exact version should be pinned in the SCR repository.

---

# 8. Build LLVM/MLIR

Create a separate build directory:

```bash
mkdir build
cd build
```

Configure:

```bash
cmake -G Ninja ../llvm \
    -DLLVM_ENABLE_PROJECTS="mlir;clang;lld" \
    -DLLVM_TARGETS_TO_BUILD="Native;NVPTX;AMDGPU" \
    -DLLVM_BUILD_EXAMPLES=ON \
    -DMLIR_INCLUDE_INTEGRATION_TESTS=ON \
    -DLLVM_ENABLE_ASSERTIONS=ON \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DCMAKE_C_COMPILER=clang \
    -DCMAKE_CXX_COMPILER=clang++ \
    -DLLVM_ENABLE_LLD=ON \
    -DLLVM_CCACHE_BUILD=ON
```

The LLVM/MLIR project documents Ninja as the common development generator and recommends Clang/LLD for MLIR development.

Build:

```bash
cmake --build . --parallel
```

This is a large build.

Do not be concerned if this takes significant time on the first build.

---

# 9. Establish an LLVM/MLIR Installation Prefix

For SCR development it is useful to have a stable installation tree.

From the LLVM build directory:

```bash
cmake -G Ninja ../llvm \
    -DCMAKE_INSTALL_PREFIX="$HOME/opt/llvm-scr" \
    ...
```

Then:

```bash
cmake --build . --target install
```

Set:

```bash
export LLVM_ROOT="$HOME/opt/llvm-scr"
export PATH="$LLVM_ROOT/bin:$PATH"
export LD_LIBRARY_PATH="$LLVM_ROOT/lib:${LD_LIBRARY_PATH:-}"
```

Add these to your shell configuration once the environment is stable.

---

# 10. Verify MLIR Tools

The most important first test is:

```bash
mlir-opt --version
```

You should see an MLIR/LLVM version.

Then:

```bash
mlir-opt --help
```

Test MLIR with a minimal module:

```bash
cat > hello.mlir <<'EOF'
module {
  func.func @main() {
    return
  }
}
EOF
```

Run:

```bash
mlir-opt hello.mlir
```

Expected result:

```text
module {
  func.func @main() {
    return
  }
}
```

Now verify the IR:

```bash
mlir-opt hello.mlir --verify-diagnostics
```

If this succeeds, the basic MLIR environment is functional.

---

# 11. Test MLIR Optimization

Create:

```bash
cat > arithmetic.mlir <<'EOF'
module {
  func.func @add(%a: i32, %b: i32) -> i32 {
    %result = arith.addi %a, %b : i32
    return %result : i32
  }
}
EOF
```

Run:

```bash
mlir-opt arithmetic.mlir
```

Then:

```bash
mlir-opt arithmetic.mlir \
    --canonicalize
```

Verify that MLIR can parse, verify, and transform ordinary IR.

---

# 12. Run the MLIR Test Suite

From the LLVM build directory:

```bash
cmake --build . --target check-mlir
```

MLIR officially uses `lit` and `FileCheck` extensively for compiler and dialect testing.

A successful:

```text
check-mlir
```

is the first major environment milestone.

Run integration tests:

```bash
cmake --build . --target check-mlir-integration
```

The integration target requires:

```text
-DMLIR_INCLUDE_INTEGRATION_TESTS=ON
```

as configured above.

---

# 13. Test `lit` and `FileCheck`

Locate:

```bash
build/bin/llvm-lit
```

Verify:

```bash
build/bin/llvm-lit --version
```

Test a subset:

```bash
build/bin/llvm-lit -v \
    ../mlir/test/Dialect/Arith
```

`lit` orchestrates MLIR tests while `FileCheck` validates expected IR and diagnostics.

SCR should use this same mechanism.

---

# 14. Test LLVM Lowering

Create:

```bash
cat > lower.mlir <<'EOF'
module {
  func.func @add(%a: i32, %b: i32) -> i32 {
    %result = arith.addi %a, %b : i32
    return %result : i32
  }
}
EOF
```

Try:

```bash
mlir-opt lower.mlir \
    --convert-arith-to-llvm \
    --convert-func-to-llvm
```

The resulting IR should contain LLVM dialect operations.

This confirms that the basic:

```text
MLIR
  ↓
LLVM dialect
```

pipeline is functioning.

---

# 15. Test LLVM Code Generation

The exact lowering pipeline will evolve, but a basic environment test should eventually demonstrate:

```text
MLIR
  ↓
LLVM dialect
  ↓
LLVM IR
  ↓
native executable
```

The important environment property is that LLVM's native target is available:

```bash
llc --version
```

Verify that the host target is listed.

Also:

```bash
clang --version
```

---

# 16. Test GPU Targets

Even if no GPU is installed, configure the build with:

```text
Native
NVPTX
AMDGPU
```

This ensures that MLIR/LLVM can represent and lower toward major GPU target families.

Verify:

```bash
llc --version
```

Look for:

```text
NVPTX
AMDGPU
```

Actual GPU execution should be treated as a separate test.

---

# 17. MLIR Python Bindings

Enable Python bindings in the LLVM/MLIR configuration:

```text
-DMLIR_ENABLE_BINDINGS_PYTHON=ON
```

Reconfigure and build:

```bash
cmake --build . --parallel
```

MLIR's Python packages will be produced in the build tree.

For an uninstalled build, the package directory is typically:

```text
build/tools/mlir/python_packages/mlir_core
```

Set:

```bash
export PYTHONPATH="$LLVM_BUILD/tools/mlir/python_packages/mlir_core:$PYTHONPATH"
```

MLIR documents this mechanism for interactive use of the Python bindings.

Test:

```bash
python -c "import mlir; print(mlir)"
```

Then:

```bash
python -c "from mlir import ir; print(ir.Context)"
```

Run the official Python binding tests:

```bash
cmake --build . --target check-mlir-python
```

---

# 18. First Python MLIR Program

Create:

```bash
cat > test_mlir.py <<'EOF'
from mlir import ir

with ir.Context() as ctx:
    module = ir.Module.create()

    print(module)
EOF
```

Run:

```bash
python test_mlir.py
```

Expected:

```text
module {
}
```

This verifies:

```text
Python
  ↓
MLIR Python bindings
  ↓
MLIR Context
  ↓
MLIR IR
```

---

# 19. Rust MLIR Integration

SCR's runtime should be implemented primarily in Rust while using MLIR as its compiler/IR substrate.

A practical starting point is the Rust MLIR ecosystem around:

* `mlir-sys`
* `melior`

`mlir-sys` provides Rust bindings to the MLIR C API, while Melior provides higher-level Rust bindings over that API.

Create a test project:

```bash
cargo new scr-mlir-test
cd scr-mlir-test
```

Add Melior:

```bash
cargo add melior
```

The important constraint is **version compatibility**.

SCR should pin:

```text
LLVM version
MLIR version
mlir-sys version
Melior version
```

as one compatibility set.

Do not allow Cargo to independently select an arbitrary MLIR version.

---

# 20. Rust MLIR Smoke Test

Create a minimal Rust program that:

1. creates an MLIR context
2. registers dialects
3. creates a module
4. verifies the module
5. prints the module

Conceptually:

```text
Rust
  ↓
Melior
  ↓
MLIR C API
  ↓
MLIR Context
  ↓
MLIR Module
```

The exact API should be kept behind an SCR-owned abstraction rather than allowing Melior types to leak throughout the entire runtime.

This is important for future MLIR upgrades.

---

# 21. SCR's Rust Architecture

The Rust project should eventually look approximately like:

```text
scr/
│
├── crates/
│   ├── scr-core/
│   ├── scr-ir/
│   ├── scr-dialect/
│   ├── scr-compiler/
│   ├── scr-runtime/
│   ├── scr-provider/
│   ├── scr-scheduler/
│   ├── scr-memory/
│   ├── scr-telemetry/
│   └── scr-cli/
│
├── dialects/
│   ├── semantic-core/
│   ├── semantic-field/
│   ├── semantic-physics/
│   ├── semantic-dynamics/
│   ├── semantic-geometry/
│   └── ...
│
├── test/
│   ├── lit/
│   ├── integration/
│   ├── unit/
│   └── fixtures/
│
└── examples/
```

The exact structure is not yet normative.

---

# 22. First SCR Dialect

The first meaningful SCR milestone is not a physics engine.

It is a tiny semantic dialect.

For example:

```text
semantic.constant
semantic.add
semantic.transform
```

A minimal semantic program might eventually look like:

```mlir
module {
  %a = semantic.constant 10 : i64
  %b = semantic.constant 20 : i64
  %c = semantic.add %a, %b : i64
}
```

The first dialect should demonstrate:

* custom operations
* custom types where appropriate
* verification
* textual parsing
* textual printing
* interfaces
* canonicalization
* lowering

---

# 23. First Semantic Interface

Introduce a capability interface such as:

```text
semantic.Composable
```

Then later:

```text
semantic.Dynamical
semantic.Spatial
semantic.Differentiable
semantic.Parallelizable
semantic.Vectorizable
semantic.Streamable
semantic.Renderable
```

The first test should establish that a generic compiler component can inspect an operation through an interface without knowing its concrete dialect.

This is one of the most important architectural tests in SCR.

---

# 24. First Provider

After the semantic core works, implement one trivial provider.

For example:

```text
semantic.add
     ↓
arith.addi
```

This gives:

```text
Semantic operation
        ↓
Provider-independent semantic representation
        ↓
MLIR lowering
        ↓
standard MLIR dialect
```

Only after this works should complex external libraries be introduced.

---

# 25. First External Provider

A useful first external provider should be relatively simple.

Candidates include:

```text
Eigen
H3
OpenVDB
CGAL
Chrono
VSG
```

Physics through Chrono is likely to be one of the more demanding integration tests.

The provider architecture should look like:

```text
semantic.physics.*
        │
        ▼
provider interface
        │
        ├── Chrono
        ├── native implementation
        └── generated implementation
```

The semantic dialect must never require Chrono.

---

# 26. Testing Architecture

SCR should use several levels of testing.

## Level 0 — Environment

```text
clang
cmake
ninja
rustc
cargo
python
mlir-opt
mlir-translate
llc
```

All available.

---

## Level 1 — MLIR

```text
check-mlir
check-mlir-python
check-mlir-integration
```

All passing.

---

## Level 2 — Semantic IR

Test:

```text
parse
print
verify
serialize
deserialize
```

---

## Level 3 — Dialects

Every operation should have:

```text
valid IR test
invalid IR test
diagnostic test
canonicalization test
```

---

## Level 4 — Interfaces

Test generic algorithms against interface capabilities.

Example:

```text
Dynamical
Parallelizable
Vectorizable
```

rather than concrete operation names.

---

## Level 5 — Lowering

Test:

```text
semantic
   ↓
domain dialect
   ↓
standard MLIR
```

and eventually:

```text
semantic
   ↓
LLVM
   ↓
native code
```

---

## Level 6 — Provider

Test:

```text
semantic operation
   ↓
provider selection
   ↓
provider implementation
   ↓
result
```

---

## Level 7 — Runtime

Test:

```text
compiled artifact
   ↓
runtime
   ↓
resource discovery
   ↓
execution
   ↓
result
```

---

## Level 8 — Hardware

Test actual execution on:

```text
CPU
GPU
accelerator
distributed environment
```

where available.

---

# 27. Lit/FileCheck Test Example

A semantic dialect test should eventually look similar to:

```mlir
// RUN: scr-opt %s | FileCheck %s

module {
  %x = semantic.constant 10 : i64
  %y = semantic.constant 20 : i64
  %z = semantic.add %x, %y : i64
}

// CHECK: semantic.constant 10
// CHECK: semantic.constant 20
// CHECK: semantic.add
```

This allows semantic IR to be tested without executing a complete runtime.

---

# 28. Negative Tests

Invalid programs are just as important.

Example:

```mlir
// RUN: scr-opt %s 2>&1 | FileCheck %s

module {
  %x = semantic.add %a, %b : i64
}

// CHECK: error
```

The test suite should verify:

* type errors
* invalid attributes
* invalid regions
* violated semantic invariants
* unsupported compositions
* illegal provider selections
* invalid lowering requirements

---

# 29. Semantic Contract Testing

Every important semantic operation should eventually have a machine-checkable contract.

For example:

```text
semantic.integrate
```

might specify:

```text
Input:
    state
    derivative
    timestep

Output:
    new state

Properties:
    deterministic
    dynamical
    stateful
```

The compiler should be able to reason about these properties.

---

# 30. Runtime Smoke Test

The first end-to-end SCR test should be extremely small.

Example:

```text
Application
    ↓
SCR API
    ↓
Semantic MLIR
    ↓
Semantic optimization
    ↓
Lowering
    ↓
Native executable
    ↓
Runtime
    ↓
Result
```

A suitable first program is:

```text
10 + 20 = 30
```

The triviality is intentional.

The test proves the architecture rather than the algorithm.

---

# 31. End-to-End Semantic Test

The next milestone should be something like:

```text
field
    ↓
sample
    ↓
transform
    ↓
dynamics
    ↓
state transition
```

The compiler should produce executable code without the application explicitly selecting a particular low-level implementation.

This demonstrates the central SCR proposition.

---

# 32. Provider Discovery

The runtime should eventually expose a capability query similar to:

```text
providers.list()
```

returning concepts such as:

```text
physics.integrate
    provider: chrono
    targets: cpu
    capabilities:
        deterministic
        parallel
```

and:

```text
geometry.boolean
    provider: cgal
    targets: cpu
```

This information should eventually participate in compilation and scheduling.

---

# 33. Hardware Discovery

The runtime should eventually be able to report:

```text
CPU
    cores
    SIMD width
    cache hierarchy

GPU
    architecture
    memory
    compute units

Memory
    capacity
    bandwidth

Interconnect
    topology
    bandwidth
    latency
```

This information feeds the hardware-aware compilation and scheduling system.

---

# 34. Optional GPU SDKs

GPU development should initially remain optional.

Later environments may add:

### NVIDIA

```text
CUDA Toolkit
NVIDIA driver
```

### AMD

```text
ROCm
```

### Vulkan

```text
Vulkan SDK
```

### SPIR-V

MLIR already provides SPIR-V infrastructure.

The SCR core must remain usable without any particular vendor SDK.

---

# 35. Optional Provider SDKs

External providers should be installed only when the corresponding provider is being developed.

Potential development environments include:

```text
Chrono
Eigen
CGAL
H3
OpenVDB
VulkanSceneGraph
```

These should not become mandatory dependencies of the SCR semantic core.

Instead:

```text
SCR Core
   │
   ├── Provider: Chrono
   ├── Provider: Eigen
   ├── Provider: CGAL
   ├── Provider: H3
   └── Provider: VSG
```

---

# 36. C++ Development

Although Rust should be the primary systems language for the SCR runtime, C++ remains important because:

* MLIR itself is C++
* many scientific libraries are C++
* many high-performance providers expose C++ APIs
* provider adapters may need to interact directly with native libraries

Install/use:

```text
clang++
CMake
Ninja
```

The SCR C++ layer should primarily contain:

```text
MLIR dialect definitions
MLIR passes
MLIR interfaces
provider adapters
```

while Rust should increasingly own:

```text
runtime
orchestration
scheduling
resource management
telemetry
language-facing APIs
```

The boundary should remain explicit.

---

# 37. Recommended Build Modes

## Development

```text
RelWithDebInfo
Assertions ON
ccache ON
```

Recommended for normal development.

## Debug

```text
Debug
Assertions ON
```

Use for compiler/runtime debugging.

## Sanitized

Periodically use:

```text
AddressSanitizer
UndefinedBehaviorSanitizer
```

MLIR's documentation specifically recommends sanitizers as a useful mechanism for finding bugs early.

---

# 38. CI Environment

CI should eventually test at least:

```text
Ubuntu
LLVM pinned version
Clang
Rust stable
Python
```

Pipeline:

```text
checkout
   ↓
configure
   ↓
build
   ↓
unit tests
   ↓
lit/FileCheck
   ↓
MLIR tests
   ↓
Python tests
   ↓
Rust tests
   ↓
integration tests
```

GPU CI should be separate initially because hardware availability varies.

---

# 39. Environment Validation Script

SCR should provide:

```bash
./scripts/check-environment.sh
```

The script should check:

```text
✓ git
✓ clang
✓ clang++
✓ lld
✓ cmake
✓ ninja
✓ python
✓ rustc
✓ cargo
✓ mlir-opt
✓ mlir-translate
✓ llc
✓ FileCheck
✓ llvm-lit
```

It should report:

```text
SCR Development Environment

[PASS] Git
[PASS] Clang
[PASS] CMake
[PASS] Ninja
[PASS] Python
[PASS] Rust
[PASS] MLIR
[PASS] LLVM
[PASS] FileCheck
[PASS] lit

Environment READY
```

---

# 40. Recommended Initial Acceptance Test

The environment should not be considered ready until all of the following succeed:

### Compiler infrastructure

```bash
clang --version
cmake --version
ninja --version
```

### Rust

```bash
rustc --version
cargo --version
cargo test
```

### Python

```bash
python --version
python -c "import mlir"
```

### MLIR

```bash
mlir-opt --version
mlir-opt hello.mlir
```

### MLIR verification

```bash
cmake --build build --target check-mlir
```

### Python MLIR

```bash
cmake --build build --target check-mlir-python
```

### LLVM

```bash
llc --version
clang --version
```

### SCR

```bash
cargo test
cmake --build build --target check-scr
```

The final two commands become available once the SCR repository itself has been bootstrapped.

---

# 41. Development Milestones

The recommended development sequence is:

```text
Phase 0
───────
Development environment

Phase 1
───────
MLIR integration

Phase 2
───────
semantic.core dialect

Phase 3
───────
semantic interfaces

Phase 4
───────
semantic.math / semantic.data

Phase 5
───────
first lowering

Phase 6
───────
Rust runtime

Phase 7
───────
Python API

Phase 8
───────
provider architecture

Phase 9
───────
first external provider

Phase 10
────────
hardware-aware compilation

Phase 11
────────
CPU/GPU execution

Phase 12
────────
cross-domain semantic composition

Phase 13
────────
reference simulation

Phase 14
────────
adaptive heterogeneous execution
```

---

# 42. What NOT to Install Yet

Do not make the initial SCR development environment depend on:

```text
CUDA
ROCm
Vulkan
Chrono
CGAL
OpenVDB
H3
VSG
Kubernetes
RabbitMQ
distributed storage
```

unless a specific development task requires them.

The core environment should first establish:

```text
LLVM
MLIR
Clang
CMake
Ninja
Rust
Python
```

Everything else should be introduced as an optional provider or runtime capability.

This keeps the semantic core clean and prevents external libraries from becoming accidental architectural dependencies.

---

# 43. First Development Exercise

Once the environment passes validation, the first SCR implementation task should be:

> Create a minimal `semantic.core` dialect containing a constant operation and a composable binary operation, verify it, print it, test it with FileCheck, and lower it to `arith`.

The complete path should be:

```text
semantic.constant
       │
       ▼
semantic.add
       │
       ▼
semantic canonicalization
       │
       ▼
arith.constant
       │
       ▼
arith.addi
       │
       ▼
LLVM
       │
       ▼
native code
```

If this works, we have demonstrated the fundamental SCR architecture in miniature.

---

# 44. The First Real Goal

The first major SCR milestone is therefore not:

> "Build a simulator."

It is:

> **Demonstrate that computational semantics can be defined as MLIR-native abstractions, composed independently of implementation libraries, transformed by generic compiler infrastructure, lowered through replaceable providers, and executed on real hardware.**

Once that is proven, the physics, simulation, neural, geometry, morphology, field, graph, rendering, and streaming domains become progressively larger applications of the same architecture.

---

# 45. Environment Definition

The canonical development environment should eventually be reproducible from one command:

```bash
./bootstrap.sh
```

producing:

```text
SCR Development Environment
────────────────────────────

LLVM/MLIR       ✓
Clang           ✓
LLD             ✓
CMake           ✓
Ninja           ✓
Rust            ✓
Python          ✓
MLIR Python     ✓
FileCheck       ✓
lit             ✓

SCR Toolchain   READY
```

A future containerized environment should provide the same result:

```bash
docker build -t scr-dev .
docker run -it scr-dev
```

and a future Nix-based environment may provide:

```bash
nix develop
```

The development environment itself should therefore become reproducible and versioned alongside SCR.

---

# 46. Definition of "Ready"

A machine is considered **SCR Development Ready** when:

```text
                    ┌──────────────────┐
                    │  SCR Environment │
                    └────────┬─────────┘
                             │
              ┌──────────────┼──────────────┐
              │              │              │
             MLIR           Rust          Python
              │              │              │
          dialects       runtime         bindings
              │              │              │
              └──────────────┼──────────────┘
                             │
                         SCR Build
                             │
                         SCR Tests
                             │
                    Semantic IR Test
                             │
                         Lowering
                             │
                       Native Execution
```

All stages must succeed.

At that point the environment is not merely capable of compiling LLVM.

It is capable of developing the **Semantic Computational Runtime itself**.
