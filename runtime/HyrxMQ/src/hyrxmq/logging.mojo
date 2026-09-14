# HyrxMQ structured logging (Phase 10).
#
# One-line JSON log records plus the level-filtering primitives. Pure
# formatting and ranking: no I/O, no global sink, no authority. Callers
# decide where a rendered record goes; this module only renders/filters.

from std.collections import List

from std.time import monotonic


def _json_escape(value: String) -> String:
    """Escape a string for a JSON double-quoted value.

    Same rule as ``BrokerStatus._json_escape`` (``"`` and ``\\``) plus the
    control characters that would break single-line framing (``\\n``,
    ``\\r``, ``\\t``)."""
    var out = String()
    for ch in value:
        if ch == "\"":
            out += "\\\""
        elif ch == "\\":
            out += "\\\\"
        elif ch == "\n":
            out += "\\n"
        elif ch == "\r":
            out += "\\r"
        elif ch == "\t":
            out += "\\t"
        else:
            out += ch
    return out^


def log_json(
    level: String,
    component: String,
    message: String,
    fields_json: String,
    correlation_id: String,
) -> String:
    """Render one single-line JSON log record.

    ``fields_json`` is the caller-supplied body of the ``fields`` object,
    e.g. ``"\\"queue\\":\\"q1\\""``; it is spliced verbatim (the caller owns
    its validity). The string values (level/component/message) are escaped
    here. ``correlation_id`` ties log lines across a request/connection."""
    var parts = List[String]()
    parts.append("\"timestamp\":" + String(monotonic()))
    parts.append("\"level\":\"" + _json_escape(level) + "\"")
    parts.append("\"component\":\"" + _json_escape(component) + "\"")
    parts.append("\"correlation_id\":\"" + _json_escape(correlation_id) + "\"")
    parts.append("\"message\":\"" + _json_escape(message) + "\"")
    parts.append("\"fields\":{" + fields_json + "}")
    return "{" + ",".join(parts) + "}"


def log_json_simple(
    level: String,
    component: String,
    message: String,
    fields_json: String,
) -> String:
    """Compatibility shim: no correlation_id."""
    return log_json(level, component, message, fields_json, "")


def redact_secret(var value: String) -> String:
    """Mask a secret for logging: keep only a 2-char head/tail witness.

    Values of length <= 4 collapse to ``"***"`` (too short to reveal any
    prefix/suffix without disclosing most of the secret). Otherwise return
    ``first 2 chars + "***" + last 2 chars`` (e.g. ``"password"`` ->
    ``"pa***rd"``). The result is deliberately NOT reversible: the middle
    (the bulk of any real secret) is discarded."""
    var n = len(value.bytes())
    if n <= 4:
        return "***"
    var head = String(value[byte = 0:2])
    var tail = String(value[byte = n - 2 : n])
    return head + "***" + tail


def redact_fields_json(var fields_json: String) -> String:
    """Redact a ``fields`` body when it may carry a sensitive key.

    Parsing JSON is heavy, so this is a conservative SCAN, not a parser: if
    the (case-insensitive) body contains any known-sensitive key name
    (``password``, ``passwd``, ``secret``, ``token``, ``key``) the ENTIRE
    fields object is replaced with ``{"redacted":true}`` rather than risk
    splicing a credential verbatim. Otherwise the body is passed through
    unchanged."""
    var lower = fields_json.lower()
    if (
        lower.find("password") >= 0
        or lower.find("passwd") >= 0
        or lower.find("secret") >= 0
        or lower.find("token") >= 0
        or lower.find("key") >= 0
    ):
        return "{\"redacted\":true}"
    return fields_json^


def log_json_redacted(
    level: String,
    component: String,
    message: String,
    var fields_json: String,
    correlation_id: String,
) -> String:
    """``log_json`` with sensitive ``fields`` redacted first.

    Signature mirrors ``log_json`` (same record shape, same escaping); only
    the fields body is pre-filtered through ``redact_fields_json``. Redaction
    is opt-in: ``log_json`` itself is unchanged for callers that own their
    field safety.

    ``redact_fields_json`` returns either the caller's inner body unchanged or
    a COMPLETE object (``{"redacted":true}``). ``log_json`` wraps its argument
    in ``"fields":{...}``, so the redacted object's outer braces are stripped
    before splicing — otherwise the record would carry ``fields:{{...}}`` and
    stop being valid JSON."""
    var fields = redact_fields_json(fields_json^)
    var n = len(fields.bytes())
    if (
        n >= 2
        and String(fields[byte = 0:1]) == "{"
        and String(fields[byte = n - 1 : n]) == "}"
    ):
        var stripped = String(fields[byte = 1 : n - 1])
        fields = stripped^
    return log_json(level, component, message, fields^, correlation_id)


def log_level_rank(level: String) -> Int:
    """Severity rank: DEBUG=0, INFO=1, WARN=2, ERROR=3; unknown = -1."""
    if level == "DEBUG":
        return 0
    if level == "INFO":
        return 1
    if level == "WARN":
        return 2
    if level == "ERROR":
        return 3
    return -1


def should_log(min_level: String, level: String) -> Bool:
    """True when ``level`` is at or above ``min_level``.

    An unknown ``level`` is never logged; an unknown ``min_level`` ranks
    below every known level, so every known level passes."""
    var rank = log_level_rank(level)
    if rank < 0:
        return False
    return rank >= log_level_rank(min_level)
