from __future__ import annotations
from dataclasses import dataclass, field
from copy import deepcopy
from .constraint import Constraint
from .entity import Entity
from .relationship import Relationship

class SemanticError(Exception): pass
class DuplicateEntity(SemanticError): pass
class UnknownEntity(SemanticError): pass

@dataclass
class SemanticField:
    entities: dict[str, Entity] = field(default_factory=dict)
    relationships: list[Relationship] = field(default_factory=list)
    constraints: list[Constraint] = field(default_factory=list)

    def add_entity(self, entity: Entity) -> None:
        if entity.id in self.entities: raise DuplicateEntity(entity.id)
        self.entities[entity.id] = entity

    def require_entity(self, entity_id: str) -> Entity:
        try: return self.entities[entity_id]
        except KeyError as exc: raise UnknownEntity(entity_id) from exc

    def add_relationship(self, relationship: Relationship) -> None:
        self.require_entity(relationship.source)
        self.require_entity(relationship.target)
        self.relationships.append(relationship)

    def add_constraint(self, constraint: Constraint) -> None:
        self.require_entity(constraint.entity)
        self.constraints.append(constraint)

    def snapshot(self) -> "SemanticField":
        return deepcopy(self)
