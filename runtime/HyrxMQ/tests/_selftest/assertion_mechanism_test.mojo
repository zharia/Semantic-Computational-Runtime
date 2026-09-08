# Self-test for the hyrx.testing assertion mechanism (audit §3 B2).
#
# Positive case: true checks pass -> prints marker, exit 0.
# The negative case lives in tests/_selftest/assertion_negfail.mojo
# (deliberately failing; NOT part of scripts/test_all.sh traversal).

from hyrx.testing import check, check_eq


def main() raises:
    check(True, "true literal must pass")
    # Non-constant condition so the pass is exercised at runtime.
    var x = Int(3) + Int(4)
    check(x == 7, "x must equal 7")
    check_eq[Int](x, 7, "sum")
    check_eq[String]("hyrx", "hyrx", "literal")
    print("ASSERTION_MECHANISM_PASS")
