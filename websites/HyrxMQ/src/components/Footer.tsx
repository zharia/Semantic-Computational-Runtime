import logoOnDark from '../assets/logo/lynx-mark.png'
import { GithubIcon } from './GithubIcon'
import { GITHUB_URL } from '../constants'

const columns = [
  {
    title: 'Family',
    links: [
      { label: 'Hyrx', href: '#family' },
      { label: 'Hyrx WASM', href: '#family' },
      { label: 'HyrxMQ', href: '#family' },
      { label: 'HyrxMQ++', href: '#family' },
    ],
  },
  {
    title: 'Learn',
    links: [
      { label: 'Architecture', href: '#architecture' },
      { label: 'Features', href: '#features' },
      { label: 'Why Hyrx', href: '#compare' },
      { label: 'Performance', href: '#performance' },
      { label: 'Built with Mojo', href: '#technology' },
    ],
  },
  {
    title: 'Company',
    links: [
      { label: 'Byte Money', href: 'https://bytemoney.co.za' },
      { label: 'Open Source', href: '#features' },
      { label: 'Get Started', href: '#get-started' },
      { label: 'GitHub', href: GITHUB_URL },
    ],
  },
]

export function Footer() {
  return (
    <footer className="footer">
      <div className="container footer__inner">
        <div className="footer__brand">
          <div className="footer__brand-top">
            <img src={logoOnDark} alt="HyrxMQ" className="footer__logo" />
            <span className="footer__wordmark">
              <strong>HYRXMQ</strong>
              <span>GPU Messaging Fabric</span>
            </span>
          </div>
          <p className="footer__tagline">
            High-performance AMQP messaging, from the browser to the GPU. The messaging fabric for
            heterogeneous compute.
          </p>
        </div>

        <div className="footer__columns">
          {columns.map((column) => (
            <div className="footer__column" key={column.title}>
              <h4>{column.title}</h4>
              <ul>
                {column.links.map((link) => (
                  <li key={link.label}>
                    <a
                      href={link.href}
                      className={link.label === 'GitHub' ? 'footer__link--github' : undefined}
                      {...(link.href.startsWith('http') ? { target: '_blank', rel: 'noreferrer noopener' } : {})}
                    >
                      {link.label === 'GitHub' && <GithubIcon size={15} />}
                      {link.label}
                    </a>
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </div>
      </div>

      <div className="container footer__bottom">
        <p>© {new Date().getFullYear()} Byte Money. Hyrx and HyrxMQ are products of Byte Money.</p>
        <p className="footer__meta">Open. Fast. AMQP-native. Accelerator-ready.</p>
      </div>
    </footer>
  )
}
