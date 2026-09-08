# Project-level test assertion mechanism (audit §3).
#
# Mojo 1.0.0 (ed45d567): a runtime-false `assert` is INERT (see
# reports/baseline.md B1 probe: exit code 0, execution continues).
# All genuine test assertions must therefore be raise-based: an
# unhandled `raises` in `main` exits non-zero, which scripts/test_all.sh
# detects. This module is test-only; it imports nothing beyond the
# standard library.


def check(condition: Bool, message: String) raises:
    """Fail the test (raise) when `condition` is false."""
    if not condition:
        raise "CHECK FAILED: " + message


def check_eq[T: Equatable](got: T, want: T, message: String) raises:
    """Fail the test when `got != want`; `message` names the quantity."""
    if got != want:
        raise "CHECK FAILED: " + message
