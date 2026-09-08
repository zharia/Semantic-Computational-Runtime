# Flow control for TCP connections.
#
# Tracks send/receive windows for backpressure.
# Protocol: sender decrements window on send, receiver grants window via
# FLOW_CONTROL frames. Sender blocks when window hits zero.

struct FlowWindow:
    """Tracks flow control window for a single connection."""
    var _send_window: Int
    var _recv_window: Int
    var _max_window: Int
    var _blocked: Bool

    def __init__(out self, max_window: Int):
        self._send_window = max_window
        self._recv_window = max_window
        self._max_window = max_window
        self._blocked = False

    def can_send(ref self) -> Bool:
        """Check if send is allowed."""
        return self._send_window > 0

    def record_send(mut self, bytes_sent: Int):
        """Decrement send window after sending bytes."""
        self._send_window -= bytes_sent
        if self._send_window <= 0:
            self._blocked = True

    def record_recv(mut self, bytes_received: Int):
        """Decrement recv window after receiving bytes."""
        self._recv_window -= bytes_received

    def adjust_send_window(mut self, new_window: Int):
        """Update send window (from remote FLOW_CONTROL frame)."""
        self._send_window = new_window
        if self._send_window > 0:
            self._blocked = False

    def grant_recv_window(mut self, window_size: Int):
        """Update recv window (local grant to send to remote)."""
        self._recv_window = window_size

    def send_window(ref self) -> Int:
        return self._send_window

    def recv_window(ref self) -> Int:
        return self._recv_window

    def max_window(ref self) -> Int:
        return self._max_window

    def is_blocked(ref self) -> Bool:
        return self._blocked

    def reset(mut self):
        """Reset both windows to max."""
        self._send_window = self._max_window
        self._recv_window = self._max_window
        self._blocked = False
