# Broker status snapshot (Phase 7 product surface).
#
# Plain data assembled by HyrxMQBroker.status(). No behaviour, no authority:
# the engine owns the state; this is a read-only projection for health/status.

from std.collections import List

from hyrx.core.pool_stats import PoolStats


struct BrokerStatus:
    """A point-in-time projection of broker state for management/health."""

    var node_name: String
    var vhost: String
    var uptime: Bool
    var ready: Bool
    var listening: Bool
    var queues: Int
    var consumers: Int
    var messages_published: Int
    var messages_delivered: Int
    var messages_acked: Int
    # Tier 1 additions.
    var messages_rejected: Int
    var active_connections: Int
    var refused_connections: Int
    var content_errors: Int
    var pool_stats: PoolStats

    def __init__(out self):
        self.node_name = ""
        self.vhost = ""
        self.uptime = False
        self.ready = False
        self.listening = False
        self.queues = 0
        self.consumers = 0
        self.messages_published = 0
        self.messages_delivered = 0
        self.messages_acked = 0
        self.messages_rejected = 0
        self.active_connections = 0
        self.refused_connections = 0
        self.content_errors = 0
        self.pool_stats = PoolStats(0, 0, 0, 0)

    def __copyinit__(out self, existing: Self):
        self.node_name = existing.node_name
        self.vhost = existing.vhost
        self.uptime = existing.uptime
        self.ready = existing.ready
        self.listening = existing.listening
        self.queues = existing.queues
        self.consumers = existing.consumers
        self.messages_published = existing.messages_published
        self.messages_delivered = existing.messages_delivered
        self.messages_acked = existing.messages_acked
        self.messages_rejected = existing.messages_rejected
        self.active_connections = existing.active_connections
        self.refused_connections = existing.refused_connections
        self.content_errors = existing.content_errors
        self.pool_stats = existing.pool_stats

    @staticmethod
    def _json_escape(value: String) -> String:
        """Escape the JSON string delimiters `"` and `\\`."""
        var out = String()
        for ch in value:
            if ch == "\"":
                out += "\\\""
            elif ch == "\\":
                out += "\\\\"
            else:
                out += ch
        return out^

    @staticmethod
    def _bool_gauge(value: Bool) -> String:
        return "1" if value else "0"

    def to_prometheus(ref self) -> String:
        """Prometheus text exposition format (metrics from the snapshot)."""
        var parts = List[String]()
        parts.append("# HELP hyrxmq_uptime Broker uptime")
        parts.append("# TYPE hyrxmq_uptime gauge")
        parts.append("hyrxmq_uptime " + Self._bool_gauge(self.uptime))
        parts.append("# HELP hyrxmq_ready Broker readiness")
        parts.append("# TYPE hyrxmq_ready gauge")
        parts.append("hyrxmq_ready " + Self._bool_gauge(self.ready))
        parts.append("# HELP hyrxmq_listening Broker listener state")
        parts.append("# TYPE hyrxmq_listening gauge")
        parts.append("hyrxmq_listening " + Self._bool_gauge(self.listening))
        parts.append("# HELP hyrxmq_up Broker is up (ready)")
        parts.append("# TYPE hyrxmq_up gauge")
        parts.append("hyrxmq_up " + Self._bool_gauge(self.ready))
        parts.append("# HELP hyrxmq_queues Number of declared queues")
        parts.append("# TYPE hyrxmq_queues gauge")
        parts.append("hyrxmq_queues " + String(self.queues))
        parts.append("# HELP hyrxmq_consumers Number of active consumers")
        parts.append("# TYPE hyrxmq_consumers gauge")
        parts.append("hyrxmq_consumers " + String(self.consumers))
        parts.append("# HELP hyrxmq_messages_published Total messages published")
        parts.append("# TYPE hyrxmq_messages_published counter")
        parts.append("hyrxmq_messages_published " + String(self.messages_published))
        parts.append("# HELP hyrxmq_messages_delivered Total messages delivered")
        parts.append("# TYPE hyrxmq_messages_delivered counter")
        parts.append("hyrxmq_messages_delivered " + String(self.messages_delivered))
        parts.append("# HELP hyrxmq_messages_acked Total messages acked")
        parts.append("# TYPE hyrxmq_messages_acked counter")
        parts.append("hyrxmq_messages_acked " + String(self.messages_acked))
        parts.append("# HELP hyrxmq_messages_rejected Total messages rejected")
        parts.append("# TYPE hyrxmq_messages_rejected counter")
        parts.append("hyrxmq_messages_rejected " + String(self.messages_rejected))
        parts.append("# HELP hyrxmq_active_connections Active connections")
        parts.append("# TYPE hyrxmq_active_connections gauge")
        parts.append("hyrxmq_active_connections " + String(self.active_connections))
        parts.append("# HELP hyrxmq_refused_connections Refused connections")
        parts.append("# TYPE hyrxmq_refused_connections counter")
        parts.append("hyrxmq_refused_connections " + String(self.refused_connections))
        parts.append("# HELP hyrxmq_content_errors Content errors")
        parts.append("# TYPE hyrxmq_content_errors counter")
        parts.append("hyrxmq_content_errors " + String(self.content_errors))
        parts.append("# HELP hyrxmq_pool_allocations Buffer pool allocations")
        parts.append("# TYPE hyrxmq_pool_allocations counter")
        parts.append("hyrxmq_pool_allocations " + String(self.pool_stats.allocations))
        parts.append("# HELP hyrxmq_pool_reuses Buffer pool reuses")
        parts.append("# TYPE hyrxmq_pool_reuses counter")
        parts.append("hyrxmq_pool_reuses " + String(self.pool_stats.reuses))
        parts.append("# HELP hyrxmq_pool_capacity Buffer pool capacity")
        parts.append("# TYPE hyrxmq_pool_capacity gauge")
        parts.append("hyrxmq_pool_capacity " + String(self.pool_stats.capacity))
        parts.append("# HELP hyrxmq_pool_in_use Buffer pool buffers in use")
        parts.append("# TYPE hyrxmq_pool_in_use gauge")
        parts.append("hyrxmq_pool_in_use " + String(self.pool_stats.in_use))
        return "\n".join(parts) + "\n"

    def to_json(ref self) -> String:
        """Single-line JSON object of every status field."""
        var parts = List[String]()
        parts.append("\"node_name\":\"" + Self._json_escape(self.node_name) + "\"")
        parts.append("\"vhost\":\"" + Self._json_escape(self.vhost) + "\"")
        parts.append("\"uptime\":" + ("true" if self.uptime else "false"))
        parts.append("\"ready\":" + ("true" if self.ready else "false"))
        parts.append("\"listening\":" + ("true" if self.listening else "false"))
        parts.append("\"queues\":" + String(self.queues))
        parts.append("\"consumers\":" + String(self.consumers))
        parts.append("\"messages_published\":" + String(self.messages_published))
        parts.append("\"messages_delivered\":" + String(self.messages_delivered))
        parts.append("\"messages_acked\":" + String(self.messages_acked))
        parts.append("\"messages_rejected\":" + String(self.messages_rejected))
        parts.append("\"active_connections\":" + String(self.active_connections))
        parts.append("\"refused_connections\":" + String(self.refused_connections))
        parts.append("\"content_errors\":" + String(self.content_errors))
        parts.append("\"pool_stats\":{\"allocations\":" + String(self.pool_stats.allocations)
        + ",\"reuses\":" + String(self.pool_stats.reuses)
        + ",\"capacity\":" + String(self.pool_stats.capacity)
        + ",\"in_use\":" + String(self.pool_stats.in_use)
        + "}")
        return "{" + ",".join(parts) + "}"
