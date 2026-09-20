// amqp.go — a MINIMAL raw AMQP 0-9-1 client over the Transport seam.
//
// This is deliberately not a library: it implements exactly the methods the
// interface benchmark exercises, so the measured cost is the broker + the
// carrier, not a client framework. The same code runs over TCP and WS.
//
// Wire facts this client relies on (see src/hyrx/amqp/frame_codec.mojo and
// src/hyrxmq/amqp_service.mojo):
//   frame = type(1) + channel(2) + size(4) + payload(size) + 0xCE(1)
//   protocol header = "AMQP\x00\x00\x09\x01"
//   SASL PLAIN response = authzid NUL authcid NUL passwd
package main

import (
	"encoding/binary"
	"fmt"
	"io"
	"time"
)

const (
	frameMethod    = 1
	frameHeader    = 2
	frameBody      = 3
	frameHeartbeat = 8
	frameEnd       = 0xCE
)

const (
	classConnection = 10
	classChannel    = 20
	classExchange   = 40
	classQueue      = 50
	classBasic      = 60
	classConfirm    = 85
)

// AMQPClient is one connection + one channel's worth of raw protocol state.
type AMQPClient struct {
	t           Transport
	rbuf        []byte
	frameMax    int
	channelMax  int
	confirmMode bool
	nextConfirm uint64 // 1-based publish counter while confirm mode is on
}

func NewAMQPClient(t Transport) *AMQPClient {
	return &AMQPClient{t: t, frameMax: 131072}
}

// ---- byte helpers ----------------------------------------------------------

func appendU16(b []byte, v uint16) []byte {
	return append(b, byte(v>>8), byte(v))
}
func appendU32(b []byte, v uint32) []byte {
	return append(b, byte(v>>24), byte(v>>16), byte(v>>8), byte(v))
}
func appendU64(b []byte, v uint64) []byte {
	return append(b,
		byte(v>>56), byte(v>>48), byte(v>>40), byte(v>>32),
		byte(v>>24), byte(v>>16), byte(v>>8), byte(v))
}
func appendShortstr(b []byte, s string) []byte {
	b = append(b, byte(len(s)))
	return append(b, s...)
}
func appendLongstr(b []byte, s []byte) []byte {
	b = appendU32(b, uint32(len(s)))
	return append(b, s...)
}

type argReader struct {
	b []byte
	i int
}

func (r *argReader) u8() byte {
	v := r.b[r.i]
	r.i++
	return v
}
func (r *argReader) u16() uint16 {
	v := binary.BigEndian.Uint16(r.b[r.i:])
	r.i += 2
	return v
}
func (r *argReader) u32() uint32 {
	v := binary.BigEndian.Uint32(r.b[r.i:])
	r.i += 4
	return v
}
func (r *argReader) u64() uint64 {
	v := binary.BigEndian.Uint64(r.b[r.i:])
	r.i += 8
	return v
}
func (r *argReader) shortstr() string {
	n := int(r.b[r.i])
	r.i++
	s := string(r.b[r.i : r.i+n])
	r.i += n
	return s
}
func (r *argReader) longstr() []byte {
	n := int(r.u32())
	s := r.b[r.i : r.i+n]
	r.i += n
	return s
}

func methodIDs(payload []byte) (uint16, uint16, []byte) {
	if len(payload) < 4 {
		return 0, 0, nil
	}
	return binary.BigEndian.Uint16(payload[0:2]),
		binary.BigEndian.Uint16(payload[2:4]),
		payload[4:]
}

// ---- raw I/O ---------------------------------------------------------------

func (c *AMQPClient) readMore() error {
	scratch := make([]byte, 65536)
	n, err := c.t.Read(scratch)
	if n > 0 {
		c.rbuf = append(c.rbuf, scratch[:n]...)
		return nil
	}
	if err == nil {
		err = io.EOF
	}
	return err
}

