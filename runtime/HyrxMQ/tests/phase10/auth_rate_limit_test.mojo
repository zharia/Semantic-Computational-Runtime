# Phase 10 / M2.1 — auth-failure rate limiting tests.
#
# Covers:
#   - HyrxMQConfig.max_auth_failures_per_minute default = 60
#   - apply("max_auth_failures_per_minute", "5") sets 5
#   - validate() rejects 0 and negative values
#   - the sliding-window prune logic on AMQPService (trailing 60s)
#   - _auth_rate_limited() flips at the configured ceiling

from hyrxmq.config import HyrxMQConfig
from hyrxmq.amqp_service import AMQPService

from hyrx.testing import check


def test_config_default() raises:
    var cfg = HyrxMQConfig()
    check(
        cfg.max_auth_failures_per_minute == 60,
        "default max_auth_failures_per_minute is 60",
    )


def test_config_apply() raises:
    var cfg = HyrxMQConfig()
    cfg.apply("max_auth_failures_per_minute", "5")
    check(
        cfg.max_auth_failures_per_minute == 5,
        "apply sets max_auth_failures_per_minute to 5",
    )


def test_validate_rejects_nonpositive() raises:
    var cfg0 = HyrxMQConfig()
    cfg0.max_auth_failures_per_minute = 0
    var raised0 = False
    try:
        cfg0.validate()
    except:
        raised0 = True
    check(raised0, "validate rejects 0")

    var cfg_neg = HyrxMQConfig()
    cfg_neg.max_auth_failures_per_minute = -3
    var raised_neg = False
    try:
        cfg_neg.validate()
    except:
        raised_neg = True
    check(raised_neg, "validate rejects negative")


def test_window_prune() raises:
    var cfg = HyrxMQConfig()
    var svc = AMQPService(cfg^)
    svc.start()
    # now=100_000ms. Entry at 0 is 100s old (pruned); 40_001 is 59_999ms old
    # (kept); 40_000 is exactly 60_000ms old (pruned).
    svc._auth_failure_window.append(0)
    svc._auth_failure_window.append(40_001)
    svc._auth_failure_window.append(40_000)
    svc._prune_auth_window(100_000)
    check(
        len(svc._auth_failure_window) == 1,
        "prune keeps only entries younger than 60s",
    )
    check(
        svc._auth_failure_window[0] == 40_001,
        "prune keeps the youngest entry",
    )


def test_rate_limited_flag() raises:
    var cfg = HyrxMQConfig()
    cfg.max_auth_failures_per_minute = 2
    var svc = AMQPService(cfg^)
    svc.start()
    check(not svc._auth_rate_limited(), "empty window is not rate limited")
    svc._auth_failure_window.append(100_000)
    check(not svc._auth_rate_limited(), "1 failure below ceiling of 2")
    svc._auth_failure_window.append(100_001)
    check(svc._auth_rate_limited(), "2 failures reach the ceiling of 2")


def main() raises:
    test_config_default()
    test_config_apply()
    test_validate_rejects_nonpositive()
    test_window_prune()
    test_rate_limited_flag()
    print("AUTH_RATE_LIMIT_TEST=PASS")
