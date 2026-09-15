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
struct UserRecord(Copyable):
    """One configured broker user (username + password)."""

    var username: String
    var password: String
    # 0025 M2: per-vhost permissions (configure, write, read).
    var vhost: String
    var can_configure: Bool
    var can_write: Bool
    var can_read: Bool

    def __init__(out self, var user: String, var passwd: String):
        self.username = user^
        self.password = passwd^
        self.vhost = "/"
        self.can_configure = True
        self.can_write = True
        self.can_read = True

    def __init__(
        out self,
        var user: String,
        var passwd: String,
        var user_vhost: String,
        user_configure: Bool,
        user_write: Bool,
        user_read: Bool,
    ):
        self.username = user^
        self.password = passwd^
        self.vhost = user_vhost^
        self.can_configure = user_configure
        self.can_write = user_write
        self.can_read = user_read

    def __copyinit__(out self, existing: Self):
        self.username = existing.username
        self.password = existing.password
        self.vhost = existing.vhost
        self.can_configure = existing.can_configure
        self.can_write = existing.can_write
        self.can_read = existing.can_read


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


def _parse_user_entry(var entry: String) raises -> UserRecord:
    """Parse one HYRXMQ_USERS entry into a UserRecord.

    Shape: `username:password` or `username:password:vhost` or
    `username:password:vhost:configure,write,read`. vhost defaults to "/";
    omitted perms default to all three true. A malformed entry (wrong field
    count, empty username/password) raises naming the entry.
    """
    var parts = entry.split(":")
    if len(parts) < 2 or len(parts) > 4:
        raise "config: malformed HYRXMQ_USERS entry '" + entry + "'"
    var user = String(parts[0].strip())
    var passwd = String(parts[1].strip())
    if len(user.bytes()) == 0:
        raise "config: HYRXMQ_USERS entry '" + entry + "' has an empty username"
    if len(passwd.bytes()) == 0:
        raise "config: HYRXMQ_USERS entry '" + entry + "' has an empty password"
    var vhost = String("/")
    if len(parts) >= 3:
        var v = String(parts[2].strip())
        if len(v.bytes()) > 0:
            vhost = v
    var can_configure = True
    var can_write = True
    var can_read = True
    if len(parts) == 4:
        can_configure = False
        can_write = False
        can_read = False
        var perms = String(parts[3].strip())
        if len(perms.bytes()) == 0:
            raise "config: HYRXMQ_USERS entry '" + entry + "' has an empty permission list"
        var items = perms.split(",")
        for j in range(len(items)):
            var p = String(items[j].strip())
            if len(p.bytes()) == 0:
                continue
            if p == "configure":
                can_configure = True
            elif p == "write":
                can_write = True
            elif p == "read":
                can_read = True
            else:
                raise (
                    "config: HYRXMQ_USERS entry '"
                    + entry
                    + "' has unknown permission '"
                    + p
                    + "' (configure|write|read)"
                )
    return UserRecord(user^, passwd^, vhost^, can_configure, can_write, can_read)


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
    # TLS certificate validation policy. `tls_verify_peer` (default True)
    # requires the peer chain to be verified; `tls_allow_self_signed`
    # (default False) is only meaningful while verifying and is rejected
    # when verification is off. `tls_ca_path` is the trust anchor used by
    # peer verification (EMPTY = fall back to the configured cert chain).
    var tls_verify_peer: Bool
    var tls_allow_self_signed: Bool
    var tls_ca_path: String

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
    # 0025: resource governance — hard limits.
    var max_message_size: Int
    var max_queues: Int
    var max_exchanges: Int
    var max_channels_per_connection: Int
    var idle_timeout_secs: Int
    var max_memory_bytes: Int
    # 0026: per-connection backpressure — max unacked deliveries before
    # the broker stops pushing to that connection.
    var max_unacked: Int
    # M2.1: sliding-window auth-failure rate limit — SASL failures
    # permitted per 60s window before new logins are refused.
    var max_auth_failures_per_minute: Int

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
        self.tls_verify_peer = True
        self.tls_allow_self_signed = False
        self.tls_ca_path = ""
        self.wss_listen = 0
        self.wss_tls_mode = "none"
        self.wss_tls_path = ""
        self.wss_tls_key_path = ""
        self.wss_origin_allowlist = List[String]()
        self.admin_http_port = 0
        self.max_message_size = 134217728
        self.max_queues = 65535
        self.max_exchanges = 65535
        self.max_channels_per_connection = 65535
        self.idle_timeout_secs = 300
        self.max_memory_bytes = 536870912
        self.max_unacked = 1000
        self.max_auth_failures_per_minute = 60

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
        self.tls_verify_peer = existing.tls_verify_peer
        self.tls_allow_self_signed = existing.tls_allow_self_signed
        self.tls_ca_path = existing.tls_ca_path.copy()
        self.wss_listen = existing.wss_listen
        self.wss_tls_mode = existing.wss_tls_mode
        self.wss_tls_path = existing.wss_tls_path.copy()
        self.wss_tls_key_path = existing.wss_tls_key_path.copy()
        self.wss_origin_allowlist = existing.wss_origin_allowlist.copy()
        self.admin_http_port = existing.admin_http_port
        self.max_message_size = existing.max_message_size
        self.max_queues = existing.max_queues
        self.max_exchanges = existing.max_exchanges
        self.max_channels_per_connection = existing.max_channels_per_connection
        self.idle_timeout_secs = existing.idle_timeout_secs
        self.max_memory_bytes = existing.max_memory_bytes
        self.max_unacked = existing.max_unacked
        self.max_auth_failures_per_minute = existing.max_auth_failures_per_minute

    def copy(ref self) -> Self:
        """Return an independent copy (the explicit-copy seam; the same field
        transfer as __copyinit__, mirroring the project's `copy()` convention
        for non-implicitly-copyable types)."""
        var c = HyrxMQConfig()
        c.listen_host = self.listen_host.copy()
        c.port = self.port
        c.max_connections = self.max_connections
        c.frame_max = self.frame_max
        c.heartbeat_secs = self.heartbeat_secs
        c.default_queue_capacity = self.default_queue_capacity
        c.vhost = self.vhost.copy()
        c.node_name = self.node_name.copy()
        c.users = self.users.copy()
        c.storage_mode = self.storage_mode.copy()
        c.storage_path = self.storage_path.copy()
        c.tls_enabled = self.tls_enabled
        c.tls_cert_path = self.tls_cert_path.copy()
        c.tls_key_path = self.tls_key_path.copy()
        c.tls_verify_peer = self.tls_verify_peer
        c.tls_allow_self_signed = self.tls_allow_self_signed
        c.tls_ca_path = self.tls_ca_path.copy()
        c.wss_listen = self.wss_listen
        c.wss_tls_mode = self.wss_tls_mode.copy()
        c.wss_tls_path = self.wss_tls_path.copy()
        c.wss_tls_key_path = self.wss_tls_key_path.copy()
        c.wss_origin_allowlist = self.wss_origin_allowlist.copy()
        c.admin_http_port = self.admin_http_port
        c.max_message_size = self.max_message_size
        c.max_queues = self.max_queues
        c.max_exchanges = self.max_exchanges
        c.max_channels_per_connection = self.max_channels_per_connection
        c.idle_timeout_secs = self.idle_timeout_secs
        c.max_memory_bytes = self.max_memory_bytes
        c.max_unacked = self.max_unacked
        c.max_auth_failures_per_minute = self.max_auth_failures_per_minute
        return c^

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
        elif key == "tls_verify_peer":
            var tv = value.strip()
            if tv == "true" or tv == "1":
                self.tls_verify_peer = True
            elif tv == "false" or tv == "0":
                self.tls_verify_peer = False
            else:
                raise "config: invalid tls_verify_peer '" + tv + "' (true|false|1|0)"
        elif key == "tls_allow_self_signed":
            var ts = value.strip()
            if ts == "true" or ts == "1":
                self.tls_allow_self_signed = True
            elif ts == "false" or ts == "0":
                self.tls_allow_self_signed = False
            else:
                raise "config: invalid tls_allow_self_signed '" + ts + "' (true|false|1|0)"
        elif key == "tls_ca_path":
            self.tls_ca_path = _require_text(key, value)
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
        elif key == "max_message_size":
            self.max_message_size = _require_int(key, value)
        elif key == "max_queues":
            self.max_queues = _require_int(key, value)
        elif key == "max_exchanges":
            self.max_exchanges = _require_int(key, value)
        elif key == "max_channels_per_connection":
            self.max_channels_per_connection = _require_int(key, value)
        elif key == "idle_timeout_secs":
            self.idle_timeout_secs = _require_int(key, value)
        elif key == "max_memory_bytes":
            self.max_memory_bytes = _require_int(key, value)
        elif key == "max_unacked":
            self.max_unacked = _require_int(key, value)
        elif key == "max_auth_failures_per_minute":
            self.max_auth_failures_per_minute = _require_int(key, value)
        else:
            raise "config: unknown field '" + key + "'"

    def parse_users_env(mut self, var spec: String) raises:
        """Replace the users table from the HYRXMQ_USERS environment spec.

        Format (comma-separated entries; whitespace trimmed):
          username:password
          username:password:vhost
          username:password:vhost:configure,write,read
        vhost defaults to "/"; omitted perms default to all three (true). An
        empty spec is a NO-OP (the admin/password default stands). A malformed
        entry raises an error naming the entry. A non-empty spec REPLACES the
        default users list, so the operator's env fully controls credentials.
        """
        var trimmed = String(spec.strip())
        if len(trimmed.bytes()) == 0:
            return
        var tokens = trimmed.split(",")
        var parsed = List[UserRecord]()
        var current = String("")
        for i in range(len(tokens)):
            var tok = String(tokens[i].strip())
            if len(tok.bytes()) == 0:
                continue
            if tok.find(":") >= 0:
                if len(current.bytes()) > 0:
                    parsed.append(_parse_user_entry(current))
                current = tok
            else:
                if len(current.bytes()) == 0:
                    raise (
                        "config: malformed HYRXMQ_USERS entry '"
                        + tok
                        + "' (expected username:password)"
                    )
                current = current + "," + tok
        if len(current.bytes()) > 0:
            parsed.append(_parse_user_entry(current))
        self.users = parsed^

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
        # tls_enabled=False requires both paths empty. Certificate-validation
        # policy: allowing self-signed certs is only meaningful while peer
        # verification is on, so it is rejected when tls_verify_peer is false.
        if self.tls_enabled:
            if len(self.tls_cert_path.strip().bytes()) == 0:
                raise "config: tls_enabled=true requires a non-empty tls_cert_path"
            if len(self.tls_key_path.strip().bytes()) == 0:
                raise "config: tls_enabled=true requires a non-empty tls_key_path"
        else:
            if len(self.tls_cert_path.strip().bytes()) != 0 or len(self.tls_key_path.strip().bytes()) != 0:
                raise "config: tls_cert_path / tls_key_path must be empty when tls_enabled is false"
            if len(self.tls_ca_path.strip().bytes()) != 0:
                raise "config: tls_ca_path must be empty when tls_enabled is false"
        if self.tls_allow_self_signed and not self.tls_verify_peer:
            raise "config: tls_allow_self_signed requires tls_verify_peer=true"
        # 0023: wss + admin-HTTP invariants (OFF-by-default tiers).
        if self.wss_listen < 0 or self.wss_listen > 65535:
            raise "config: wss_listen out of range"
        if self.admin_http_port < 0 or self.admin_http_port > 65535:
            raise "config: admin_http_port out of range"
        if self.max_message_size <= 0:
            raise "config: max_message_size must be positive"
        if self.max_queues <= 0:
            raise "config: max_queues must be positive"
        if self.max_exchanges <= 0:
            raise "config: max_exchanges must be positive"
        if self.max_channels_per_connection <= 0:
            raise "config: max_channels_per_connection must be positive"
        if self.idle_timeout_secs < 0:
            raise "config: idle_timeout_secs must not be negative"
        if self.max_memory_bytes <= 0:
            raise "config: max_memory_bytes must be positive"
        if self.max_unacked <= 0:
            raise "config: max_unacked must be positive"
        if self.max_auth_failures_per_minute <= 0:
            raise "config: max_auth_failures_per_minute must be positive"
        if self.wss_tls_mode == "path":
            if len(self.wss_tls_path.strip().bytes()) == 0:
                raise "config: wss_tls_mode='path' requires a non-empty wss_tls_path (the cert chain PEM)"
            if len(self.wss_tls_key_path.strip().bytes()) == 0:
                raise "config: wss_tls_mode='path' requires a non-empty wss_tls_key_path"
        else:
            if len(self.wss_tls_path.strip().bytes()) != 0 or len(self.wss_tls_key_path.strip().bytes()) != 0:
                raise "config: wss_tls_path / wss_tls_key_path must be empty in the '" + self.wss_tls_mode + "' wss_tls_mode"
