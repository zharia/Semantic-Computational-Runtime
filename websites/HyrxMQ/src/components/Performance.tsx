import { Reveal } from './Reveal'

const headlineStats = [
  { value: '19.5%', label: 'higher overall throughput than RabbitMQ 4.x' },
  { value: '~5.6×', label: 'higher overall throughput than LavinMQ' },
  { value: '50 / 80', label: 'benchmark cells where HyrxMQ was fastest' },
  { value: '0', label: 'failures across the reliability test matrix' },
]

const chart = [
  { name: 'HyrxMQ', value: 100, raw: 'fastest overall', tone: 'lead' },
  { name: 'RabbitMQ 4.x', value: 83.7, raw: '≈19.5% slower', tone: 'mid' },
  { name: 'LavinMQ', value: 15, raw: '≈5.6× slower', tone: 'slow' },
]

const bands = [
  { band: 'Concurrency 1', hyrx: '1.007', rabbit: '1.324', lavin: '7.675' },
  { band: 'Concurrency 4–8', hyrx: '1.059', rabbit: '1.223', lavin: '8.749' },
  { band: 'Concurrency 16–32', hyrx: '1.039', rabbit: '1.225', lavin: '5.194' },
]

const peaks = [
  { value: '676,490', unit: 'msg/s', detail: 'Publish, 64 B messages, 32 connections' },
  { value: '592,326', unit: 'msg/s', detail: 'Publish, 1 KiB messages' },
  { value: '24,710', unit: 'msg/s', detail: 'basic.get, 16 KiB messages' },
]

const reliability = [
  '10-minute soak: memory drift +0.056%',
  'Survives kill -9 at 10%, 50% and 90% — full recovery',
  'Graceful shutdown in under 5 ms on SIGTERM',
  'Wire-compatible with pika, amqplib, Java and Go clients',
  'Kubernetes rollout and termination lifecycle verified on a live cluster',
]

export function Performance() {
  return (
    <section className="section perf" id="performance">
      <div className="container">
        <Reveal className="section__head">
          <span className="eyebrow">Measured, Not Promised</span>
          <h2 className="section__title">
            Performance you can <span className="gradient-text">verify for yourself.</span>
          </h2>
          <p className="section__lede">
            HyrxMQ v0.0.4 was benchmarked head-to-head against RabbitMQ 4.x and LavinMQ under
            identical conditions. It came out fastest overall — and stayed correct and stable while
            doing it.
          </p>
        </Reveal>

        <Reveal className="perf__stats" delay={60}>
          {headlineStats.map((stat) => (
            <div className="perf-stat" key={stat.label}>
              <span className="perf-stat__value">{stat.value}</span>
              <span className="perf-stat__label">{stat.label}</span>
            </div>
          ))}
        </Reveal>

        <div className="perf__layout">
          <Reveal className="perf__chart-card" delay={80}>
            <div className="perf__chart-head">
              <h3>Overall throughput</h3>
              <span className="perf__chart-note">Indexed to HyrxMQ = 100 · higher is better</span>
            </div>
            <div className="perf__chart">
              {chart.map((row) => (
                <div className={`perf-bar perf-bar--${row.tone}`} key={row.name}>
                  <span className="perf-bar__label">{row.name}</span>
                  <span className="perf-bar__track">
                    <span className="perf-bar__fill" style={{ width: `${row.value}%` }} />
                  </span>
                  <span className="perf-bar__value">{row.raw}</span>
                </div>
              ))}
            </div>
            <p className="perf__chart-foot">
              Geometric mean of relative throughput across 80 benchmark cells — publish, publish +
              get, publisher confirms and fanout — at concurrency 1 to 32.
            </p>
          </Reveal>

          <Reveal className="perf__bands" delay={140}>
            <div className="perf__bands-head">
              <h3>Fastest in every concurrency band</h3>
              <span className="perf__chart-note">Lower index = faster</span>
            </div>
            <table className="perf-table">
              <thead>
                <tr>
                  <th>Workload</th>
                  <th className="is-lead">HyrxMQ</th>
                  <th>RabbitMQ</th>
                  <th>LavinMQ</th>
                </tr>
              </thead>
              <tbody>
                {bands.map((row) => (
                  <tr key={row.band}>
                    <td>{row.band}</td>
                    <td className="is-lead">{row.hyrx}</td>
                    <td>{row.rabbit}</td>
                    <td>{row.lavin}</td>
                  </tr>
                ))}
              </tbody>
            </table>
            <p className="perf__bands-foot">
              HyrxMQ led on three of four workloads; LavinMQ retained fanout. The narrowest HyrxMQ
              loss was 1.03×, the widest 1.31×.
            </p>
          </Reveal>
        </div>

        <Reveal className="perf__peaks" delay={80}>
          <div className="perf__peaks-head">
            <span className="eyebrow">Peak Throughput Observed</span>
          </div>
          <div className="perf__peaks-grid">
            {peaks.map((peak) => (
              <div className="perf-peak" key={peak.detail}>
                <span className="perf-peak__value">
                  {peak.value} <span className="perf-peak__unit">{peak.unit}</span>
                </span>
                <span className="perf-peak__detail">{peak.detail}</span>
              </div>
            ))}
          </div>
        </Reveal>

        <Reveal className="perf__reliability" delay={80}>
          <div className="perf__reliability-copy">
            <span className="eyebrow">Reliability Underneath the Speed</span>
            <h3>Fast means little if it is not dependable.</h3>
            <p>
              The same release passed an adversarial test matrix: malformed input, resource
              exhaustion, network failure, process termination, disk failure, slow consumers, large
              messages and TLS. The result is a broker that stays correct under pressure — not just
              quick on a good day.
            </p>
          </div>
          <ul className="perf__reliability-list">
            {reliability.map((item) => (
              <li key={item}>
                <span className="perf__check" aria-hidden="true">
                  ✓
                </span>
                {item}
              </li>
            ))}
          </ul>
        </Reveal>

        <Reveal className="perf__note" delay={80}>
          <strong>How this was measured.</strong> All three brokers ran in Docker on one network with
          identical CPU and memory limits, identical AMQP configuration, a single compiled load
          generator and seven rotated repetitions (medians reported). This is a single-host,
          single-client result: it establishes relative behaviour here, and is not a
          “fastest in the world” claim. We publish the method because we would rather be checked than
          believed.
        </Reveal>
      </div>
    </section>
  )
}