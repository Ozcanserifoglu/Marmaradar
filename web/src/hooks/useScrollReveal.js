import { useEffect, useRef } from 'react'

/**
 * Intersection Observer scroll-reveal. Adds `reveal` + `visible` classes.
 * Returns a callback ref factory for className composition.
 */
export function useScrollReveal(options = {}) {
  const {
    threshold = 0.12,
    rootMargin = '0px 0px -40px 0px',
    staggerClass,
  } = options

  const ref = useRef(null)

  useEffect(() => {
    const el = ref.current
    if (!el) return undefined

    const reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches
    el.classList.add('reveal')
    if (staggerClass) el.classList.add(staggerClass)

    if (reduceMotion || !('IntersectionObserver' in window)) {
      el.classList.add('visible')
      return undefined
    }

    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            entry.target.classList.add('visible')
            observer.unobserve(entry.target)
          }
        })
      },
      { threshold, rootMargin },
    )

    observer.observe(el)
    return () => observer.disconnect()
  }, [threshold, rootMargin, staggerClass])

  return ref
}
