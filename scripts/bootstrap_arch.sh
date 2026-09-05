#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

LLVM_VERSION="${SCR_LLVM_VERSION:-22.1.8}"

SCR_ROOT="${SCR_ROOT:-${HOME}/.local/share/scr}"
SCR_LLVM_ROOT="${SCR_LLVM_ROOT:-${HOME}/.local/opt/scr/llvm-${LLVM_VERSION}}"

info() {
    printf '[INFO] %s\n' "$*"
}

ok() {
    printf '[ OK ] %s\n' "$*"
}

warn() {
    printf '[WARN] %s\n' "$*" >&2
}

fail() {
    printf '[ERROR] %s\n' "$*" >&2
    exit 1
}

trap 'printf "[ERROR] Bootstrap failed at line %s: %s\n" "$LINENO" "$BASH_COMMAND" >&2' ERR

# ---------------------------------------------------------------------------
# Platform
# ---------------------------------------------------------------------------

[[ -f /etc/arch-release ]] || fail "This script requires Arch Linux."

if [[ "${EUID}" -eq 0 ]]; then
    SUDO=""
else
    command -v sudo >/dev/null 2>&1 || fail "sudo is required."
    SUDO="sudo"
fi

# ---------------------------------------------------------------------------
# Package management
# ---------------------------------------------------------------------------

info "Synchronizing Arch Linux."

"${SUDO}" pacman -Syu --noconfirm

# ---------------------------------------------------------------------------
# Core development environment
# ---------------------------------------------------------------------------

PACKAGES=(
    base-devel
    git
    cmake
    ninja
    clang
    lld
    llvm
    compiler-rt
    jsoncpp
    pkgconf
    ccache
    python
    python-pip
    rustup
)

info "Installing core development packages."

"${SUDO}" pacman -S --needed --noconfirm "${PACKAGES[@]}"

ok "Core packages installed."

# ---------------------------------------------------------------------------
# Optional development utilities
# ---------------------------------------------------------------------------

OPTIONAL_PACKAGES=(
    gdb
    lldb
    ripgrep
    fd
    jq
    tree
    shellcheck
    shfmt
    eigen
    fmt
    spdlog
)

info "Installing development utilities."

"${SUDO}" pacman -S --needed --noconfirm "${OPTIONAL_PACKAGES[@]}"

ok "Development utilities installed."

# ---------------------------------------------------------------------------
# Rust
# ---------------------------------------------------------------------------

if command -v rustup >/dev/null 2>&1; then
    ok "rustup detected."
else
    fail "rustup installation failed."
fi

info "Installing/selecting stable Rust."

rustup toolchain install stable
rustup default stable

command -v rustc >/dev/null 2>&1 || fail "rustc not available."
command -v cargo >/dev/null 2>&1 || fail "cargo not available."

ok "Rust toolchain ready."

# ---------------------------------------------------------------------------
# Basic toolchain checks
# ---------------------------------------------------------------------------

command -v clang >/dev/null 2>&1 || fail "clang not found."
command -v clang++ >/dev/null 2>&1 || fail "clang++ not found."
command -v ld.lld >/dev/null 2>&1 || fail "ld.lld not found."
command -v llvm-config >/dev/null 2>&1 || fail "llvm-config not found."
command -v cmake >/dev/null 2>&1 || fail "cmake not found."
command -v ninja >/dev/null 2>&1 || fail "ninja not found."
command -v python >/dev/null 2>&1 || fail "python not found."

# Catch broken dynamic dependencies such as the jsoncpp problem you had.
cmake --version >/dev/null 2>&1 ||
    fail "cmake is installed but cannot execute. Check its shared-library dependencies."

ok "CMake: $(cmake --version | head -n1)"
ok "Ninja: $(ninja --version)"
ok "Clang: $(clang --version | head -n1)"
ok "LLVM: $(llvm-config --version)"
ok "Rust: $(rustc --version)"
ok "Python: $(python --version)"

# ---------------------------------------------------------------------------
# MLIR detection
# ---------------------------------------------------------------------------

info "Checking for MLIR."

MLIR_FOUND=0

