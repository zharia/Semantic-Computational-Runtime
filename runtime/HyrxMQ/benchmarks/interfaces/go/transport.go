// transport.go — the one byte-stream seam the benchmark varies.
//
// The AMQP client (amqp.go) speaks only to the Transport interface, so the
// TCP and WebSocket runs execute IDENTICAL client code; the only difference
// is which Transport implementation is dialed. That is what isolates the
// WebSocket carrier overhead from the broker's AMQP behavior.
//
// TCPTransport: a net.Conn with TCP_NODELAY set on connect.
// WSTransport:  a gorilla *websocket.Conn. Each Write is ONE RFC 6455 binary
//               message carrying ALL the bytes handed over. Read concatenates
//               WS payloads into a byte stream (short reads allowed) so the
//               AMQP frame parser in amqp.go sees a transport-independent
//               stream regardless of how many AMQP frames ride one WS message.
package main

import (
	"crypto/tls"
	"net"
	"time"

	"github.com/gorilla/websocket"
)

// Transport is the minimal byte-stream surface the AMQP client needs.
type Transport interface {
	Write([]byte) (int, error)
	Read([]byte) (int, error)
	Close() error
}

// deadliner lets the confirm/latency paths bound a blocking read without
// widening the Transport interface (both implementations support it).
type deadliner interface {
	SetReadDeadline(time.Time) error
}

// ---- TCP -------------------------------------------------------------------

type TCPTransport struct {
	c net.Conn
}

// DialTCP connects to host:port as a plaintext AMQP byte stream.
func DialTCP(addr string) (*TCPTransport, error) {
	d := net.Dialer{Timeout: 10 * time.Second}
	c, err := d.Dial("tcp", addr)
	if err != nil {
		return nil, err
	}
	if tc, ok := c.(*net.TCPConn); ok {
		_ = tc.SetNoDelay(true)
	}
	return &TCPTransport{c: c}, nil
}

func (t *TCPTransport) Write(p []byte) (int, error) {
	total := 0
	for total < len(p) {
		n, err := t.c.Write(p[total:])
		total += n
		if err != nil {
			return total, err
		}
	}
	return total, nil
}

func (t *TCPTransport) Read(p []byte) (int, error) { return t.c.Read(p) }

func (t *TCPTransport) Close() error { return t.c.Close() }

func (t *TCPTransport) SetReadDeadline(d time.Time) error { return t.c.SetReadDeadline(d) }

// ---- WebSocket -------------------------------------------------------------

type WSTransport struct {
	c   *websocket.Conn
	buf []byte // decoded WS payload bytes not yet copied to the caller
}

// DialWS performs the RFC 7395 upgrade: GET /ws with the REQUIRED
// `Sec-WebSocket-Protocol: amqp` subprotocol. useTLS selects ws:// vs wss://.
func DialWS(addr string, useTLS, insecureSkipVerify bool) (*WSTransport, error) {
	scheme := "ws"
	if useTLS {
		scheme = "wss"
	}
	dialer := websocket.Dialer{
		Subprotocols:     []string{"amqp"},
		HandshakeTimeout: 10 * time.Second,
	}
	if useTLS {
		dialer.TLSClientConfig = &tls.Config{InsecureSkipVerify: insecureSkipVerify}
	}
	c, _, err := dialer.Dial(scheme+"://"+addr+"/ws", nil)
	if err != nil {
		return nil, err
	}
	// A single WS message may carry a whole AMQP frame (up to the server's
	// 16 MiB payload cap); keep that ceiling generous.
	c.SetReadLimit(32 << 20)
	return &WSTransport{c: c}, nil
}

// Write sends ONE binary WebSocket message containing all of p.
func (t *WSTransport) Write(p []byte) (int, error) {
	if err := t.c.WriteMessage(websocket.BinaryMessage, p); err != nil {
		return 0, err
	}
	return len(p), nil
}

// Read copies buffered WS payload bytes; when empty it blocks for the next
// binary message and appends its payload to the stream buffer.
func (t *WSTransport) Read(p []byte) (int, error) {
	for len(t.buf) == 0 {
		_, msg, err := t.c.ReadMessage()
		if err != nil {
			return 0, err
		}
		if len(msg) == 0 {
			continue
		}
		t.buf = append(t.buf, msg...)
	}
	n := copy(p, t.buf)
	t.buf = t.buf[n:]
	return n, nil
}

func (t *WSTransport) Close() error { return t.c.Close() }

func (t *WSTransport) SetReadDeadline(d time.Time) error { return t.c.SetReadDeadline(d) }