import './HowItWorks.css'

const STEPS = [
  {
    title: 'APK İndir',
    description: 'Android beta paketini indir, yükle ve uygulamayı aç.',
  },
  {
    title: 'Konum İzni',
    description: 'Konum ve bildirim izinlerini ver; arka plan uyarıları için “her zaman” seç.',
  },
  {
    title: 'Sürüşe Başla',
    description: 'Haritada konumunu kilitle, Sürüşe Başla’ya dokun veya Otomatik’i aç.',
  },
]

export default function HowItWorks({ stepRefs }) {
  return (
    <section className="page-section" id="how">
      <div className="container">
        <div className="section-head" ref={stepRefs?.head}>
          <h2>Nasıl çalışır?</h2>
          <p>Üç adımda yola çık. Mağaza beklemeden beta ile başla.</p>
        </div>

        <div className="steps">
          {STEPS.map((step, index) => (
            <div
              className="step"
              key={step.title}
              ref={stepRefs?.items?.[index]}
            >
              <h3>{step.title}</h3>
              <p>{step.description}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}
