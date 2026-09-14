# Phase 10 — TLS certificate-validation config tests.
#
# Covers the HyrxMQConfig TLS certificate-validation policy surface:
#   - defaults: tls_verify_peer=True, tls_allow_self_signed=False
#   - apply("tls_verify_peer", "false") / apply("tls_allow_self_signed", ...)
#   - validate() rejects allow_self_signed while verify_peer is off and
#     accepts every coherent combination
#   - __copyinit__ preserves the new fields
#
# No TLS handshake happens here: this is the pure config surface (the
# handshake itself is proved by scripts/interop/tls_probe.py).

from std.collections import List

from hyrxmq.config import HyrxMQConfig

from hyrx.testing import check


def test_defaults() raises:
    var cfg = HyrxMQConfig()
    check(cfg.tls_verify_peer == True, "default tls_verify_peer is True")
    check(
        cfg.tls_allow_self_signed == False,
        "default tls_allow_self_signed is False",
    )
    check(cfg.tls_ca_path == "", "default tls_ca_path is empty")


def test_apply_verify_peer() raises:
    var cfg = HyrxMQConfig()
    cfg.apply("tls_verify_peer", "false")
    check(cfg.tls_verify_peer == False, "apply tls_verify_peer=false")
    cfg.apply("tls_verify_peer", "true")
    check(cfg.tls_verify_peer == True, "apply tls_verify_peer=true")

    var cfg2 = HyrxMQConfig()
    cfg2.apply("tls_allow_self_signed", "true")
    check(
        cfg2.tls_allow_self_signed == True,
        "apply tls_allow_self_signed=true",
    )
    cfg2.apply("tls_allow_self_signed", "false")
    check(
        cfg2.tls_allow_self_signed == False,
        "apply tls_allow_self_signed=false",
    )

    var cfg3 = HyrxMQConfig()
    cfg3.apply("tls_ca_path", "/etc/hyrx/ca.pem")
    check(cfg3.tls_ca_path == "/etc/hyrx/ca.pem", "apply tls_ca_path")

    # Invalid boolean spellings are rejected.
    var bad = False
    try:
        var cfg4 = HyrxMQConfig()
        cfg4.apply("tls_verify_peer", "maybe")
    except:
        bad = True
    check(bad, "invalid tls_verify_peer value raises")


def test_validate_combinations() raises:
    # verify_peer=True + allow_self_signed=False : valid.
    var ok1 = True
    try:
        var c = HyrxMQConfig()
        c.tls_verify_peer = True
        c.tls_allow_self_signed = False
        c.validate()
    except:
        ok1 = False
    check(ok1, "validate accepts verify_peer=true, self_signed=false")

    # verify_peer=True + allow_self_signed=True : valid.
    var ok2 = True
    try:
        var c = HyrxMQConfig()
        c.tls_verify_peer = True
        c.tls_allow_self_signed = True
        c.validate()
    except:
        ok2 = False
    check(ok2, "validate accepts verify_peer=true, self_signed=true")

    # verify_peer=False + allow_self_signed=False : valid.
    var ok3 = True
    try:
        var c = HyrxMQConfig()
        c.tls_verify_peer = False
        c.tls_allow_self_signed = False
        c.validate()
    except:
        ok3 = False
    check(ok3, "validate accepts verify_peer=false, self_signed=false")

    # verify_peer=False + allow_self_signed=True : INVALID (rejected).
    var rejected = False
    try:
        var c = HyrxMQConfig()
        c.tls_verify_peer = False
        c.tls_allow_self_signed = True
        c.validate()
    except:
        rejected = True
    check(
        rejected,
        "validate rejects allow_self_signed while verify_peer is false",
    )


def test_copy_preserves_fields() raises:
    var cfg = HyrxMQConfig()
    cfg.tls_verify_peer = False
    cfg.tls_allow_self_signed = False
    cfg.tls_ca_path = "/etc/hyrx/ca.pem"
    var cfg2 = cfg.copy()
    check(cfg2.tls_verify_peer == False, "copy preserves tls_verify_peer")
    check(
        cfg2.tls_allow_self_signed == False,
        "copy preserves tls_allow_self_signed",
    )
    check(cfg2.tls_ca_path == "/etc/hyrx/ca.pem", "copy preserves tls_ca_path")
    # The source is untouched (copyinit, not move).
    check(cfg.tls_ca_path == "/etc/hyrx/ca.pem", "source stays intact")


def main() raises:
    test_defaults()
    test_apply_verify_peer()
    test_validate_combinations()
    test_copy_preserves_fields()
    print("TLS_VALIDATION_TEST=PASS")