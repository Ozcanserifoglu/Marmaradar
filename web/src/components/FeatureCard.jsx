import './FeatureCard.css'

export default function FeatureCard({ icon: Icon, title, description, className = '', lead = false }) {
  return (
    <article className={`feature-card ${className}`.trim()}>
      {Icon ? (
        <Icon
          className="feature-icon"
          size={lead ? 40 : 28}
          strokeWidth={1.5}
          aria-hidden="true"
        />
      ) : null}
      <h3>{title}</h3>
      <p>{description}</p>
    </article>
  )
}
