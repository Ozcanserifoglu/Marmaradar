import { motion, useReducedMotion } from 'motion/react'
import { FADE, SPRING_DEFAULT } from '../motion/springs'
import './FeatureCard.css'

export default function FeatureCard({
  icon: Icon,
  title,
  description,
  image,
  className = '',
  lead = false,
  delay = 0,
}) {
  const reduceMotion = useReducedMotion()
  const cardClassName = ['feature-card', image ? 'feature-card-has-image' : '', className]
    .filter(Boolean)
    .join(' ')

  return (
    <motion.article
      className={cardClassName}
      initial={{ opacity: 0, y: reduceMotion ? 0 : 20 }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true, margin: '0px 0px -40px 0px' }}
      whileHover={reduceMotion ? undefined : { y: -3 }}
      whileTap={reduceMotion ? undefined : { scale: 0.985 }}
      transition={reduceMotion ? { ...FADE, delay } : { ...SPRING_DEFAULT, delay }}
    >
      <div className="feature-copy">
        {Icon ? (
          <span className="feature-icon" aria-hidden="true">
            <Icon size={lead ? 26 : 22} strokeWidth={1.75} />
          </span>
        ) : null}
        <h3 className={lead ? 't-title2' : 't-title3'}>{title}</h3>
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
            draggable={false}
          />
        </figure>
      ) : null}
    </motion.article>
  )
}
