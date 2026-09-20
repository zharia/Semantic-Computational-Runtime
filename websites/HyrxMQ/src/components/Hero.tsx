import logoOnDark from '../assets/logo/logo-on-dark.png'
import { Reveal } from './Reveal'

const badges = ['Open', 'Fast', 'AMQP-native', 'Accelerator-ready']

const stats = [
  { value: '4', label: 'Execution models' },
  { value: '1', label: 'AMQP family' },
  { value: 'GPU ↔ GPU', label: 'Direct data path' },
  { value: 'Mojo', label: 'Systems core' },
]

export function Hero() {
  return (
    <section className="hero" id="top">
      <div className="hero__grid" aria-hidden="true" />
      <div className="hero__glow hero__glow--one" aria-hidden="true" />
      <div className="hero__glow hero__glow--two" aria-hidden="true" />

      <div className="container hero__inner">
        <Reveal className="hero__copy">
          <span className="eyebrow">Hyrx — Messaging for the Age of Heterogeneous Compute</span>
          <h1 className="hero__title">
            High-performance AMQP messaging,
            <span className="gradient-text"> from the browser to the GPU.</span>
          </h1>
          <p className="hero__lede">
            A new generation of open, high-performance messaging infrastructure built around a
            simple idea: <strong>messaging should move data at the speed and location at which
            computation actually happens.</strong>
          </p>

          <div className="hero__actions">
            <a href="#family" className="btn btn--primary">
              Explore Hyrx
            </a>
            <a href="#architecture" className="btn btn--ghost">
              View the Architecture
            </a>
            <a href="#get-started" className="btn btn--text">
              Get Started →
            </a>
          </div>

          <ul className="hero__badges">
            {badges.map((badge) => (
              <li key={badge}>{badge}</li>
            ))}
          </ul>
        </Reveal>

        <Reveal className="hero__visual" delay={120}>
          <div className="hero__logo-frame">
            <img src={logoOnDark} alt="HyrxMQ — GPU Messaging Fabric" className="hero__logo" />
          </div>
          <div className="hero__orbit" aria-hidden="true" />
        </Reveal>
      </div>

      <div className="container">
        <Reveal className="hero__stats" delay={200}>
          {stats.map((stat) => (
            <div className="hero__stat" key={stat.label}>
              <span className="hero__stat-value">{stat.value}</span>
              <span className="hero__stat-label">{stat.label}</span>
            </div>
          ))}
        </Reveal>
      </div>
    </section>
  )
}
