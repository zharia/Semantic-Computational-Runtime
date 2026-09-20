import { Reveal } from './Reveal'

const industries = [
  { title: 'AI & Machine Learning', body: 'Move data between inference, preprocessing, postprocessing and model-serving workloads.' },
  { title: 'Financial Technology', body: 'Low-latency communication between pricing, risk, execution and market-data systems.' },
  { title: 'Scientific Computing', body: 'Connect distributed computational workloads without treating the network as a dumb pipe.' },
  { title: 'Simulation', body: 'Move state between distributed simulation components while preserving high-performance execution.' },
  { title: 'Robotics & Autonomy', body: 'Connect perception, planning, control and sensor-processing workloads.' },
  { title: 'Real-Time Analytics', body: 'Move information between data producers and computational consumers with minimal overhead.' },
  { title: 'Edge Computing', body: 'Deploy lightweight messaging where bandwidth, power and compute are constrained.' },
  { title: 'Web Applications', body: 'Bring real-time messaging directly into browser-based computation through Hyrx WASM.' },
]

export function Industries() {
  return (
    <section className="section section--alt" id="industries">
      <div className="container">
        <Reveal className="section__head">
          <span className="eyebrow">Built for the Next Generation</span>
          <h2 className="section__title">
            Designed for the systems <span className="gradient-text">that are coming.</span>
          </h2>
          <p className="section__lede">
            The future is unlikely to be CPU + memory + network. It is increasingly CPU + GPU + NPU +
            memory + storage + network + edge + cloud + browser. The messaging layer sits between all
            of them.
          </p>
        </Reveal>

        <div className="industries">
          {industries.map((item, i) => (
            <Reveal as="article" className="industry" delay={i * 50} key={item.title}>
              <h3>{item.title}</h3>
              <p>{item.body}</p>
            </Reveal>
          ))}
        </div>

        <Reveal className="machines" delay={60}>
          <p className="machines__line">From a laptop to a Kubernetes cluster.</p>
          <p className="machines__line">From a browser to a GPU farm.</p>
          <p className="machines__line">From a microservice to an accelerator.</p>
          <p className="machines__strong">Hyrx is designed to make them participants in the same messaging universe.</p>
        </Reveal>
      </div>
    </section>
  )
}
