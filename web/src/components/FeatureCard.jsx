import './FeatureCard.css'

export default function FeatureCard({
  icon: Icon,
  title,
  description,
  image,
  className = '',
  lead = false,
}) {
  const cardClassName = [
    'feature-card',
    image ? 'feature-card-has-image' : '',
    className,
  ]
    .filter(Boolean)
    .join(' ')

  return (
    <article className={cardClassName}>
      <div className="feature-copy">
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
      </div>
      {image ? (
        <figure className="feature-shot">
          <img
            src={image.src}
            alt={image.alt}
            width={502}
            height={1024}
            loading="lazy"
            decoding="async"
          />
        </figure>
      ) : null}
    </article>
  )
}
