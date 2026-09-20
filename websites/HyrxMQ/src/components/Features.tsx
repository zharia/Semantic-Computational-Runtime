import { Reveal } from './Reveal'

const principles = [
  {
    index: '01',
    title: 'Open',
    body: 'Built around open technology and open standards. The messaging ecosystem should not become another proprietary island.',
  },
  {
    index: '02',
    title: 'Performance',
    body: 'Every unnecessary byte copied, context switch, serialization or CPU↔GPU transfer is work — and Hyrx treats that work as an engineering problem.',
  },
  {
    index: '03',
    title: 'Native to the environment',
    body: 'A browser is not a Kubernetes cluster. A cluster is not a GPU fabric. Same philosophy, different execution models.',
  },
  {
    index: '04',
    title: 'Data locality',
    body: 'The fastest data transfer is often the one that never needed to happen. Where is the data? Where is the computation?',
  },
  {
    index: '05',
    title: 'Programmable performance',
    body: 'Hardware changes too quickly to marry infrastructure to one execution model. Hyrx is built with a modern systems-language strategy.',
  },
]

const capabilities = [
  {
    title: 'AMQP-native',
    body: 'Established, open messaging semantics with interoperability at the core — not a proprietary protocol.',
  },
  {
    title: 'Browser to GPU',
    body: 'One family spanning applications, browsers, clusters and accelerators without fragmenting the stack.',
  },
  {
    title: 'Kubernetes-native',
    body: 'The orchestration environment is part of the operating model, not something surrounding a traditional broker.',
  },
  {
    title: 'Accelerator-aware',
    body: 'Locality-aware routing designed to keep expensive GPUs doing useful computation, not waiting for data.',
  },
  {
    title: 'Mojo systems core',
    body: 'One language across the performance boundary: network, CPU, SIMD, memory, GPU and accelerator.',
  },
  {
    title: 'Open source core',
    body: 'Inspect it, extend it, embed it, deploy it. Commercial infrastructure built on an open foundation.',
  },
]

export function Features() {
  return (
    <section className="section section--alt" id="features">
      <div className="container">
        <Reveal className="section__head">
          <span className="eyebrow">Features &amp; Benefits</span>
          <h2 className="section__title">
            Five principles. <span className="gradient-text">One architecture.</span>
          </h2>
          <p className="section__lede">
            The interesting proposition is not merely that Hyrx makes messaging faster. It is that Hyrx
            evolves the <strong>location of the messaging boundary.</strong>
          </p>
        </Reveal>

        <div className="principles">
          {principles.map((item, i) => (
            <Reveal as="article" className="principle" delay={i * 70} key={item.title}>
              <span className="principle__index">{item.index}</span>
              <h3 className="principle__title">{item.title}</h3>
              <p className="principle__body">{item.body}</p>
            </Reveal>
          ))}
        </div>

        <Reveal className="features__divider" delay={60}>
          <span>Capabilities</span>
        </Reveal>

        <div className="capabilities">
          {capabilities.map((item, i) => (
            <Reveal as="article" className="capability" delay={i * 60} key={item.title}>
              <h3 className="capability__title">{item.title}</h3>
              <p className="capability__body">{item.body}</p>
            </Reveal>
          ))}
        </div>
      </div>
    </section>
  )
}