// readFrame returns the next non-heartbeat frame (heartbeats are skipped).
func (c *AMQPClient) readFrame() (byte, uint16, []byte, error) {
	for {
		for len(c.rbuf) < 7 {
			if err := c.readMore(); err != nil {
				return 0, 0, nil, err
			}
		}
		ftype := c.rbuf[0]
		ch := binary.BigEndian.Uint16(c.rbuf[1:3])
		size := int(binary.BigEndian.Uint32(c.rbuf[3:7]))
		total := 7 + size + 1
		for len(c.rbuf) < total {
			if err := c.readMore(); err != nil {
				return 0, 0, nil, err
			}
		}
		if c.rbuf[7+size] != frameEnd {
			return 0, 0, nil, fmt.Errorf("bad frame-end byte %#x on type %d", c.rbuf[7+size], ftype)
		}
		payload := make([]byte, size)
		copy(payload, c.rbuf[7:7+size])
		c.rbuf = c.rbuf[total:]
		if ftype == frameHeartbeat {
			continue
		}
		return ftype, ch, payload, nil
	}
}

func (c *AMQPClient) sendMethod(ch, class, method uint16, args []byte) error {
	buf := make([]byte, 0, 12+len(args))
	buf = append(buf, frameMethod)
	buf = appendU16(buf, ch)
	buf = appendU32(buf, uint32(4+len(args)))
	buf = appendU16(buf, class)
	buf = appendU16(buf, method)
	buf = append(buf, args...)
	buf = append(buf, frameEnd)
	_, err := c.t.Write(buf)
	return err
}

// ---- error decoding --------------------------------------------------------

func connCloseErr(args []byte) error {
	r := &argReader{b: args}
	code := r.u16()
	text := r.shortstr()
	return fmt.Errorf("server connection.close %d: %s", code, text)
}

func channelCloseErr(args []byte) error {
	r := &argReader{b: args}
	code := r.u16()
	text := r.shortstr()
	return fmt.Errorf("server channel.close %d: %s", code, text)
}

// readContent consumes the HEADER frame and its BODY frames after a content
// bearing method, returning the reassembled body.
func (c *AMQPClient) readContent() ([]byte, error) {
	ft, _, pl, err := c.readFrame()
	if err != nil {
		return nil, err
	}
	if ft != frameHeader {
		return nil, fmt.Errorf("expected content header, got frame type %d", ft)
	}
	if len(pl) < 14 {
		return nil, fmt.Errorf("short content header (%d bytes)", len(pl))
	}
	bodySize := binary.BigEndian.Uint64(pl[4:12])
	body := make([]byte, 0, bodySize)
	for uint64(len(body)) < bodySize {
		bft, _, bpl, err := c.readFrame()
		if err != nil {
			return nil, err
		}
		if bft != frameBody {
			return nil, fmt.Errorf("expected content body, got frame type %d", bft)
		}
		body = append(body, bpl...)
	}
	return body, nil
}

// expect reads until the wanted method arrives, tolerating (and draining)
// basic.return content and surfacing server-side close frames as errors.
func (c *AMQPClient) expect(ch, class, method uint16, timeout time.Duration) ([]byte, error) {
	if d, ok := c.t.(deadliner); ok && timeout > 0 {
		_ = d.SetReadDeadline(time.Now().Add(timeout))
		defer d.SetReadDeadline(time.Time{})
	}
	for {
		ft, rch, pl, err := c.readFrame()
		if err != nil {
			return nil, err
		}
		if ft != frameMethod {
			continue
		}
		cl, m, args := methodIDs(pl)
		switch {
		case cl == classConnection && m == 50:
			return nil, connCloseErr(args)
		case cl == classChannel && m == 40:
			return nil, channelCloseErr(args)
		case cl == classBasic && m == 50:
			if _, err := c.readContent(); err != nil {
				return nil, err
			}
			continue
		case cl == class && m == method && (rch == ch || class == classConnection):
			return args, nil
		}
	}
}

// ---- handshake -------------------------------------------------------------

