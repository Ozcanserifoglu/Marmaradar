import Navbar from './Navbar'
import GradientBlobs from './GradientBlobs'
import Footer from './Footer'
import '../pages/Legal.css'

export default function LegalLayout({ title, children }) {
  return (
    <div className="legal-page">
      <Navbar />
      <div className="legal-body">
        <GradientBlobs subtle />
        <article className="container legal-container">
          <header className="legal-head">
            <h1>{title}</h1>
            <p className="legal-updated">Son güncelleme: 24 Ağustos 2026</p>
          </header>
          <div className="legal-prose">{children}</div>
        </article>
      </div>
      <Footer />
    </div>
  )
}
