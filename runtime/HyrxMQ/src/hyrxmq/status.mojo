# Broker status snapshot (Phase 7 product surface).
#
# Plain data assembled by HyrxMQBroker.status(). No behaviour, no authority:
# the engine owns the state; this is a read-only projection for health/status.


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
