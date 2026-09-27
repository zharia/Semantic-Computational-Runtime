# Input uplink — `scr_input_batch` (104_contract.md §5, 20 bytes packed) and
# the table-driven dispatch (AP-5) that turns a batch into player intents.
#
# Field order and packing match adapter/scr_godot_abi.h exactly:
#   0:3  f32 move_x | 4:7  f32 move_y | 8:11 f32 look_dx | 12:15 f32 look_dy
#  16 u8 jump | 17 u8 sprint | 18 u8 action_primary | 19 u8 action_secondary
# Natural alignment of {f32×4, u8×4} = 4, size = 20 (asserted by tests).

from std.collections import List

# --- Action codes (table keys; the applier is the only switch) ------------
comptime ACT_MOVE: Int = 0
comptime ACT_LOOK: Int = 1
comptime ACT_JUMP: Int = 2
comptime ACT_SPRINT: Int = 3
comptime ACT_PRIMARY: Int = 4
comptime ACT_SECONDARY: Int = 5
comptime ACT_COUNT: Int = 6

struct InputBatch(Copyable, Movable, Deinitable, ImplicitlyCopyable):
    var move_x: Float32
    var move_y: Float32
    var look_dx: Float32
    var look_dy: Float32
    var jump: UInt8
    var sprint: UInt8
    var action_primary: UInt8
    var action_secondary: UInt8

    def __init__(out self):
        self.move_x = 0.0
        self.move_y = 0.0
        self.look_dx = 0.0
        self.look_dy = 0.0
        self.jump = 0
        self.sprint = 0
        self.action_primary = 0
        self.action_secondary = 0

    def __deinit__(deinit self):
        pass


def idle_input() -> InputBatch:
    return InputBatch()


struct InputEvent(Copyable, Movable, Deinitable, ImplicitlyCopyable):
    """One table row: an action slot plus its payload for this batch."""
    var action: Int
    var value_x: Float32
    var value_y: Float32
    var flag: UInt8

    def __init__(out self, action: Int, value_x: Float32, value_y: Float32, flag: UInt8):
        self.action = action
        self.value_x = value_x
        self.value_y = value_y
        self.flag = flag

    def __deinit__(deinit self):
        pass


def build_input_table(batch: InputBatch) -> List[InputEvent]:
    """Fixed-order dispatch table: every tick evaluates exactly these rows.
    Row order is part of the deterministic pipeline (never data-dependent)."""
    var table = List[InputEvent]()
    table.append(InputEvent(ACT_MOVE, batch.move_x, batch.move_y, 0))
    table.append(InputEvent(ACT_LOOK, batch.look_dx, batch.look_dy, 0))
    table.append(InputEvent(ACT_JUMP, 0.0, 0.0, batch.jump))
    table.append(InputEvent(ACT_SPRINT, 0.0, 0.0, batch.sprint))
    table.append(InputEvent(ACT_PRIMARY, 0.0, 0.0, batch.action_primary))
    table.append(InputEvent(ACT_SECONDARY, 0.0, 0.0, batch.action_secondary))
    return table^


def table_size() -> Int:
    return ACT_COUNT
