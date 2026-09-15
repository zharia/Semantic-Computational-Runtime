// loadgen — compiled, multi-connection AMQP 0-9-1 load generator.
//
// Purpose: remove the client (Python GIL) as the bottleneck when comparing
// brokers. One goroutine per connection; each goroutine owns its own AMQP
// connection + channel. All timed work is done in Go, so the measured rate is
// bounded by the broker and the socket, not by an interpreter.
//
// Workloads:
//   publish  fire-and-forget to a bindingless direct exchange, max rate for
//            --duration, producer/transport ceiling (no queue growth).
//   pubget   closed-loop publish -> basic.get(auto_ack), bounded batch, so the
//            queue depth never exceeds the batch (routing + content + get).
//   confirm  publisher confirms; one publish, wait for its confirm (per
//            message), periodic untimed drain keeps the queue bounded.
//   fanout   1 fanout exchange -> --declares bound queues; reported rate is
//            delivered msgs/s (publish+drain inside the timed window).
//   latency  publish -> basic.get -> ack, one message in flight per worker;
//            reports p50/p95/p99/p99.9 in microseconds over pooled samples.
//
// A durable, non-exclusive, non-auto-delete queue is predeclared and purged
// before each run so nothing races with connection close / auto-delete.
//
// Output: exactly one JSON line on stdout.
package main

import (
	"context"
	"encoding/json"
	"flag"
	"fmt"
	"math"
	"os"
	"sort"
	"strings"
	"sync"
	"sync/atomic"
	"time"

	amqp "github.com/rabbitmq/amqp091-go"
)

type options struct {
	url         string
	broker      string
	workload    string
	payload     int
	count       int64
	concurrency int
	duration    float64
	declares    int
	exchange    string
	queue       string
	warmup      float64
	samplesOut  string
	routingKey  string
}

type topo struct {
	exchange string
	queues   []string
	routing  string
}

type workerResult struct {
	timedOps int64
	start    time.Time
	end      time.Time
	samples  []float64
	err      error
}

type errBox struct {
	mu      sync.Mutex
	n       int
	samples []string
}

func (e *errBox) add(err error) {
	if err == nil {
		return
	}
	e.mu.Lock()
	e.n++
	if len(e.samples) < 8 {
		e.samples = append(e.samples, err.Error())
	}
	e.mu.Unlock()
}

type result struct {
	Broker           string      `json:"broker"`
	Workload         string      `json:"workload"`
	Payload          int         `json:"payload"`
	Concurrency      int         `json:"concurrency"`
	MsgsPerSec       float64     `json:"msgs_per_sec"`
	P50Us            interface{} `json:"p50_us"`
	P95Us            interface{} `json:"p95_us"`
	P99Us            interface{} `json:"p99_us"`
	P999Us           interface{} `json:"p999_us"`
	Errors           int         `json:"errors"`
	Count            int64       `json:"count"`
	WallS            float64     `json:"wall_s"`
	TimedOps         int64       `json:"timed_ops"`
	Delivered        int64       `json:"delivered,omitempty"`
	Queues           int         `json:"queues,omitempty"`
	WorkersConnected int         `json:"workers_connected"`
	ErrorSamples     []string    `json:"error_samples,omitempty"`
}

func main() {
	var o options
	flag.StringVar(&o.url, "url", "amqp://guest:guest@127.0.0.1:5672/", "AMQP URL")
	flag.StringVar(&o.broker, "broker", "unknown", "broker label for the JSON line")
	flag.StringVar(&o.workload, "workload", "pubget", "publish|pubget|confirm|fanout|latency")
	flag.IntVar(&o.payload, "payload", 1024, "message payload bytes")
	flag.Int64Var(&o.count, "count", 20000, "total messages/ops (ignored by duration publish)")
	flag.IntVar(&o.concurrency, "concurrency", 1, "number of connections (goroutines)")
	flag.Float64Var(&o.duration, "duration", 2.0, "seconds; publish workload runs for this long")
	flag.IntVar(&o.declares, "declares", 4, "fanout: number of bound queues")
	flag.StringVar(&o.exchange, "exchange", "", "exchange name (default bench.<workload>)")
	flag.StringVar(&o.queue, "queue", "", "queue name (default bench.<workload>.q)")
	flag.Float64Var(&o.warmup, "warmup", 0.10, "fraction of each worker's ops discarded as warm-up")
	flag.StringVar(&o.samplesOut, "samples-out", "", "optional file to write raw latency samples (us), one per line")
	flag.StringVar(&o.routingKey, "routing-key", "rk", "direct routing key")
	flag.Parse()

	if o.concurrency < 1 {
		o.concurrency = 1
	}
	if o.workload == "fanout" && o.declares < 1 {
		o.declares = 1
	}
	if o.exchange == "" {
		o.exchange = "bench." + o.workload
	}
	if o.queue == "" {
		o.queue = "bench." + o.workload + ".q"
	}

	res := run(&o)
	enc, _ := json.Marshal(res)
	fmt.Println(string(enc))
	if res.Errors > 0 && res.WorkersConnected == 0 {
		os.Exit(1)
	}
}

