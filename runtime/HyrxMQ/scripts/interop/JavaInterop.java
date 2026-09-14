import com.rabbitmq.client.Channel;
import com.rabbitmq.client.Connection;
import com.rabbitmq.client.ConnectionFactory;
import com.rabbitmq.client.DefaultConsumer;
import com.rabbitmq.client.Envelope;
import com.rabbitmq.client.AMQP;

import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.LinkedBlockingQueue;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicReference;

/*
 * Java AMQP interop gate for HyrxMQ (M8.1).
 *
 * Drives the real com.rabbitmq:amqp-client against localhost:${HYRX_PORT}
 * (default 5672), admin/password, vhost "/". Verifies connect, exchange/queue
 * declare + bind, 10 publishes consumed back byte-for-byte, publisher confirms
 * and basic.return for a mandatory unroutable publish.
 *
 * Single-file (no package declaration). Prints JAVA_INTEROP=PASS or
 * JAVA_INTEROP=FAIL; exits 0 only on full PASS.
 */
public class JavaInterop {

    static final String HOST = System.getenv().getOrDefault("HYRX_HOST", "127.0.0.1");
    static final int PORT = Integer.parseInt(System.getenv().getOrDefault("HYRX_PORT", "5672"));
    static final String USER = System.getenv().getOrDefault("HYRX_USER", "admin");
    static final String PASS = System.getenv().getOrDefault("HYRX_PASS", "password");
    static final String VHOST = "/";

    static final String EXCH = "java-ex";
    static final String QUEUE = "java-q";
    static final String RK = "java-key";
    static final String UNROUTABLE_RK = "java-no-route";
    static final String MSG_PREFIX = "java-msg-";
    static final int N = 10;

    static final List<String> failures = new ArrayList<>();
    static final List<String> notes = new ArrayList<>();

    static void note(String m) {
        notes.add(m);
    }

    static void fail(String m) {
        failures.add(m);
    }

    public static void main(String[] args) {
        ConnectionFactory factory = new ConnectionFactory();
        factory.setHost(HOST);
        factory.setPort(PORT);
        factory.setUsername(USER);
        factory.setPassword(PASS);
        factory.setVirtualHost(VHOST);
        factory.setConnectionTimeout(10000);

        Connection conn = null;
        try {
            conn = factory.newConnection();
            note("connected as " + USER + "@" + HOST + ":" + PORT + " vhost=" + VHOST);

            Channel ch = conn.createChannel();
            ch.exchangeDeclare(EXCH, "direct", false, true, (Map<String, Object>) null);
            ch.queueDeclare(QUEUE, false, true, true, (Map<String, Object>) null);
            ch.queueBind(QUEUE, EXCH, RK);
            note("declared direct '" + EXCH + "', queue '" + QUEUE + "', bind '" + RK + "'");

            ch.confirmSelect();

            final BlockingQueue<String> received = new LinkedBlockingQueue<>();
            ch.basicConsume(QUEUE, false, new DefaultConsumer(ch) {
                @Override
                public void handleDelivery(String consumerTag, Envelope envelope,
                                           AMQP.BasicProperties properties, byte[] body) throws java.io.IOException {
                    received.add(new String(body, StandardCharsets.UTF_8));
                    ch.basicAck(envelope.getDeliveryTag(), false);
                }
            });

            for (int i = 1; i <= N; i++) {
                ch.basicPublish(EXCH, RK, null, (MSG_PREFIX + i).getBytes(StandardCharsets.UTF_8));
            }
            note("published " + N + " messages on '" + RK + "'");

            ch.waitForConfirmsOrDie(10000);
            note("publisher confirms OK (broker acked all " + N + ")");

            for (int i = 1; i <= N; i++) {
                String expected = MSG_PREFIX + i;
                String got = received.poll(10, TimeUnit.SECONDS);
                if (!expected.equals(got)) {
                    fail("body mismatch at index " + (i - 1) + ": expected "
                            + quote(expected) + ", got " + quote(got));
                }
            }
            if (failures.isEmpty()) {
                note("consumed " + received.size() + " messages, bodies verified");
            }

            // ---- basic.return for a mandatory unroutable publish ----
            final AtomicReference<AMQP.BasicProperties> returnedProps = new AtomicReference<>();
            final AtomicReference<Integer> returnedCode = new AtomicReference<>();
            ch.addReturnListener((replyCode, replyText, exchange, routingKey, properties, body) -> {
                returnedCode.set(replyCode);
                returnedProps.set(properties);
            });

            ch.basicPublish(EXCH, UNROUTABLE_RK, true, null, "java-unroutable".getBytes(StandardCharsets.UTF_8));

            long deadline = System.currentTimeMillis() + 5000;
            while (returnedCode.get() == null && System.currentTimeMillis() < deadline) {
                Thread.sleep(50);
            }
            if (returnedCode.get() != null) {
                note("basic.return received for '" + UNROUTABLE_RK + "' (replyCode=" + returnedCode.get() + ")");
            } else {
                fail("basic.return not received for mandatory unroutable publish");
            }
        } catch (Exception e) {
            fail("fatal: " + e.getClass().getSimpleName() + ": " + e.getMessage());
        } finally {
            if (conn != null) {
                try {
                    conn.close();
                } catch (Exception ignored) {
                    /* broker teardown is the runner's job */
                }
            }
        }

        for (String n : notes) {
            System.out.println("  " + n);
        }
        if (failures.isEmpty()) {
            System.out.println("JAVA_INTEROP=PASS");
        } else {
            System.out.println("JAVA_INTEROP=FAIL");
            for (String f : failures) {
                System.out.println("  " + f);
            }
            System.exit(1);
        }
    }

    static String quote(String s) {
        return s == null ? "null" : "\"" + s + "\"";
    }
}