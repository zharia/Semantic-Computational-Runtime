// main.go — HyrxMQ TCP-vs-WebSocket interface benchmark (Go load generator).
//
// One goroutine per connection; each owns its own connection + channel and its
// own exchange/queue so concurrent workers never contend on one queue. The
// TCP and WS runs execute the same code; only --transport changes.
//
// Output: exactly one JSON line on stdout.
package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"math"
	"os"
	"sort"
	"sync"
	"sync/atomic"
	"time"
)

type options struct {
	transport   string
	url         string
	tls         bool
	insecure    bool
	workload    string
	payload     int
	count       int64
	concurrency int
	duration    float64
	exchange    string
	queue       string
	routingKey  string
	user        string
	pass        string
	vhost       string
	warmup      float64
	probe       bool
}

type workerResult struct {
	timedOps int64
	start    time.Time
	end      time.Time
	samples  []float64
	err      error
}

type result struct {
	Transport   string      `json:"transport"`
	Workload    string      `json:"workload"`
	Payload     int         `json:"payload"`
	Concurrency int         `json:"concurrency"`
	MsgsPerSec  float64     `json:"msgs_per_sec"`
	P50Us       interface{} `json:"p50_us"`
	P95Us       interface{} `json:"p95_us"`
	P99Us       interface{} `json:"p99_us"`
	P999Us      interface{} `json:"p999_us"`
	Errors      int         `json:"errors"`
	Count       int64       `json:"count"`
	WallS       float64     `json:"wall_s"`
}

func main() {
	var o options
	flag.StringVar(&o.transport, "transport", "tcp", "tcp|ws")
	flag.StringVar(&o.url, "url", "127.0.0.1:5673", "host:port (no scheme)")
	flag.BoolVar(&o.tls, "tls", false, "ws: dial wss:// instead of ws:// ; tcp: unused")
	flag.BoolVar(&o.insecure, "insecure", false, "ws: skip TLS certificate verification")
	flag.StringVar(&o.workload, "workload", "publish", "publish|pubget|confirm|latency")
	flag.IntVar(&o.payload, "payload", 1024, "payload bytes")
	flag.Int64Var(&o.count, "count", 20000, "messages per run (pubget/confirm/latency)")
	flag.IntVar(&o.concurrency, "concurrency", 1, "connections (goroutines)")
	flag.Float64Var(&o.duration, "duration", 2.0, "seconds; publish runs for this long")
	flag.StringVar(&o.exchange, "exchange", "bench.ex", "exchange base name")
	flag.StringVar(&o.queue, "queue", "bench.q", "queue base name")
	flag.StringVar(&o.routingKey, "routing-key", "rk", "direct routing key")
	flag.StringVar(&o.user, "user", "admin", "SASL PLAIN username")
	flag.StringVar(&o.pass, "pass", "password", "SASL PLAIN password")
	flag.StringVar(&o.vhost, "vhost", "/", "virtual host")
	flag.Float64Var(&o.warmup, "warmup", 0.10, "fraction of work discarded as warm-up")
	flag.BoolVar(&o.probe, "probe", false, "handshake + publish + get once; print PASS/FAIL")
	flag.Parse()

	if o.concurrency < 1 {
		o.concurrency = 1
	}
	if o.probe {
		probe(&o)
		return
	}

	res := run(&o)
	enc, _ := json.Marshal(res)
	fmt.Println(string(enc))
	if res.Errors > 0 && res.Count == 0 {
		os.Exit(1)
	}
}

func dialTransport(o *options) (Transport, error) {
	switch o.transport {
	case "tcp":
		return DialTCP(o.url)
	case "ws":
		return DialWS(o.url, o.tls, o.insecure)
	default:
		return nil, fmt.Errorf("unknown transport %q", o.transport)
	}
}

type workerCtx struct {
	conn  *AMQPClient
	ch    uint16
	exch  string
	queue string
	rk    string
}

func setupWorker(o *options, idx int) (*workerCtx, Transport, error) {
	t, err := dialTransport(o)
	if err != nil {
		return nil, nil, fmt.Errorf("dial: %w", err)
	}
	c := NewAMQPClient(t)
	if err := c.Handshake(o.user, o.pass, o.vhost); err != nil {
		_ = t.Close()
		return nil, nil, fmt.Errorf("handshake: %w", err)
	}
	ch := uint16(1)
	if err := c.ChannelOpen(ch); err != nil {
		_ = t.Close()
		return nil, nil, fmt.Errorf("channel.open: %w", err)
	}
	exch := fmt.Sprintf("%s.x.%d", o.exchange, idx)
	if err := c.ExchangeDeclare(ch, exch, "direct", false, false); err != nil {
		_ = t.Close()
		return nil, nil, fmt.Errorf("exchange.declare: %w", err)
	}
	wc := &workerCtx{conn: c, ch: ch, exch: exch, rk: o.routingKey}
	// publish does not need a queue (fire-and-forget sink); the others do.
	if o.workload != "publish" {
		q := fmt.Sprintf("%s.%d", o.queue, idx)
		if _, err := c.QueueDeclare(ch, q, false, false, false); err != nil {
			_ = t.Close()
			return nil, nil, fmt.Errorf("queue.declare: %w", err)
		}
		if err := c.QueueBind(ch, q, exch, o.routingKey); err != nil {
			_ = t.Close()
			return nil, nil, fmt.Errorf("queue.bind: %w", err)
		}
		wc.queue = q
	}
	return wc, t, nil
}