func dial(o *options) (*amqp.Connection, error) {
	cfg := amqp.Config{
		Heartbeat: 30 * time.Second,
		FrameSize: 131072,
	}
	return amqp.DialConfig(o.url, cfg)
}

// closeConn tears a connection down without waiting on HyrxMQ, which does not
// implement connection.close-ok: a graceful Close() blocks ~20s there. A short
// deadline bounds the wait on every broker identically.
func closeConn(c *amqp.Connection) {
	if c == nil {
		return
	}
	_ = c.CloseDeadline(time.Now().Add(200 * time.Millisecond))
}

// declareTopo builds each worker's OWN exchange + queue(s). Concurrent workers
// therefore never contend on one queue's basic.get (a shared queue stalls
// HyrxMQ at ~16 connections and is not the connection-scaling property under
// test). Queues are durable, non-exclusive and non-auto-delete so connection
// close never races a delete; they are purged here and reused across reps.
func declareTopo(o *options, idx int, ch *amqp.Channel) (topo, error) {
	var t topo
	suffix := fmt.Sprintf("%d", idx)
	base := o.exchange

	if o.workload == "publish" {
		// Bindingless direct exchange: fire-and-forget sink, nothing stored.
		t.exchange = fmt.Sprintf("%s.x.%s", base, suffix)
		t.routing = o.routingKey
		if err := ch.ExchangeDeclare(t.exchange, "direct", true, false, false, false, nil); err != nil {
			return t, fmt.Errorf("declare exchange %q: %w", t.exchange, err)
		}
		return t, nil
	}

	kind := "direct"
	routing := o.routingKey
	t.exchange = fmt.Sprintf("%s.x.%s", base, suffix)
	if o.workload == "fanout" {
		kind = "fanout"
		routing = ""
		for i := 0; i < o.declares; i++ {
			t.queues = append(t.queues, fmt.Sprintf("%s.%s.%d", o.queue, suffix, i))
		}
	} else {
		t.queues = []string{fmt.Sprintf("%s.%s", o.queue, suffix)}
	}
	if err := ch.ExchangeDeclare(t.exchange, kind, true, false, false, false, nil); err != nil {
		return t, fmt.Errorf("declare exchange %q: %w", t.exchange, err)
	}
	for _, q := range t.queues {
		if _, err := ch.QueueDeclare(q, true, false, false, false, nil); err != nil {
			return t, fmt.Errorf("declare queue %q: %w", q, err)
		}
		if err := ch.QueueBind(q, routing, t.exchange, false, nil); err != nil {
			return t, fmt.Errorf("bind queue %q: %w", q, err)
		}
		if _, err := ch.QueuePurge(q, false); err != nil {
			return t, fmt.Errorf("purge queue %q: %w", q, err)
		}
	}
	t.routing = routing
	return t, nil
}

