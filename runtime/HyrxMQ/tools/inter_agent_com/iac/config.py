"""Broker connection config, overridable by environment (defaults = this node).

Env vars: IAC_HOST IAC_PORT IAC_USER IAC_PASS IAC_VHOST IAC_HEARTBEAT
Defaults match the live docker `node-rabbitmq` on this machine (127.0.0.1:5672,
admin/password, vhost '/'). `guest` is deliberately NOT the default: RabbitMQ
restricts it to loopback and the container is reached over the docker bridge.
"""

from __future__ import annotations

import os
from dataclasses import dataclass

import pika


@dataclass
class Config:
    host: str = "127.0.0.1"
    port: int = 5672
    user: str = "admin"
    password: str = "password"
    virtual_host: str = "/"
    heartbeat: int = 60
    prefetch: int = 1

    @classmethod
    def from_env(cls) -> "Config":
        return cls(
            host=os.getenv("IAC_HOST", "127.0.0.1"),
            port=int(os.getenv("IAC_PORT", "5672")),
            user=os.getenv("IAC_USER", "admin"),
            password=os.getenv("IAC_PASS", "password"),
            virtual_host=os.getenv("IAC_VHOST", "/"),
            heartbeat=int(os.getenv("IAC_HEARTBEAT", "60")),
            prefetch=int(os.getenv("IAC_PREFETCH", "1")),
        )

    def connection_params(self) -> pika.ConnectionParameters:
        return pika.ConnectionParameters(
            host=self.host,
            port=self.port,
            virtual_host=self.virtual_host,
            credentials=pika.PlainCredentials(self.user, self.password),
            heartbeat=self.heartbeat,
            blocked_connection_timeout=15,
        )
