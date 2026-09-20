import { Reveal } from './Reveal'

const comparisons = [
  {
    name: 'RabbitMQ',
    position: 'Mature, general-purpose messaging with breadth and a substantial ecosystem.',
    approach: 'Performance-focused AMQP infrastructure designed from the outset for modern heterogeneous compute.',
    verdict: 'RabbitMQ remains excellent where broad ecosystem and mature feature set are the priority. Hyrx is for workloads where execution efficiency, Kubernetes-native operation and accelerator-aware evolution matter.',
  },
  {
    name: 'Apache Kafka',
    position: 'A fundamentally event-streaming platform for durable logs, replay, partitioning and stream processing.',
    approach: 'Aimed at “Which computational component needs this information, and how efficiently can we get it there?”',
    verdict: 'Kafka excels as an event log. Hyrx is designed around the messaging fabric. They can be complementary rather than mutually exclusive.',
  },
  {
    name: 'NATS',
    position: 'Lightweight, high-performance distributed messaging with pub/sub, request/reply and streaming.',
    approach: 'Shares the desire for efficient distributed messaging, but retains an AMQP-oriented design centre.',
    verdict: 'Less “fast vs slow”, more “which messaging semantics and ecosystem do you want your infrastructure built around?”.',
  },
]

export function Comparison() {
  return (
    <section className="section section--alt" id="compare">
      <div className="container">
        <Reveal className="section__head">
          <span className="eyebrow">Hyrx vs the Market</span>
          <h2 className="section__title">
            Not replacing every technology. <span className="gradient-text">Rebuilding the boundary.</span>
          </h2>
          <p className="section__lede">
            Different systems solve different problems. Hyrx approaches messaging from the direction
            of execution efficiency and heterogeneous compute.
          </p>
        </Reveal>

        <div className="comparison">
          {comparisons.map((item, i) => (
            <Reveal as="article" className="comparison__card" delay={i * 90} key={item.name}>
              <h3 className="comparison__name">{item.name}</h3>
              <div className="comparison__row">
                <span className="comparison__label">Its centre</span>
                <p>{item.position}</p>
              </div>
              <div className="comparison__row comparison__row--hy">
                <span className="comparison__label">Hyrx approach</span>
                <p>{item.approach}</p>
              </div>
              <p className="comparison__verdict">{item.verdict}</p>
            </Reveal>
          ))}
        </div>

        <Reveal className="amqp" delay={60}>
          <div className="amqp__copy">
            <span className="eyebrow">Why AMQP?</span>
            <h3>Performance without interoperability is a trap.</h3>
            <p>
              A proprietary protocol can be extremely fast while creating a new island of
              infrastructure. Hyrx keeps the messaging semantics open. AMQP provides an established
              foundation for reliable application messaging and interoperability.
            </p>
            <p>
              Hyrx does not reinvent messaging semantics merely to optimise the machinery underneath
              them. RabbitMQ supports AMQP 0-9-1 and 1.0; Apache Qpid provides a high-performance AMQP
              toolkit. Hyrx builds on that open foundation.
            </p>
          </div>
          <div className="amqp__pillars">
            <div className="amqp__pillar">
              <span className="amqp__pillar-num">01</span>
              <strong>Open protocol.</strong>
            </div>
            <div className="amqp__pillar">
              <span className="amqp__pillar-num">02</span>
              <strong>Modern implementation.</strong>
            </div>
            <div className="amqp__pillar">
              <span className="amqp__pillar-num">03</span>
              <strong>Aggressive optimisation.</strong>
            </div>
          </div>
        </Reveal>
      </div>
    </section>
  )
}
