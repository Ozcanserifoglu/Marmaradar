import { useEffect, useState } from 'react'
import { Link, useLocation } from 'react-router-dom'
import { motion, useScroll, useTransform } from 'motion/react'
import { ArrowLeft, Menu, X } from 'lucide-react'
import { PLAY_STORE_URL } from '../config/storeLinks'
import MenuSheet from './MenuSheet'
import './Navbar.css'

const LINKS = [
  { href: '/#features', label: 'Özellikler' },
  { href: '/#how', label: 'Nasıl Çalışır' },
  { href: '/#faq', label: 'SSS' },
]

export default function Navbar({ minimal = false }) {
  const [menuOpen, setMenuOpen] = useState(false)
  const { pathname } = useLocation()
  const onChangelog = pathname === '/changelog'
  const ctaHref = PLAY_STORE_URL || '#get-app'
  const ctaExternal = Boolean(PLAY_STORE_URL)

  // The edge fade only appears once content has actually scrolled under the bar.
  const { scrollY } = useScroll()
  const edgeOpacity = useTransform(scrollY, [0, 48], [0, 1])

  useEffect(() => {
    if (!menuOpen) return undefined
    const onKey = (e) => {
      if (e.key === 'Escape') setMenuOpen(false)
    }
    const onResize = () => {
      if (window.innerWidth >= 768) setMenuOpen(false)
    }
    window.addEventListener('keydown', onKey)
    window.addEventListener('resize', onResize)
    return () => {
      window.removeEventListener('keydown', onKey)
      window.removeEventListener('resize', onResize)
    }
  }, [menuOpen])

  const closeMenu = () => setMenuOpen(false)

  const externalProps = ctaExternal
    ? { target: '_blank', rel: 'noopener noreferrer' }
    : undefined

  return (
    <>
      <header className="nav material">
        <div className="container nav-inner">
          <div className="nav-leading">
            {minimal ? (
              <Link to="/" className="nav-back" aria-label="Ana sayfaya dön">
                <ArrowLeft size={18} aria-hidden="true" />
                <span>Ana sayfa</span>
              </Link>
            ) : null}
            <Link to="/" className="wordmark" onClick={closeMenu} aria-label="Marmaradar ana sayfa">
              <span className="wordmark-accent">Marmaradar</span>
            </Link>
          </div>

          {!minimal && (
            <nav className="nav-links" aria-label="Ana menü">
              {LINKS.map((link) => (
                <a key={link.href} href={link.href}>
                  {link.label}
                </a>
              ))}
              <Link to="/changelog" aria-current={onChangelog ? 'page' : undefined}>
                Güncellemeler
              </Link>
            </nav>
          )}

          {!minimal && (
            <div className="nav-actions">
              <a href={ctaHref} className="btn btn-primary btn-sm nav-cta" {...externalProps}>
                Google Play
              </a>
              <motion.button
                className="menu-toggle"
                type="button"
                aria-label={menuOpen ? 'Menüyü kapat' : 'Menüyü aç'}
                aria-expanded={menuOpen}
                whileTap={{ scale: 0.9 }}
                transition={{ type: 'spring', bounce: 0, duration: 0.2 }}
                onClick={() => setMenuOpen((open) => !open)}
              >
                {menuOpen ? <X size={20} aria-hidden="true" /> : <Menu size={20} aria-hidden="true" />}
              </motion.button>
            </div>
          )}
        </div>
        <motion.div className="nav-edge" style={{ opacity: edgeOpacity }} aria-hidden="true" />
      </header>

      {!minimal && (
        <MenuSheet open={menuOpen} onOpenChange={setMenuOpen}>
          {LINKS.map((link) => (
            <a key={link.href} href={link.href} onClick={closeMenu}>
              {link.label}
            </a>
          ))}
          <Link
            to="/changelog"
            aria-current={onChangelog ? 'page' : undefined}
            onClick={closeMenu}
          >
            Güncellemeler
          </Link>
          <a
            href={ctaHref}
            className="btn btn-primary menu-sheet-cta"
            onClick={closeMenu}
            {...externalProps}
          >
            Google Play’de İndir
          </a>
        </MenuSheet>
      )}
    </>
  )
}
