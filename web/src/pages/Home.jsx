import { Download, Map, Camera, Gauge, BellRing } from 'lucide-react'
import Navbar from '../components/Navbar'
import GradientBlobs from '../components/GradientBlobs'
import Hero from '../components/Hero'
import StoreBadges from '../components/StoreBadges'
import FeatureCard from '../components/FeatureCard'
import HowItWorks from '../components/HowItWorks'
import Footer from '../components/Footer'
import { useScrollReveal } from '../hooks/useScrollReveal'
import './Home.css'

const FEATURES = [
  {
    icon: Map,
    title: 'Canlı Harita',
    description: 'Konumun, yakındaki kameralar ve koridor hatları haritada net görünür.',
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
  },
]

export default function Home() {
  const featuresHeadRef = useScrollReveal()
  const featureRef1 = useScrollReveal({ staggerClass: 'stagger-1' })
  const featureRef2 = useScrollReveal({ staggerClass: 'stagger-2' })
  const featureRef3 = useScrollReveal({ staggerClass: 'stagger-3' })
  const featureRef4 = useScrollReveal({ staggerClass: 'stagger-4' })
  const featureRefs = [featureRef1, featureRef2, featureRef3, featureRef4]

  const howHeadRef = useScrollReveal()
  const howStep1 = useScrollReveal({ staggerClass: 'stagger-1' })
  const howStep2 = useScrollReveal({ staggerClass: 'stagger-2' })
  const howStep3 = useScrollReveal({ staggerClass: 'stagger-3' })
  const howStepRefs = [howStep1, howStep2, howStep3]

  const faqHeadRef = useScrollReveal()
  const faqRef1 = useScrollReveal({ staggerClass: 'stagger-1' })
  const faqRef2 = useScrollReveal({ staggerClass: 'stagger-2' })
  const faqRef3 = useScrollReveal({ staggerClass: 'stagger-3' })
  const faqRefs = [faqRef1, faqRef2, faqRef3]

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
          <div className="section-head" ref={featuresHeadRef}>
            <h2>Neden Marmaradar?</h2>
            <p>Sürüş sırasında ihtiyacın olan uyarılar — gereksiz gürültü yok.</p>
          </div>

          <div className="feature-grid">
            {FEATURES.map((feature, index) => (
              <div key={feature.title} ref={featureRefs[index]}>
                <FeatureCard
                  icon={feature.icon}
                  title={feature.title}
                  description={feature.description}
                />
              </div>
            ))}
          </div>
        </div>
      </section>

      <HowItWorks stepRefs={{ head: howHeadRef, items: howStepRefs }} />

      <section className="page-section faq-section" id="faq">
        <div className="container">
          <div className="section-head" ref={faqHeadRef}>
            <h2>Sık sorulanlar</h2>
            <p>Beta hakkında bilmen gerekenler.</p>
          </div>

          <div className="faq-list">
            <div className="faq-item" ref={faqRefs[0]}>
              <h3>Mağazalarda ne zaman olacak?</h3>
              <p>
                Google Play ve App Store yayınları henüz hazır değil. Şimdilik Android beta APK ile
                erken erişim sunuyoruz.
              </p>
            </div>
            <div className="faq-item" ref={faqRefs[1]}>
              <h3>Hangi bölgeleri kapsıyor?</h3>
              <p>
                Türkiye genelinde EDS ve ortalama hız koridorlarını takip ediyoruz; kapsam
                sürekli genişliyor.
              </p>
            </div>
            <div className="faq-item" ref={faqRefs[2]}>
              <h3>Konum verisi ne için kullanılıyor?</h3>
              <p>
                Yalnızca sürüş uyarıları ve harita takibi için. Reklam veya sosyal özellik yok.
              </p>
            </div>
          </div>
        </div>
      </section>

      <section className="final-cta">
        <div className="container">
          <div className="final-cta-box" ref={finalCtaRef}>
            <h2>Beta’ya katıl, yolda bir adım önde ol</h2>
            <p>
              Marmaradar Android beta’sını şimdi indir; mağaza açılışından önce geri bildiriminle
              şekillendir.
            </p>
            <a
              className="btn btn-primary btn-lg"
              href="/downloads/marmaradar-beta.apk"
              download
            >
              <Download size={18} aria-hidden="true" />
              APK İndir (Beta)
            </a>
          </div>
        </div>
      </section>

      <Footer />
    </div>
  )
}
