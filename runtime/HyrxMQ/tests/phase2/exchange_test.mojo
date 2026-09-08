# Tests for Exchange routing logic.
#
# Covers: direct, fanout, topic (wildcard), headers, bind/unbind.

from hyrx.core.exchange import (
    Exchange,
    ExchangeType,
    Binding,
    _topic_match,
)

from hyrx.testing import check

def _make_binding(var queue_name: String, var routing_key: String) -> Binding:
    var args = Dict[String, String]()
    return Binding(queue_name^, routing_key^, args^)

def test_direct_exchange() raises:
    """Direct exchange matches exact routing key."""
    var ex = Exchange("amq.direct", ExchangeType.direct())
    ex.add_binding(_make_binding("orders", "orders.new"))
    ex.add_binding(_make_binding("logs", "logs.info"))

    var matched = ex.match("orders.new")
    check(len(matched) == 1, "L23 expect: len(matched) == 1")
    check(matched[0] == "orders", "L24 expect: matched[0] == 'orders'")

    matched = ex.match("logs.info")
    check(len(matched) == 1, "L27 expect: len(matched) == 1")
    check(matched[0] == "logs", "L28 expect: matched[0] == 'logs'")

    # Non-matching key
    matched = ex.match("orders.old")
    check(len(matched) == 0, "L32 expect: len(matched) == 0")

def test_fanout_exchange() raises:
    """Fanout exchange returns all bound queues."""
    var ex = Exchange("amq.fanout", ExchangeType.fanout())
    ex.add_binding(_make_binding("q1", ""))
    ex.add_binding(_make_binding("q2", ""))
    ex.add_binding(_make_binding("q3", ""))

    var matched = ex.match("anything")
    check(len(matched) == 3, "L42 expect: len(matched) == 3")

def test_topic_star_wildcard() raises:
    """Topic exchange: * matches exactly one word."""
    var ex = Exchange("amq.topic", ExchangeType.topic())
    ex.add_binding(_make_binding("orders", "orders.*"))

    var matched = ex.match("orders.new")
    check(len(matched) == 1, "L50 expect: len(matched) == 1")
    check(matched[0] == "orders", "L51 expect: matched[0] == 'orders'")

    # Two words after "orders" — * only matches one
    matched = ex.match("orders.new.urgent")
    check(len(matched) == 0, "L55 expect: len(matched) == 0")

    matched = ex.match("orders")
    check(len(matched) == 0, "L58 expect: len(matched) == 0")

def test_topic_hash_wildcard() raises:
    """Topic exchange: # matches zero or more words."""
    var ex = Exchange("amq.topic", ExchangeType.topic())
    ex.add_binding(_make_binding("all", "#"))
    ex.add_binding(_make_binding("orders", "orders.#"))

    # # matches everything
    var matched = ex.match("any.thing.here")
    check(len(matched) == 1, "L68 expect: len(matched) == 1")
    check(matched[0] == "all", "L69 expect: matched[0] == 'all'")

    # orders.# matches orders.new, orders.new.urgent, etc.
    matched = ex.match("orders.new")
    check(len(matched) == 2, "L73 expect: len(matched) == 2")  # both "all" and "orders"

    matched = ex.match("orders.new.urgent")
    check(len(matched) == 2, "L76 expect: len(matched) == 2")

    # orders.# also matches just "orders" (zero words)
    matched = ex.match("orders")
    check(len(matched) == 2, "L80 expect: len(matched) == 2")

def test_topic_complex_pattern() raises:
    """Topic exchange: complex wildcard patterns."""
    var ex = Exchange("amq.topic", ExchangeType.topic())
    ex.add_binding(_make_binding("kq", "*.*.rabbit"))
    ex.add_binding(_make_binding("lazy", "*.lazy.#"))

    # quick.orange.rabbit — matches *.*.rabbit and *.lazy.#
    var matched = ex.match("quick.orange.rabbit")
    check(len(matched) == 1, "L90 expect: len(matched) == 1")
    check(matched[0] == "kq", "L91 expect: matched[0] == 'kq'")

    # quick.orangefox.rabbit — still matches *.*.rabbit (* = any single word)
    matched = ex.match("quick.orangefox.rabbit")
    check(len(matched) == 1, "L96 expect: len(matched) == 1")
    check(matched[0] == "kq", "L97 expect: matched[0] == 'kq'")

    # quick.lazy.pink.rabbit — matches *.lazy.#
    matched = ex.match("quick.lazy.pink.rabbit")
    check(len(matched) == 1, "L99 expect: len(matched) == 1")
    check(matched[0] == "lazy", "L100 expect: matched[0] == 'lazy'")

    # quick.lazy.rabbit — matches *.lazy.# and *.*.rabbit
    matched = ex.match("quick.lazy.rabbit")
    check(len(matched) == 2, "L104 expect: len(matched) == 2")

