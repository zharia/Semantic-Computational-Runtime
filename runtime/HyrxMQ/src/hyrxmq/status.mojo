# Broker status snapshot (Phase 7 product surface).
#
# Plain data assembled by HyrxMQBroker.status(). No behaviour, no authority:
# the engine owns the state; this is a read-only projection for health/status.

from std.collections import List

from hyrx.core.pool_stats import PoolStats


struct LatencyHistogram(Copyable):
    """Fixed-bucket latency histogram (microsecond resolution).

    Buckets: 0-100us, 100-500us, 500us-1ms, 1-5ms, 5-10ms, 10-50ms, 50-100ms,
    100ms-1s, 1s+. Covers the AMQP publish/consume latency spectrum.
    """

    var bucket_le_100us: Int
    var bucket_le_500us: Int
    var bucket_le_1ms: Int
    var bucket_le_5ms: Int
    var bucket_le_10ms: Int
    var bucket_le_50ms: Int
    var bucket_le_100ms: Int
    var bucket_le_1s: Int
    var bucket_gt_1s: Int
    var total_count: Int
    var total_sum_us: Int

    def __init__(out self):
        self.bucket_le_100us = 0
        self.bucket_le_500us = 0
        self.bucket_le_1ms = 0
        self.bucket_le_5ms = 0
        self.bucket_le_10ms = 0
        self.bucket_le_50ms = 0
        self.bucket_le_100ms = 0
        self.bucket_le_1s = 0
        self.bucket_gt_1s = 0
        self.total_count = 0
        self.total_sum_us = 0

    def copy(ref self) -> Self:
        """Return a copy of this histogram."""
        var h = LatencyHistogram()
        h.bucket_le_100us = self.bucket_le_100us
        h.bucket_le_500us = self.bucket_le_500us
        h.bucket_le_1ms = self.bucket_le_1ms
        h.bucket_le_5ms = self.bucket_le_5ms
        h.bucket_le_10ms = self.bucket_le_10ms
        h.bucket_le_50ms = self.bucket_le_50ms
        h.bucket_le_100ms = self.bucket_le_100ms
        h.bucket_le_1s = self.bucket_le_1s
        h.bucket_gt_1s = self.bucket_gt_1s
        h.total_count = self.total_count
        h.total_sum_us = self.total_sum_us
        return h^

    def observe(mut self, latency_us: Int):
        """Record a latency sample in microseconds."""
        self.total_count += 1
        self.total_sum_us += latency_us
        if latency_us <= 100:
            self.bucket_le_100us += 1
        elif latency_us <= 500:
            self.bucket_le_500us += 1
        elif latency_us <= 1000:
            self.bucket_le_1ms += 1
        elif latency_us <= 5000:
            self.bucket_le_5ms += 1
        elif latency_us <= 10000:
            self.bucket_le_10ms += 1
        elif latency_us <= 50000:
            self.bucket_le_50ms += 1
        elif latency_us <= 100000:
            self.bucket_le_100ms += 1
        elif latency_us <= 1000000:
            self.bucket_le_1s += 1
        else:
            self.bucket_gt_1s += 1

    def mean_us(ref self) -> Int:
        """Mean latency in microseconds, 0 if no samples."""
        if self.total_count == 0:
            return 0
        return self.total_sum_us // self.total_count

    def to_json(ref self) -> String:
        """JSON representation for API responses."""
        return (
            "{\"le_100us\":" + String(self.bucket_le_100us)
            + ",\"le_500us\":" + String(self.bucket_le_500us)
            + ",\"le_1ms\":" + String(self.bucket_le_1ms)
            + ",\"le_5ms\":" + String(self.bucket_le_5ms)
            + ",\"le_10ms\":" + String(self.bucket_le_10ms)
            + ",\"le_50ms\":" + String(self.bucket_le_50ms)
            + ",\"le_100ms\":" + String(self.bucket_le_100ms)
            + ",\"le_1s\":" + String(self.bucket_le_1s)
            + ",\"gt_1s\":" + String(self.bucket_gt_1s)
            + ",\"total\":" + String(self.total_count)
            + ",\"mean_us\":" + String(self.mean_us()) + "}"
        )


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
    var publish_latency: LatencyHistogram
    var consume_latency: LatencyHistogram

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
        self.publish_latency = LatencyHistogram()
        self.consume_latency = LatencyHistogram()

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
        self.publish_latency = existing.publish_latency
        self.consume_latency = existing.consume_latency

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
        # Latency histogram metrics (publish path).
        parts.append("# HELP hyrxmq_publish_latency_us Publish latency microseconds (histogram)")
        parts.append("# TYPE hyrxmq_publish_latency_us histogram")
        parts.append("hyrxmq_publish_latency_us_bucket{le=\"100\"} " + String(self.publish_latency.bucket_le_100us))
        parts.append("hyrxmq_publish_latency_us_bucket{le=\"500\"} " + String(self.publish_latency.bucket_le_500us))
        parts.append("hyrxmq_publish_latency_us_bucket{le=\"1000\"} " + String(self.publish_latency.bucket_le_1ms))
        parts.append("hyrxmq_publish_latency_us_bucket{le=\"5000\"} " + String(self.publish_latency.bucket_le_5ms))
        parts.append("hyrxmq_publish_latency_us_bucket{le=\"10000\"} " + String(self.publish_latency.bucket_le_10ms))
        parts.append("hyrxmq_publish_latency_us_bucket{le=\"50000\"} " + String(self.publish_latency.bucket_le_50ms))
        parts.append("hyrxmq_publish_latency_us_bucket{le=\"100000\"} " + String(self.publish_latency.bucket_le_100ms))
        parts.append("hyrxmq_publish_latency_us_bucket{le=\"1000000\"} " + String(self.publish_latency.bucket_le_1s))
        parts.append("hyrxmq_publish_latency_us_bucket{le=\"+Inf\"} " + String(self.publish_latency.total_count))
        parts.append("hyrxmq_publish_latency_us_sum " + String(self.publish_latency.total_sum_us))
        parts.append("hyrxmq_publish_latency_us_count " + String(self.publish_latency.total_count))
        # Latency histogram metrics (consume path).
        parts.append("# HELP hyrxmq_consume_latency_us Consume latency microseconds (histogram)")
        parts.append("# TYPE hyrxmq_consume_latency_us histogram")
        parts.append("hyrxmq_consume_latency_us_bucket{le=\"100\"} " + String(self.consume_latency.bucket_le_100us))
        parts.append("hyrxmq_consume_latency_us_bucket{le=\"500\"} " + String(self.consume_latency.bucket_le_500us))
        parts.append("hyrxmq_consume_latency_us_bucket{le=\"1000\"} " + String(self.consume_latency.bucket_le_1ms))
        parts.append("hyrxmq_consume_latency_us_bucket{le=\"5000\"} " + String(self.consume_latency.bucket_le_5ms))
        parts.append("hyrxmq_consume_latency_us_bucket{le=\"10000\"} " + String(self.consume_latency.bucket_le_10ms))
        parts.append("hyrxmq_consume_latency_us_bucket{le=\"50000\"} " + String(self.consume_latency.bucket_le_50ms))
        parts.append("hyrxmq_consume_latency_us_bucket{le=\"100000\"} " + String(self.consume_latency.bucket_le_100ms))
        parts.append("hyrxmq_consume_latency_us_bucket{le=\"1000000\"} " + String(self.consume_latency.bucket_le_1s))
        parts.append("hyrxmq_consume_latency_us_bucket{le=\"+Inf\"} " + String(self.consume_latency.total_count))
        parts.append("hyrxmq_consume_latency_us_sum " + String(self.consume_latency.total_sum_us))
        parts.append("hyrxmq_consume_latency_us_count " + String(self.consume_latency.total_count))
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
        parts.append("\"publish_latency\":" + self.publish_latency.to_json())
        parts.append("\"consume_latency\":" + self.consume_latency.to_json())
        return "{" + ",".join(parts) + "}"
