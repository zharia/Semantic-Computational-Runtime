```nix
{
  description = "Semantic Computational Runtime — MLIR-based computational semantics";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      forAllSystems = nixpkgs.lib.genAttrs systems;

      pkgsFor = forAllSystems (system:
        import nixpkgs {
          inherit system;

          # Keep the development environment deterministic.
          config = {
            allowUnfree = false;
          };
        }
      );

    in
    {
      devShells = forAllSystems (system:
        let
          pkgs = pkgsFor.${system};

          llvm = pkgs.llvmPackages;

          # Keep the LLVM family internally consistent.
          llvmTools = [
            llvm.llvm
            llvm.clang
            llvm.lld
            llvm.mlir
          ];

          commonTools = with pkgs; [
            # Build system
            cmake
            ninja
            pkg-config

            # Source control / developer utilities
            git
            git-lfs
            curl
            wget
            jq
            yq-go
            ripgrep
            fd
            tree
            shellcheck
            shfmt

            # Native debugging / profiling
            gdb
            lldb
            valgrind

            # C/C++ developer tooling
            clang-tools

            # Cache
            ccache

            # Python
            python3
            python3Packages.pip
            python3Packages.virtualenv

            # Rust
            rustc
            cargo
            rustfmt
            clippy

            # General build/test tooling
            which
            file
            unzip
            zip
          ];

          llvmToolsAll = llvmTools ++ [
            # LLVM testing infrastructure where available.
            llvm.lit
          ];

        in
        {
          default = pkgs.mkShell {
            name = "scr";

            packages =
              llvmToolsAll
              ++ commonTools;

            shellHook = ''
              export SCR_ROOT="$PWD"

              # ------------------------------------------------------------
              # LLVM / MLIR
              # ------------------------------------------------------------

              export LLVM_ROOT="${llvm.llvm}"
              export MLIR_ROOT="${llvm.mlir}"

              export LLVM_DIR="${llvm.llvm}/lib/cmake/llvm"
              export MLIR_DIR="${llvm.mlir}/lib/cmake/mlir"

              # Put LLVM/MLIR tools first.
              export PATH="${llvm.llvm}/bin:${llvm.mlir}/bin:$PATH"

              # ------------------------------------------------------------
              # C/C++
              # ------------------------------------------------------------

              export CC="${llvm.clang}/bin/clang"
              export CXX="${llvm.clang}/bin/clang++"
              export LD="${llvm.lld}/bin/ld.lld"

              export CMAKE_GENERATOR="Ninja"

              # ------------------------------------------------------------
              # Rust / MLIR integration
              # ------------------------------------------------------------

              # Useful to crates which discover LLVM through llvm-config.
              export LLVM_CONFIG="${llvm.llvm}/bin/llvm-config"

              # Melior/mlir-sys can use these when the selected crate version
              # expects an explicitly versioned MLIR installation.
              #
              # The exact MLIR_SYS_* variable is intentionally not hardcoded
              # here because it follows the mlir-sys/LLVM version selected by
              # Cargo.
              #
              # Example for LLVM 22:
              # export MLIR_SYS_220_PREFIX="${llvm.mlir}"

              # ------------------------------------------------------------
              # CCache
              # ------------------------------------------------------------

              export CCACHE_DIR="''${CCACHE_DIR:-$HOME/.cache/ccache}"

              # ------------------------------------------------------------
              # Project paths
              # ------------------------------------------------------------

              export SCR_BUILD_DIR="$SCR_ROOT/build"
              export SCR_CARGO_TARGET_DIR="$SCR_ROOT/target"

              # ------------------------------------------------------------
              # Make the environment obvious
              # ------------------------------------------------------------

              echo
              echo "╭────────────────────────────────────────────────────────────╮"
              echo "│ Semantic Computational Runtime development environment    │"
              echo "╰────────────────────────────────────────────────────────────╯"
              echo
              echo "LLVM : $(llvm-config --version)"
              echo "Clang: $(clang --version | head -n 1)"
              echo "MLIR : $(mlir-opt --version 2>/dev/null | head -n 1 || true)"
              echo "Rust : $(rustc --version)"
              echo "CMake: $(cmake --version | head -n 1)"
              echo "Ninja: $(ninja --version)"
              echo
              echo "LLVM_ROOT = $LLVM_ROOT"
              echo "MLIR_ROOT = $MLIR_ROOT"
              echo "MLIR_DIR  = $MLIR_DIR"
              echo
            '';
          };

          minimal = pkgs.mkShell {
            name = "scr-minimal";

            packages =
              llvmToolsAll
              ++ (with pkgs; [
                cmake
                ninja
                pkg-config
                git
                clang-tools
                ccache
                rustc
                cargo
                rustfmt
                clippy
              ]);

            shellHook = ''
              export SCR_ROOT="$PWD"

              export LLVM_ROOT="${llvm.llvm}"
              export MLIR_ROOT="${llvm.mlir}"
              export LLVM_DIR="${llvm.llvm}/lib/cmake/llvm"
              export MLIR_DIR="${llvm.mlir}/lib/cmake/mlir"

              export CC="${llvm.clang}/bin/clang"
              export CXX="${llvm.clang}/bin/clang++"
              export LD="${llvm.lld}/bin/ld.lld"
              export LLVM_CONFIG="${llvm.llvm}/bin/llvm-config"

              export PATH="${llvm.llvm}/bin:${llvm.mlir}/bin:$PATH"
              export CMAKE_GENERATOR="Ninja"
            '';
          };
        }
      );

      # ------------------------------------------------------------
      # Development checks
      # ------------------------------------------------------------

      checks = forAllSystems (system:
        let
          pkgs = pkgsFor.${system};
          llvm = pkgs.llvmPackages;
        in
        {
          toolchain = pkgs.runCommand "scr-toolchain-check" {
            nativeBuildInputs = [
              llvm.llvm
              llvm.clang
              llvm.lld
              llvm.mlir
              llvm.lit
              pkgs.cmake
              pkgs.ninja
              pkgs.rustc
              pkgs.cargo
            ];
          } ''
            set -euo pipefail

            command -v clang
            command -v clang++
            command -v ld.lld
            command -v llvm-config
            command -v mlir-opt
            command -v mlir-translate
            command -v cmake
            command -v ninja
            command -v rustc
            command -v cargo

            llvm-config --version
            mlir-opt --version
            clang --version
            cmake --version
            ninja --version
            rustc --version
            cargo --version

            touch $out
          '';
        }
      );
    };
}
```
