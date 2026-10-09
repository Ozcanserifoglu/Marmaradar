import { useId, useState } from 'react'
import { AnimatePresence, motion, useReducedMotion } from 'motion/react'
import { ChevronDown, Map, Camera, Gauge, Route, BellRing } from 'lucide-react'
import { Link } from 'react-router-dom'
import Navbar from '../components/Navbar'
import Hero from '../components/Hero'
import StoreBadges from '../components/StoreBadges'
import FeatureCard from '../components/FeatureCard'
import HowItWorks from '../components/HowItWorks'
import Footer from '../components/Footer'
import Reveal from '../components/Reveal'
import { PLAY_STORE_URL } from '../config/storeLinks'
import { FADE, SPRING_SNAPPY } from '../motion/springs'
import './Home.css'

const FEATURES = [
  {
    icon: Map,
    title: 'Canlı Harita',
    description: 'Konumun, yakındaki kameralar ve koridor hatları haritada net görünür.',
    className: 'feature-card-wide feature-card-lead',
    lead: true,
    image: {
      src: '/screenshots/hero.jpg',
      alt: 'Canlı harita: konum, yakındaki yerler ve sürüş paneli',
    },
  },
  {
    icon: Camera,
    title: 'Hız Kamerası Uyarıları',
    description: 'Sabit EDS kameralarına yaklaşırken mesafe ve hız limiti ile uyarılırsın.',
    className: 'feature-card-square',
  },
  {
    icon: Gauge,
    title: 'Ortalama Hız Koridorları',
    description: 'Koridor içindeyken ortalama hızını limite göre takip et.',
    className: 'feature-card-square',
    image: {
      src: '/screenshots/corridor.jpg',
      alt: 'Haritada turuncu ortalama hız koridoru',
    },
  },
  {
    icon: Route,
    title: 'Sürüş Analizi ve Video Çıktısı',
    description:
      'Sürüşlerini kaydet. En düşük, en yüksek ve ortalama hızı gör, rotayı haritada tekrar izle, videoya al.',
    image: {
      src: '/screenshots/drive-replay.jpg',
      alt: 'Sürüş kaydı: hız özeti ve rota yeniden oynatma',
    },
    className: 'feature-card-wide',
  },
  {
    icon: BellRing,
    title: 'Sesli ve Görsel Uyarılar',
    description: 'Uygulama açıkken yaklaşan kameraları ve koridorları sesli ve görsel uyarır.',
    className: 'feature-card-full',
  },
]

/**
 * Disclosure row. The panel's height is driven by a spring that starts from
 * its current value, so rapid toggling never jumps or waits.
 */
function FaqItem({ question, children }) {
  const [open, setOpen] = useState(false)
  const reduceMotion = useReducedMotion()
  const baseId = useId()
  const panelId = `${baseId}-panel`
  const buttonId = `${baseId}-button`
  const transition = reduceMotion ? FADE : SPRING_SNAPPY

  return (
    <div className={`faq-item${open ? ' open' : ''}`}>
      <h3>
        <button
          type="button"
          id={buttonId}
          className="faq-q"
          aria-expanded={open}
          aria-controls={panelId}
          onClick={() => setOpen((value) => !value)}
        >
          {question}
          <motion.span
            className="faq-icon"
            animate={{ rotate: open ? 180 : 0 }}
            transition={transition}
          >
            <ChevronDown size={18} aria-hidden="true" />
          </motion.span>
        </button>
      </h3>
      <AnimatePresence initial={false}>
        {open ? (
          <motion.div
            key="panel"
            className="faq-a"
            id={panelId}
            role="region"
            aria-labelledby={buttonId}
            initial={reduceMotion ? { opacity: 0 } : { height: 0, opacity: 0 }}
            animate={reduceMotion ? { opacity: 1 } : { height: 'auto', opacity: 1 }}
            exit={reduceMotion ? { opacity: 0 } : { height: 0, opacity: 0 }}
            transition={transition}
          >
            <p>{children}</p>
          </motion.div>
        ) : null}
      </AnimatePresence>
    </div>
  )
}

export default function Home() {
  const playHref = PLAY_STORE_URL || '#get-app'
  const playExternal = Boolean(PLAY_STORE_URL)

  return (
    <div className="home-page">
      <Navbar />

      <Hero />

      <StoreBadges />

      <section className="page-section features-section" id="features">
        <div className="container">
          <Reveal className="section-head section-head-split">
            <h2 className="t-title1">Neden Marmaradar?</h2>
            <p>Sürüşte işine yarayan uyarılar. Gereksiz gürültü yok.</p>
          </Reveal>

          <div className="feature-grid">
            {FEATURES.map((feature, index) => (
              <FeatureCard
                key={feature.title}
                icon={feature.icon}
                title={feature.title}
                description={feature.description}
                className={feature.className}
                lead={feature.lead}
                image={feature.image}
                delay={Math.min(index, 2) * 0.06}
              />
            ))}
          </div>
        </div>
      </section>

      <HowItWorks />

      <section className="page-section faq-section" id="faq">
        <div className="container faq-layout">
          <Reveal className="section-head">
            <h2 className="t-title1">Sık sorulanlar</h2>
            <p>Uygulama hakkında bilmen gerekenler.</p>
          </Reveal>

          <Reveal className="faq-list" delay={0.06}>
            <FaqItem question="Nereden indirebilirim?">
              Android için Google Play’den. App Store sürümü henüz yayınlanmadı.
            </FaqItem>
            <FaqItem question="Hangi bölgeleri kapsıyor?">
              Türkiye genelinde EDS ve ortalama hız koridorlarını takip ediyoruz; kapsam sürekli
              genişliyor.
            </FaqItem>
            <FaqItem question="Konum verisi ne için kullanılıyor?">
              Harita, EDS ve koridor uyarıları için. Giriş yaptıysan sürüş kaydı sunucuya
              yüklenebilir; topluluk raporları da konumla ilişkilendirilebilir. Reklam ağı yok.
              Ayrıntılar{' '}
              <Link className="link" to="/gizlilik">
                gizlilik sayfasında
              </Link>
              .
            </FaqItem>
          </Reveal>
        </div>
      </section>

      <section className="final-cta">
        <div className="container">
          <Reveal className="final-cta-box material-thick">
            <div className="final-cta-copy">
              <h2 className="t-title2">Yolda bir adım önde ol</h2>
              <p>Marmaradar’ı Google Play’den indir; sürüşe çıkmadan önce hazır ol.</p>
            </div>
            <div className="final-cta-action">
              <a
                className="btn btn-primary btn-lg"
                href={playHref}
                {...(playExternal ? { target: '_blank', rel: 'noopener noreferrer' } : undefined)}
              >
                Google Play’de İndir
              </a>
            </div>
          </Reveal>
        </div>
      </section>

      <Footer />
    </div>
  )
}
