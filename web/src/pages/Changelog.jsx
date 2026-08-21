import Navbar from '../components/Navbar'
import GradientBlobs from '../components/GradientBlobs'
import Footer from '../components/Footer'
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
        <GradientBlobs subtle />
        <div className="container changelog-container">
          <header className="changelog-head">
            <h1>Güncellemeler</h1>
            <p>Marmaradar&apos;daki yenilikler ve iyileştirmeler — en yeniler en üstte.</p>
          </header>

          <ol className="changelog-list">
            {changelog.map((entry) => (
              <li key={entry.version} className="changelog-card">
                <div className="changelog-meta">
                  <span className="changelog-version">v{entry.version}</span>
                  <time dateTime={entry.date}>{formatDate(entry.date)}</time>
                </div>
                <h2 className="changelog-title">{entry.title}</h2>
                <ul className="changelog-changes">
                  {entry.changes.map((change) => (
                    <li key={change}>{change}</li>
                  ))}
                </ul>
              </li>
            ))}
          </ol>
        </div>
      </div>

      <Footer />
    </div>
  )
}
