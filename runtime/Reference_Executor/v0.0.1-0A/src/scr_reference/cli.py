from __future__ import annotations
import argparse, json
from .execution.executor import ReferenceExecutor
from .serialization.json import load_program

def main():
    parser = argparse.ArgumentParser(description="SCR Reference Semantic Executor")
    parser.add_argument("program")
    parser.add_argument("--json", action="store_true", dest="machine")
    args = parser.parse_args()
    field, transformations, observations = load_program(args.program)
    result = ReferenceExecutor(field).execute(transformations, observations)
    if args.machine:
        output = {
            "step": result.trace.entries[-1].step if result.trace.entries else 0,
            "entities": {i: {"type": e.type, "value": e.value, "properties": e.properties} for i,e in result.field.entities.items()},
            "observations": [o.__dict__ for o in result.observations],
            "trace": result.trace.as_dict(),
        }
        print(json.dumps(output, indent=2, sort_keys=True))
    else:
        for o in result.observations: print(f"{o.entity}.{o.property} = {o.value!r}")
    return 0
