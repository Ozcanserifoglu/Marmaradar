import { Download } from 'lucide-react'
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
            Marmara&apos;nın <span className="gradient-text">Nabzı</span> Artık Cebinde
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
        </div>

        <div className="phone-wrap reveal-hero d6" aria-hidden="true">
          <div className="phone">
            <div className="phone-screen">
              <div className="phone-map-grid" />
              <div className="phone-route" />
              <div className="phone-pin" />
              <div className="phone-pin cam" />

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
