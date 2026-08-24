import { Download } from 'lucide-react'
import ApkDisclaimer from './ApkDisclaimer'
import './Hero.css'

export default function Hero() {
  return (
    <section className="hero" id="top">
      <div className="hero-grid-bg" aria-hidden="true" />

      <div className="container hero-grid">
        <div className="hero-copy">
          <div className="pill reveal-hero d1">
            <span className="pill-dot" aria-hidden="true" />
            Beta Now Live
          </div>

          <h1 className="reveal-hero d2">
            Marmara&apos;nın <span className="headline-mark">Nabzı</span> Artık Cebinde
          </h1>

          <p className="hero-lead reveal-hero d3">
            Türkiye genelinde sabit hız kameraları (EDS) ve ortalama hız koridorlarını canlı takip et.
            Yola çıkmadan önce uyar; sürüş sırasında arka planda da uyarı al.
          </p>

          <div className="hero-ctas reveal-hero d4" id="download">
            <a
              className="btn btn-primary"
              href="/downloads/marmaradar-beta.apk"
              download
            >
              <Download size={18} aria-hidden="true" />
              APK İndir (Beta)
            </a>
            <a className="btn btn-ghost" href="#how">
              Nasıl Çalışır?
            </a>
          </div>

          {/* TODO: update version number and file size once real APK is finalized */}
          <p className="hero-meta reveal-hero d5">Android 8.0+ · v0.x Beta</p>
          <div className="reveal-hero d5">
            <ApkDisclaimer />
          </div>
        </div>

        <div className="phone-wrap reveal-hero d6" aria-hidden="true">
          <div className="phone">
            <div className="phone-screen">
              <svg
                className="phone-map"
                viewBox="0 0 240 420"
                preserveAspectRatio="xMidYMid slice"
                aria-hidden="true"
              >
                <g className="map-roads-minor">
                  <path d="M-20 118 L260 92" />
                  <path d="M-20 246 L260 226" />
                  <path d="M-20 358 L260 336" />
                  <path d="M36 -20 L58 440" />
                  <path d="M186 -20 L172 440" />
                  <path d="M110 -20 L118 118" />
                  <path d="M58 300 L172 288" />
                </g>
                <g className="map-roads-major">
                  <path d="M-20 190 C 60 176, 120 214, 260 168" />
                  <path d="M124 -20 L112 440" />
                </g>
                <path
                  className="map-route-glow"
                  d="M64 372 L70 250 L118 244 L112 150 L196 138"
                />
                <path
                  className="map-route"
                  d="M64 372 L70 250 L118 244 L112 150 L196 138"
                />
                <circle className="map-cam-halo" cx="112" cy="150" r="13" />
                <circle className="map-cam" cx="112" cy="150" r="5" />
                <circle className="map-here-halo" cx="70" cy="250" r="15" />
                <circle className="map-here" cx="70" cy="250" r="6" />
              </svg>

              <div className="phone-status">
                <span className="live">
                  <span className="pill-dot sm" /> Canlı
                </span>
                <span>Bursa</span>
              </div>

              <div className="phone-card">
                <div className="label">Rota</div>
                <div className="title">Nilüfer → Osmangazi</div>
                <div className="sub">12,4 km · ~18 dk</div>
              </div>

              <div className="phone-card alert">
                <div className="label">Uyarı</div>
                <div className="title">EDS — 350 m</div>
                <div className="sub">Hız limiti 70 km/s</div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  )
}
