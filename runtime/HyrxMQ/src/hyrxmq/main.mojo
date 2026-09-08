# HyrxMQ standalone executable (Phase 7 vertical slice).
#
# Product entry point. It assembles a broker from default configuration, runs
# an in-process self-check (declare -> publish -> deliver -> ack), and prints
# readiness. The default `main()` MUST NOT hang: it exits 0 after the check.
# The real accept loop is the SEPARATE entry point src/hyrxmq/main_listen.mojo
# (built as the hyrxmq-listen binary); AMQPListener rides the flare-backed
# transport contract, proven end-to-end by
# tests/integration/broker_tcp_e2e.mojo. TLS and clean-systemd-machine
# validation remain NOT PROVEN (spec §36/§48).
#
# Run:  pixi run mojo run -I src -I vendor/flare src/hyrxmq/main.mojo

from std.collections import List

from hyrxmq.config import HyrxMQConfig
from hyrxmq.broker import HyrxMQBroker


def run_selfcheck() raises -> Bool:
    """In-process broker self-check: no sockets, no hangs.

    Builds a broker, declares topology, publishes a message, delivers it to a
    registered consumer, verifies the payload bytes, and acknowledges it.
    Returns True only if every invariant holds.
    """
    var cfg = HyrxMQConfig()
    var broker = HyrxMQBroker(cfg^)
    broker.start()

    if not broker.declare_exchange("sc-exchange", "direct"):
        return False
    if not broker.declare_queue("sc-queue"):
        return False
    if not broker.bind_queue("sc-queue", "sc-exchange", "sc-key"):
        return False

    var body = List[UInt8]()
    body.append(0x48)  # 'H'
    body.append(0x69)  # 'i'
    var routed = broker.publish("sc-exchange", "sc-key", body^)
    if routed < 1:
        return False

    var cid = broker.consume_register("sc-queue")
    var delivery = broker.deliver(cid)
    if not delivery.__bool__():
        return False
    var tag = delivery.value().delivery_tag()

    var payload = broker.read_payload(cid, tag)
    if len(payload) != 2 or payload[0] != 0x48 or payload[1] != 0x69:
        return False

    if not broker.ack(cid, tag):
        return False

    # Empty queue: a further deliver must be None.
    if broker.deliver(cid).__bool__():
        return False

    var st = broker.status()
    if (
        st.messages_published < 1
        or st.messages_delivered < 1
        or st.messages_acked < 1
    ):
        return False
    if broker.health() != "ok":
        return False

    broker.shutdown()
    return True


def main() raises:
    var cfg = HyrxMQConfig()
    var broker = HyrxMQBroker(cfg^)
    print("HyrxMQ " + broker.node_name() + " starting")
    broker.start()
    print(
        "HyrxMQ "
        + broker.node_name()
        + " ready (TCP/UDS provided by the flare-backed transport contract;"
        " AMQP-over-TCP + broker handshake proven in tests/integration;"
        " TLS NOT PROVEN)"
    )

    # ------------------------------------------------------------------
    # The real accept loop is main_listen.mojo (separate binary/entry),
    # never this file. The default main() path stays non-hanging: it runs
    # the in-process self-check and exits, so tests never block.
    # ------------------------------------------------------------------

    if run_selfcheck():
        print("self-check=PASS (declare/publish/deliver/ack in-process)")
    else:
        print("self-check=FAIL")
        return

    var st = broker.status()
    print(
        "status: ready="
        + String(st.ready)
        + " queues="
        + String(st.queues)
        + " health="
        + broker.health()
    )
    broker.shutdown()
