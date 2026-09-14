#!/usr/bin/env node
'use strict';

/*
 * Node.js AMQP interop gate for HyrxMQ (M8.1).
 *
 * Drives the real `amqplib` client against build/hyrxmq-listen on a port that is
 * NOT RabbitMQ's 5672. Verifies: connect/handshake, exchange+queue declare, bind,
 * 10 publishes consumed back byte-for-byte, publisher confirms (confirm channel)
 * and basic.return for a mandatory unroutable publish.
 *
 * Port comes from HYRX_PORT (defaults 5672). Prints NODE_INTEROP=PASS or
 * NODE_INTEROP=FAIL with a per-step detail list; exits 0 only on full PASS.
 */

const amqp = require('amqplib');

const HOST = process.env.HYRX_HOST || '127.0.0.1';
const PORT = process.env.HYRX_PORT || '5672';
const USER = process.env.HYRX_USER || 'admin';
const PASS = process.env.HYRX_PASS || 'password';
const URL = `amqp://${encodeURIComponent(USER)}:${encodeURIComponent(PASS)}@${HOST}:${PORT}/`;

const EXCH = 'node-ex';
const QUEUE = 'node-q';
const RK = 'node-key';
const N = 10;
const UNROUTABLE_RK = 'node-no-route';
const MSG_PREFIX = 'node-msg-';

const failures = [];
const notes = [];
let conn = null;

function note(msg) {
  notes.push(msg);
}

function fail(msg) {
  failures.push(msg);
}

function withTimeout(promise, ms, label) {
  let timer;
  const guard = new Promise((_, rej) => {
    timer = setTimeout(() => rej(new Error(`${label}: timed out after ${ms}ms`)), ms);
  });
  return Promise.race([promise, guard]).finally(() => clearTimeout(timer));
}

function sleep(ms) {
  return new Promise((r) => setTimeout(r, ms));
}

async function waitFor(predicate, ms, label) {
  const deadline = Date.now() + ms;
  while (Date.now() < deadline) {
    if (predicate()) return;
    await sleep(50);
  }
  throw new Error(`${label}: not satisfied within ${ms}ms`);
}

async function main() {
  try {
    conn = await withTimeout(amqp.connect(URL), 10000, 'connect');
    note(`connected as ${USER}@${HOST}:${PORT} vhost=/`);

    const ch = await withTimeout(conn.createConfirmChannel(), 10000, 'createConfirmChannel');

    await withTimeout(ch.assertExchange(EXCH, 'direct', { durable: false, autoDelete: true }), 10000, 'exchange.declare');
    await withTimeout(ch.assertQueue(QUEUE, { durable: false, exclusive: true }), 10000, 'queue.declare');
    await withTimeout(ch.bindQueue(QUEUE, EXCH, RK), 10000, 'queue.bind');
    note(`declared direct '${EXCH}', queue '${QUEUE}', bind '${RK}'`);

    const received = [];
    await withTimeout(
      ch.consume(QUEUE, (msg) => {
        if (msg === null) return;
        received.push(msg.content.toString('utf8'));
        ch.ack(msg);
      }, { noAck: false }),
      10000, 'basic.consume'
    );

    for (let i = 1; i <= N; i++) {
      const body = Buffer.from(`${MSG_PREFIX}${i}`, 'utf8');
      await withTimeout(
        new Promise((res, rej) => {
          ch.publish(EXCH, RK, body, { persistent: false }, (err) => (err ? rej(err) : res()));
        }),
        10000, `basic.publish #${i}`
      );
    }
    note(`published ${N} messages on '${RK}'`);

    await withTimeout(ch.waitForConfirms(), 10000, 'publisher confirms');
    note('publisher confirms OK (broker acked all 10)');

    await waitFor(() => received.length >= N, 10000, 'deliveries');
    for (let i = 1; i <= N; i++) {
      const expected = `${MSG_PREFIX}${i}`;
      if (received[i - 1] !== expected) {
        fail(`body mismatch at index ${i - 1}: expected ${JSON.stringify(expected)}, got ${JSON.stringify(received[i - 1])}`);
      }
    }
    if (received.length !== N) fail(`expected ${N} deliveries, got ${received.length}`);
    if (failures.length === 0) note(`consumed ${received.length} messages, bodies verified`);

    // ---- basic.return for a mandatory unroutable publish ----
    let returned = null;
    ch.on('return', (msg) => { returned = msg; });
    await withTimeout(
      new Promise((res, rej) => {
        ch.publish(EXCH, UNROUTABLE_RK, Buffer.from('node-unroutable', 'utf8'), { mandatory: true }, (err) => (err ? rej(err) : res()));
      }),
      10000, 'mandatory publish'
    );
    try {
      await waitFor(() => returned !== null, 5000, 'basic.return');
      note(`basic.return received for '${UNROUTABLE_RK}' (replyCode=${returned.fields && returned.fields.replyCode})`);
    } catch (e) {
      fail(`basic.return not received: ${e.message}`);
    }
  } catch (e) {
    fail(`fatal: ${e && e.message ? e.message : e}`);
  } finally {
    if (conn) {
      try {
        await withTimeout(conn.close(), 5000, 'connection.close');
      } catch (_) {
        /* broker teardown is the runner's job; ignore close gaps */
      }
    }
  }

  for (const n of notes) console.log(`  ${n}`);
  if (failures.length === 0) {
    console.log('NODE_INTEROP=PASS');
    process.exit(0);
  }
  console.log('NODE_INTEROP=FAIL');
  for (const f of failures) console.log(`  ${f}`);
  process.exit(1);
}

process.on('unhandledRejection', (e) => fail(`unhandledRejection: ${e && e.message ? e.message : e}`));
main();