func (c *AMQPClient) Handshake(user, pass, vhost string) error {
	if _, err := c.t.Write([]byte{'A', 'M', 'Q', 'P', 0, 0, 9, 1}); err != nil {
		return fmt.Errorf("write protocol header: %w", err)
	}
	// connection.start (10,10)
	_, _, pl, err := c.readFrame()
	if err != nil {
		return fmt.Errorf("read connection.start: %w", err)
	}
	cl, m, _ := methodIDs(pl)
	if cl != classConnection || m != 10 {
		return fmt.Errorf("expected connection.start, got %d.%d", cl, m)
	}
	// start-ok: client-properties(table) + mechanism + response + locale
	var a []byte
	a = appendU32(a, 0) // empty client-properties field table
	a = appendShortstr(a, "PLAIN")
	sasl := []byte{0}
	sasl = append(sasl, user...)
	sasl = append(sasl, 0)
	sasl = append(sasl, pass...)
	a = appendLongstr(a, sasl)
	a = appendShortstr(a, "en_US")
	if err := c.sendMethod(0, classConnection, 11, a); err != nil {
		return fmt.Errorf("write start-ok: %w", err)
	}
	// connection.tune (10,30) — or connection.close on refused auth.
	_, _, pl, err = c.readFrame()
	if err != nil {
		return fmt.Errorf("read connection.tune: %w", err)
	}
	cl, m, args := methodIDs(pl)
	if cl == classConnection && m == 50 {
		return connCloseErr(args)
	}
	if cl != classConnection || m != 30 {
		return fmt.Errorf("expected connection.tune, got %d.%d", cl, m)
	}
	tr := &argReader{b: args}
	c.channelMax = int(tr.u16())
	c.frameMax = int(tr.u32())
	_ = tr.u16() // server heartbeat
	if c.frameMax <= 0 {
		c.frameMax = 131072
	}
	// tune-ok: request "no limit" so the server's own ceilings hold.
	var tok []byte
	tok = appendU16(tok, 0)
	tok = appendU32(tok, 0)
	tok = appendU16(tok, 0)
	if err := c.sendMethod(0, classConnection, 31, tok); err != nil {
		return fmt.Errorf("write tune-ok: %w", err)
	}
	// connection.open: virtual-host + reserved-1 + reserved-2 bit
	var o []byte
	o = appendShortstr(o, vhost)
	o = appendShortstr(o, "")
	o = append(o, 0)
	if err := c.sendMethod(0, classConnection, 40, o); err != nil {
		return fmt.Errorf("write connection.open: %w", err)
	}
	if _, err := c.expect(0, classConnection, 41, 10*time.Second); err != nil {
		return fmt.Errorf("connection.open-ok: %w", err)
	}
	return nil
}

// ---- channel / topology ----------------------------------------------------

func (c *AMQPClient) ChannelOpen(ch uint16) error {
	if err := c.sendMethod(ch, classChannel, 10, appendShortstr(nil, "")); err != nil {
		return err
	}
	_, err := c.expect(ch, classChannel, 11, 10*time.Second)
	return err
}

func (c *AMQPClient) ExchangeDeclare(ch uint16, name, kind string, durable, autoDelete bool) error {
	var mask byte
	if durable {
		mask |= 2
	}
	if autoDelete {
		mask |= 4
	}
	var a []byte
	a = appendU16(a, 0) // reserved-1
	a = appendShortstr(a, name)
	a = appendShortstr(a, kind)
	a = append(a, mask)
	a = appendU32(a, 0) // arguments table (empty)
	if err := c.sendMethod(ch, classExchange, 10, a); err != nil {
		return err
	}
	_, err := c.expect(ch, classExchange, 11, 10*time.Second)
	return err
}

func (c *AMQPClient) QueueDeclare(ch uint16, name string, durable, exclusive, autoDelete bool) (string, error) {
	var mask byte
	if durable {
		mask |= 2
	}
	if exclusive {
		mask |= 4
	}
	if autoDelete {
		mask |= 8
	}
	var a []byte
	a = appendU16(a, 0)
	a = appendShortstr(a, name)
	a = append(a, mask)
	a = appendU32(a, 0)
	if err := c.sendMethod(ch, classQueue, 10, a); err != nil {
		return "", err
	}
	args, err := c.expect(ch, classQueue, 11, 10*time.Second)
	if err != nil {
		return "", err
	}
	r := &argReader{b: args}
	return r.shortstr(), nil
}

