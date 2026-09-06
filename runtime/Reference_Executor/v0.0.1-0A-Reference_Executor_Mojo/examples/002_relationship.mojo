from scr_reference.entity import Entity
from scr_reference.field import SemanticField
from scr_reference.relationship import Relationship

def main() raises:
    var field = SemanticField()

    field.add_entity(Entity("alice", "Person"))
    field.add_entity(Entity("bob", "Person"))

    field.add_relationship(
        Relationship(
            "friendship-1",
            "FRIEND_OF",
            "alice",
            "bob",
        )
    )

    print("Relationship count:", field.relationship_count())

    for id in field.relationship_ids():
        var relationship = field.get_relationship(id)
        print(relationship)
