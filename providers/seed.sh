#!/usr/bin/env bash
#
# SCR Provider Directory Seeder
#
# Run from:
#   providers/
#
# Purpose:
#   Establish the canonical SCR provider directory taxonomy and seed the
#   initial provider integration structure.
#
# Provider classification:
#
#   providers/
#       <domain>/
#           <subdomain>/
#               <provider>/
#
# The directory hierarchy is organizational. Semantic authority remains in
# lib/, while provider contracts and integration rules remain governed by
# docs/architecture/.
#

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "============================================================"
echo " Semantic Computational Runtime"
echo " Provider Directory Seeder"
echo "============================================================"
echo
echo "Provider root: ${ROOT}"
echo

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

create_file_if_missing() {
    local file="$1"

    if [[ -e "$file" ]]; then
        echo "  EXISTS  $file"
        return
    fi

    mkdir -p "$(dirname "$file")"
    touch "$file"
    echo "  CREATE  $file"
}

create_dir() {
    local dir="$1"

    mkdir -p "$dir"
    echo "  DIR     $dir"
}

create_provider() {
    local domain="$1"
    local subdomain="$2"
    local provider="$3"
    local description="$4"

    local base="${ROOT}/${domain}/${subdomain}/${provider}"

    echo
    echo "Provider:"
    echo "  ${domain}/${subdomain}/${provider}"
    echo "  ${description}"

    create_dir "$base"
    create_dir "$base/adapter"
    create_dir "$base/implementation"
    create_dir "$base/tests"

    if [[ ! -f "$base/101_definition.md" ]]; then
        cat > "$base/101_definition.md" <<EOF
# ${provider} Provider

**Provider ID:** ${provider}
**Domain:** ${domain}
**Subdomain:** ${subdomain}
**Status:** Seeded

## Purpose

This directory defines the SCR integration of the \`${provider}\`
implementation as a Provider for the \`${domain}/${subdomain}\`
semantic capability area.

## Provider Role

The Provider supplies a concrete implementation of one or more
SCR semantic capabilities through the applicable Normative Provider
Contracts.

The Provider is not the semantic authority.

Semantic meaning is defined by the corresponding SCR semantic library
under \`lib/\`.

Provider architecture is governed by:

\`docs/architecture/102_provider_architecture.md\`

Normative Provider Contracts are governed by:

\`docs/architecture/103_provider_contracts.md\`

## Required Work

Before this Provider can be considered operational:

1. Identify the semantic capabilities supplied.
2. Identify the applicable semantic contracts.
3. Define the Provider identity and provenance.
4. Define the supported versions.
5. Define implementation bindings.
6. Define adapters where required.
7. Declare resources and platform requirements.
8. Declare fidelity and numerical semantics where applicable.
9. Declare determinism and lifecycle behaviour.
10. Implement conformance tests.
11. Validate Provider Contract conformance.
12. Register the Provider with EGS.

## Provider Isolation

No provider-specific types, classes, terminology, or ontology may
be promoted into the SCR semantic library merely because they exist
in this implementation.

Provider-specific concepts remain here unless they are explicitly
promoted into the semantic layer through the Provider Promotion rules.

## Status

This directory was created by the SCR provider seeding process.

It is not evidence that the Provider is implemented or conformant.
EOF
        echo "  CREATE  $base/101_definition.md"
    else
        echo "  EXISTS  $base/101_definition.md"
    fi

    if [[ ! -f "$base/102_status.yaml" ]]; then
        cat > "$base/102_status.yaml" <<EOF
provider: ${provider}
domain: ${domain}
subdomain: ${subdomain}

status: seeded
implementation_status: not_started
contract_status: not_defined
conformance_status: not_tested

canonical: false
reference: false

capabilities: []
supported_versions: []
platforms: []
architectures: []
dependencies: []
limitations: []
EOF
        echo "  CREATE  $base/102_status.yaml"
    else
        echo "  EXISTS  $base/102_status.yaml"
    fi

    if [[ ! -f "$base/103_provider.graph.json" ]]; then
        cat > "$base/103_provider.graph.json" <<EOF
{
  "provider": "${provider}",
  "domain": "${domain}",
  "subdomain": "${subdomain}",
  "status": "seeded",
  "capabilities": [],
  "contracts": [],
  "implementations": [],
  "adapters": [],
  "artifacts": [],
  "dependencies": [],
  "resources": [],
  "platforms": [],
  "architectures": [],
  "provenance": {}
}
EOF
        echo "  CREATE  $base/103_provider.graph.json"
    else
        echo "  EXISTS  $base/103_provider.graph.json"
    fi

    if [[ ! -f "$base/104_contract.md" ]]; then
        cat > "$base/104_contract.md" <<EOF
# ${provider} Provider Contract

**Provider:** ${provider}
**Domain:** ${domain}
**Subdomain:** ${subdomain}
**Status:** Not Defined

## Contract

This document defines the concrete Provider Contract implemented by
\`${provider}\`.

No Provider implementation should be treated as conformant until
the applicable normative obligations have been explicitly defined
and tested.

## Semantic Capabilities

TODO

## Operations

TODO

## Inputs

TODO

## Outputs

TODO

## Preconditions

TODO

## Postconditions

TODO

## State and Effects

TODO

## Failure Semantics

TODO

## Resource Requirements

TODO

## Fidelity

TODO

## Determinism

TODO

## Numerical Semantics

TODO

## Lifecycle

TODO

## Security and Authority

TODO

## Provenance

TODO

## Conformance Tests

TODO
EOF
        echo "  CREATE  $base/104_contract.md"
    else
        echo "  EXISTS  $base/104_contract.md"
    fi

    create_file_if_missing "$base/adapter/.gitkeep"
    create_file_if_missing "$base/implementation/.gitkeep"
    create_file_if_missing "$base/tests/.gitkeep"
}

# ---------------------------------------------------------------------------
# Provider taxonomy
#
# IMPORTANT:
# This is an initial organizational taxonomy, not a semantic ontology.
#
# Add a new provider only after determining:
#
#   1. Its semantic capability.
#   2. Its domain.
#   3. Its subdomain.
#   4. Whether an existing provider already satisfies that capability.
#   5. The applicable Normative Provider Contract.
#
# ---------------------------------------------------------------------------

echo "Creating provider taxonomy..."
echo

# Mathematical providers
create_provider \
    "math" \
    "linear_algebra" \
    "blas" \
    "BLAS-compatible linear algebra implementation"

# Geometry providers
create_provider \
    "geometry" \
    "computational_geometry" \
    "cgal" \
    "Computational Geometry Algorithms Library"

# Topology / spatial indexing
create_provider \
    "topology" \
    "spatial_indexing" \
    "h3" \
    "Hierarchical geospatial indexing"

# Spatial / volumetric data
create_provider \
    "spatial" \
    "volumetric" \
    "openvdb" \
    "Sparse volumetric data structure and processing"

# Physics
create_provider \
    "physics" \
    "dynamics" \
    "chrono" \
    "Multibody and physical dynamics simulation"

# Rendering
create_provider \
    "render" \
    "graphics" \
    "vulkan" \
    "Low-level GPU graphics and compute API"

# Compute / accelerator infrastructure
create_provider \
    "system" \
    "accelerator" \
    "cuda" \
    "GPU compute platform"

# Messaging
create_provider \
    "system" \
    "messaging" \
    "rabbitmq" \
    "AMQP messaging infrastructure"

echo
echo "============================================================"
echo " Provider seeding complete"
echo "============================================================"
echo
echo "Provider hierarchy:"
echo
find "$ROOT" \
    -mindepth 3 \
    -maxdepth 3 \
    -type d \
    ! -path "$ROOT/.git*" \
    | sort \
    | sed "s#^${ROOT}/#  #"
echo
echo "Next step:"
echo
echo "  Define each Provider's semantic capabilities and Provider"
echo "  Contract before implementing its adapter or executable binding."
echo
echo "Do not place semantic definitions in providers/."
echo "Do not treat seeded providers as automatically conformant."
echo
