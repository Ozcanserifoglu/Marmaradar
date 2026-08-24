import { useId, useState } from 'react'
import { ChevronDown, Download, Map, Camera, Gauge, BellRing } from 'lucide-react'
import { Link } from 'react-router-dom'
import Navbar from '../components/Navbar'
import GradientBlobs from '../components/GradientBlobs'
import Hero from '../components/Hero'
import StoreBadges from '../components/StoreBadges'
import FeatureCard from '../components/FeatureCard'
import HowItWorks from '../components/HowItWorks'
import Footer from '../components/Footer'
import ApkDisclaimer from '../components/ApkDisclaimer'
import { useScrollReveal } from '../hooks/useScrollReveal'
import './Home.css'

const FEATURES = [
  {
    icon: Map,
    title: 'Canlı Harita',
    description: 'Konumun, yakındaki kameralar ve koridor hatları haritada net görünür.',
    className: 'feature-card-lead',
    lead: true,
  },
  {
    icon: Camera,
    title: 'Hız Kamerası Uyarıları',
    description: 'Sabit EDS kameralarına yaklaşırken mesafe ve hız limiti ile uyarılırsın.',
  },
  {
    icon: Gauge,
    title: 'Ortalama Hız Koridorları',
    description: 'Koridor içindeyken ortalama hızını limite göre takip et.',
  },
  {
    icon: BellRing,
    title: 'Arka Plan Uyarıları',
    description: 'Ekran kapalıyken bile uyarılar çalışmaya devam eder — yola odaklan.',
    className: 'feature-card-wide',
  },
]

function FaqItem({ question, children, itemRef }) {
  const [open, setOpen] = useState(false)
  const baseId = useId()
  const panelId = `${baseId}-panel`
  const buttonId = `${baseId}-button`

  return (
    <div className={`faq-item${open ? ' open' : ''}`} ref={itemRef}>
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
          <ChevronDown className="faq-icon" size={18} aria-hidden="true" />
        </button>
      </h3>
      <div className="faq-a" id={panelId} role="region" aria-labelledby={buttonId}>
        <div>
          <p>{children}</p>
        </div>
      </div>
    </div>
  )
}

export default function Home() {
  const featuresHeadRef = useScrollReveal()
  const featureGridRef = useScrollReveal({ staggerClass: 'stagger-1' })

  const howHeadRef = useScrollReveal()
  const howStep1 = useScrollReveal({ staggerClass: 'stagger-1' })
  const howStep2 = useScrollReveal({ staggerClass: 'stagger-2' })
  const howStep3 = useScrollReveal({ staggerClass: 'stagger-3' })
  const howStepRefs = [howStep1, howStep2, howStep3]

  const faqHeadRef = useScrollReveal()
  const faqRef1 = useScrollReveal({ staggerClass: 'stagger-1' })
  const faqRef2 = useScrollReveal({ staggerClass: 'stagger-2' })
  const faqRef3 = useScrollReveal({ staggerClass: 'stagger-3' })
  const faqRef4 = useScrollReveal({ staggerClass: 'stagger-4' })
  const faqRefs = [faqRef1, faqRef2, faqRef3, faqRef4]

  const finalCtaRef = useScrollReveal()

  return (
    <div className="home-page">
      <Navbar />

      <div className="home-hero-wrap">
        <GradientBlobs />
        <Hero />
      </div>

      <StoreBadges />

      <section className="page-section features-section" id="features">
        <div className="container">
          <div className="section-head section-head-split" ref={featuresHeadRef}>
            <h2>Neden Marmaradar?</h2>
            <p>Sürüş sırasında ihtiyacın olan uyarılar — gereksiz gürültü yok.</p>
          </div>

          <div className="feature-grid" ref={featureGridRef}>
            {FEATURES.map((feature) => (
              <FeatureCard
                key={feature.title}
                icon={feature.icon}
                title={feature.title}
                description={feature.description}
                className={feature.className}
                lead={feature.lead}
              />
            ))}
          </div>
        </div>
      </section>

      <HowItWorks stepRefs={{ head: howHeadRef, items: howStepRefs }} />

      <section className="page-section faq-section" id="faq">
        <div className="container faq-layout">
          <div className="section-head" ref={faqHeadRef}>
            <h2>Sık sorulanlar</h2>
            <p>Beta hakkında bilmen gerekenler.</p>
          </div>

          <div className="faq-list">
            <FaqItem question="Mağazalarda ne zaman olacak?" itemRef={faqRefs[0]}>
              Google Play ve App Store yayınları henüz hazır değil. Şimdilik Android beta APK ile
              erken erişim sunuyoruz.
            </FaqItem>
            <FaqItem question="Hangi bölgeleri kapsıyor?" itemRef={faqRefs[1]}>
              Türkiye genelinde EDS ve ortalama hız koridorlarını takip ediyoruz; kapsam
              sürekli genişliyor.
            </FaqItem>
            <FaqItem question="Konum verisi ne için kullanılıyor?" itemRef={faqRefs[2]}>
              Harita, EDS ve koridor uyarıları için. Giriş yaptıysan sürüş kaydı sunucuya
              yüklenebilir; topluluk raporları da konumla ilişkilendirilebilir. Reklam ağı
              yok. Ayrıntılar <Link to="/gizlilik">gizlilik sayfasında</Link>.
            </FaqItem>
            <FaqItem question="APK’yı nasıl kurarım? Güvenli mi?" itemRef={faqRefs[3]}>
              Google Play henüz yok; Android’de bilinmeyen kaynaklardan kurulum gerekir. Play
              Protect uyarabilir. İndirme ve kurulum tamamen senin riskin; Marmaradar oluşan
              hiçbir sonuçtan sorumlu değildir. Kurulumdan önce{' '}
              <Link to="/kullanim-sartlari">kullanım şartlarını</Link> oku.
            </FaqItem>
          </div>
        </div>
      </section>

      <section className="final-cta">
        <div className="container">
          <div className="final-cta-box" ref={finalCtaRef}>
            <div className="final-cta-copy">
              <h2>Beta’ya katıl, yolda bir adım önde ol</h2>
              <p>
                Marmaradar Android beta’sını şimdi indir; mağaza açılışından önce geri bildiriminle
                şekillendir.
              </p>
            </div>
            <div className="final-cta-action">
              <a
                className="btn btn-primary btn-lg"
                href="/downloads/marmaradar-beta.apk"
                download
              >
                <Download size={18} aria-hidden="true" />
                APK İndir (Beta)
              </a>
            </div>
            <ApkDisclaimer />
          </div>
        </div>
      </section>

      <Footer />
    </div>
  )
}