func (c *AMQPClient) QueueBind(ch uint16, queue, exchange, key string) error {
	var a []byte
	a = appendU16(a, 0)
	a = appendShortstr(a, queue)
	a = appendShortstr(a, exchange)
	a = appendShortstr(a, key)
	a = append(a, 0)    // no-wait bit
	a = appendU32(a, 0) // arguments table (empty)
	if err := c.sendMethod(ch, classQueue, 20, a); err != nil {
		return err
	}
	_, err := c.expect(ch, classQueue, 21, 10*time.Second)
	return err
}

// ---- publish ---------------------------------------------------------------

func (c *AMQPClient) Publish(ch uint16, exchange, routingKey string, body []byte, mandatory bool) error {
	var bits byte
	if mandatory {
		bits |= 1
	}
	var a []byte
	a = appendU16(a, 0)
	a = appendShortstr(a, exchange)
	a = appendShortstr(a, routingKey)
	a = append(a, bits)

	out := make([]byte, 0, 12+len(a)+22+len(body)+8)
	out = appendMethodFrame(out, ch, classBasic, 40, a)
	out = appendHeaderFrame(out, ch, classBasic, len(body), 0, nil)
	out = appendBodyFrames(out, ch, body, c.bodyChunk())
	if _, err := c.t.Write(out); err != nil {
		return err
	}
	if c.confirmMode {
		c.nextConfirm++
	}
	return nil
}

func (c *AMQPClient) bodyChunk() int {
	chunk := c.frameMax - 8
	if chunk < 1 {
		chunk = 131064
	}
	return chunk
}

func appendMethodFrame(b []byte, ch, class, method uint16, args []byte) []byte {
	b = append(b, frameMethod)
	b = appendU16(b, ch)
	b = appendU32(b, uint32(4+len(args)))
	b = appendU16(b, class)
	b = appendU16(b, method)
	b = append(b, args...)
	return append(b, frameEnd)
}

func appendHeaderFrame(b []byte, ch, class uint16, bodySize int, propFlags uint16, props []byte) []byte {
	b = append(b, frameHeader)
	b = appendU16(b, ch)
	b = appendU32(b, uint32(14+len(props)))
	b = appendU16(b, class)
	b = appendU16(b, 0) // weight (reserved, MUST be 0)
	b = appendU64(b, uint64(bodySize))
	b = appendU16(b, propFlags)
	b = append(b, props...)
	return append(b, frameEnd)
}

func appendBodyFrames(b []byte, ch uint16, body []byte, chunk int) []byte {
	for pos := 0; pos < len(body); {
		n := chunk
		if pos+n > len(body) {
			n = len(body) - pos
		}
		b = append(b, frameBody)
		b = appendU16(b, ch)
		b = appendU32(b, uint32(n))
		b = append(b, body[pos:pos+n]...)
		b = append(b, frameEnd)
		pos += n
	}
	return b
}

// ---- get / ack -------------------------------------------------------------

// Get returns (body, tag, found, err). noAck=true resolves the delivery
// immediately server-side (auto-ack).
func (c *AMQPClient) Get(ch uint16, queue string, noAck bool) ([]byte, uint64, bool, error) {
	var a []byte
	a = appendU16(a, 0)
	a = appendShortstr(a, queue)
	var bits byte
	if noAck {
		bits |= 1
	}
	a = append(a, bits)
	if err := c.sendMethod(ch, classBasic, 70, a); err != nil {
		return nil, 0, false, err
	}
	if d, ok := c.t.(deadliner); ok {
		_ = d.SetReadDeadline(time.Now().Add(15 * time.Second))
		defer d.SetReadDeadline(time.Time{})
	}
	for {
		ft, _, pl, err := c.readFrame()
		if err != nil {
			return nil, 0, false, err
		}
		if ft != frameMethod {
			continue
		}
		cl, m, args := methodIDs(pl)
		switch {
		case cl == classConnection && m == 50:
			return nil, 0, false, connCloseErr(args)
		case cl == classChannel && m == 40:
			return nil, 0, false, channelCloseErr(args)
		case cl == classBasic && m == 50: // basic.return: drain, keep waiting
			if _, err := c.readContent(); err != nil {
				return nil, 0, false, err
			}
		case cl == classBasic && m == 72: // get-empty
			return nil, 0, false, nil
		case cl == classBasic && m == 71: // get-ok
			r := &argReader{b: args}
			tag := r.u64()
			_ = r.u8()       // redelivered
			_ = r.shortstr() // exchange
			_ = r.shortstr() // routing key
			_ = r.u32()      // message-count
			body, err := c.readContent()
			return body, tag, true, err
		}
	}
}

