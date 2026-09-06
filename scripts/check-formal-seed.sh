#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../SCRFormal"
lake build SCRFormal
