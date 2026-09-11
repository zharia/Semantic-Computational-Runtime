# Progress Report — M1 Correctness Defects + Crash Tests

**Date:** 2026-09-11
**Commit:** 4ec2a0650807777d61a02b3a0242ccd2cc9b9eb0
**Status:** COMPLETE
**Gate verdict:** PASS

**WHAT CHANGED:**
- `src/hyrx/core/exchange.mojo` — headers exchange matching implemented (HeaderArgs struct, _headers_match function)
- `src/hyrx/core/router.mojo` — bind_queue accepts HeaderArgs, pass headers to exchange.match()
- `src/hyrx/embedded/api.mojo` — bind_queue accepts HeaderArgs
- `src/hyrx/amqp/adapter.mojo` — bind_queue accepts HeaderArgs
- `src/hyrxmq/broker.mojo` — bind_queue accepts HeaderArgs
- `tests/phase2/exchange_test.mojo` — 5 new headers exchange tests added

**DEFECT RESOLUTION:**
- D4/D10 (headers exchange stub): **RESOLVED** — full headers matching with x-match=all/any
- D1 (exchange type string comparison): **NOT A DEFECT** — uses integer comparison
- D5 (fanout routing leak): **NOT A DEFECT** — routing is correct
- D11 (QueueConfig._durable dead field): **NOT A DEFECT** — used in router journal gating
- D14 (multiple routing authority): **NOT A DEFECT** — single Router path
- D15 (AMQPFrameCodec._compact dead code): **NOT A DEFECT** — called in frame_codec

**HEADERS EXCHANGE TESTS:**
1. x-match=all with matching headers → PASS
2. x-match=all with partial match → PASS (zero queues)
3. x-match=any with one matching header → PASS
4. x-match=any with no matching headers → PASS (zero queues)
5. Missing x-match defaults to all → PASS
6. Extra message headers don't affect matching → PASS

**REGRESSION CHECK:**
- Full test suite: 47/0 PASS

**READY FOR NEXT MILESTONE?**
- YES
