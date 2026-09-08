# HyrxMQ broker configuration.
#
# Product-layer configuration surface. Parsing is pure (no file I/O), so it
# is unit-testable without any filesystem or socket dependency.
#
# Policy (docs/CONFIGURATION.md): explicit, typed, validated before startup,
# safe defaults, deterministic. `from_lines`/`from_key_values` apply typed
# coercion; a non-integer value for an integer key raises.

from std.collections import List, Optional


struct KeyValuePair:
    """A single parsed `key = value` configuration entry."""

    var key: String
    var value: String

    def __init__(out self, var k: String, var v: String):
        self.key = k^
        self.value = v^

    def __copyinit__(out self, existing: Self):
        self.key = existing.key
        self.value = existing.value


def parse_config_line(var line: String) raises -> KeyValuePair:
    """Split `key = value` into trimmed parts.

    Raises if the line has no '=' or an empty key. Comment lines must be
    filtered by the caller (see HyrxMQConfig.from_lines).
    """
    var eq = line.find("=")
    if eq < 0:
        raise "config line missing '=': " + line
    var k = String(line[byte=0:eq].strip())
    var v = String(line[byte = eq + 1 : len(line.bytes())].strip())
    if len(k.bytes()) == 0:
        raise "config line has empty key: " + line
    return KeyValuePair(k^, v^)


def _is_comment(var line: String) -> Bool:
    """True if the trimmed line is blank or starts with '#'."""
    var t = line.strip()
    if len(t.bytes()) == 0:
        return True
    return String(t[codepoint=0]) == "#"


struct HyrxMQConfig:
    """Standalone broker configuration with safe defaults."""

    var listen_host: String
    var port: Int
    var max_connections: Int
    var frame_max: Int
    var heartbeat_secs: Int
    var default_queue_capacity: Int
    var vhost: String
    var node_name: String

    def __init__(out self):
        self.listen_host = "0.0.0.0"
        self.port = 5672
        self.max_connections = 1024
        self.frame_max = 131072
        self.heartbeat_secs = 60
        self.default_queue_capacity = 1024
        self.vhost = "/"
        self.node_name = "hyrxmq@localhost"

    def __copyinit__(out self, existing: Self):
        self.listen_host = existing.listen_host
        self.port = existing.port
        self.max_connections = existing.max_connections
        self.frame_max = existing.frame_max
        self.heartbeat_secs = existing.heartbeat_secs
        self.default_queue_capacity = existing.default_queue_capacity
        self.vhost = existing.vhost
        self.node_name = existing.node_name

    def apply(mut self, var key: String, var value: String) raises:
        """Assign one recognized key. Unknown keys are ignored (forward compat).

        Integer keys coerce via Int(); malformed values raise.
        """
        if key == "listen_host":
            self.listen_host = value
        elif key == "port":
            self.port = Int(value)
        elif key == "max_connections":
            self.max_connections = Int(value)
        elif key == "frame_max":
            self.frame_max = Int(value)
        elif key == "heartbeat_secs":
            self.heartbeat_secs = Int(value)
        elif key == "default_queue_capacity":
            self.default_queue_capacity = Int(value)
        elif key == "vhost":
            self.vhost = value
        elif key == "node_name":
            self.node_name = value
        # unknown keys intentionally ignored

    @staticmethod
    def from_key_values(var entries: List[KeyValuePair]) raises -> HyrxMQConfig:
        """Build a config by applying ordered key/value entries over defaults.

        Ownership: `entries` is consumed.
        """
        var cfg = HyrxMQConfig()
        while len(entries) > 0:
            var kv = entries.pop()
            cfg.apply(kv.key, kv.value)
        return cfg^

    @staticmethod
    def from_lines(var lines: List[String]) raises -> HyrxMQConfig:
        """Build a config from raw `key = value` text lines.

        Blank and '#' comment lines are skipped. Ownership: `lines` consumed.
        """
        var cfg = HyrxMQConfig()
        while len(lines) > 0:
            var raw = lines.pop()
            if _is_comment(raw):
                continue
            var pair = parse_config_line(raw^)
            cfg.apply(pair.key, pair.value)
        return cfg^

    # NOTE: load_from_file(path) is intentionally NOT provided. Mojo 1.0 does
    # not expose a portable `os`/`File` module in this environment, so a real
    # file read is not available; config loading is exercised from in-memory
    # lines instead. When the stdlib lands, `load_from_file` should read bytes
    # and delegate to `from_lines`.

    def validate(ref self) raises:
        """Validate physical constraints. Raises if configuration is unsafe."""
        if self.port < 0 or self.port > 65535:
            raise "config: port out of range"
        if self.max_connections <= 0:
            raise "config: max_connections must be positive"
        if self.frame_max <= 0:
            raise "config: frame_max must be positive"
        if self.default_queue_capacity <= 0:
            raise "config: default_queue_capacity must be positive"
        if self.heartbeat_secs < 0:
            raise "config: heartbeat_secs must not be negative"
