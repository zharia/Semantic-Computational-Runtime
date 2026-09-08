# Minimal executable verification seed.
#
# Phase 0 tests are deliberately small. More elaborate test infrastructure
# must be selected only after validating the current Mojo toolchain.

from hyrx.testing import check


def _seed() -> Int:
    return 7


def main() raises:
    check(_seed() == 7, "L14 expect: compiled code executes and returns 7")
    check(String("hyrx").byte_length() == 4, "L15 expect: String runtime works")
    print("PHASE0_TEST_BOOTSTRAP=PASS")
