from __future__ import annotations
import json
from pathlib import Path
from typing import Any
from ..model import Constraint, Entity, Relationship, SemanticField, Transformation

def load_program(path: str | Path):
    data: dict[str, Any] = json.loads(Path(path).read_text(encoding="utf-8"))
    field = SemanticField()
    for raw in data.get("entities", []):
        field.add_entity(Entity(raw["id"], raw["type"], raw.get("value"), raw.get("properties", {})))
    for raw in data.get("relationships", []):
        field.add_relationship(Relationship(raw["source"], raw["type"], raw["target"]))
    for raw in data.get("constraints", []):
        field.add_constraint(Constraint(raw["entity"], raw["property"], raw["operator"], raw["value"]))
    transformations = [Transformation(raw["id"], raw["operation"], raw["target"], raw.get("argument")) for raw in data.get("transformations", [])]
    observations = [(raw["entity"], raw["property"]) for raw in data.get("observations", [])]
    return field, transformations, observations
