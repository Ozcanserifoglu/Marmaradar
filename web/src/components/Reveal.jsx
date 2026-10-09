import { motion, useReducedMotion } from 'motion/react'
import { SPRING_DEFAULT, FADE } from '../motion/springs'

/**
 * Reveals children once they scroll into view. Travels a short distance on
 * a critically damped spring; cross-fades when the user prefers reduced motion.
 */
export default function Reveal({
  as = 'div',
  delay = 0,
  distance = 20,
  className,
  children,
  ...rest
}) {
  const reduceMotion = useReducedMotion()
  const Component = motion[as] ?? motion.div

  return (
    <Component
      className={className}
      initial={{ opacity: 0, y: reduceMotion ? 0 : distance }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true, margin: '0px 0px -40px 0px' }}
      transition={reduceMotion ? { ...FADE, delay } : { ...SPRING_DEFAULT, delay }}
      {...rest}
    >
      {children}
    </Component>
  )
}
