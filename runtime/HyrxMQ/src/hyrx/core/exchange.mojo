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
    # Exchange→exchange bindings (exchange.bind (40,30)); _queue_name holds
    # the destination exchange name. Independent of _bindings.
    var _dest_exchanges: List[Binding]

    def __init__(out self, var name: String, var exchange_type: ExchangeType):
        self._name = name^
        self._type = exchange_type^
        self._bindings = List[Binding]()
        # Exchange→exchange bindings (exchange.bind (40,30)); _queue_name holds
        # the destination exchange name. Independent of _bindings.
        self._dest_exchanges = List[Binding]()

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

    # ---- exchange-to-exchange bindings (amqp exchange.bind (40,30)) ----
    #
    # The SAME Binding shape is reused: _queue_name holds the DESTINATION
    # exchange name (the exchange messages flow INTO). The queue-binding table
    # and this table are independent, so routing order cannot conflate them;
    # Router.publish walks this table through Router._expand_chain.

    def add_exchange_binding(mut self, var binding: Binding):
        """Register a binding whose destination is ANOTHER exchange (40,30).

        Duplicate (destination, routing-key) bindings are ignored, like the
        queue-binding path.
        """
        if not _binding_exists(
            self._dest_exchanges, binding._queue_name, binding._routing_key
        ):
            self._dest_exchanges.append(binding^)

    def remove_exchange_binding(
        mut self, var dest: String, routing_key: String
    ) -> Bool:
        """Remove one exchange→exchange binding. True if found and removed."""
        for i in range(len(self._dest_exchanges)):
            if (
                self._dest_exchanges[i]._queue_name == dest
                and self._dest_exchanges[i]._routing_key == routing_key
            ):
                _ = self._dest_exchanges.pop(i)
                return True
        return False

    def remove_exchange_bindings_to(mut self, var dest: String) -> Int:
        """Drop every E2E binding pointing AT `dest` (exchange.delete 40,20).

        Router.delete_exchange calls this on every surviving exchange so
        the deleted exchange is fully unbound from the chain. Returns the
        number of bindings dropped. Pop-in-place: Binding is not Copyable,
        so it is moved directly into the popped slot (destroyed by pop).
        """
        var dropped = 0
        var i = 0
        while i < len(self._dest_exchanges):
            if self._dest_exchanges[i]._queue_name == dest:
                _ = self._dest_exchanges.pop(i)
                dropped += 1
            else:
                i += 1
        return dropped

    def match_exchanges(ref self, routing_key: String) -> List[String]:
        """Destination SET of EXCHANGE names matching for a publish (40,30).

        Same matching rules as match() (direct exact / fanout all / topic
        wildcards / headers stub), evaluated on the E2E binding table.
        Duplicates removed."""
        var result = List[String]()

        if self._type == ExchangeType.direct():
            for i in range(len(self._dest_exchanges)):
                if self._dest_exchanges[i]._routing_key == routing_key:
                    var d = self._dest_exchanges[i]._queue_name
                    if not _already_present(result, d):
                        result.append(d)
        elif self._type == ExchangeType.fanout():
            for i in range(len(self._dest_exchanges)):
                var d = self._dest_exchanges[i]._queue_name
                if not _already_present(result, d):
                    result.append(d)
        elif self._type == ExchangeType.topic():
            for i in range(len(self._dest_exchanges)):
                if _topic_match(routing_key, self._dest_exchanges[i]._routing_key):
                    var d = self._dest_exchanges[i]._queue_name
                    if not _already_present(result, d):
                        result.append(d)
        elif self._type == ExchangeType.headers():
            # Stub: return all bound exchanges (mirrors the queue stub).
            for i in range(len(self._dest_exchanges)):
                var d = self._dest_exchanges[i]._queue_name
                if not _already_present(result, d):
                    result.append(d)

        return result^

    def exchange_binding_count(ref self) -> Int:
        """Number of exchange→exchange bindings on this exchange (40,30)."""
        return len(self._dest_exchanges)

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

    # 0017 T1: exchange→exchange surface lives above (add_exchange_binding,
    # remove_exchange_binding, remove_exchange_bindings_to, match_exchanges,
    # exchange_binding_count)
