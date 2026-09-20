import { Reveal } from './Reveal'

type Product = {
  name: string
  tag: string
  where: string
  purpose: string
  points: string[]
  accent: string
}

const products: Product[] = [
  {
    name: 'Hyrx',
    tag: 'The engine',
    where: 'Native apps, services, embedded systems',
    purpose: 'The optimised open-source AMQP messaging core.',
    points: ['Efficient service-to-service messaging', 'No heavyweight platform tax', 'Optimised outward from the primitive'],
    accent: 'core',
  },
  {
    name: 'Hyrx WASM',
    tag: 'The browser-native messenger',
    where: 'Browsers and WebAssembly environments',
    purpose: 'High-performance messaging directly inside the browser.',
    points: ['Browser as active participant', 'Real-time dashboards and collaboration', 'WebGPU-ready workloads'],
    accent: 'wasm',
  },
  {
    name: 'HyrxMQ',
    tag: 'The cloud-native broker',
    where: 'Kubernetes and cloud infrastructure',
    purpose: 'Production-grade, Kubernetes-native AMQP messaging.',
    points: ['Messaging as infrastructure-native', 'Deploy, scale, observe, automate', 'AMQP at the heart of the model'],
    accent: 'mq',
  },
  {
    name: 'HyrxMQ++',
    tag: 'The accelerator-native fabric',
    where: 'GPU and accelerator clusters',
    purpose: 'Accelerator-aware messaging and data routing.',
    points: ['GPU-resident messaging', 'Locality-aware routing', 'Move references, not copies'],
    accent: 'plus',
  },
]

const progression = ['Application', 'Browser', 'Cluster', 'Accelerator']

export function Family() {
  return (
    <section className="section" id="family">
      <div className="container">
        <Reveal className="section__head">
          <span className="eyebrow">The Hyrx Family</span>
          <h2 className="section__title">
            One philosophy. <span className="gradient-text">Four execution models.</span>
          </h2>
          <p className="section__lede">
            Hyrx is not a single product. It is a family of messaging technologies sharing a common
            goal: <strong>high-performance communication without surrendering interoperability.</strong>
          </p>
        </Reveal>

        <div className="family__progression" aria-label="Hyrx progression">
          {progression.map((step, i) => (
            <Reveal className="family__step" delay={i * 70} key={step}>
              <span className="family__step-index">{String(i + 1).padStart(2, '0')}</span>
              <span className="family__step-label">{step}</span>
              {i < progression.length - 1 && <span className="family__step-arrow" aria-hidden="true">→</span>}
            </Reveal>
          ))}
        </div>

        <div className="family__grid">
          {products.map((product, i) => (
            <Reveal as="article" className={`product-card product-card--${product.accent}`} delay={i * 90} key={product.name}>
              <div className="product-card__top">
                <h3 className="product-card__name">{product.name}</h3>
                <span className="product-card__tag">{product.tag}</span>
              </div>
              <p className="product-card__where">{product.where}</p>
              <p className="product-card__purpose">{product.purpose}</p>
              <ul className="product-card__points">
                {product.points.map((point) => (
                  <li key={point}>{point}</li>
                ))}
              </ul>
            </Reveal>
          ))}
        </div>
      </div>
    </section>
  )
}
