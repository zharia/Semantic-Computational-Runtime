# HyrxMQ

HyrxMQ is a native Mojo AMQP broker built on Hyrx, a low-cost messaging engine designed for direct, local, and network communication.

It is a standalone Linux product. It does not require the simulation project that originally motivated some of its workloads.

## Why Hyrx?

Most messaging systems start from network communication. Hyrx starts from the messaging operation itself.

That means a local message can use a direct in-process path without paying for serialization, sockets, or network framing unnecessarily.

When network interoperability is needed, HyrxMQ can expose AMQP 0-9-1.
