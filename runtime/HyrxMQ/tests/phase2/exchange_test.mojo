# Tests for Exchange routing logic.
#
# Covers: direct, fanout, topic (wildcard), headers, bind/unbind.

from hyrx.core.exchange import (
    Exchange,
    ExchangeType,
    Binding,
    _topic_match,
)

def _make_binding(var queue_name: String, var routing_key: String) -> Binding:
    var args = Dict[String, String]()
    return Binding(queue_name^, routing_key^, args^)

def test_direct_exchange() raises:
    """Direct exchange matches exact routing key."""
    var ex = Exchange("amq.direct", ExchangeType.direct())
    ex.add_binding(_make_binding("orders", "orders.new"))
    ex.add_binding(_make_binding("logs", "logs.info"))

    var matched = ex.match("orders.new")
    assert len(matched) == 1
    assert matched[0] == "orders"

    matched = ex.match("logs.info")
    assert len(matched) == 1
    assert matched[0] == "logs"

    # Non-matching key
    matched = ex.match("orders.old")
    assert len(matched) == 0

def test_fanout_exchange() raises:
    """Fanout exchange returns all bound queues."""
    var ex = Exchange("amq.fanout", ExchangeType.fanout())
    ex.add_binding(_make_binding("q1", ""))
    ex.add_binding(_make_binding("q2", ""))
    ex.add_binding(_make_binding("q3", ""))

    var matched = ex.match("anything")
    assert len(matched) == 3

def test_topic_star_wildcard() raises:
    """Topic exchange: * matches exactly one word."""
    var ex = Exchange("amq.topic", ExchangeType.topic())
    ex.add_binding(_make_binding("orders", "orders.*"))

    var matched = ex.match("orders.new")
    assert len(matched) == 1
    assert matched[0] == "orders"

    # Two words after "orders" — * only matches one
    matched = ex.match("orders.new.urgent")
    assert len(matched) == 0

    matched = ex.match("orders")
    assert len(matched) == 0

def test_topic_hash_wildcard() raises:
    """Topic exchange: # matches zero or more words."""
    var ex = Exchange("amq.topic", ExchangeType.topic())
    ex.add_binding(_make_binding("all", "#"))
    ex.add_binding(_make_binding("orders", "orders.#"))

    # # matches everything
    var matched = ex.match("any.thing.here")
    assert len(matched) == 1
    assert matched[0] == "all"

    # orders.# matches orders.new, orders.new.urgent, etc.
    matched = ex.match("orders.new")
    assert len(matched) == 2  # both "all" and "orders"

    matched = ex.match("orders.new.urgent")
    assert len(matched) == 2

    # orders.# also matches just "orders" (zero words)
    matched = ex.match("orders")
    assert len(matched) == 2

def test_topic_complex_pattern() raises:
    """Topic exchange: complex wildcard patterns."""
    var ex = Exchange("amq.topic", ExchangeType.topic())
    ex.add_binding(_make_binding("kq", "*.*.rabbit"))
    ex.add_binding(_make_binding("lazy", "*.lazy.#"))

    # quick.orange.rabbit — matches *.*.rabbit and *.lazy.#
    var matched = ex.match("quick.orange.rabbit")
    assert len(matched) == 1
    assert matched[0] == "kq"

    # quick.orangefox.rabbit — doesn't match *.*.rabbit (orangefox != orange)
    matched = ex.match("quick.orangefox.rabbit")
    assert len(matched) == 0

    # quick.lazy.pink.rabbit — matches *.lazy.#
    matched = ex.match("quick.lazy.pink.rabbit")
    assert len(matched) == 1
    assert matched[0] == "lazy"

    # quick.lazy.rabbit — matches *.lazy.# and *.*.rabbit
    matched = ex.match("quick.lazy.rabbit")
    assert len(matched) == 2

def test_headers_exchange() raises:
    """Headers exchange: returns all bound queues (stub)."""
    var ex = Exchange("amq.headers", ExchangeType.headers())
    ex.add_binding(_make_binding("q1", ""))
    ex.add_binding(_make_binding("q2", ""))

    var matched = ex.match("ignored")
    assert len(matched) == 2

def test_bind_unbind() raises:
    """Bind and unbind operations."""
    var ex = Exchange("test", ExchangeType.direct())
    ex.add_binding(_make_binding("q1", "key1"))
    ex.add_binding(_make_binding("q2", "key2"))
    assert ex.binding_count() == 2

    # Unbind existing
    assert ex.remove_binding("q1", "key1") == True
    assert ex.binding_count() == 1

    # Unbind non-existing
    assert ex.remove_binding("q1", "key1") == False
    assert ex.binding_count() == 1

    # Verify remaining binding
    var matched = ex.match("key2")
    assert len(matched) == 1
    assert matched[0] == "q2"

def test_duplicate_binding_ignored() raises:
    """Adding the same binding twice is idempotent."""
    var ex = Exchange("test", ExchangeType.direct())
    ex.add_binding(_make_binding("q1", "key"))
    ex.add_binding(_make_binding("q1", "key"))
    assert ex.binding_count() == 1

def test_topic_match_helper() raises:
    """Direct test of _topic_match helper."""
    assert _topic_match("orders.new", "orders.*") == True
    assert _topic_match("orders", "orders.*") == False
    assert _topic_match("a.b.c", "#") == True
    assert _topic_match("a.b.c", "a.#") == True
    assert _topic_match("a.b.c", "a.b.#") == True
    assert _topic_match("a.b.c", "a.b") == False
    assert _topic_match("a.b.c", "a.b.c") == True

def main() raises:
    test_direct_exchange()
    test_fanout_exchange()
    test_topic_star_wildcard()
    test_topic_hash_wildcard()
    test_topic_complex_pattern()
    test_headers_exchange()
    test_bind_unbind()
    test_duplicate_binding_ignored()
    test_topic_match_helper()
    print("EXCHANGE_TEST=PASS")
