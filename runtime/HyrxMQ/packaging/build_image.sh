#!/usr/bin/env bash
# Build the self-contained HyrxMQ listen-mode container image.
#   ./packaging/build_image.sh [IMAGE_TAG]
# Image default: hyrxmq:local
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
TAG="${1:-hyrxmq:local}"
cd "$ROOT"

echo "[1/4] building hyrxmq-listen (Mojo)"
pixi run mojo build -I src -I vendor/flare src/hyrxmq/main_listen.mojo -o build/hyrxmq-listen

echo "[2/4] staging self-contained rootfs (binary + full .so closure + loader)"
rm -rf dist/rootfs
mkdir -p dist/rootfs/app/lib dist/rootfs/lib64
cp build/hyrxmq-listen dist/rootfs/app/hyrxmq-listen

# every resolved shared object except the kernel vDSO; + the ELF interpreter.
ldd build/hyrxmq-listen | awk '{print $3}' | grep -E '\.so' | grep -v 'linux-vdso' \
  | sort -u | while read -r lib; do
    [ -n "$lib" ] && [ -f "$lib" ] && cp -n "$lib" dist/rootfs/app/lib/ || true
done
# glibc loader referenced by the binary's PT_INTERP
LOADER="$(ldd build/hyrxmq-listen | awk '/ld-linux/{print $3; exit}')"
[ -n "$LOADER" ] && cp "$LOADER" dist/rootfs/lib64/ || true
# a couple of libs may be symlinked soname-only; dereference-copy any dangling
find dist/rootfs/app/lib -maxdepth 1 -type l | while read -r l; do
  tgt="$(readlink -f "$l")"; [ -f "$tgt" ] && cp -f "$tgt" "${l}" || true
done

echo "[3/4] docker build ${TAG}"
docker build -t "$TAG" -f Dockerfile .

echo "[4/4] image built:"
docker images "$TAG" --format '  {{.Repository}}:{{.Tag}}  {{.Size}}  (id {{.ID}})'
du -sh dist/rootfs | sed 's#^#  rootfs: #'
