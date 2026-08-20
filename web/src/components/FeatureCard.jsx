import './FeatureCard.css'

export default function FeatureCard({ icon: Icon, title, description, className = '' }) {
  return (
    <article className={`feature-card ${className}`.trim()}>
      <div className="feature-icon">
        {Icon ? <Icon size={22} aria-hidden="true" /> : null}
      </div>
      <h3>{title}</h3>
      <p>{description}</p>
    </article>
  )
}
