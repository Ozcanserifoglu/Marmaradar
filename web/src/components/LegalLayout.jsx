import Navbar from './Navbar'
import Footer from './Footer'
import Reveal from './Reveal'
import '../pages/Legal.css'

export default function LegalLayout({ title, children }) {
  return (
    <div className="legal-page">
      <Navbar minimal />
      <div className="legal-body">
        <div className="ambient ambient-subtle" aria-hidden="true" />
        <Reveal as="article" className="container legal-container">
          <header className="legal-head">
            <h1 className="t-title1">{title}</h1>
            <p className="legal-updated t-footnote">Son güncelleme: 30 Eylül 2026</p>
          </header>
          <div className="legal-prose">{children}</div>
        </Reveal>
      </div>
      <Footer />
    </div>
  )
}
