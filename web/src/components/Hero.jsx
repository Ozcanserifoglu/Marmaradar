import { PLAY_STORE_URL } from '../config/storeLinks'
import './Hero.css'

export default function Hero() {
  const primaryHref = PLAY_STORE_URL || '#get-app'
  const primaryExternal = Boolean(PLAY_STORE_URL)

  return (
    <section className="hero" id="top">
      <div className="hero-grid-bg" aria-hidden="true" />

      <div className="container hero-grid">
        <div className="hero-copy">
          <div className="pill reveal-hero d1">
            <span className="pill-dot" aria-hidden="true" />
            Google Play’de
          </div>

          <h1 className="reveal-hero d2">
            Her Yolda <span className="headline-mark">Yanında</span>
          </h1>

          <p className="hero-lead reveal-hero d3">
            Türkiye genelinde sabit hız kameraları (EDS) ve ortalama hız koridorlarını canlı takip et.
            Yola çıkmadan önce uyar; sürüş sırasında uygulama açıkken sesli ve görsel uyarı al.
          </p>

          <div className="hero-ctas reveal-hero d4" id="download">
            <a
              className="btn btn-primary"
              href={primaryHref}
              {...(primaryExternal
                ? { target: '_blank', rel: 'noopener noreferrer' }
                : undefined)}
            >
              Google Play’de İndir
            </a>
            <a className="btn btn-ghost" href="#how">
              Nasıl Çalışır?
            </a>
          </div>

          <p className="hero-meta reveal-hero d5">Android · Google Play</p>
        </div>

        <div className="phone-wrap reveal-hero d6">
          <div className="phone">
            <div className="phone-screen">
              <img
                className="phone-shot"
                src="/screenshots/hero.jpg"
                alt="Marmaradar canlı harita: konum, yakındaki yerler ve sürüş paneli"
                width={472}
                height={1024}
              />
            </div>
          </div>
        </div>
      </div>
    </section>
  )
}
