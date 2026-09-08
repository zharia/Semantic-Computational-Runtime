# NEGATIVE self-test for the hyrx.testing assertion mechanism (audit §3 B2).
#
# Deliberately FALSE check. Must exit non-zero and print the failure.
# Kept under tests/_selftest/ — scripts/test_all.sh does not traverse it.

from hyrx.testing import check


def main() raises:
    var x = Int(3) + Int(4)
    print("NEGFAIL_BEFORE")
    check(x == 99, "deliberately false: 7 must not equal 99")
    print("NEGFAIL_AFTER_MUST_NOT_PRINT")
