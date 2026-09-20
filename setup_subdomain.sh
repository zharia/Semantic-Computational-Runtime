#!/bin/bash
# Subdomain Setup Script for SCR Library
# Usage: ./setup_subdomain.sh <domain_name>
# This script sets up a new subdomain following the established pattern

DOMAIN=$1
BASE_DIR="/home/zharia/Projects/experiments/semantic_computational_runtime/lib"

# Fail if domain already exists
if [ -d "$BASE_DIR/$DOMAIN" ]; then
    echo "Error: Domain '$DOMAIN' already exists"
    exit 1
fi

# Create domain directory structure
echo "Creating domain directory structure..."
mkdir -p "$BASE_DIR/$DOMAIN"
mkdir -p "$BASE_DIR/$DOMAIN/201_LeanLang"
mkdir -p "$BASE_DIR/$DOMAIN/IR/mlir"
mkdir -p "$BASE_DIR/$DOMAIN/Search"

# Copy 101_definition.md template (from Core as reference)
cp /home/zharia/Projects/experiments/semantic_computational_runtime/lib/101_Core/101_definition.md "$BASE_DIR/$DOMAIN/101_definition.md"

# Copy Lean template files from Hypergraph
cp -r /home/zharia/Projects/experiments/semantic_computational_runtime/lib/203_Graph/Hypergraph/201_LeanLang/LeanHypergraph/* "$BASE_DIR/$DOMAIN/201_LeanLang/"

# Copy MLIR dialect files from IR
cp -r /home/zharia/Projects/experiments/semantic_computational_runtime/lib/203_Graph/IR/mlir/* "$BASE_DIR/$DOMAIN/IR/mlir/"

# Create Search directory structure
mkdir -p "$BASE_DIR/$DOMAIN/Search"
cp /home/zharia/Projects/experiments/semantic_computational_runtime/lib/203_Graph/Search/101_definition.md "$BASE_DIR/$DOMAIN/Search/101_definition.md"

# Create domain metadata
cat > "$BASE_DIR/$DOMAIN/001_meta.md" << META_EOF
# $DOMAIN Meta

**Domain:** $DOMAIN
**Directory:** lib/$DOMAIN/
**Purpose:** Semantic domain for the SCR library
**Status:** draft
**Version:** 0.1.0
**Created:** $(date +%Y-%m-%d)

**Relationship to Parent:**
- Parent is Hypergraph within the SCR library hierarchy

**Documentation Status:**
- 101_definition.md: populated
- Lean-Lang formalization: in progress
- MLIR dialect: in progress
- Search domain: not started

**Scope Boundary:**
- <domain-specific scope notes>

**Notes:**
- <domain-specific notes>
META_EOF

echo "Domain '$DOMAIN' setup complete"
