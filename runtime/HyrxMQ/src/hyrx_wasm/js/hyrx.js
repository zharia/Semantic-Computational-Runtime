/// Hyrx WASM — JavaScript bindings for browser usage.
///
/// Usage:
///   import { HyrxEngine } from './hyrx.js';
///   const engine = new HyrxEngine();
///   await engine.init();
///   engine.declareQueue('my-queue');
///   engine.publish('hello', 'my-queue', '', 'amq.direct');
///   const consumer = engine.consume('my-queue');
///   const tag = engine.nextMessage(consumer);
///   if (tag) {
///     const payload = engine.readPayload(consumer, tag);
///     engine.acknowledge(consumer, tag);
///   }

export class HyrxEngine {
  constructor() {
    this._instance = null;
    this._ready = false;
  }

  /// Load the WASM module and initialize the engine.
  async init(queueCapacity = 1024, wasmUrl = 'hyrx.wasm') {
    const response = await fetch(wasmUrl);
    const bytes = await response.arrayBuffer();
    const { instance } = await WebAssembly.instantiate(bytes, {
      env: { memory: new WebAssembly.Memory({ initial: 256 }) },
    });
    this._instance = instance;
    this._ready = !!instance.exports.hyrx_init(queueCapacity);
    return this._ready;
  }

  /// Check if engine is initialized.
  get ready() {
    return this._ready;
  }

  _exports() {
    if (!this._instance) throw new Error('HyrxEngine not initialized');
    return this._instance.exports;
  }

  /// Declare an exchange.
  /// type: 'direct' | 'fanout' | 'topic' | 'headers'
  declareExchange(name, type = 'direct') {
    const types = { direct: 0, fanout: 1, topic: 2, headers: 3 };
    const t = types[type] ?? 0;
    return this._writeString(name, (ptr) => {
      return this._exports().hyrx_declare_exchange(ptr, t);
    });
  }

  /// Declare a queue.
  declareQueue(name) {
    return this._writeString(name, (ptr) => {
      return this._exports().hyrx_declare_queue(ptr);
    });
  }

  /// Bind a queue to an exchange.
  bindQueue(queueName, exchangeName, routingKey) {
    return this._writeStrings([queueName, exchangeName, routingKey], (ptrs) => {
      return this._exports().hyrx_bind_queue(ptrs[0], ptrs[1], ptrs[2]);
    });
  }

  /// Unbind a queue from an exchange.
  unbindQueue(queueName, exchangeName, routingKey) {
    return this._writeStrings([queueName, exchangeName, routingKey], (ptrs) => {
      return this._exports().hyrx_unbind_queue(ptrs[0], ptrs[1], ptrs[2]);
    });
  }

  /// Delete a queue.
  deleteQueue(name) {
    return this._writeString(name, (ptr) => {
      return this._exports().hyrx_delete_queue(ptr);
    });
  }

  /// Delete an exchange.
  deleteExchange(name) {
    return this._writeString(name, (ptr) => {
      return this._exports().hyrx_delete_exchange(ptr);
    });
  }

  /// Check if a queue exists.
  hasQueue(name) {
    return this._writeString(name, (ptr) => {
      return this._exports().hyrx_has_queue(ptr);
    });
  }

  /// Check if an exchange exists.
  hasExchange(name) {
    return this._writeString(name, (ptr) => {
      return this._exports().hyrx_has_exchange(ptr);
    });
  }

  /// Publish a message.
  /// Returns routed queue count.
  publish(routingKey, payload, exchangeName) {
    const exp = this._exports();
    const mem = exp.memory;
    const rkBytes = new TextEncoder().encode(routingKey);
    const exBytes = new TextEncoder().encode(exchangeName);
    const payloadBytes = typeof payload === 'string'
      ? new TextEncoder().encode(payload)
      : new Uint8Array(payload);

    // Allocate: routing_key + exchange_name + payload
    const total = rkBytes.length + 1 + exBytes.length + 1 + payloadBytes.length;
    const ptr = exp.malloc(total);
    const view = new Uint8Array(mem.buffer);

    let off = ptr;
    view.set(rkBytes, off); off += rkBytes.length; view[off++] = 0;
    view.set(exBytes, off); off += exBytes.length; view[off++] = 0;
    const payloadStart = off;
    view.set(payloadBytes, off);

    const result = exp.hyrx_publish(ptr, payloadStart, payloadBytes.length, ptr + rkBytes.length + 1);
    exp.free(ptr);
    return result;
  }

  /// Publish directly to a queue (default exchange).
  publishToQueue(routingKey, payload, queueName) {
    const exp = this._exports();
    const mem = exp.memory;
    const rkBytes = new TextEncoder().encode(routingKey);
    const qnBytes = new TextEncoder().encode(queueName);
    const payloadBytes = typeof payload === 'string'
      ? new TextEncoder().encode(payload)
      : new Uint8Array(payload);

    const total = rkBytes.length + 1 + qnBytes.length + 1 + payloadBytes.length;
    const ptr = exp.malloc(total);
    const view = new Uint8Array(mem.buffer);

    let off = ptr;
    view.set(rkBytes, off); off += rkBytes.length; view[off++] = 0;
    view.set(qnBytes, off); off += qnBytes.length; view[off++] = 0;
    const payloadStart = off;
    view.set(payloadBytes, off);

    const result = exp.hyrx_publish_to_queue(ptr, payloadStart, payloadBytes.length, ptr + rkBytes.length + 1);
    exp.free(ptr);
    return result;
  }

