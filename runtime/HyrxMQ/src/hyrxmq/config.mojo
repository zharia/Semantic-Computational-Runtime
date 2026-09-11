# HyrxMQ broker configuration.
#
# Product-layer configuration surface. Parsing is pure (no file I/O), so it
# is unit-testable without any filesystem or socket dependency.
#
# Policy (docs/CONFIGURATION.md, audit §17): explicit, typed, validated before
# startup, safe defaults, deterministic. `from_lines`/`from_key_values` apply
# typed coercion in source order (later lines win for duplicate keys).
# Unknown keys are REJECTED, empty values are REJECTED, and a malformed value
# for an integer key raises a key-named error (never panics the process).

from std.collections import List, Optional


# 0017 T4: one credentials-table entry (username + password). The broker
# validates SASL PLAIN responses against THIS table (default: admin/password);
# a mismatch is the normative connection.close 403 ACCESS_REFUSED.
struct UserRecord:
    """One configured broker user (username + password)."""

    var username: String
    var password: String

    def __init__(out self, var user: String, var passwd: String):
        self.username = user^
        self.password = passwd^

    def __copyinit__(out self, existing: Self):
        self.username = existing.username
        self.password = existing.password


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


def _require_text(var key: String, var value: String) raises -> String:
    """Trim a required text value; reject empty (audit §17: missing value)."""
    var t = String(value.strip())
    if len(t.bytes()) == 0:
        raise "config: empty value for '" + key + "'"
    return t


