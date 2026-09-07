# Minimal example proving that Hyrx can be referenced as a native Mojo source
# tree without introducing an AMQP or network dependency.

from hyrx.version import hyrx_version

def main() raises:
    print("Hyrx version: " + hyrx_version())