  /// Register a consumer. Returns consumer id.
  consume(queueName) {
    return this._writeString(queueName, (ptr) => {
      return Number(this._exports().hyrx_consume(ptr));
    });
  }

  /// Deliver next message for a consumer.
  /// Returns delivery tag, or 0 if none.
  nextMessage(consumerId) {
    return Number(this._exports().hyrx_next_message(BigInt(consumerId)));
  }

  /// Read payload of a delivered message. Returns Uint8Array.
  readPayload(consumerId, deliveryTag) {
    const exp = this._exports();
    const mem = exp.memory;
    // Allocate a temp buffer (64KB max).
    const bufSize = 65536;
    const bufPtr = exp.malloc(bufSize);
    const len = exp.hyrx_read_payload(
      BigInt(consumerId), BigInt(deliveryTag), bufPtr, bufSize
    );
    if (len === 0) {
      exp.free(bufPtr);
      return new Uint8Array(0);
    }
    const data = new Uint8Array(mem.buffer.slice(bufPtr, bufPtr + len));
    exp.free(bufPtr);
    return data;
  }

  /// Acknowledge a delivery.
  acknowledge(consumerId, deliveryTag) {
    return this._exports().hyrx_acknowledge(
      BigInt(consumerId), BigInt(deliveryTag)
    );
  }

  /// Reject a delivery (requeue).
  reject(consumerId, deliveryTag) {
    return this._exports().hyrx_reject(
      BigInt(consumerId), BigInt(deliveryTag)
    );
  }

  /// Unregister a consumer.
  unregisterConsumer(consumerId) {
    return this._exports().hyrx_unregister_consumer(BigInt(consumerId));
  }

  /// Get engine statistics.
  stats() {
    const exp = this._exports();
    const mem = exp.memory;
    // Use stack-allocated output via a small WASM call.
    // We'll read from the stats function output.
    // For simplicity, use the WASM memory directly.
    const ptr = exp.malloc(64);
    exp.hyrx_stats(ptr, ptr + 8, ptr + 16, ptr + 24, ptr + 32, ptr + 40);
    const view = new DataView(mem.buffer);
    const stats = {
      published: Number(view.getBigUint64(ptr, true)),
      delivered: Number(view.getBigUint64(ptr + 8, true)),
      acknowledged: Number(view.getBigUint64(ptr + 16, true)),
      rejected: Number(view.getBigUint64(ptr + 24, true)),
      queues: view.getUint32(ptr + 32, true),
      consumers: view.getUint32(ptr + 40, true),
    };
    exp.free(ptr);
    return stats;
  }

  /// Get queue depth.
  getQueueDepth(name) {
    return this._writeString(name, (ptr) => {
      return this._exports().hyrx_get_queue_depth(ptr);
    });
  }

  /// List queue names.
  listQueues() {
    return this._listNames('hyrx_list_queues');
  }

  /// List exchange names.
  listExchanges() {
    return this._listNames('hyrx_list_exchanges');
  }

  /// Shutdown the engine.
  shutdown() {
    if (this._instance) {
      this._exports().hyrx_shutdown();
      this._ready = false;
    }
  }

  // ---- Internal helpers ----

  _allocString(str) {
    const exp = this._exports();
    const bytes = new TextEncoder().encode(str + '\0');
    const ptr = exp.malloc(bytes.length);
    new Uint8Array(exp.memory.buffer).set(bytes, ptr);
    return { ptr, len: bytes.length };
  }

  _writeString(str, fn) {
    const { ptr } = this._allocString(str);
    const result = fn(ptr);
    this._exports().free(ptr);
    return typeof result === 'bigint' ? Number(result) : result;
  }

  _writeStrings(strs, fn) {
    const exp = this._exports();
    const allocs = strs.map((s) => this._allocString(s));
    const result = fn(allocs.map((a) => a.ptr));
    allocs.forEach((a) => exp.free(a.ptr));
    return typeof result === 'bigint' ? Number(result) : result;
  }

  _listNames(funcName) {
    const exp = this._exports();
    const mem = exp.memory;
    const bufSize = 4096;
    const bufPtr = exp.malloc(bufSize);
    const len = exp[funcName](bufPtr, bufSize);
    if (len === 0) { exp.free(bufPtr); return []; }

    const view = new Uint8Array(mem.buffer, bufPtr, len);
    const names = [];
    let start = 0;
    for (let i = 0; i < view.length; i++) {
      if (view[i] === 0) {
        if (i > start) {
          names.push(new TextDecoder().decode(view.slice(start, i)));
        }
        start = i + 1;
      }
    }
    exp.free(bufPtr);
    return names;
  }
}

export default HyrxEngine;
