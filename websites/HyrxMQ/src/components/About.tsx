import { Reveal } from './Reveal'

const hardware = [
  'CPUs', 'GPUs', 'NPUs', 'TPUs', 'Specialised accelerators', 'High-speed storage',
  'Distributed memory', 'Edge devices', 'Cloud regions', 'Browser runtimes',
]

const costs = [
  'Memory bandwidth', 'CPU cycles', 'PCIe bandwidth', 'Network bandwidth',
  'Latency budget', 'Power', 'Infrastructure capacity', 'Money',
]

export function About() {
  return (
    <section className="section section--alt" id="about">
      <div className="container">
        <div className="about__layout">
          <Reveal className="about__intro">
            <span className="eyebrow">The Problem</span>
            <h2 className="section__title">
              Data movement is becoming <span className="gradient-text">the bottleneck.</span>
            </h2>
            <p className="section__lede">
              For decades, software architecture assumed computation was expensive and communication
              was comparatively cheap. That assumption is breaking.
            </p>
            <p className="muted">
              Modern systems are heterogeneous by default. Their computational capability keeps
              increasing — but computation is useful only when the right data reaches the right
              computation at the right time. That creates a new infrastructure problem.
            </p>
            <div className="about__callout">
              <span className="about__callout-label">The new bottleneck</span>
              <span className="about__callout-value">The data movement problem</span>
            </div>
          </Reveal>

          <Reveal className="about__panels" delay={120}>
            <div className="panel">
              <h3 className="panel__title">The system is now many machines</h3>
              <ul className="chip-list">
                {hardware.map((item) => (
                  <li key={item}>{item}</li>
                ))}
              </ul>
            </div>
            <div className="panel panel--accent">
              <h3 className="panel__title">Every unnecessary copy consumes</h3>
              <ul className="cost-list">
                {costs.map((item) => (
                  <li key={item}>
                    <span className="cost-list__dot" aria-hidden="true" />
                    {item}
                  </li>
                ))}
              </ul>
              <p className="panel__footnote">
                And ultimately <strong>money.</strong> The next generation of infrastructure must
                optimise not merely computation, but the movement of information between computations.
              </p>
            </div>
          </Reveal>
        </div>
      </div>
    </section>
  )
}
