import './StoreBadges.css'

export default function StoreBadges() {
  return (
    <div className="store-strip">
      <div className="container store-inner">
        <p className="store-label">Mağazalar yakında</p>
        <div className="store-badges">
          <div className="store-badge">
            <span className="coming-tag">Coming Soon</span>
            <div className="store-badge-frame">
              <svg viewBox="0 0 24 24" fill="currentColor" aria-hidden="true" width="28" height="28">
                <path d="M3.6 2.4l10.1 10.1L3.6 22.6A1.2 1.2 0 012 21.6V3.4a1.2 1.2 0 011.6-1zM15.1 13.9l2.6 1.5-9.6 5.5 7-7zm2.6-5.3l-2.6 1.5-7-7 9.6 5.5zM20.2 10.7l-2.2-1.3-2.7 1.6 2.7 1.6 2.2-1.3a1.2 1.2 0 000-2.1z" />
              </svg>
              <div className="store-text">
                <div className="tiny">GET IT ON</div>
                <div className="name">Google Play</div>
              </div>
            </div>
          </div>
          <div className="store-badge">
            <span className="coming-tag">Coming Soon</span>
            <div className="store-badge-frame">
              <svg viewBox="0 0 24 24" fill="currentColor" aria-hidden="true" width="28" height="28">
                <path d="M16.4 12.7c0-2.3 1.9-3.4 2-3.5-1.1-1.6-2.8-1.8-3.4-1.8-1.4-.1-2.8.9-3.5.9s-1.8-.8-3-.8c-1.5 0-3 .9-3.8 2.3-1.6 2.8-.4 7 1.2 9.3.8 1.1 1.7 2.3 2.9 2.3 1.2 0 1.6-.7 3-.7s1.8.7 3 .7 2-.1 3-2.2c1.1-1.6 1.5-3.1 1.5-3.2-.1 0-2.9-1.1-2.9-4.1zM14.3 5.9c.6-.8 1.1-1.9 1-3-.9 0-2 .6-2.6 1.4-.6.7-1.1 1.8-1 2.9 1 .1 2-.5 2.6-1.3z" />
              </svg>
              <div className="store-text">
                <div className="tiny">Download on the</div>
                <div className="name">App Store</div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