if command -v mlir-opt >/dev/null 2>&1 &&
   command -v mlir-tblgen >/dev/null 2>&1 &&
   command -v mlir-translate >/dev/null 2>&1; then

    MLIR_FOUND=1
    ok "System MLIR tools detected."
fi

# Search conventional Arch/system locations for MLIR CMake configuration.
SYSTEM_MLIR_CONFIG=""

for candidate in \
    /usr/lib/cmake/mlir/MLIRConfig.cmake \
    /usr/lib/cmake/MLIR/MLIRConfig.cmake \
    /usr/local/lib/cmake/mlir/MLIRConfig.cmake \
    /usr/local/lib/cmake/MLIR/MLIRConfig.cmake
do
    if [[ -f "${candidate}" ]]; then
        SYSTEM_MLIR_CONFIG="${candidate}"
        break
    fi
done

if [[ -n "${SYSTEM_MLIR_CONFIG}" ]]; then
    ok "System MLIR CMake configuration: ${SYSTEM_MLIR_CONFIG}"
fi

# ---------------------------------------------------------------------------
# MLIR installation
# ---------------------------------------------------------------------------

if [[ "${MLIR_FOUND}" -eq 0 ]]; then

    info "System MLIR is not available."

    cat <<EOF

SCR requires a complete MLIR development environment.

Required:

    mlir-opt
    mlir-tblgen
    mlir-translate
    MLIRConfig.cmake
    MLIR headers
    MLIR libraries

The installed Arch LLVM package does not provide these components on
this system.

The bootstrap will therefore build MLIR ${LLVM_VERSION} from the official
LLVM project source.

Installation:

    ${SCR_LLVM_ROOT}

Source/build cache:

    ${SCR_ROOT}/src
    ${SCR_ROOT}/build

EOF

    mkdir -p "${SCR_ROOT}/src"
    mkdir -p "${SCR_ROOT}/build"

    LLVM_SOURCE="${SCR_ROOT}/src/llvm-project-${LLVM_VERSION}"
    LLVM_BUILD="${SCR_ROOT}/build/llvm-${LLVM_VERSION}"

    # -----------------------------------------------------------------------
    # Obtain llvm-project
    # -----------------------------------------------------------------------

    if [[ -d "${LLVM_SOURCE}/.git" ]]; then

        info "LLVM source already exists."

        git -C "${LLVM_SOURCE}" fetch --tags --force

        git -C "${LLVM_SOURCE}" checkout --force \
            "llvmorg-${LLVM_VERSION}"

    else

        info "Cloning LLVM ${LLVM_VERSION}."

        git clone \
            --depth 1 \
            --branch "llvmorg-${LLVM_VERSION}" \
            https://github.com/llvm/llvm-project.git \
            "${LLVM_SOURCE}"

    fi

    ok "LLVM source ready."

    # -----------------------------------------------------------------------
    # Configure
    # -----------------------------------------------------------------------

    info "Configuring LLVM/MLIR."

    cmake \
        -S "${LLVM_SOURCE}/llvm" \
        -B "${LLVM_BUILD}" \
        -G Ninja \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX="${SCR_LLVM_ROOT}" \
        -DCMAKE_C_COMPILER=clang \
        -DCMAKE_CXX_COMPILER=clang++ \
        -DLLVM_ENABLE_PROJECTS=mlir \
        -DLLVM_TARGETS_TO_BUILD=Native \
        -DLLVM_ENABLE_ASSERTIONS=ON \
        -DMLIR_INCLUDE_TESTS=ON \
        -DLLVM_INCLUDE_TESTS=ON

    ok "LLVM/MLIR configured."

    # -----------------------------------------------------------------------
    # Build
    # -----------------------------------------------------------------------

    JOBS="${SCR_BUILD_JOBS:-$(nproc)}"

    info "Building MLIR using ${JOBS} parallel jobs."

    cmake \
        --build "${LLVM_BUILD}" \
        --parallel "${JOBS}"

    ok "MLIR build complete."

    # -----------------------------------------------------------------------
    # Install
    # -----------------------------------------------------------------------

    info "Installing MLIR."

    cmake \
        --build "${LLVM_BUILD}" \
        --target install \
        --parallel "${JOBS}"

    ok "MLIR installed."

fi

