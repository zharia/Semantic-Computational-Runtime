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
) -> String:
    """Render one single-line JSON log record.

    ``fields_json`` is the caller-supplied body of the ``fields`` object,
    e.g. ``"\\"queue\\":\\"q1\\""``; it is spliced verbatim (the caller owns
    its validity). The string values (level/component/message) are escaped
    here."""
    var parts = List[String]()
    parts.append("\"timestamp\":" + String(monotonic()))
    parts.append("\"level\":\"" + _json_escape(level) + "\"")
    parts.append("\"component\":\"" + _json_escape(component) + "\"")
    parts.append("\"message\":\"" + _json_escape(message) + "\"")
    parts.append("\"fields\":{" + fields_json + "}")
    return "{" + ",".join(parts) + "}"


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
