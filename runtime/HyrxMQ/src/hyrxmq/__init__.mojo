# HyrxMQ product layer (Phase 7).
#
# Standalone broker assembly built ON TOP of Hyrx.
# This is Layer 5 in the architecture: it composes Hyrx Core, the Embedded
# API and the AMQP adapter into an operational product surface.
#
# Dependency direction: hyrxmq -> hyrx. Nothing in hyrx/ may import hyrxmq.