# ---------------------------------------------------------------------------
# Verify MLIR
# ---------------------------------------------------------------------------

export PATH="${SCR_LLVM_ROOT}/bin:${PATH}"

if ! command -v mlir-opt >/dev/null 2>&1; then
    fail "mlir-opt is still unavailable after MLIR installation."
fi

if ! command -v mlir-tblgen >/dev/null 2>&1; then
    fail "mlir-tblgen is still unavailable after MLIR installation."
fi

if ! command -v mlir-translate >/dev/null 2>&1; then
    fail "mlir-translate is still unavailable after MLIR installation."
fi

MLIR_DIR=""

for candidate in \
    "${SCR_LLVM_ROOT}/lib/cmake/mlir" \
    "${SCR_LLVM_ROOT}/lib64/cmake/mlir"
do
    if [[ -f "${candidate}/MLIRConfig.cmake" ]]; then
        MLIR_DIR="${candidate}"
        break
    fi
done

[[ -n "${MLIR_DIR}" ]] ||
    fail "MLIRConfig.cmake was not installed."

ok "mlir-opt: $(command -v mlir-opt)"
ok "mlir-tblgen: $(command -v mlir-tblgen)"
ok "mlir-translate: $(command -v mlir-translate)"
ok "MLIR CMake: ${MLIR_DIR}"

# ---------------------------------------------------------------------------
# Generate environment file
# ---------------------------------------------------------------------------

ENV_FILE="${PROJECT_ROOT}/scripts/env-arch.sh"

info "Writing ${ENV_FILE}."

cat > "${ENV_FILE}" <<EOF
#!/usr/bin/env bash

export SCR_ROOT="${PROJECT_ROOT}"

export SCR_LLVM_VERSION="${LLVM_VERSION}"
export SCR_LLVM_ROOT="${SCR_LLVM_ROOT}"

export LLVM_ROOT="\${SCR_LLVM_ROOT}"
export MLIR_ROOT="\${SCR_LLVM_ROOT}"

export MLIR_DIR="\${SCR_LLVM_ROOT}/lib/cmake/mlir"
export LLVM_DIR="\${SCR_LLVM_ROOT}/lib/cmake/llvm"

export PATH="\${SCR_LLVM_ROOT}/bin:\${PATH}"

export CC="\${CC:-clang}"
export CXX="\${CXX:-clang++}"
export LD="\${LD:-ld.lld}"

export CMAKE_GENERATOR="\${CMAKE_GENERATOR:-Ninja}"
EOF

chmod +x "${ENV_FILE}"

ok "Environment file generated."

# ---------------------------------------------------------------------------
# Final MLIR test
# ---------------------------------------------------------------------------

TMPDIR="$(mktemp -d)"

cleanup() {
    rm -rf "${TMPDIR}"
}

trap cleanup EXIT

cat > "${TMPDIR}/test.mlir" <<'EOF'
module {
  func.func @main() {
    return
  }
}
EOF

info "Running MLIR sanity test."

mlir-opt \
    "${TMPDIR}/test.mlir" \
    -o "${TMPDIR}/output.mlir"

grep -q 'module' "${TMPDIR}/output.mlir" ||
    fail "MLIR sanity test produced invalid output."

ok "MLIR sanity test passed."

# ---------------------------------------------------------------------------
# Final report
# ---------------------------------------------------------------------------

printf '\n'
printf '%s\n' "============================================================"
printf '%s\n' " SCR Arch development environment is ready"
printf '%s\n' "============================================================"
printf '\n'

printf 'LLVM/MLIR: %s\n' "${LLVM_VERSION}"
printf 'MLIR root: %s\n' "${SCR_LLVM_ROOT}"
printf 'MLIR CMake: %s\n' "${MLIR_DIR}"
printf 'Rust:       %s\n' "$(rustc --version)"
printf 'Python:     %s\n' "$(python --version)"
printf 'CMake:      %s\n' "$(cmake --version | head -n1)"
printf '\n'

printf 'To use the environment in your current shell:\n'
printf '    source ./scripts/env-arch.sh\n'
printf '\n'

printf 'To validate later:\n'
printf '    ./scripts/bootstrap_arch.sh --check\n'
printf '\n'

ok "Bootstrap complete."
