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
#   - match() returns a DESTINATION SET: each matching queue appears once,
#     even when several of its bindings match the same routing key.
#     (audit §6 / AMQP: "each queue receives exactly one copy" — a queue
#     bound by two matching patterns must not be double-delivered.)

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
    var key_parts = routing_key.split(".")
    var pat_parts = pattern.split(".")
    var key_words = List[String]()
    var pat_words = List[String]()
    for i in range(len(key_parts)):
        key_words.append(String(key_parts[i]))
    for j in range(len(pat_parts)):
        pat_words.append(String(pat_parts[j]))
    return _match_words(key_words, 0, pat_words, 0)

def _match_words(
    key: List[String],
    ki: Int,
    pat: List[String],
    pi: Int,
) -> Bool:
    """Recursive word-level matching for topic patterns."""
    if pi == len(pat):
        return ki == len(key)

    var word = pat[pi]

    # '#' matches zero or more words — try every consumption length.
    if word == "#":
        var n = ki
        while n <= len(key):
            if _match_words(key, n, pat, pi + 1):
                return True
            n += 1
        return False

    if ki == len(key):
        return False

    # '*' matches exactly one word.
    if word == "*":
        return _match_words(key, ki + 1, pat, pi + 1)

    # Literal word.
    if word != key[ki]:
        return False
    return _match_words(key, ki + 1, pat, pi + 1)

def _already_present(result: List[String], queue_name: String) -> Bool:
    """True if `queue_name` is already in the destination list."""
    for i in range(len(result)):
        if result[i] == queue_name:
            return True
    return False

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
        """Return the destination SET of queue names matching the routing key.

        Duplicates are removed: one queue bound by several matching
        bindings is listed once, so publish() delivers one copy to it.

        Direct: exact match on routing_key.
        Fanout: all bound queues.
        Topic: wildcard pattern match.
        Headers: all bound queues (stub).
        """
        var result = List[String]()

        if self._type == ExchangeType.direct():
            for i in range(len(self._bindings)):
                if self._bindings[i]._routing_key == routing_key:
                    var qname = self._bindings[i]._queue_name
                    if not _already_present(result, qname):
                        result.append(qname)
        elif self._type == ExchangeType.fanout():
            for i in range(len(self._bindings)):
                var qname_f = self._bindings[i]._queue_name
                if not _already_present(result, qname_f):
                    result.append(qname_f)
        elif self._type == ExchangeType.topic():
            for i in range(len(self._bindings)):
                if _topic_match(routing_key, self._bindings[i]._routing_key):
                    var qname_t = self._bindings[i]._queue_name
                    if not _already_present(result, qname_t):
                        result.append(qname_t)
        elif self._type == ExchangeType.headers():
            # Stub: return all bound queues
            for i in range(len(self._bindings)):
                var qname_h = self._bindings[i]._queue_name
                if not _already_present(result, qname_h):
                    result.append(qname_h)

        return result^

    def binding_count(ref self) -> Int:
        return len(self._bindings)