func run(o *options) result {
	res := result{
		Broker:      o.broker,
		Workload:    o.workload,
		Payload:     o.payload,
		Concurrency: o.concurrency,
	}

	res.Queues = 1
	if o.workload == "fanout" {
		res.Queues = o.declares
	}

	body := mkbody(o.payload)
	var errs errBox
	share := o.count / int64(o.concurrency)
	remainder := o.count % int64(o.concurrency)

	results := make([]workerResult, o.concurrency)
	startGate := make(chan struct{})
	var ready, done sync.WaitGroup
	var connected int64

	for i := 0; i < o.concurrency; i++ {
		n := share
		if int64(i) < remainder {
			n++
		}
		ready.Add(1)
		done.Add(1)
		go func(idx int, myCount int64) {
			defer done.Done()
			var once sync.Once
			markReady := func() { once.Do(func() { ready.Done() }) }
			defer markReady()
			wr := runWorker(o, body, idx, myCount, startGate, markReady)
			results[idx] = wr
			if wr.err != nil {
				errs.add(wr.err)
			}
			if !wr.start.IsZero() {
				atomic.AddInt64(&connected, 1)
			}
		}(i, n)
	}

	// Wait until every worker has opened its connection + channel, or a
	// bounded setup budget expires; then open the start gate.
	setupDone := make(chan struct{})
	go func() {
		ready.Wait()
		close(setupDone)
	}()
	select {
	case <-setupDone:
	case <-time.After(8 * time.Second):
	}

	gateOpen := time.Now()
	close(startGate)
	done.Wait()
	res.WallS = round3(time.Since(gateOpen).Seconds())
	res.WorkersConnected = int(connected)

	var totalOps int64
	var minStart, maxEnd time.Time
	var pooled []float64
	for _, wr := range results {
		totalOps += wr.timedOps
		if !wr.start.IsZero() && (minStart.IsZero() || wr.start.Before(minStart)) {
			minStart = wr.start
		}
		if !wr.end.IsZero() && wr.end.After(maxEnd) {
			maxEnd = wr.end
		}
		pooled = append(pooled, wr.samples...)
	}
	if !minStart.IsZero() && !maxEnd.IsZero() && maxEnd.After(minStart) {
		res.WallS = round3(maxEnd.Sub(minStart).Seconds())
	}
	res.TimedOps = totalOps
	if res.WallS > 0 {
		res.MsgsPerSec = round1(float64(totalOps) / res.WallS)
	}
	if o.workload == "fanout" {
		res.Delivered = totalOps * int64(o.declares)
		if res.WallS > 0 {
			res.MsgsPerSec = round1(float64(res.Delivered) / res.WallS)
		}
	}
	if o.workload == "latency" && len(pooled) > 0 {
		res.P50Us = round3(pct(pooled, 0.50))
		res.P95Us = round3(pct(pooled, 0.95))
		res.P99Us = round3(pct(pooled, 0.99))
		res.P999Us = round3(pct(pooled, 0.999))
		if o.samplesOut != "" {
			writeSamples(o.samplesOut, pooled)
		}
	}
	res.Count = o.count
	res.Errors = errs.n
	res.ErrorSamples = errs.samples
	return res
}

func runWorker(o *options, body []byte, idx int, count int64, gate <-chan struct{}, markReady func()) workerResult {
	var wr workerResult
	conn, err := dial(o)
	if err != nil {
		wr.err = fmt.Errorf("worker %d dial: %w", idx, err)
		return wr
	}
	defer closeConn(conn)
	ch, err := conn.Channel()
	if err != nil {
		wr.err = fmt.Errorf("worker %d channel: %w", idx, err)
		return wr
	}
	t, err := declareTopo(o, idx, ch)
	if err != nil {
		wr.err = err
		return wr
	}
	markReady()

	switch o.workload {
	case "latency":
		return latencyWorker(o, t, body, count, gate, ch, wr)
	case "publish":
		return publishWorker(o, t, body, gate, ch, wr)
	case "confirm":
		return confirmWorker(o, t, body, count, gate, ch, wr)
	case "fanout":
		return fanoutWorker(o, t, body, count, gate, ch, wr)
	default:
		return pubgetWorker(o, t, body, count, gate, ch, wr)
	}
}

// ---- publish (duration-bounded, fire-and-forget) ---------------------------

func publishWorker(o *options, t topo, body []byte, gate <-chan struct{}, ch *amqp.Channel, wr workerResult) workerResult {
	<-gate
	deadline := time.Now().Add(time.Duration(o.duration * float64(time.Second)))
	warmEnd := time.Now().Add(time.Duration(o.duration * o.warmup * float64(time.Second)))
	var n int64
	var warmBase int64
	warmed := false
	wr.start = time.Now()
	const batch = 64
	msg := amqp.Publishing{ContentType: "application/octet-stream", DeliveryMode: 1, Body: body}
	for {
		now := time.Now()
		if !warmed && now.After(warmEnd) {
			warmed = true
			warmBase = n
			wr.start = now
		}
		if now.After(deadline) {
			break
		}
		for i := 0; i < batch; i++ {
			if err := ch.Publish(t.exchange, t.routing, false, false, msg); err != nil {
				wr.err = fmt.Errorf("worker publish: %w", err)
				wr.timedOps = n - warmBase
				wr.end = time.Now()
				return wr
			}
			n++
		}
	}
	if !warmed {
		wr.start = time.Now().Add(-time.Duration(o.duration * float64(time.Second)))
	}
	wr.timedOps = n - warmBase
	wr.end = time.Now()
	return wr
}

