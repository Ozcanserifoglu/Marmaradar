import { useEffect, useState } from 'react'
import { Link, useLocation } from 'react-router-dom'
import { Menu, X } from 'lucide-react'
import { PLAY_STORE_URL } from '../config/storeLinks'
import './Navbar.css'

export default function Navbar({ minimal = false }) {
  const [scrolled, setScrolled] = useState(false)
  const [menuOpen, setMenuOpen] = useState(false)
  const { pathname } = useLocation()
  const onChangelog = pathname === '/changelog'
  const ctaHref = PLAY_STORE_URL || '#get-app'
  const ctaExternal = Boolean(PLAY_STORE_URL)

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 24)
    onScroll()
    window.addEventListener('scroll', onScroll, { passive: true })
    return () => window.removeEventListener('scroll', onScroll)
  }, [])

  useEffect(() => {
    if (!menuOpen) return undefined
    const onKey = (e) => {
      if (e.key === 'Escape') setMenuOpen(false)
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [menuOpen])

  const closeMenu = () => setMenuOpen(false)

  return (
    <header className={`nav${scrolled ? ' scrolled' : ''}`}>
      <div className="container">
        <div className="nav-inner">
          <Link to="/" className="wordmark" onClick={closeMenu} aria-label="Marmaradar ana sayfa">
            <span className="wordmark-accent">Marmaradar</span>
          </Link>

          {!minimal && (
            <nav className="nav-links" aria-label="Ana menü">
              <a href="/#features">Özellikler</a>
              <a href="/#how">Nasıl Çalışır</a>
              <a href="/#faq">SSS</a>
              <Link
                to="/changelog"
                className={onChangelog ? 'active' : undefined}
                aria-current={onChangelog ? 'page' : undefined}
              >
                Güncellemeler
              </Link>
            </nav>
          )}

          <div className="nav-actions">
            {!minimal && (
              <a
                href={ctaHref}
                className="btn btn-ghost btn-sm nav-cta"
                {...(ctaExternal
                  ? { target: '_blank', rel: 'noopener noreferrer' }
                  : undefined)}
              >
                Google Play
              </a>
            )}
            {!minimal && (
              <button
                className="menu-toggle"
                type="button"
                aria-label={menuOpen ? 'Menüyü kapat' : 'Menüyü aç'}
                aria-expanded={menuOpen}
                aria-controls="mobileMenu"
                onClick={() => setMenuOpen((open) => !open)}
              >
                {menuOpen ? <X size={20} /> : <Menu size={20} />}
              </button>
            )}
          </div>
        </div>

        {!minimal && (
          <div className={`mobile-menu${menuOpen ? ' open' : ''}`} id="mobileMenu">
            <a href="/#features" onClick={closeMenu}>Özellikler</a>
            <a href="/#how" onClick={closeMenu}>Nasıl Çalışır</a>
            <a href="/#faq" onClick={closeMenu}>SSS</a>
            <Link
              to="/changelog"
              className={onChangelog ? 'active' : undefined}
              aria-current={onChangelog ? 'page' : undefined}
              onClick={closeMenu}
            >
              Güncellemeler
            </Link>
            <a
              href={ctaHref}
              onClick={closeMenu}
              {...(ctaExternal
                ? { target: '_blank', rel: 'noopener noreferrer' }
                : undefined)}
            >
              Google Play
            </a>
          </div>
        )}
      </div>
    </header>
  )
}
