# Hyrx-native message framing over TCP.
#
# Wire format: [4 bytes frame_type] [4 bytes payload_length] [N bytes payload]
# Big-endian byte order.
# This is Hyrx's internal frame format, NOT AMQP framing.

from std.collections import List

# Frame type constants
def FRAME_TYPE_MESSAGE() -> UInt32:
    return 0x01

def FRAME_TYPE_ACK() -> UInt32:
    return 0x02

def FRAME_TYPE_REJECT() -> UInt32:
    return 0x03

def FRAME_TYPE_HEARTBEAT() -> UInt32:
    return 0x04

def FRAME_TYPE_FLOW_CONTROL() -> UInt32:
    return 0x05

struct FrameHeader:
    """8-byte frame header: 4 bytes type + 4 bytes payload length."""
    var frame_type: UInt32
    var payload_length: UInt32

    def __init__(out self, frame_type: UInt32, payload_length: UInt32):
        self.frame_type = frame_type
        self.payload_length = payload_length

    def to_bytes(self) -> List[UInt8]:
        """Serialize header to 8 bytes big-endian."""
        var result = List[UInt8](capacity=8)
        result.append(UInt8((self.frame_type >> 24) & 0xFF))
        result.append(UInt8((self.frame_type >> 16) & 0xFF))
        result.append(UInt8((self.frame_type >> 8) & 0xFF))
        result.append(UInt8(self.frame_type & 0xFF))
        result.append(UInt8((self.payload_length >> 24) & 0xFF))
        result.append(UInt8((self.payload_length >> 16) & 0xFF))
        result.append(UInt8((self.payload_length >> 8) & 0xFF))
        result.append(UInt8(self.payload_length & 0xFF))
        return result^

    @staticmethod
    def from_bytes(data: List[UInt8]) raises -> FrameHeader:
        """Parse header from 8 bytes. Raises if data too short."""
        if len(data) < 8:
            raise Error("FrameHeader.from_bytes: need 8 bytes, got fewer")
        var frame_type: UInt32 = (UInt32(data[0]) << 24) | (UInt32(data[1]) << 16) | (UInt32(data[2]) << 8) | UInt32(data[3])
        var payload_length: UInt32 = (UInt32(data[4]) << 24) | (UInt32(data[5]) << 16) | (UInt32(data[6]) << 8) | UInt32(data[7])
        return FrameHeader(frame_type, payload_length)


struct Frame:
    """A complete Hyrx frame: header + payload."""
    var header: FrameHeader
    var payload: List[UInt8]

    def __init__(out self, var header: FrameHeader, var payload: List[UInt8]):
        self.header = header^
        self.payload = payload^

    def to_bytes(self) -> List[UInt8]:
        """Serialize full frame: header bytes + payload bytes."""
        var header_bytes = self.header.to_bytes()
        var result = List[UInt8](capacity=8 + len(self.payload))
        for i in range(len(header_bytes)):
            result.append(header_bytes[i])
        for i in range(len(self.payload)):
            result.append(self.payload[i])
        return result^

    @staticmethod
    def from_bytes(data: List[UInt8]) raises -> Frame:
        """Parse full frame from bytes. Raises if insufficient data."""
        if len(data) < 8:
            raise Error("Frame.from_bytes: need at least 8 bytes")
        var header_data = List[UInt8](capacity=8)
        for i in range(8):
            header_data.append(data[i])
        var header = FrameHeader.from_bytes(header_data^)
        if len(data) < 8 + Int(header.payload_length):
            raise Error("Frame.from_bytes: payload truncated")
        var payload = List[UInt8](capacity=Int(header.payload_length))
        for i in range(8, 8 + Int(header.payload_length)):
            payload.append(data[i])
        return Frame(header^, payload^)

    @staticmethod
    def from_raw(frame_type: UInt32, var payload: List[UInt8]) -> Frame:
        """Construct a frame from type and payload."""
        var header = FrameHeader(frame_type, UInt32(len(payload)))
        return Frame(header^, payload^)
