"""
IAM-RM-001 Deterministic State Explorer.
Explores reachable state space for N=8 coordinate space [0, 256).
T : Σ × Event -> Σ | Error
"""

from __future__ import annotations
from typing import List, Tuple, Dict, Set, Any, Optional
from dataclasses import dataclass
from .machine import IAMReferenceMachine, IAMError
from .models import State, Region
from .invariants import check_all_invariants


@dataclass
class ExplorationResult:
    states_explored: int
    transitions_attempted: int
    transitions_legal: int
    transitions_illegal: int
    max_depth: int
    invariant_violations: List[Tuple[str, str, List[str]]]
    boundary_reason: str
    seeds_used: List[int]
    pruned: int
    elapsed_seconds: float


class StateExplorer:
    """
    Deterministic breadth-first explorer over small event traces.
    Concurrency is modelled as interleaving (concurrency model checking).
    """

    def __init__(self, n_bits: int = 8, max_depth: int = 3, max_states: int = 20000):
        self.n_bits = n_bits
        self.space = 1 << n_bits
        self.max_depth = max_depth
        self.max_states = max_states

    def _initial_machine(self) -> IAMReferenceMachine:
        m = IAMReferenceMachine()
        m.create_root("ROOT")
        m.create_space("S", "ROOT", Region(0, self.space))
        m.activate_authority("AUTH_A", "ROOT")
        m.reserve_domain("dom_root_S", "DOM_A", Region(0, self.space // 2))
        m.commit_domain("DOM_A")
        m.delegate_domain("DOM_A", "AUTH_A")
        return m

    def _events(self, depth: int) -> List[Tuple[str, Dict[str, Any]]]:
        """Generate candidate events at a given depth (bounded event alphabet)."""
        events: List[Tuple[str, Dict[str, Any]]] = []
        # SID allocation events across a few coordinates
        for sid in range(0, self.space, max(1, self.space // 8)):
            events.append(("allocate_sid", dict(domain_id="DOM_A", authority_id="AUTH_A", generation=1, sid=sid, tx_id=f"TX-{sid}-{depth}")))
        # Authority rotation
        events.append(("rotate_authority", dict(authority_id="AUTH_A")))
        # Binding / manifestation / retirement for a sample SID
        events.append(("bind_sid", dict(sid=0, entity_id=f"E-{depth}")))
        events.append(("manifest_sid", dict(sid=0, runtime_handle=f"H-{depth}")))
        events.append(("retire_sid", dict(sid=0)))
        # Domain reserve attempts (including overlapping)
        events.append(("reserve_domain", dict(parent_dom_id="dom_root_S", domain_id=f"DOM_B_{depth}", region=Region(self.space // 2, self.space))))
        events.append(("reserve_domain", dict(parent_dom_id="dom_root_S", domain_id=f"DOM_OVL_{depth}", region=Region(self.space // 4, self.space // 2 + 1))))
        return events

    def explore(self, seed: int = 0) -> ExplorationResult:
        import time
        start = time.time()
        violations: List[Tuple[str, str, List[str]]] = []
        states_explored = 0
        transitions_attempted = 0
        transitions_legal = 0
        transitions_illegal = 0
        max_depth_reached = 0
        pruned = 0
        boundary = "complete"

        # BFS over state frontier
        root_machine = self._initial_machine()
        frontier: List[Tuple[IAMReferenceMachine, int, List[str]]] = [(root_machine, 0, [])]
        visited: Set[int] = set()

        while frontier:
            if states_explored >= self.max_states:
                boundary = f"max_states={self.max_states} reached (bounded, not complete)"
                break
            machine, depth, trace = frontier.pop(0)
            state_key = self._state_key(machine.state)
            if state_key in visited:
                pruned += 1
                continue
            visited.add(state_key)
            states_explored += 1
            max_depth_reached = max(max_depth_reached, depth)

            # Verify invariants at every reachable state
            v = check_all_invariants(machine.state)
            for inv_id, msg in v:
                violations.append((inv_id, msg, list(trace)))

            if depth >= self.max_depth:
                continue

            for event_name, kwargs in self._events(depth):
                transitions_attempted += 1
                child = IAMReferenceMachine(machine.state.clone())
                result, err = child.transition(event_name, **kwargs)
                if err is None:
                    transitions_legal += 1
                    frontier.append((child, depth + 1, trace + [f"{event_name}({self._fmt(kwargs)})"]))
                else:
                    transitions_illegal += 1
                    # Atomicity: failed transition must not mutate state
                    if result is not None and self._state_key(result) != self._state_key(machine.state):
                        violations.append(("ATOMICITY", f"Failed {event_name} mutated state: {err}", list(trace)))

        elapsed = time.time() - start
        return ExplorationResult(
            states_explored=states_explored,
            transitions_attempted=transitions_attempted,
            transitions_legal=transitions_legal,
            transitions_illegal=transitions_illegal,
            max_depth=max_depth_reached,
            invariant_violations=violations,
            boundary_reason=boundary,
            seeds_used=[seed],
            pruned=pruned,
            elapsed_seconds=elapsed,
        )

    @staticmethod
    def _state_key(state: State) -> int:
        h = hash((
            frozenset(state.H),
            frozenset((k, v.state.value, v.region.low, v.region.high) for k, v in state.D.items()),
            frozenset((k, v.generation, v.state.value) for k, v in state.A.items()),
            frozenset(state.B.keys()),
            frozenset(state.M.keys()),
            frozenset((k, v.status) for k, v in state.Q.items()),
        ))
        return h

    @staticmethod
    def _fmt(kwargs: Dict[str, Any]) -> str:
        parts = []
        for k, v in kwargs.items():
            if isinstance(v, Region):
                parts.append(f"{k}={v}")
            else:
                parts.append(f"{k}={v}")
        return ", ".join(parts)
