import { Reveal } from './Reveal'
import { MojoFlame, MojoLockup } from './MojoMark'

const trajectory = ['Network', 'CPU', 'SIMD', 'Memory', 'GPU', 'Accelerator']

const concerns = [
  'Memory', 'Scheduling', 'Concurrency', 'Topology', 'Device management', 'Data layout', 'Compilation',
]

export function Technology() {
  return (
    <section className="section technology" id="technology">
      <div className="container">
        <Reveal className="section__head">
          <MojoLockup className="section__head-mojo" />
          <span className="eyebrow">Built with Mojo</span>
          <h2 className="section__title">
            One language across <span className="gradient-text">the performance boundary.</span>
          </h2>
          <p className="section__lede">
            Hyrx is built with <strong>Mojo</strong>, the language created by Modular. This is not a
            superficial implementation detail — it is part of the architecture.
          </p>
        </Reveal>

        <div className="technology__layout">
          <Reveal className="technology__copy">
            <p>
              Modern messaging infrastructure sits at the intersection of networking, concurrency,
              memory management, SIMD, CPU architecture, GPU computation, accelerators, data movement
              and low-level systems programming. Historically that meant combining Python, C, C++,
              CUDA, compiler tooling and specialised DSLs. That fragmentation creates friction.
            </p>
            <p>
              Mojo 1.0 was released in August 2026, and Modular subsequently open-sourced the language
              and compiler under Apache 2.0 with LLVM exceptions. It targets heterogeneous hardware
              including CPUs and GPUs while retaining Python interoperability — unusually well aligned
              with the Hyrx vision.
            </p>
            <div className="technology__trajectory">
              <span className="technology__trajectory-label">A single implementation trajectory</span>
              <div className="technology__trajectory-chain">
                {trajectory.map((step, i) => (
                  <span className="technology__trajectory-step" key={step}>
                    {step}
                    {i < trajectory.length - 1 && <span aria-hidden="true"> →</span>}
                  </span>
                ))}
              </div>
            </div>
          </Reveal>

          <Reveal className="technology__panel" delay={120}>
            <h3>
              <MojoFlame className="technology__panel-flame" />
              Mojo + HyrxMQ++
            </h3>
            <p>
              GPU-aware messaging is not simply a networking problem. It is simultaneously a:
            </p>
            <ul className="chip-list chip-list--tight">
              {concerns.map((item) => (
                <li key={item}>{item} problem</li>
              ))}
            </ul>
            <p className="technology__panel-foot">
              Mojo gives Hyrx a path toward an implementation where the distinction between
              <strong> networking infrastructure</strong> and <strong>accelerated computation</strong>
              becomes progressively thinner.
            </p>
          </Reveal>
        </div>
      </div>
    </section>
  )
}
