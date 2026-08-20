import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { Mail, Menu, X } from 'lucide-react'
import './Navbar.css'

// Suggestion (product copy): consider renaming label to "Beta İçin Başvur" or "Bize Ulaş"
// so the mailto destination is clearer; keeping "Beta'ya Katıl" until decided.
const BETA_MAILTO =
  'mailto:marmaradar@gmail.com?subject=Beta%20Program%20Ba%C5%9Fvurusu&body=Merhaba%2C%0A%0ABeta%20program%C4%B1na%20kat%C4%B1lmak%20istiyorum.%0A%0ATe%C5%9Fekk%C3%BCrler.'

export default function Navbar({ minimal = false }) {
  const [scrolled, setScrolled] = useState(false)
  const [menuOpen, setMenuOpen] = useState(false)

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
              <a href="#features">Özellikler</a>
              <a href="#how">Nasıl Çalışır</a>
              <a href="#faq">SSS</a>
            </nav>
          )}

          <div className="nav-actions">
            {!minimal && (
              <a
                href={BETA_MAILTO}
                className="btn btn-ghost btn-sm nav-cta"
                aria-label="Beta programı için marmaradar@gmail.com adresine e-posta gönder"
              >
                <Mail size={16} aria-hidden="true" />
                Beta&apos;ya Katıl
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
            <a href="#features" onClick={closeMenu}>Özellikler</a>
            <a href="#how" onClick={closeMenu}>Nasıl Çalışır</a>
            <a href="#faq" onClick={closeMenu}>SSS</a>
            <a href={BETA_MAILTO} onClick={closeMenu} aria-label="Beta programı için e-posta gönder">
              <Mail size={16} aria-hidden="true" />
              Beta&apos;ya Katıl
            </a>
          </div>
        )}
      </div>
    </header>
  )
}
