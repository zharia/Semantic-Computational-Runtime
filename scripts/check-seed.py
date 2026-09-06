#!/usr/bin/env python3
"""Validate basic SCR Seed invariants without external dependencies."""
from pathlib import Path
import re, json, sys

ROOT = Path(__file__).resolve().parents[1]
seed = ROOT / "seed"

concepts = {}
errors = []

for p in seed.rglob("*.md"):
    text = p.read_text(encoding="utf-8")
    if not text.startswith("---\n"):
        continue
    m = re.search(r"^id:\s*(scr:[a-z0-9-]+)\s*$", text, re.M)
    if m:
        cid = m.group(1)
        if cid in concepts:
            errors.append(f"duplicate concept id: {cid}")
        concepts[cid] = p

graph = seed / "103_seed.graph.json"
data = json.loads(graph.read_text(encoding="utf-8"))
for c in data["concepts"]:
    if c["id"] not in concepts:
        # graph may intentionally contain future/projection entries
        errors.append(f"graph concept missing source record: {c['id']}")

for r in data["relations"]:
    for endpoint in ("source", "target"):
        if r[endpoint] not in concepts:
            errors.append(f"relation endpoint missing: {r[endpoint]}")

if errors:
    print("\n".join(errors))
    sys.exit(1)

print(f"Seed validation passed: {len(concepts)} concept records, {len(data['relations'])} graph relations.")