// ---- pubget (closed loop, bounded batch) -----------------------------------

func pubgetWorker(o *options, t topo, body []byte, count int64, gate <-chan struct{}, ch *amqp.Channel, wr workerResult) workerResult {
	<-gate
	q := t.queues[0]
	warm := int64(float64(count) * o.warmup)
	if warm > count {
		warm = count
	}
	msg := amqp.Publishing{ContentType: "application/octet-stream", DeliveryMode: 1, Body: body}
	batch := int64(pubBatch(o.payload))
	var done int64
	warmed := false
	wr.start = time.Now()
	var timedStart time.Time
	var timedOps int64
	for done < count {
		b := batch
		if count-done < b {
			b = count - done
		}
		if !warmed && done+b > warm {
			warmed = true
			timedStart = time.Now()
		}
		for i := int64(0); i < b; i++ {
			if err := ch.Publish(t.exchange, t.routing, false, false, msg); err != nil {
				wr.err = fmt.Errorf("publish: %w", err)
				wr.timedOps = timedOps
				wr.end = time.Now()
				return wr
			}
		}
		if err := drainQueue(ch, q, int(b), 10*time.Second); err != nil {
			wr.err = err
			wr.timedOps = timedOps
			wr.end = time.Now()
			return wr
		}
		newDone := done + b
		if newDone > warm {
			lo := done
			if lo < warm {
				lo = warm
			}
			timedOps += newDone - lo
		}
		done = newDone
	}
	if timedStart.IsZero() {
		timedStart = time.Now()
	}
	wr.start = timedStart
	wr.timedOps = timedOps
	wr.end = time.Now()
	return wr
}

// ---- confirm (wait per publish) --------------------------------------------

func confirmWorker(o *options, t topo, body []byte, count int64, gate <-chan struct{}, ch *amqp.Channel, wr workerResult) workerResult {
	<-gate
	q := t.queues[0]
	if err := ch.Confirm(false); err != nil {
		wr.err = fmt.Errorf("confirm.select: %w", err)
		return wr
	}
	warm := int64(float64(count) * o.warmup)
	if warm > count {
		warm = count
	}
	msg := amqp.Publishing{ContentType: "application/octet-stream", DeliveryMode: 1, Body: body}
	var timedOps int64
	var timedStart time.Time
	wr.start = time.Now()
	drained := 0
	drainEvery := confirmBatch(o.payload)
	for i := int64(0); i < count; i++ {
		dc, err := ch.PublishWithDeferredConfirm(t.exchange, t.routing, false, false, msg)
		if err != nil {
			wr.err = fmt.Errorf("publish confirm: %w", err)
			break
		}
		ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
		ok, waitErr := dc.WaitContext(ctx)
		cancel()
		if waitErr != nil {
			wr.err = fmt.Errorf("confirm wait: %w", waitErr)
			break
		}
		if !ok {
			wr.err = fmt.Errorf("publish was nacked")
			break
		}
		if i == warm {
			timedStart = time.Now()
		}
		if i >= warm {
			timedOps++
		}
		// Untimed drain keeps the queue bounded.
		drained++
		if drained >= drainEvery {
			if err := drainQueue(ch, q, drained, 10*time.Second); err != nil {
				wr.err = err
				break
			}
			drained = 0
		}
	}
	if drained > 0 {
		if err := drainQueue(ch, q, drained, 10*time.Second); err != nil && wr.err == nil {
			wr.err = err
		}
	}
	if timedStart.IsZero() {
		timedStart = time.Now()
	}
	wr.start = timedStart
	wr.timedOps = timedOps
	wr.end = time.Now()
	return wr
}

// ---- fanout (1 exchange -> --declares queues) ------------------------------

