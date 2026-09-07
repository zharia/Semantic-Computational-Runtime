#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "Phase 0 benchmark harness is a measurement scaffold only."
echo "No performance claim is made by this script."
echo
echo "Required future baseline sequence:"
echo "  1. direct in-process path"
echo "  2. Unix-domain transport"
echo "  3. Hyrx TCP"
echo "  4. AMQP TCP"
echo "  5. TLS"
echo "  6. durability variants"
