import Reveal from './Reveal'
import './HowItWorks.css'

const STEPS = [
  {
    title: 'Uygulamayı İndir',
    description: 'Google Play’den Marmaradar’ı kur ve uygulamayı aç.',
  },
  {
    title: 'Konum İzni',
    description: 'Konum (kullanımdayken) ve bildirim izinlerini ver.',
  },
  {
    title: 'Sürüşe Başla',
    description: 'Haritada konumunu kilitle, Sürüşe Başla’ya dokun veya Otomatik’i aç.',
  },
]

export default function HowItWorks() {
  return (
    <section className="page-section how-section" id="how">
      <div className="container">
        <Reveal className="section-head">
          <h2 className="t-title1">Nasıl çalışır?</h2>
          <p>Üç adımda yola çık.</p>
        </Reveal>

        <ol className="steps">
          {STEPS.map((step, index) => (
            <Reveal as="li" className="step" key={step.title} delay={index * 0.07}>
              <div className="step-marker" aria-hidden="true">
                <span className="step-num">{`0${index + 1}`}</span>
                <span className="step-rule" />
              </div>
              <h3 className="t-title3">{step.title}</h3>
              <p>{step.description}</p>
            </Reveal>
          ))}
        </ol>
      </div>
    </section>
  )
}
