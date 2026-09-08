# Tests for AMQP connection and channel state machines.
#
# Verifies state transitions and accessor methods.

from hyrx.amqp.connection_state import (
    AMQPConnectionState,
    AMQPChannelState,
    CONN_STATE_CLOSED,
    CONN_STATE_START_SENT,
    CONN_STATE_TUNE_RECEIVED,
    CONN_STATE_OPEN,
    CONN_STATE_CLOSING,
    CHAN_STATE_CLOSED,
    CHAN_STATE_OPEN_SENT,
    CHAN_STATE_OPEN,
    CHAN_STATE_CLOSING,
)


def check(cond: Bool, var msg: String) raises:
    if not cond:
        raise "FAIL: " + msg


def test_connection_initial_state() raises:
    """Connection starts in CLOSED state."""
    var conn = AMQPConnectionState()
    check((conn.is_closed()), "L23")
    check(not (conn.is_open()), "L24")
    check((conn.state() == CONN_STATE_CLOSED()), "L25")


def test_connection_state_transitions() raises:
    """Connection progresses through handshake states."""
    var conn = AMQPConnectionState()

    conn.set_state(CONN_STATE_START_SENT())
    check((conn.state() == CONN_STATE_START_SENT()), "L33")
    check(not (conn.is_closed()), "L34")

    conn.set_state(CONN_STATE_TUNE_RECEIVED())
    check((conn.state() == CONN_STATE_TUNE_RECEIVED()), "L37")

    conn.set_state(CONN_STATE_OPEN())
    check((conn.is_open()), "L40")
    check(not (conn.is_closed()), "L41")

    conn.set_state(CONN_STATE_CLOSING())
    check((conn.state() == CONN_STATE_CLOSING()), "L44")


def test_connection_negotiate() raises:
    """negotiate() stores server parameters and updates state."""
    var conn = AMQPConnectionState()
    conn.negotiate(channel_max=200, frame_max=131072, heartbeat=60)

    check((conn.channel_max() == 200), "L52")
    check((conn.frame_max() == 131072), "L53")
    check((conn.heartbeat() == 60), "L54")
    check((conn.state() == CONN_STATE_TUNE_RECEIVED()), "L55")


def test_channel_initial_state() raises:
    """Channel starts in CLOSED state."""
    var chan = AMQPChannelState(channel_id=1)
    check((chan.channel_id() == 1), "L61")
    check((chan.is_closed()), "L62")
    check(not (chan.is_open()), "L63")
    check((chan.state() == CHAN_STATE_CLOSED()), "L64")


def test_channel_state_transitions() raises:
    """Channel progresses through open/close states."""
    var chan = AMQPChannelState(channel_id=5)

    chan.set_state(CHAN_STATE_OPEN_SENT())
    check((chan.state() == CHAN_STATE_OPEN_SENT()), "L72")
    check(not (chan.is_closed()), "L73")

    chan.set_state(CHAN_STATE_OPEN())
    check((chan.is_open()), "L76")
    check(not (chan.is_closed()), "L77")

    chan.set_state(CHAN_STATE_CLOSING())
    check((chan.state() == CHAN_STATE_CLOSING()), "L80")
    check(not (chan.is_open()), "L81")


def test_multiple_channels_independent() raises:
    """Different channel IDs have independent states."""
    var c1 = AMQPChannelState(channel_id=1)
    var c2 = AMQPChannelState(channel_id=2)

    c1.set_state(CHAN_STATE_OPEN())
    check((c1.is_open()), "L90")
    check(not (c2.is_open()), "L91")

    c2.set_state(CHAN_STATE_CLOSING())
    check((c1.is_open()), "L94")
    check((c2.state() == CHAN_STATE_CLOSING()), "L95")


def main() raises:
    test_connection_initial_state()
    test_connection_state_transitions()
    test_connection_negotiate()
    test_channel_initial_state()
    test_channel_state_transitions()
    test_multiple_channels_independent()
    print("PHASE6_CONNECTION_STATE_TEST=PASS")
