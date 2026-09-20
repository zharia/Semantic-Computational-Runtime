import mojoLogo from '../assets/logo/mojo-logo.svg?raw'
import mojoFlame from '../assets/logo/mojo-flame.svg?raw'

export function MojoLockup({ className = '' }: { className?: string }) {
  return (
    <span
      className={`mojo-lockup ${className}`}
      role="img"
      aria-label="Mojo"
      dangerouslySetInnerHTML={{ __html: mojoLogo }}
    />
  )
}

export function MojoFlame({ className = '' }: { className?: string }) {
  return (
    <span
      className={`mojo-flame ${className}`}
      role="img"
      aria-label="Mojo flame"
      dangerouslySetInnerHTML={{ __html: mojoFlame }}
    />
  )
}