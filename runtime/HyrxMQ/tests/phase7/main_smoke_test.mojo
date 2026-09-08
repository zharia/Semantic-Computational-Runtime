# Phase 7 — main self-check smoke test.
#
# Calls the factored in-process self-check (does NOT exec main's prints/loop).

from hyrxmq.main import run_selfcheck


def check(cond: Bool, var msg: String) raises:
    if not cond:
        raise "FAIL: " + msg


def main() raises:
    var ok = run_selfcheck()
    check(ok, "run_selfcheck must return True")
    print("PHASE7_MAIN_SMOKE_TEST=PASS")
