# Phase 10 — per-connection backpressure config tests (0026).
#
# The delivery-path wiring is deliberately NOT implemented (too invasive);
# this exercises the config contract only: default, apply override and the
# validate() rejection of a non-positive ceiling.

from hyrxmq.config import HyrxMQConfig, KeyValuePair

from std.collections import List

from hyrx.testing import check


def test_max_unacked_default() raises:
    var cfg = HyrxMQConfig()
    check((cfg.max_unacked == 1000), "max_unacked default is 1000")


def test_max_unacked_apply() raises:
    var cfg = HyrxMQConfig()
    cfg.apply("max_unacked", "500")
    check((cfg.max_unacked == 500), "apply max_unacked sets 500")


def test_max_unacked_validate_rejects_zero() raises:
    var cfg = HyrxMQConfig()
    cfg.apply("max_unacked", "0")
    var rejected = False
    try:
        cfg.validate()
    except:
        rejected = True
    check(rejected, "validate rejects max_unacked == 0")


def test_max_unacked_validate_rejects_negative() raises:
    var entries = List[KeyValuePair]()
    entries.append(KeyValuePair("max_unacked", "-5"))
    var cfg = HyrxMQConfig.from_key_values(entries^)
    var rejected = False
    try:
        cfg.validate()
    except:
        rejected = True
    check(rejected, "validate rejects max_unacked < 0")


def main() raises:
    test_max_unacked_default()
    test_max_unacked_apply()
    test_max_unacked_validate_rejects_zero()
    test_max_unacked_validate_rejects_negative()
    print("BACKPRESSURE_TEST=PASS")