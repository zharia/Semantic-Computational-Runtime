# Tests for flow control.

from hyrx.transport.flow_control import FlowWindow

from hyrx.testing import check

def test_initial_state() raises:
    var fw = FlowWindow(1024)
    check(fw.send_window() == 1024, "L7 expect: fw.send_window() == 1024")
    check(fw.recv_window() == 1024, "L8 expect: fw.recv_window() == 1024")
    check(fw.max_window() == 1024, "L9 expect: fw.max_window() == 1024")
    check(not fw.is_blocked(), "L10 expect: not fw.is_blocked()")
    check(fw.can_send(), "L11 expect: fw.can_send()")
    print("  initial state: OK")

def test_record_send() raises:
    var fw = FlowWindow(1000)
    fw.record_send(300)
    check(fw.send_window() == 700, "L17 expect: fw.send_window() == 700")
    check(fw.can_send(), "L18 expect: fw.can_send()")

    fw.record_send(700)
    check(fw.send_window() == 0, "L21 expect: fw.send_window() == 0")
    check(not fw.can_send(), "L22 expect: not fw.can_send()")
    check(fw.is_blocked(), "L23 expect: fw.is_blocked()")
    print("  record send: OK")

def test_adjust_send_window() raises:
    var fw = FlowWindow(1000)
    fw.record_send(1000)
    check(not fw.can_send(), "L29 expect: not fw.can_send()")
    check(fw.is_blocked(), "L30 expect: fw.is_blocked()")

    fw.adjust_send_window(500)
    check(fw.send_window() == 500, "L33 expect: fw.send_window() == 500")
    check(fw.can_send(), "L34 expect: fw.can_send()")
    check(not fw.is_blocked(), "L35 expect: not fw.is_blocked()")
    print("  adjust send window: OK")

def test_record_recv() raises:
    var fw = FlowWindow(1000)
    fw.record_recv(400)
    check(fw.recv_window() == 600, "L41 expect: fw.recv_window() == 600")
    print("  record recv: OK")

def test_grant_recv_window() raises:
    var fw = FlowWindow(1000)
    fw.record_recv(900)
    check(fw.recv_window() == 100, "L47 expect: fw.recv_window() == 100")

    fw.grant_recv_window(2000)
    check(fw.recv_window() == 2000, "L50 expect: fw.recv_window() == 2000")
    print("  grant recv window: OK")

def test_reset() raises:
    var fw = FlowWindow(500)
    fw.record_send(400)
    fw.record_recv(300)
    check(fw.send_window() == 100, "L57 expect: fw.send_window() == 100")
    check(fw.recv_window() == 200, "L58 expect: fw.recv_window() == 200")

    fw.reset()
    check(fw.send_window() == 500, "L61 expect: fw.send_window() == 500")
    check(fw.recv_window() == 500, "L62 expect: fw.recv_window() == 500")
    check(not fw.is_blocked(), "L63 expect: not fw.is_blocked()")
    print("  reset: OK")

def test_multiple_windows() raises:
    var fw1 = FlowWindow(100)
    var fw2 = FlowWindow(200)
    fw1.record_send(50)
    check(fw1.send_window() == 50, "L70 expect: fw1.send_window() == 50")
    check(fw2.send_window() == 200, "L71 expect: fw2.send_window() == 200")
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
