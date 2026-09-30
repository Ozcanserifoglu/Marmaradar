import { Mail } from 'lucide-react'
import { Link } from 'react-router-dom'
import './Footer.css'

export default function Footer() {
  return (
    <footer className="footer">
      <div className="container">
        <div className="footer-top">
          <div className="footer-brand">
            <Link to="/" className="wordmark">
              <span className="wordmark-accent">Marmaradar</span>
            </Link>
            <p>Türkiye genelinde sürücüler için canlı EDS ve koridor uyarıları.</p>
          </div>
          <a className="footer-contact" href="mailto:marmaradar@gmail.com">
            <Mail size={18} aria-hidden="true" />
            İletişim için: marmaradar@gmail.com
          </a>
        </div>

        <div className="footer-bottom">
          <div className="footer-copy">
            <p>© 2026 Marmaradar. Tüm hakları saklıdır.</p>
            <p className="footer-osm">
              Kamera verisi ©{' '}
              <a
                href="https://www.openstreetmap.org/copyright"
                target="_blank"
                rel="noopener noreferrer"
              >
                OpenStreetMap
              </a>{' '}
              katkıcıları (ODbL)
            </p>
          </div>
          <div className="footer-legal">
            <Link to="/gizlilik">Gizlilik</Link>
            <Link to="/kullanim-sartlari">Kullanım Şartları</Link>
          </div>
        </div>
      </div>
    </footer>
  )
}