def test_headers_exchange() raises:
    """Headers exchange: returns all bound queues (stub)."""
    var ex = Exchange("amq.headers", ExchangeType.headers())
    ex.add_binding(_make_binding("q1", ""))
    ex.add_binding(_make_binding("q2", ""))

    var matched = ex.match("ignored")
    check(len(matched) == 2, "L113 expect: len(matched) == 2")

def test_bind_unbind() raises:
    """Bind and unbind operations."""
    var ex = Exchange("test", ExchangeType.direct())
    ex.add_binding(_make_binding("q1", "key1"))
    ex.add_binding(_make_binding("q2", "key2"))
    check(ex.binding_count() == 2, "L120 expect: ex.binding_count() == 2")

    # Unbind existing
    check(ex.remove_binding("q1", "key1") == True, "L123 expect: ex.remove_binding('q1', 'key1') == True")
    check(ex.binding_count() == 1, "L124 expect: ex.binding_count() == 1")

    # Unbind non-existing
    check(ex.remove_binding("q1", "key1") == False, "L127 expect: ex.remove_binding('q1', 'key1') == False")
    check(ex.binding_count() == 1, "L128 expect: ex.binding_count() == 1")

    # Verify remaining binding
    var matched = ex.match("key2")
    check(len(matched) == 1, "L132 expect: len(matched) == 1")
    check(matched[0] == "q2", "L133 expect: matched[0] == 'q2'")

def test_duplicate_binding_ignored() raises:
    """Adding the same binding twice is idempotent."""
    var ex = Exchange("test", ExchangeType.direct())
    ex.add_binding(_make_binding("q1", "key"))
    ex.add_binding(_make_binding("q1", "key"))
    check(ex.binding_count() == 1, "L140 expect: ex.binding_count() == 1")

def test_topic_match_helper() raises:
    """Direct test of _topic_match helper."""
    check(_topic_match("orders.new", "orders.*") == True, "L144 expect: _topic_match('orders.new', 'orders.*') == True")
    check(_topic_match("orders", "orders.*") == False, "L145 expect: _topic_match('orders', 'orders.*') == False")
    check(_topic_match("a.b.c", "#") == True, "L146 expect: _topic_match('a.b.c', '#') == True")
    check(_topic_match("a.b.c", "a.#") == True, "L147 expect: _topic_match('a.b.c', 'a.#') == True")
    check(_topic_match("a.b.c", "a.b.#") == True, "L148 expect: _topic_match('a.b.c', 'a.b.#') == True")
    check(_topic_match("a.b.c", "a.b") == False, "L149 expect: _topic_match('a.b.c', 'a.b') == False")
    check(_topic_match("a.b.c", "a.b.c") == True, "L150 expect: _topic_match('a.b.c', 'a.b.c') == True")

    # AMQP 0-9-1 contract: '#' = zero or more words, '*' = exactly one word.
    check(_topic_match("orders", "orders.#") == True, "L154 expect: _topic_match('orders', 'orders.#') == True")
    check(_topic_match("orders.us", "orders.#") == True, "L155 expect: _topic_match('orders.us', 'orders.#') == True")
    check(_topic_match("orders.us.east", "orders.#") == True, "L156 expect: _topic_match('orders.us.east', 'orders.#') == True")
    check(_topic_match("anything.at.all", "#") == True, "L157 expect: _topic_match('anything.at.all', '#') == True")
    check(_topic_match("ordersx", "orders.#") == False, "L158 expect: _topic_match('ordersx', 'orders.#') == False")
    check(_topic_match("other", "orders.#") == False, "L159 expect: _topic_match('other', 'orders.#') == False")
    check(_topic_match("orders.east", "*.east") == True, "L160 expect: _topic_match('orders.east', '*.east') == True")
    check(_topic_match("orders.us.east", "*.east") == False, "L161 expect: _topic_match('orders.us.east', '*.east') == False")
    check(_topic_match("orders", "orders.*") == False, "L162 expect: _topic_match('orders', 'orders.*') == False")
    check(_topic_match("orders.x.east", "orders.*.east") == True, "L163 expect: _topic_match('orders.x.east', 'orders.*.east') == True")
    check(_topic_match("orders.us.east", "#.east") == True, "L164 expect: _topic_match('orders.us.east', '#.east') == True")
    check(_topic_match("east", "#.east") == True, "L165 expect: _topic_match('east', '#.east') == True")
    check(_topic_match("a.b", "a.#") == True, "L166 expect: _topic_match('a.b', 'a.#') == True")
    check(_topic_match("a.z", "a.#.z") == True, "L167 expect: _topic_match('a.z', 'a.#.z') == True")
    check(_topic_match("a.b.c.z", "a.#.z") == True, "L168 expect: _topic_match('a.b.c.z', 'a.#.z') == True")

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
