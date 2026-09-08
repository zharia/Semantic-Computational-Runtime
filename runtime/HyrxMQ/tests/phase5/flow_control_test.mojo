# Tests for flow control.

from hyrx.transport.flow_control import FlowWindow

def test_initial_state() raises:
    var fw = FlowWindow(1024)
    assert fw.send_window() == 1024
    assert fw.recv_window() == 1024
    assert fw.max_window() == 1024
    assert not fw.is_blocked()
    assert fw.can_send()
    print("  initial state: OK")

def test_record_send() raises:
    var fw = FlowWindow(1000)
    fw.record_send(300)
    assert fw.send_window() == 700
    assert fw.can_send()

    fw.record_send(700)
    assert fw.send_window() == 0
    assert not fw.can_send()
    assert fw.is_blocked()
    print("  record send: OK")

def test_adjust_send_window() raises:
    var fw = FlowWindow(1000)
    fw.record_send(1000)
    assert not fw.can_send()
    assert fw.is_blocked()

    fw.adjust_send_window(500)
    assert fw.send_window() == 500
    assert fw.can_send()
    assert not fw.is_blocked()
    print("  adjust send window: OK")

def test_record_recv() raises:
    var fw = FlowWindow(1000)
    fw.record_recv(400)
    assert fw.recv_window() == 600
    print("  record recv: OK")

def test_grant_recv_window() raises:
    var fw = FlowWindow(1000)
    fw.record_recv(900)
    assert fw.recv_window() == 100

    fw.grant_recv_window(2000)
    assert fw.recv_window() == 2000
    print("  grant recv window: OK")

def test_reset() raises:
    var fw = FlowWindow(500)
    fw.record_send(400)
    fw.record_recv(300)
    assert fw.send_window() == 100
    assert fw.recv_window() == 200

    fw.reset()
    assert fw.send_window() == 500
    assert fw.recv_window() == 500
    assert not fw.is_blocked()
    print("  reset: OK")

def test_multiple_windows() raises:
    var fw1 = FlowWindow(100)
    var fw2 = FlowWindow(200)
    fw1.record_send(50)
    assert fw1.send_window() == 50
    assert fw2.send_window() == 200
    print("  multiple windows: OK")

def main() raises:
    print("FLOW_CONTROL_TEST")
    test_initial_state()
    test_record_send()
    test_adjust_send_window()
    test_record_recv()
    test_grant_recv_window()
    test_reset()
    test_multiple_windows()
    print("FLOW_CONTROL_TEST=PASS")