def _require_int(var key: String, var value: String) raises -> Int:
    """Coerce an integer value; reject empty and non-integer with a key-named
    error so the process never panics on a malformed config (audit §17)."""
    var t = value.strip()
    if len(t.bytes()) == 0:
        raise "config: empty value for '" + key + "'"
    try:
        return Int(t)
    except:
        raise "config: invalid integer for '" + key + "' (got '" + value + "')"


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
    # 0017 T4: SASL PLAIN credentials table (default: admin/password).
    var users: List[UserRecord]
    # 0018: pluggable storage. DEFAULT = "disabled" (zero fs writes/reads
    # anywhere); "memory" = the byte-identical RAM WAL; "file" = the
    # injectable WAL through the supplied FileSystemOps (storage_path
    # required). storage_path EMPTY = unset (a non-empty value in the
    # disabled/memory tiers is REJECTED in validate()).
    var storage_mode: String
    var storage_path: String

    # TCP-tier TLS (optional, off by default). When tls_enabled is True
    # and cert/key paths are set, accepted TCP connections are wrapped
    # with OpenSSL TLS before AMQP negotiation. Plaintext remains the
    # default so unconfigured binaries are byte-identical to before.
    var tls_enabled: Bool
    var tls_cert_path: String
    var tls_key_path: String

    # 0023: OPTIONAL WSS tier (browser transport) + the admin-HTTP tier
    # key for T3. Defaults are all OFF ("0"/"none") so unconfigured
    # binaries behave byte-identical to before.
    var wss_listen: Int
    var wss_tls_mode: String  # "none" | "injected" | "path"
    # Path cert model: the cert chain + key PEM paths (injected mode
    # carries the PEM bytes in the WssConfig struct instead; TLS config
    # never reaches disk through THIS layer — the tier itself uses the
    # injected ops seam). wss_tls_path EMPTY = unset (a non-empty value
    # in the none/injected modes is REJECTED in validate(), same shape
    # as storage_path above).
    var wss_tls_path: String
    var wss_tls_key_path: String
    # Browser origin allowlist (0023): the recorded extension point.
    var wss_origin_allowlist: List[String]
    # T3 (admin HTTP): port, default 0 = OFF.
    var admin_http_port: Int

    def __init__(out self):
        self.listen_host = "0.0.0.0"
        self.port = 5672
        self.max_connections = 1024
        self.frame_max = 131072
        self.heartbeat_secs = 60
        self.default_queue_capacity = 1024
        self.vhost = "/"
        self.node_name = "hyrxmq@localhost"
        self.users = List[UserRecord]()
        self.users.append(UserRecord("admin", "password"))
        self.storage_mode = "disabled"
        self.storage_path = ""
        self.tls_enabled = False
        self.tls_cert_path = ""
        self.tls_key_path = ""
        self.wss_listen = 0
        self.wss_tls_mode = "none"
        self.wss_tls_path = ""
        self.wss_tls_key_path = ""
        self.wss_origin_allowlist = List[String]()
        self.admin_http_port = 0

    def __copyinit__(out self, existing: Self):
        self.listen_host = existing.listen_host
        self.port = existing.port
        self.max_connections = existing.max_connections
        self.frame_max = existing.frame_max
        self.heartbeat_secs = existing.heartbeat_secs
        self.default_queue_capacity = existing.default_queue_capacity
        self.vhost = existing.vhost
        self.node_name = existing.node_name
        self.users = existing.users.copy()
        self.storage_mode = existing.storage_mode
        self.storage_path = existing.storage_path.copy()
        self.tls_enabled = existing.tls_enabled
        self.tls_cert_path = existing.tls_cert_path.copy()
        self.tls_key_path = existing.tls_key_path.copy()
        self.wss_listen = existing.wss_listen
        self.wss_tls_mode = existing.wss_tls_mode
        self.wss_tls_path = existing.wss_tls_path.copy()
        self.wss_tls_key_path = existing.wss_tls_key_path.copy()
        self.wss_origin_allowlist = existing.wss_origin_allowlist.copy()
        self.admin_http_port = existing.admin_http_port

    def apply(mut self, var key: String, var value: String) raises:
        """Assign one recognized key. Unknown keys are REJECTED (audit §17).

        Empty values are rejected. Integer keys coerce via `_require_int`,
        which raises a key-named error on malformed input rather than
        panicking the process.
        """
        if key == "listen_host":
            self.listen_host = _require_text(key, value)
        elif key == "port":
            self.port = _require_int(key, value)
        elif key == "max_connections":
            self.max_connections = _require_int(key, value)
        elif key == "frame_max":
            self.frame_max = _require_int(key, value)
        elif key == "heartbeat_secs":
            self.heartbeat_secs = _require_int(key, value)
        elif key == "default_queue_capacity":
            self.default_queue_capacity = _require_int(key, value)
        elif key == "vhost":
            self.vhost = _require_text(key, value)
        elif key == "node_name":
            self.node_name = _require_text(key, value)
        elif key == "storage_mode":
            var m = _require_text(key, value)
            if m != "disabled" and m != "memory" and m != "file":
                raise "config: invalid storage_mode '" + m + "' (disabled|memory|file)"
            self.storage_mode = m^
        elif key == "storage_path":
            self.storage_path = _require_text(key, value)
        elif key == "tls_enabled":
            var t = value.strip()
            if t == "true" or t == "1":
                self.tls_enabled = True
            elif t == "false" or t == "0":
                self.tls_enabled = False
            else:
                raise "config: invalid tls_enabled '" + t + "' (true|false|1|0)"
        elif key == "tls_cert_path":
            self.tls_cert_path = _require_text(key, value)
        elif key == "tls_key_path":
            self.tls_key_path = _require_text(key, value)
        elif key == "wss_listen":
            self.wss_listen = _require_int(key, value)
        elif key == "wss_tls_mode":
            var tm = _require_text(key, value)
            if tm != "none" and tm != "injected" and tm != "path":
                raise "config: invalid wss_tls_mode '" + tm + "' (none|injected|path)"
            self.wss_tls_mode = tm
        elif key == "wss_tls_path":
            self.wss_tls_path = _require_text(key, value)
        elif key == "wss_tls_key_path":
            self.wss_tls_key_path = _require_text(key, value)
        elif key == "wss_origin_allowlist":
            # Comma-separated list; empty entries are skipped. The broker
            # tier stays allow-all by default: a configured list only
            # RESTRICTS origins (0023 extensible origin policy).
            var raw = _require_text(key, value)
            var items = raw.split(",")
            var i = 0
            for item in items:
                var t = String(item.strip())
                if len(t.bytes()) != 0:
                    self.wss_origin_allowlist.append(t)
                i += 1
        elif key == "admin_http_port":
            self.admin_http_port = _require_int(key, value)
        else:
            raise "config: unknown field '" + key + "'"

    @staticmethod
    def from_key_values(var entries: List[KeyValuePair]) raises -> HyrxMQConfig:
        """Build a config by applying ordered key/value entries over defaults.

        Source order is preserved, so a later entry overrides an earlier
        duplicate (last-wins). Ownership: `entries` is consumed.
        """
        var cfg = HyrxMQConfig()
        var n = len(entries)
        for i in range(n):
            cfg.apply(entries[i].key, entries[i].value)
        while len(entries) > 0:
            _ = entries.pop()
        return cfg^

    @staticmethod
    def from_lines(var lines: List[String]) raises -> HyrxMQConfig:
        """Build a config from raw `key = value` text lines.

        Blank and '#' comment lines are skipped. Lines are applied in source
        order, so a later duplicate line wins (last-wins, deterministic).
        Ownership: `lines` consumed.
        """
        var cfg = HyrxMQConfig()
        var n = len(lines)
        for i in range(n):
            var raw = String(lines[i])
            if _is_comment(raw):
                continue
            var pair = parse_config_line(raw)
            cfg.apply(pair.key, pair.value)
        while len(lines) > 0:
            _ = lines.pop()
        return cfg^

    # NOTE: load_from_file(path) is intentionally NOT provided. A probe of this
    # environment's Mojo 1.0.0 stdlib found NO `os` (or `sys`) module resolvable
    # (`from os import Dir` -> "unable to locate module 'os'"), so a real disk
    # read is NOT AVAILABLE. Config is therefore exercised from in-memory lines;
    # env vars / CLI args are the override path at the entry-point layer. When
    # the stdlib lands, `load_from_file` should read bytes and delegate to
    # `from_lines`.

    def validate(ref self) raises:
        """Validate physical constraints. Raises if configuration is unsafe.

        Type/unknown-field/empty-value checks happen earlier, in `apply`
        (via `_require_int`/`_require_text`); this pass covers value ranges and
        defends against fields mutated directly (bypassing `apply`).
        """
        if len(self.listen_host.strip().bytes()) == 0:
            raise "config: listen_host must not be empty"
        if len(self.vhost.strip().bytes()) == 0:
            raise "config: vhost must not be empty"
        if len(self.node_name.strip().bytes()) == 0:
            raise "config: node_name must not be empty"
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
        if len(self.users) == 0:
            raise "config: users table must not be empty"
        for i in range(len(self.users)):
            if len(self.users[i].username.bytes()) == 0:
                raise "config: user entry has an empty username"
        # 0018: storage invariants (the disabled tier MUST stay fs-free).
        if self.storage_mode == "file":
            if len(self.storage_path.strip().bytes()) == 0:
                raise "config: file storage_mode requires a non-empty storage_path"
        else:
            if len(self.storage_path.strip().bytes()) != 0:
                raise "config: storage_path must be empty in the '" + self.storage_mode + "' storage_mode"
        # TCP-tier TLS invariants: tls_enabled=True requires both cert and key;
        # tls_enabled=False requires both paths empty.
        if self.tls_enabled:
            if len(self.tls_cert_path.strip().bytes()) == 0:
                raise "config: tls_enabled=true requires a non-empty tls_cert_path"
            if len(self.tls_key_path.strip().bytes()) == 0:
                raise "config: tls_enabled=true requires a non-empty tls_key_path"
        else:
            if len(self.tls_cert_path.strip().bytes()) != 0 or len(self.tls_key_path.strip().bytes()) != 0:
                raise "config: tls_cert_path / tls_key_path must be empty when tls_enabled is false"
        # 0023: wss + admin-HTTP invariants (OFF-by-default tiers).
        if self.wss_listen < 0 or self.wss_listen > 65535:
            raise "config: wss_listen out of range"
        if self.admin_http_port < 0 or self.admin_http_port > 65535:
            raise "config: admin_http_port out of range"
        if self.wss_tls_mode == "path":
            if len(self.wss_tls_path.strip().bytes()) == 0:
                raise "config: wss_tls_mode='path' requires a non-empty wss_tls_path (the cert chain PEM)"
            if len(self.wss_tls_key_path.strip().bytes()) == 0:
                raise "config: wss_tls_mode='path' requires a non-empty wss_tls_key_path"
        else:
            if len(self.wss_tls_path.strip().bytes()) != 0 or len(self.wss_tls_key_path.strip().bytes()) != 0:
                raise "config: wss_tls_path / wss_tls_key_path must be empty in the '" + self.wss_tls_mode + "' wss_tls_mode"
