// Go AMQP interop gate for HyrxMQ (M8.1).
//
// Drives the real `amqp091-go` client against build/hyrxmq-listen on a port that
// is NOT RabbitMQ's 5672 (default 5698). Verifies: connect/handshake,
// exchange+queue declare, bind, 10 publishes consumed back byte-for-byte,
// publisher confirms (Confirm/NotifyPublish), basic.return for a mandatory
// unroutable publish and channel QoS (prefetch).
//
// Port comes from HYRX_PORT (default 5698), host from HYRX_HOST (default
// 127.0.0.1). Prints GO_INTEROP=PASS or GO_INTEROP=FAIL with a detail list;
// exits 0 only on full PASS. The whole run shares a 30s context deadline.
package main

import (
	"context"
	"fmt"
	"net"
	"os"
	"time"

	amqp "github.com/rabbitmq/amqp091-go"
)

const (
	exchangeName = "go-ex"
	queueName    = "go-q"
	routingKey   = "go-key"
	unroutableRK = "go-no-route"
	messageCount = 10
	messagePrefx = "go-msg-"
	overallLimit = 30 * time.Second
)

func main() {
	ctx, cancel := context.WithTimeout(context.Background(), overallLimit)
	defer cancel()

	done := make(chan error, 1)
	go func() { done <- run(ctx) }()

	var err error
	select {
	case err = <-done:
	case <-ctx.Done():
		err = fmt.Errorf("overall timeout after %s: %w", overallLimit, ctx.Err())
	}

	if err == nil {
		fmt.Println("GO_INTEROP=PASS")
		os.Exit(0)
	}
	fmt.Println("GO_INTEROP=FAIL")
	fmt.Printf("  %v\n", err)
	os.Exit(1)
}

func run(ctx context.Context) error {
	host := getenv("HYRX_HOST", "127.0.0.1")
	port := getenv("HYRX_PORT", "5698")
	url := fmt.Sprintf("amqp://admin:password@%s:%s/", host, port)

	dialer := &net.Dialer{Timeout: 10 * time.Second}
	cfg := amqp.Config{
		Dial: func(network, addr string) (net.Conn, error) {
			return dialer.DialContext(ctx, network, addr)
		},
	}
	conn, err := amqp.DialConfig(url, cfg)
	if err != nil {
		return fmt.Errorf("dial %s: %w", url, err)
	}
	defer conn.Close()
	fmt.Printf("  connected to %s vhost=/\n", conn.LocalAddr())

	// Close the connection when the context fires so blocked reads unblock.
	stop := make(chan struct{})
	defer close(stop)
	go func() {
		select {
		case <-ctx.Done():
			conn.Close()
		case <-stop:
		}
	}()

	ch, err := conn.Channel()
	if err != nil {
		return fmt.Errorf("channel: %w", err)
	}
	defer ch.Close()

	if err := ch.ExchangeDeclare(exchangeName, "direct", false, true, false, false, nil); err != nil {
		return fmt.Errorf("exchange.declare: %w", err)
	}
	q, err := ch.QueueDeclare(queueName, false, true, true, false, nil)
	if err != nil {
		return fmt.Errorf("queue.declare: %w", err)
	}
	if err := ch.QueueBind(q.Name, routingKey, exchangeName, false, nil); err != nil {
		return fmt.Errorf("queue.bind: %w", err)
	}
	fmt.Printf("  declared direct '%s', queue '%s', bind '%s'\n", exchangeName, q.Name, routingKey)

	if err := ch.Qos(10, 0, false); err != nil {
		return fmt.Errorf("basic.qos: %w", err)
	}
	fmt.Println("  basic.qos prefetch=10 OK")

	if err := ch.Confirm(false); err != nil {
		return fmt.Errorf("confirm.select: %w", err)
	}
	confirms := ch.NotifyPublish(make(chan amqp.Confirmation, messageCount))
	returns := ch.NotifyReturn(make(chan amqp.Return, 1))

	deliveries, err := ch.Consume(q.Name, "go-consumer", false, true, false, false, nil)
	if err != nil {
		return fmt.Errorf("basic.consume: %w", err)
	}

	for i := 1; i <= messageCount; i++ {
		body := fmt.Sprintf("%s%d", messagePrefx, i)
		if err := ch.PublishWithContext(ctx, exchangeName, routingKey, false, false, amqp.Publishing{
			ContentType: "text/plain",
			Body:        []byte(body),
		}); err != nil {
			return fmt.Errorf("basic.publish #%d: %w", i, err)
		}
	}
	fmt.Printf("  published %d messages on '%s'\n", messageCount, routingKey)

	for i := 0; i < messageCount; i++ {
		select {
		case c := <-confirms:
			if !c.Ack {
				return fmt.Errorf("publisher confirm nacked (deliveryTag=%d)", c.DeliveryTag)
			}
		case <-ctx.Done():
			return fmt.Errorf("publisher confirms: %w", ctx.Err())
		}
	}
	fmt.Printf("  publisher confirms OK (broker acked all %d)\n", messageCount)

	received := make([]string, 0, messageCount)
	deadline := time.After(10 * time.Second)
	for len(received) < messageCount {
		select {
		case d, ok := <-deliveries:
			if !ok {
				return fmt.Errorf("deliveries closed after %d messages", len(received))
			}
			received = append(received, string(d.Body))
			if err := d.Ack(false); err != nil {
				return fmt.Errorf("basic.ack: %w", err)
			}
		case <-deadline:
			return fmt.Errorf("expected %d deliveries, got %d", messageCount, len(received))
		case <-ctx.Done():
			return fmt.Errorf("deliveries: %w", ctx.Err())
		}
	}
	for i, got := range received {
		want := fmt.Sprintf("%s%d", messagePrefx, i+1)
		if got != want {
			return fmt.Errorf("body mismatch at index %d: want %q, got %q", i, want, got)
		}
	}
	fmt.Printf("  consumed %d messages, bodies verified\n", len(received))

	if err := ch.PublishWithContext(ctx, exchangeName, unroutableRK, true, false, amqp.Publishing{
		Body: []byte("go-unroutable"),
	}); err != nil {
		return fmt.Errorf("mandatory publish: %w", err)
	}
	select {
	case r := <-returns:
		if r.ReplyCode != 312 {
			return fmt.Errorf("basic.return replyCode=%d, want 312", r.ReplyCode)
		}
		fmt.Printf("  basic.return received for '%s' (replyCode=%d)\n", unroutableRK, r.ReplyCode)
	case <-time.After(5 * time.Second):
		return fmt.Errorf("basic.return not received for '%s'", unroutableRK)
	case <-ctx.Done():
		return fmt.Errorf("basic.return: %w", ctx.Err())
	}

	return nil
}

func getenv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}
