import { motion } from 'motion/react'
import { PLAY_STORE_URL } from '../config/storeLinks'
import { SPRING_DEFAULT } from '../motion/springs'
import PhoneCarousel from './PhoneCarousel'
import './Hero.css'

const SLIDES = [
  {
    src: '/screenshots/hero.jpg',
    alt: 'Marmaradar canlı harita: konum, yakındaki yerler ve sürüş paneli',
    label: 'Canlı harita',
  },
  {
    src: '/screenshots/corridor.jpg',
    alt: 'Haritada turuncu ortalama hız koridoru',
    label: 'Ortalama hız koridoru',
  },
  {
    src: '/screenshots/drive-replay.jpg',
    alt: 'Sürüş kaydı: hız özeti ve rota yeniden oynatma',
    label: 'Sürüş analizi',
  },
]

const stagger = {
  hidden: {},
  show: { transition: { staggerChildren: 0.07, delayChildren: 0.05 } },
}

const rise = {
  hidden: { opacity: 0, y: 18 },
  show: { opacity: 1, y: 0, transition: SPRING_DEFAULT },
}

export default function Hero() {
  const primaryHref = PLAY_STORE_URL || '#get-app'
  const primaryExternal = Boolean(PLAY_STORE_URL)

  return (
    <section className="hero" id="top">
      <div className="ambient" aria-hidden="true" />

      <div className="container hero-grid">
        <motion.div className="hero-copy" variants={stagger} initial="hidden" animate="show">
          <motion.div className="pill" variants={rise}>
            <span className="pill-dot" aria-hidden="true" />
            Google Play’de
          </motion.div>

          <motion.h1 className="t-display" variants={rise}>
            Her Yolda <span className="headline-mark">Yanında</span>
          </motion.h1>

          <motion.p className="hero-lead" variants={rise}>
            Türkiye genelinde sabit hız kameraları (EDS) ve ortalama hız koridorlarını canlı takip
            et. Yola çıkmadan önce uyar; sürüş sırasında uygulama açıkken sesli ve görsel uyarı al.
          </motion.p>

          <motion.div className="hero-ctas" id="download" variants={rise}>
            <a
              className="btn btn-primary btn-lg"
              href={primaryHref}
              {...(primaryExternal ? { target: '_blank', rel: 'noopener noreferrer' } : undefined)}
            >
              Google Play’de İndir
            </a>
            <a className="btn btn-secondary btn-lg" href="#how">
              Nasıl Çalışır?
            </a>
          </motion.div>

          <motion.p className="hero-meta t-footnote" variants={rise}>
            Android · Google Play
          </motion.p>
        </motion.div>

        <motion.div
          className="hero-visual"
          initial={{ opacity: 0, y: 24 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ ...SPRING_DEFAULT, delay: 0.25 }}
        >
          <PhoneCarousel slides={SLIDES} />
        </motion.div>
      </div>
    </section>
  )
}
