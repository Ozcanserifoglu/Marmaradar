import Navbar from '../components/Navbar'
import Footer from '../components/Footer'
import Reveal from '../components/Reveal'
import changelog from '../data/changelog.json'
import './Changelog.css'

function formatDate(isoDate) {
  const [year, month, day] = isoDate.split('-').map(Number)
  if (!year || !month || !day) return isoDate
  return new Intl.DateTimeFormat('tr-TR', {
    day: 'numeric',
    month: 'long',
    year: 'numeric',
  }).format(new Date(year, month - 1, day))
}

export default function Changelog() {
  return (
    <div className="changelog-page">
      <Navbar />

      <div className="changelog-body">
        <div className="ambient ambient-subtle" aria-hidden="true" />
        <div className="container changelog-container">
          <Reveal as="header" className="changelog-head">
            <h1 className="t-title1">Güncellemeler</h1>
            <p>Marmaradar&apos;daki yenilikler ve iyileştirmeler — en yeniler en üstte.</p>
          </Reveal>

          <ol className="changelog-list">
            {changelog.map((entry, index) => (
              <Reveal
                as="li"
                key={entry.version}
                className="changelog-card"
                delay={Math.min(index, 3) * 0.05}
              >
                <div className="changelog-meta t-footnote">
                  <span className="changelog-version">v{entry.version}</span>
                  <time dateTime={entry.date}>{formatDate(entry.date)}</time>
                </div>
                <h2 className="changelog-title t-title3">{entry.title}</h2>
                <ul className="changelog-changes">
                  {entry.changes.map((change) => (
                    <li key={change}>{change}</li>
                  ))}
                </ul>
              </Reveal>
            ))}
          </ol>
        </div>
      </div>

      <Footer />
    </div>
  )
}
