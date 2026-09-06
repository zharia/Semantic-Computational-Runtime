# Bootstrap Semantic Program Format

JSON is a provisional serialization of semantic programs. It is not the SCR programming language.

```json
{
  "program": "name",
  "entities": [],
  "relationships": [],
  "constraints": [],
  "transformations": [],
  "observations": []
}
```

Entity: `{"id":"counter","type":"Integer","value":0,"properties":{}}`

Relationship: `{"source":"alice","type":"knows","target":"bob"}`

Constraint: `{"entity":"counter","property":"value","operator":"<=","value":10}`

Transformation: `{"id":"step-1","operation":"increment","target":"counter","argument":1}`

Observation: `{"entity":"counter","property":"value"}`
