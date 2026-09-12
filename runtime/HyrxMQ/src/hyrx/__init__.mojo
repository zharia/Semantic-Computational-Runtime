# Hyrx product layer (Phase 6).
#
# Embeddable messaging engine composed from Hyrx Core, the Embedded API,
# and transport adapters. This is Layer 2 in the architecture:
# Core → Embedded → (optionally) Local/Network → HyrxMQ product (Layer 5).
#
# Dependency direction: this layer is independent; hyrxmq depends on hyrx,
# but nothing in hyrx/ may import hyrxmq.