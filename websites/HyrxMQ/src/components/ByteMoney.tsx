import { Reveal } from './Reveal'
import byteMoneyLogo from '../assets/logo/byte-money.svg'

const pillars = [
  {
    title: 'Semantic-first engineering',
    body: 'Meaning precedes representation. Byte Money builds from explicit semantic contracts rather than implementation convenience.',
  },
  {
    title: 'Systems for heterogeneous compute',
    body: 'A research and engineering practice aimed at the CPU + GPU + accelerator era, not the CPU-only past.',
  },
  {
    title: 'Open foundations',
    body: 'Hyrx begins with open technology and an open protocol, so the infrastructure remains inspectable and extensible.',
  },
]

export function ByteMoney() {
  return (
    <section className="section byte-money" id="byte-money">
      <div className="byte-money__glow" aria-hidden="true" />
      <div className="container byte-money__inner">
        <Reveal className="byte-money__intro">
          <a
            className="byte-money__logo-link"
            href="https://bytemoney.co.za"
            target="_blank"
            rel="noreferrer noopener"
            aria-label="Byte Money — bytemoney.co.za"
          >
            <img className="byte-money__logo" src={byteMoneyLogo} alt="Byte Money" />
          </a>
          <span className="eyebrow">Built by Byte Money</span>
          <h2 className="section__title">
            The team behind <span className="gradient-text">the Hyrx family.</span>
          </h2>
          <p className="byte-money__lede">
            Hyrx is built by <strong>Byte Money</strong> — the team engineering a new class of
            infrastructure for the heterogeneous compute era. Its work spans the Semantic Computational
            Runtime, a systems-language strategy built on Mojo, and the messaging fabric you are
            reading about here.
          </p>
          <p className="muted">
            Byte Money builds infrastructure that treats computation and communication as one
            problem: making sure the right data reaches the right computation, at the right time,
            with as little overhead as the hardware allows.
          </p>
          <div className="byte-money__actions">
            <a className="btn btn--primary" href="https://bytemoney.co.za" target="_blank" rel="noreferrer noopener">
              Visit Byte Money
            </a>
            <a className="btn btn--ghost" href="#get-started">
              Work with us
            </a>
          </div>
        </Reveal>

        <Reveal className="byte-money__pillars" delay={120}>
          {pillars.map((pillar, i) => (
            <div className="byte-money__pillar" key={pillar.title} style={{ transitionDelay: `${i * 70}ms` }}>
              <h3>{pillar.title}</h3>
              <p>{pillar.body}</p>
            </div>
          ))}
        </Reveal>
      </div>
    </section>
  )
}
