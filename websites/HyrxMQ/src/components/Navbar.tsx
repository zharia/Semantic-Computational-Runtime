import { useEffect, useState } from 'react'
import logoOnDark from '../assets/logo/lynx-mark.png'
import { GithubIcon } from './GithubIcon'
import { GITHUB_URL } from '../constants'

const links = [
  { href: '#family', label: 'Family' },
  { href: '#about', label: 'About' },
  { href: '#architecture', label: 'Architecture' },
  { href: '#features', label: 'Features' },
  { href: '#compare', label: 'Why Hyrx' },
  { href: '#performance', label: 'Performance' },
  { href: '#byte-money', label: 'Byte Money' },
]

export function Navbar() {
  const [scrolled, setScrolled] = useState(false)
  const [open, setOpen] = useState(false)

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 24)
    onScroll()
    window.addEventListener('scroll', onScroll, { passive: true })
    return () => window.removeEventListener('scroll', onScroll)
  }, [])

  return (
    <header className={`nav ${scrolled ? 'nav--scrolled' : ''}`}>
      <div className="container nav__inner">
        <a href="#top" className="nav__brand" aria-label="HyrxMQ home" onClick={() => setOpen(false)}>
          <img src={logoOnDark} alt="HyrxMQ" className="nav__logo" />
          <span className="nav__brand-text">
            <strong>HYRX</strong>
            <span>GPU Messaging Fabric</span>
          </span>
        </a>

        <nav className={`nav__links ${open ? 'is-open' : ''}`} aria-label="Primary">
          {links.map((link) => (
            <a key={link.href} href={link.href} onClick={() => setOpen(false)}>
              {link.label}
            </a>
          ))}
          <a href="#get-started" className="btn btn--sm btn--primary nav__cta" onClick={() => setOpen(false)}>
            Get Started
          </a>
          <a
            href={GITHUB_URL}
            className="nav__github"
            target="_blank"
            rel="noreferrer noopener"
            aria-label="Hyrx on GitHub"
            onClick={() => setOpen(false)}
          >
            <GithubIcon size={20} />
          </a>
        </nav>

        <button
          className={`nav__toggle ${open ? 'is-open' : ''}`}
          aria-label="Toggle navigation"
          aria-expanded={open}
          onClick={() => setOpen((v) => !v)}
        >
          <span />
          <span />
          <span />
        </button>
      </div>
    </header>
  )
}
