import { Reveal } from './Reveal'
import { GithubIcon } from './GithubIcon'
import { GITHUB_URL } from '../constants'

const philosophy = [
  'Don’t move data unnecessarily.',
  'Don’t make the CPU do work an accelerator can do better.',
  'Don’t make the application understand infrastructure it shouldn’t need to understand.',
  'Don’t sacrifice interoperability for performance.',
  'Don’t sacrifice performance for abstraction.',
  'Don’t build tomorrow’s infrastructure around yesterday’s hardware assumptions.',
]

const questions = [
  'Where is the data?',
  'Where is the computation?',
  'Where should the data exist?',
  'What is the cheapest path between them?',
  'And does the data need to move at all?',
]

export function CallToAction() {
  return (
    <section className="section cta" id="get-started">
      <div className="cta__glow" aria-hidden="true" />
      <div className="container">
        <Reveal className="cta__philosophy">
          <span className="eyebrow">The Hyrx Philosophy</span>
          <ul className="philosophy">
            {philosophy.map((line) => (
              <li key={line}>{line}</li>
            ))}
          </ul>
        </Reveal>

        <Reveal className="cta__reconsidered" delay={80}>
          <h2 className="section__title">
            Messaging, <span className="gradient-text">reconsidered.</span>
          </h2>
          <p className="cta__reconsidered-lede">
            The first generation of distributed systems asked how to send a message from A to B. The
            next generation asks:
          </p>
          <div className="cta__questions">
            {questions.map((question) => (
              <span className="cta__question" key={question}>
                {question}
              </span>
            ))}
          </div>
        </Reveal>

        <Reveal className="cta__box" delay={140}>
          <div className="cta__box-copy">
            <h3>One family. One architectural direction. A new generation of messaging infrastructure.</h3>
            <p className="cta__motto">Move less. Compute more.</p>
          </div>
          <div className="cta__actions">
            <a href="#family" className="btn btn--primary">
              Explore Hyrx
            </a>
            <a href="#architecture" className="btn btn--ghost">
              Explore HyrxMQ
            </a>
            <a href="#technology" className="btn btn--ghost">
              Explore HyrxMQ++
            </a>
            <a href={GITHUB_URL} className="btn btn--ghost" target="_blank" rel="noreferrer noopener">
              <GithubIcon size={18} />
              GitHub
            </a>
          </div>
        </Reveal>
      </div>
    </section>
  )
}