func fanoutWorker(o *options, t topo, body []byte, count int64, gate <-chan struct{}, ch *amqp.Channel, wr workerResult) workerResult {
	<-gate
	warm := int64(float64(count) * o.warmup)
	if warm > count {
		warm = count
	}
	msg := amqp.Publishing{ContentType: "application/octet-stream", DeliveryMode: 1, Body: body}
	batch := int64(pubBatch(o.payload))
	var done int64
	warmed := false
	var timedStart time.Time
	var timedOps int64
	wr.start = time.Now()
	for done < count {
		b := batch
		if count-done < b {
			b = count - done
		}
		if !warmed && done+b > warm {
			warmed = true
			timedStart = time.Now()
		}
		for i := int64(0); i < b; i++ {
			if err := ch.Publish(t.exchange, t.routing, false, false, msg); err != nil {
				wr.err = fmt.Errorf("publish: %w", err)
				wr.timedOps = timedOps
				wr.end = time.Now()
				return wr
			}
		}
		for _, q := range t.queues {
			if err := drainQueue(ch, q, int(b), 10*time.Second); err != nil {
				wr.err = err
				wr.timedOps = timedOps
				wr.end = time.Now()
				return wr
			}
		}
		newDone := done + b
		if newDone > warm {
			lo := done
			if lo < warm {
				lo = warm
			}
			timedOps += newDone - lo
		}
		done = newDone
	}
	if timedStart.IsZero() {
		timedStart = time.Now()
	}
	wr.start = timedStart
	wr.timedOps = timedOps
	wr.end = time.Now()
	return wr
}

// ---- latency (publish -> get -> ack, one in flight) ------------------------

func latencyWorker(o *options, t topo, body []byte, count int64, gate <-chan struct{}, ch *amqp.Channel, wr workerResult) workerResult {
	<-gate
	q := t.queues[0]
	warm := int64(float64(count) * o.warmup)
	if warm > count {
		warm = count
	}
	msg := amqp.Publishing{ContentType: "application/octet-stream", DeliveryMode: 1, Body: body}
	samples := make([]float64, 0, count)
	wr.start = time.Now()
	for i := int64(0); i < count; i++ {
		t0 := time.Now()
		if err := ch.Publish(t.exchange, t.routing, false, false, msg); err != nil {
			wr.err = fmt.Errorf("publish: %w", err)
			break
		}
		d, ok, err := ch.Get(q, false)
		if err != nil {
			wr.err = fmt.Errorf("get: %w", err)
			break
		}
		if !ok {
			wr.err = fmt.Errorf("get returned empty on a queue we just published to")
			break
		}
		if err := d.Ack(false); err != nil {
			wr.err = fmt.Errorf("ack: %w", err)
			break
		}
		if i >= warm {
			samples = append(samples, float64(time.Since(t0).Microseconds()))
		}
	}
	wr.samples = samples
	wr.timedOps = int64(len(samples))
	wr.end = time.Now()
	return wr
}

// ---- helpers ---------------------------------------------------------------

func drainQueue(ch *amqp.Channel, q string, n int, timeout time.Duration) error {
	deadline := time.Now().Add(timeout)
	got := 0
	for got < n {
		if time.Now().After(deadline) {
			return fmt.Errorf("drain %q timeout: %d/%d", q, got, n)
		}
		_, ok, err := ch.Get(q, true)
		if err != nil {
			return fmt.Errorf("drain get %q: %w", q, err)
		}
		if !ok {
			time.Sleep(100 * time.Microsecond)
			continue
		}
		got++
	}
	return nil
}

// pubBatch bounds the number of messages held in flight so that
// batch*payload stays near 512 KiB regardless of payload size; without this,
// 256 KiB payloads at 32 connections would hold ~1 GiB per broker.
func pubBatch(payload int) int {
	b := 524288 / payload
	if b < 1 {
		b = 1
	}
	if b > 128 {
		b = 128
	}
	return b
}

// confirmBatch is the untimed drain interval, bounded near 1 MiB.
func confirmBatch(payload int) int {
	b := 1048576 / payload
	if b < 1 {
		b = 1
	}
	if b > 256 {
		b = 256
	}
	return b
}

func mkbody(n int) []byte {
	b := make([]byte, n)
	for i := range b {
		b[i] = byte((i*31 + 7) & 0xFF)
	}
	return b
}

func pct(xs []float64, q float64) float64 {
	if len(xs) == 0 {
		return 0
	}
	sorted := make([]float64, len(xs))
	copy(sorted, xs)
	sort.Float64s(sorted)
	if len(sorted) == 1 {
		return sorted[0]
	}
	idx := int(math.Round(q * float64(len(sorted)-1)))
	if idx < 0 {
		idx = 0
	}
	if idx >= len(sorted) {
		idx = len(sorted) - 1
	}
	return sorted[idx]
}

func writeSamples(path string, samples []float64) {
	var b strings.Builder
	for _, s := range samples {
		fmt.Fprintf(&b, "%.0f\n", s)
	}
	_ = os.WriteFile(path, []byte(b.String()), 0o644)
}

func round1(f float64) float64 { return math.Round(f*10) / 10 }
func round3(f float64) float64 { return math.Round(f*1000) / 1000 }