func (c *AMQPClient) Ack(ch uint16, tag uint64) error {
	a := appendU64(nil, tag)
	a = append(a, 0) // multiple=false
	return c.sendMethod(ch, classBasic, 80, a)
}

// ---- publisher confirms ----------------------------------------------------

func (c *AMQPClient) ConfirmSelect(ch uint16) error {
	if err := c.sendMethod(ch, classConfirm, 10, []byte{0}); err != nil {
		return err
	}
	if _, err := c.expect(ch, classConfirm, 11, 10*time.Second); err != nil {
		return err
	}
	c.confirmMode = true
	c.nextConfirm = 0
	return nil
}

// WaitConfirm reads until the per-publish basic.ack with tag >= want arrives.
func (c *AMQPClient) WaitConfirm(ch uint16, want uint64, timeout time.Duration) error {
	if d, ok := c.t.(deadliner); ok && timeout > 0 {
		_ = d.SetReadDeadline(time.Now().Add(timeout))
		defer d.SetReadDeadline(time.Time{})
	}
	for {
		ft, _, pl, err := c.readFrame()
		if err != nil {
			return err
		}
		if ft != frameMethod {
			continue
		}
		cl, m, args := methodIDs(pl)
		switch {
		case cl == classConnection && m == 50:
			return connCloseErr(args)
		case cl == classChannel && m == 40:
			return channelCloseErr(args)
		case cl == classBasic && m == 50:
			if _, err := c.readContent(); err != nil {
				return err
			}
		case cl == classBasic && m == 80: // basic.ack (confirm)
			r := &argReader{b: args}
			tag := r.u64()
			if tag >= want {
				return nil
			}
		}
	}
}

// ---- consume ---------------------------------------------------------------

func (c *AMQPClient) Consume(ch uint16, queue, consumerTag string, noAck bool) (string, error) {
	var a []byte
	a = appendU16(a, 0)
	a = appendShortstr(a, queue)
	a = appendShortstr(a, consumerTag)
	var bits byte
	if noAck {
		bits |= 2
	}
	a = append(a, bits)
	a = appendU32(a, 0)
	if err := c.sendMethod(ch, classBasic, 20, a); err != nil {
		return "", err
	}
	args, err := c.expect(ch, classBasic, 21, 10*time.Second)
	if err != nil {
		return "", err
	}
	r := &argReader{b: args}
	return r.shortstr(), nil
}

// ConsumeNext reads the next basic.deliver message (+ content) on the channel.
func (c *AMQPClient) ConsumeNext(ch uint16) ([]byte, uint64, error) {
	if d, ok := c.t.(deadliner); ok {
		_ = d.SetReadDeadline(time.Now().Add(30 * time.Second))
		defer d.SetReadDeadline(time.Time{})
	}
	for {
		ft, _, pl, err := c.readFrame()
		if err != nil {
			return nil, 0, err
		}
		if ft != frameMethod {
			continue
		}
		cl, m, args := methodIDs(pl)
		switch {
		case cl == classConnection && m == 50:
			return nil, 0, connCloseErr(args)
		case cl == classChannel && m == 40:
			return nil, 0, channelCloseErr(args)
		case cl == classBasic && m == 50:
			if _, err := c.readContent(); err != nil {
				return nil, 0, err
			}
		case cl == classBasic && m == 60: // basic.deliver
			r := &argReader{b: args}
			_ = r.shortstr() // consumer tag
			tag := r.u64()
			_ = r.u8()       // redelivered
			_ = r.shortstr() // exchange
			_ = r.shortstr() // routing key
			body, err := c.readContent()
			return body, tag, err
		}
	}
}

// Close sends connection.close best-effort; teardown never blocks the harness.
func (c *AMQPClient) Close() {
	var a []byte
	a = appendU16(a, 200)
	a = appendShortstr(a, "")
	a = appendU16(a, 0)
	a = appendU16(a, 0)
	_ = c.sendMethod(0, classConnection, 50, a)
}