func run(o *options) result {
	res := result{
		Transport:   o.transport,
		Workload:    o.workload,
		Payload:     o.payload,
		Concurrency: o.concurrency,
	}
	body := mkbody(o.payload)
	share := o.count / int64(o.concurrency)
	remainder := o.count % int64(o.concurrency)

	results := make([]workerResult, o.concurrency)
	gate := make(chan struct{})
	var wg sync.WaitGroup
	var ready, connected int64

	for i := 0; i < o.concurrency; i++ {
		n := share
		if int64(i) < remainder {
			n++
		}
		wg.Add(1)
		go func(idx int, myCount int64) {
			defer wg.Done()
			wc, t, err := setupWorker(o, idx)
			atomic.AddInt64(&ready, 1)
			if err != nil {
				results[idx].err = fmt.Errorf("worker %d: %w", idx, err)
				return
			}
			atomic.AddInt64(&connected, 1)
			<-gate
			switch o.workload {
			case "publish":
				results[idx] = publishWorker(wc, body, o)
			case "pubget":
				results[idx] = pubgetWorker(wc, body, myCount, o)
			case "confirm":
				results[idx] = confirmWorker(wc, body, myCount, o)
			default: // latency
				results[idx] = latencyWorker(wc, body, myCount, o)
			}
			wc.conn.Close()
			_ = t.Close()
		}(i, n)
	}

	// Open the gate only once every worker has attempted its setup (or a
	// bounded budget expires) so the timed window is not skewed by dialing.
	deadline := time.Now().Add(15 * time.Second)
	for atomic.LoadInt64(&ready) < int64(o.concurrency) && time.Now().Before(deadline) {
		time.Sleep(2 * time.Millisecond)
	}

	gateOpen := time.Now()
	close(gate)
	wg.Wait()
	res.WallS = round3(time.Since(gateOpen).Seconds())

	var totalOps int64
	var minStart, maxEnd time.Time
	var pooled []float64
	errCount := 0
	for _, wr := range results {
		if wr.err != nil {
			errCount++
			fmt.Fprintf(os.Stderr, "worker error: %v\n", wr.err)
		}
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
	res.Count = totalOps
	if res.WallS > 0 {
		res.MsgsPerSec = round1(float64(totalOps) / res.WallS)
	}
	if o.workload == "latency" && len(pooled) > 0 {
		res.P50Us = round3(pct(pooled, 0.50))
		res.P95Us = round3(pct(pooled, 0.95))
		res.P99Us = round3(pct(pooled, 0.99))
		res.P999Us = round3(pct(pooled, 0.999))
	}
	res.Errors = errCount
	return res
}

// ---- workloads -------------------------------------------------------------

func publishWorker(wc *workerCtx, body []byte, o *options) workerResult {
	var wr workerResult
	wr.start = time.Now()
	deadline := time.Now().Add(time.Duration(o.duration * float64(time.Second)))
	warmEnd := time.Now().Add(time.Duration(o.duration * o.warmup * float64(time.Second)))
	const batch = 64
	var n, warmBase int64
	warmed := false
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
			if err := wc.conn.Publish(wc.ch, wc.exch, wc.rk, body, false); err != nil {
				wr.err = fmt.Errorf("publish: %w", err)
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

func pubgetWorker(wc *workerCtx, body []byte, count int64, o *options) workerResult {
	var wr workerResult
	batch := int64(pubBatch(o.payload))
	warm := int64(float64(count) * o.warmup)
	if warm > count {
		warm = count
	}
	var done, timedOps int64
	warmed := false
	wr.start = time.Now()
	for done < count {
		b := batch
		if count-done < b {
			b = count - done
		}
		if !warmed && done+b > warm {
			warmed = true
			wr.start = time.Now()
		}
		for i := int64(0); i < b; i++ {
			if err := wc.conn.Publish(wc.ch, wc.exch, wc.rk, body, false); err != nil {
				wr.err = fmt.Errorf("publish: %w", err)
				wr.timedOps = timedOps
				wr.end = time.Now()
				return wr
			}
		}
		for i := int64(0); i < b; i++ {
			if _, _, ok, err := wc.conn.Get(wc.ch, wc.queue, true); err != nil {
				wr.err = fmt.Errorf("get: %w", err)
				wr.timedOps = timedOps
				wr.end = time.Now()
				return wr
			} else if !ok {
				wr.err = fmt.Errorf("get-empty after publishing %d", b)
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
	if wr.start.IsZero() {
		wr.start = time.Now()
	}
	wr.timedOps = timedOps
	wr.end = time.Now()
	return wr
}

func confirmWorker(wc *workerCtx, body []byte, count int64, o *options) workerResult {
	var wr workerResult
	if err := wc.conn.ConfirmSelect(wc.ch); err != nil {
		wr.err = fmt.Errorf("confirm.select: %w", err)
		return wr
	}
	warm := int64(float64(count) * o.warmup)
	if warm > count {
		warm = count
	}
	var timedOps int64
	drained := 0
	drainEvery := confirmBatch(o.payload)
	wr.start = time.Now()
	for i := int64(0); i < count; i++ {
		if err := wc.conn.Publish(wc.ch, wc.exch, wc.rk, body, false); err != nil {
			wr.err = fmt.Errorf("publish: %w", err)
			break
		}
		if err := wc.conn.WaitConfirm(wc.ch, uint64(i+1), 15*time.Second); err != nil {
			wr.err = fmt.Errorf("confirm: %w", err)
			break
		}
		if i == warm {
			wr.start = time.Now()
		}
		if i >= warm {
			timedOps++
		}
		drained++
		if drained >= drainEvery {
			if err := drainQueue(wc, drained); err != nil {
				wr.err = err
				break
			}
			drained = 0
		}
	}
	if drained > 0 {
		if err := drainQueue(wc, drained); err != nil && wr.err == nil {
			wr.err = err
		}
	}
	if wr.start.IsZero() {
		wr.start = time.Now()
	}
	wr.timedOps = timedOps
	wr.end = time.Now()
	return wr
}

func latencyWorker(wc *workerCtx, body []byte, count int64, o *options) workerResult {
	var wr workerResult
	warm := int64(float64(count) * o.warmup)
	if warm > count {
		warm = count
	}
	samples := make([]float64, 0, count)
	wr.start = time.Now()
	for i := int64(0); i < count; i++ {
		t0 := time.Now()
		if err := wc.conn.Publish(wc.ch, wc.exch, wc.rk, body, false); err != nil {
			wr.err = fmt.Errorf("publish: %w", err)
			break
		}
		_, tag, ok, err := wc.conn.Get(wc.ch, wc.queue, false)
		if err != nil {
			wr.err = fmt.Errorf("get: %w", err)
			break
		}
		if !ok {
			wr.err = fmt.Errorf("get-empty after publish")
			break
		}
		if err := wc.conn.Ack(wc.ch, tag); err != nil {
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

func drainQueue(wc *workerCtx, n int) error {
	deadline := time.Now().Add(10 * time.Second)
	for got := 0; got < n; {
		if time.Now().After(deadline) {
			return fmt.Errorf("drain timeout %d/%d", got, n)
		}
		_, _, ok, err := wc.conn.Get(wc.ch, wc.queue, true)
		if err != nil {
			return err
		}
		if !ok {
			time.Sleep(100 * time.Microsecond)
			continue
		}
		got++
	}
	return nil
}

// pubBatch bounds batch*payload near 512 KiB; confirmBatch near 1 MiB.
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

func round1(f float64) float64 { return math.Round(f*10) / 10 }
func round3(f float64) float64 { return math.Round(f*1000) / 1000 }

// ---- probe -----------------------------------------------------------------

// probe completes handshake + channel.open + declare/bind + publish + get on
// ONE connection and prints a clear PASS/FAIL. It is the health gate used by
// run_interfaces.sh for each broker tier.
func probe(o *options) {
	wc, t, err := setupWorker(o, 0)
	if err != nil {
		fmt.Printf("FAIL transport=%s url=%s: %v\n", o.transport, o.url, err)
		os.Exit(1)
	}
	defer t.Close()
	defer wc.conn.Close()

	body := mkbody(o.payload)
	q := wc.queue
	if o.workload == "publish" || q == "" {
		// probe always exercises a round trip: declare a real queue.
		q = fmt.Sprintf("%s.probe", o.queue)
		if _, err := wc.conn.QueueDeclare(wc.ch, q, false, false, false); err != nil {
			fmt.Printf("FAIL transport=%s queue.declare: %v\n", o.transport, err)
			os.Exit(1)
		}
		if err := wc.conn.QueueBind(wc.ch, q, wc.exch, o.routingKey); err != nil {
			fmt.Printf("FAIL transport=%s queue.bind: %v\n", o.transport, err)
			os.Exit(1)
		}
	}
	if err := wc.conn.Publish(wc.ch, wc.exch, wc.rk, body, false); err != nil {
		fmt.Printf("FAIL transport=%s publish: %v\n", o.transport, err)
		os.Exit(1)
	}
	got, _, ok, err := wc.conn.Get(wc.ch, q, true)
	if err != nil {
		fmt.Printf("FAIL transport=%s get: %v\n", o.transport, err)
		os.Exit(1)
	}
	if !ok {
		fmt.Printf("FAIL transport=%s get returned empty\n", o.transport)
		os.Exit(1)
	}
	if len(got) != len(body) {
		fmt.Printf("FAIL transport=%s body size %d != %d\n", o.transport, len(got), len(body))
		os.Exit(1)
	}
	fmt.Printf("PASS transport=%s url=%s payload=%d roundtrip=ok\n", o.transport, o.url, o.payload)
}