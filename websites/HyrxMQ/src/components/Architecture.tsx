import { Reveal } from './Reveal'

const oldModel = ['Application', 'Broker', 'CPU', 'Network', 'CPU', 'Broker', 'Application']
const oldAccelerated = ['GPU', 'CPU', 'Broker', 'Network', 'CPU', 'GPU']
const hyrxModel = ['Application', 'Hyrx', 'Computational Fabric']
const hyrxAccelerated = ['GPU', 'HyrxMQ++', 'GPU']

const evolution = [
  { name: 'Hyrx', line: 'Move messages efficiently.' },
  { name: 'Hyrx WASM', line: 'Move messages into the browser.' },
  { name: 'HyrxMQ', line: 'Move messages through cloud-native infrastructure.' },
  { name: 'HyrxMQ++', line: 'Move computational data intelligently across heterogeneous accelerators.' },
]

function Flow({ steps, variant }: { steps: string[]; variant: 'old' | 'new' }) {
  return (
    <div className={`flow flow--${variant}`}>
      {steps.map((step, i) => (
        <span className="flow__item" key={`${step}-${i}`}>
          <span className="flow__node">{step}</span>
          {i < steps.length - 1 && <span className="flow__arrow" aria-hidden="true">→</span>}
        </span>
      ))}
    </div>
  )
}

export function Architecture() {
  return (
    <section className="section" id="architecture">
      <div className="container">
        <Reveal className="section__head">
          <span className="eyebrow">Architecture</span>
          <h2 className="section__title">
            The messaging layer becomes aware of <span className="gradient-text">where compute lives.</span>
          </h2>
          <p className="section__lede">
            Traditional messaging thinks in terms of <strong>producer → broker → consumer</strong>.
            Hyrx increasingly thinks in terms of <strong>producer → computational fabric → consumer</strong>.
          </p>
        </Reveal>

        <div className="arch__compare">
          <Reveal className="arch__col arch__col--old">
            <div className="arch__col-head">
              <span className="arch__badge arch__badge--old">The old model</span>
              <h3>Information crosses boundaries that know nothing about each other.</h3>
            </div>
            <Flow steps={oldModel} variant="old" />
            <p className="arch__caption">Accelerated workloads become even more elaborate:</p>
            <Flow steps={oldAccelerated} variant="old" />
            <p className="arch__note">
              The messaging layer knows about messages. The application knows about computation. The
              accelerator knows about tensors. The infrastructure between them knows very little about
              the relationship.
            </p>
          </Reveal>

          <Reveal className="arch__col arch__col--new" delay={120}>
            <div className="arch__col-head">
              <span className="arch__badge arch__badge--new">The Hyrx model</span>
              <h3>The fabric understands the computational environment it operates in.</h3>
            </div>
            <Flow steps={hyrxModel} variant="new" />
            <p className="arch__caption">For accelerated workloads:</p>
            <Flow steps={hyrxAccelerated} variant="new" />
            <p className="arch__note">
              HyrxMQ++ treats data locality as a first-class architectural concern — moving references
              where moving bytes would be wasteful.
            </p>
          </Reveal>
        </div>

        <Reveal className="arch__layers" delay={80}>
          <div className="arch__layer">
            <span className="arch__layer-kicker">Hyrx</span>
            <h4>The engine</h4>
            <p>Optimised open-source AMQP messaging for developers who want the core without unnecessary infrastructure.</p>
          </div>
          <div className="arch__layer">
            <span className="arch__layer-kicker">Hyrx WASM</span>
            <h4>The browser-native messenger</h4>
            <p>High-performance messaging in WebAssembly — the browser as an active computational participant.</p>
          </div>
          <div className="arch__layer">
            <span className="arch__layer-kicker">HyrxMQ</span>
            <h4>The cloud-native broker</h4>
            <p>Hyrx deployed as production messaging infrastructure inside Kubernetes.</p>
          </div>
          <div className="arch__layer arch__layer--highlight">
            <span className="arch__layer-kicker">HyrxMQ++</span>
            <h4>The accelerator-native fabric</h4>
            <p>Messaging extended into GPU-aware, accelerator-aware data movement.</p>
          </div>
        </Reveal>

        <Reveal className="arch__ladder" delay={80}>
          <div className="arch__ladder-head">
            <span className="eyebrow">From messages to data movement</span>
            <p>A message need not be a packet of bytes. It can become a reference to computational data already resident in the fabric.</p>
          </div>
          <ol className="arch__ladder-list">
            {evolution.map((item, i) => (
              <li key={item.name}>
                <span className="arch__ladder-index">{String(i + 1).padStart(2, '0')}</span>
                <span className="arch__ladder-name">{item.name}</span>
                <span className="arch__ladder-line">{item.line}</span>
              </li>
            ))}
          </ol>
          <p className="arch__destination">
            The destination is not simply a faster broker. It is a <strong>computational messaging fabric.</strong>
          </p>
        </Reveal>
      </div>
    </section>
  )
}
