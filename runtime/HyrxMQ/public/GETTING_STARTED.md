# Getting Started

This document will be expanded alongside the first implementation release.

The intended workflow is:

1. install HyrxMQ
2. validate configuration
3. start with systemd
4. connect an AMQP 0-9-1 client
5. declare exchange/queue/binding
6. publish
7. consume
8. inspect status/metrics

For developers embedding Hyrx, use the Hyrx Core API directly and do not require HyrxMQ unless a broker boundary is desired.
