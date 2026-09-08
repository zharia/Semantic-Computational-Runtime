# Exchange types and routing logic.
#
# Exchange routes published messages to bound queues based on type:
#   - direct: exact routing_key match
#   - fanout: all bound queues
#   - topic: wildcard pattern match (* = one word, # = zero or more)
#   - headers: match on message headers (stub: returns all)
#
# Ownership model:
#   - Exchange owns its bindings list.
#   - match() returns queue names by value (copied strings).

from std.collections import List

struct ExchangeType:
    """Enum for exchange types. 0=direct, 1=fanout, 2=topic, 3=headers."""

    var _value: Int

    def __init__(out self, value: Int):
        self._value = value

    def __copyinit__(out self, existing: Self):
        self._value = existing._value

    @staticmethod
    def direct() -> ExchangeType:
        return ExchangeType(0)

    @staticmethod
    def fanout() -> ExchangeType:
        return ExchangeType(1)

    @staticmethod
    def topic() -> ExchangeType:
        return ExchangeType(2)

    @staticmethod
    def headers() -> ExchangeType:
        return ExchangeType(3)

    def __eq__(self, other: ExchangeType) -> Bool:
        return self._value == other._value

struct Binding:
    """A binding from exchange to queue with optional routing key pattern."""

    var _queue_name: String
    var _routing_key: String
    var _arguments: Dict[String, String]

    def __init__(
        out self,
        var queue_name: String,
        var routing_key: String,
        var arguments: Dict[String, String],
    ):
        self._queue_name = queue_name^
        self._routing_key = routing_key^
        self._arguments = arguments^

    def queue_name(ref self) -> String:
        return self._queue_name

    def routing_key(ref self) -> String:
        return self._routing_key

def _topic_match(routing_key: String, pattern: String) -> Bool:
    """Match routing_key against topic pattern with * and # wildcards.

    * matches exactly one word (between dots).
    # matches zero or more words.
    """
    var klen = len(routing_key.codepoints())
    var plen = len(pattern.codepoints())
    return _match_cp(routing_key, 0, klen, pattern, 0, plen)

def _match_cp(
    key: String,
    ki: Int,
    klen: Int,
    pat: String,
    pi: Int,
    plen: Int,
) -> Bool:
    """Recursive codepoint-level matching for topic patterns."""
    if ki == klen and pi == plen:
        return True
    if pi >= plen:
        return False

    var pat_c = String(pat[codepoint=pi])

    # Current pattern char is '#'
    if pat_c == "#":
        if pi + 1 >= plen:
            return True
        var nk = ki
        while nk <= klen:
            if _match_cp(key, nk, klen, pat, pi + 1, plen):
                return True
            # Advance past current word to next dot
            while nk < klen:
                var kc = String(key[codepoint=nk])
                if kc == ".":
                    nk += 1
                    break
                nk += 1
        return False

    # Current pattern char is '*'
    if pat_c == "*":
        if ki >= klen:
            return False
        # Skip one word in key — stop at dot (don't consume it)
        var nk = ki
        while nk < klen:
            var kc = String(key[codepoint=nk])
            if kc == ".":
                break
            nk += 1
        return _match_cp(key, nk, klen, pat, pi + 1, plen)

    # Literal match
    if ki >= klen:
        return False
    var key_c = String(key[codepoint=ki])
    if key_c != pat_c:
        return False
    return _match_cp(key, ki + 1, klen, pat, pi + 1, plen)

def _binding_exists(bindings: List[Binding], queue_name: String, routing_key: String) -> Bool:
    """Check if a binding already exists for the given queue and routing key."""
    for i in range(len(bindings)):
        if bindings[i]._queue_name == queue_name and bindings[i]._routing_key == routing_key:
            return True
    return False

struct Exchange:
    """Message router. Matches published messages to bound queues."""

    var _name: String
    var _type: ExchangeType
    var _bindings: List[Binding]

    def __init__(out self, var name: String, var exchange_type: ExchangeType):
        self._name = name^
        self._type = exchange_type^
        self._bindings = List[Binding]()

    def name(ref self) -> String:
        return self._name

    def exchange_type(ref self) -> ExchangeType:
        return self._type

    def add_binding(mut self, var binding: Binding):
        """Add a binding. Duplicate bindings are ignored."""
        if not _binding_exists(
            self._bindings, binding._queue_name, binding._routing_key
        ):
            self._bindings.append(binding^)

    def remove_binding(mut self, queue_name: String, routing_key: String) -> Bool:
        """Remove a binding. Returns True if found and removed."""
        for i in range(len(self._bindings)):
            if (
                self._bindings[i]._queue_name == queue_name
                and self._bindings[i]._routing_key == routing_key
            ):
                _ = self._bindings.pop(i)
                return True
        return False

    def match(ref self, routing_key: String) -> List[String]:
        """Return queue names matching the routing key for this exchange type.

        Direct: exact match on routing_key.
        Fanout: all bound queues.
        Topic: wildcard pattern match.
        Headers: all bound queues (stub).
        """
        var result = List[String]()

        if self._type == ExchangeType.direct():
            for i in range(len(self._bindings)):
                if self._bindings[i]._routing_key == routing_key:
                    result.append(self._bindings[i]._queue_name)
        elif self._type == ExchangeType.fanout():
            for i in range(len(self._bindings)):
                result.append(self._bindings[i]._queue_name)
        elif self._type == ExchangeType.topic():
            for i in range(len(self._bindings)):
                if _topic_match(routing_key, self._bindings[i]._routing_key):
                    result.append(self._bindings[i]._queue_name)
        elif self._type == ExchangeType.headers():
            # Stub: return all bound queues
            for i in range(len(self._bindings)):
                result.append(self._bindings[i]._queue_name)

        return result^

    def binding_count(ref self) -> Int:
        return len(self._bindings)
