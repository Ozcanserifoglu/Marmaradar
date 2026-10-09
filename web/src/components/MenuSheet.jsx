import { useCallback, useEffect, useLayoutEffect, useRef, useState } from 'react'
import {
  animate,
  motion,
  useMotionValue,
  useMotionValueEvent,
  useReducedMotion,
  useTransform,
} from 'motion/react'
import { FADE, SPRING_DEFAULT, SPRING_MOMENTUM, project } from '../motion/springs'
import './MenuSheet.css'

/** Above this speed the release direction alone decides commit vs. reverse. */
const DECISIVE_VELOCITY = 220

/**
 * Top-anchored sheet that emerges from the toolbar and returns to it.
 *
 * The sheet's vertical position is a single motion value that every input
 * (tap, drag, keyboard, resize) writes to. Springs always start from the
 * live value, so grabbing the sheet mid-flight just picks it up where it is.
 */
export default function MenuSheet({ open, onOpenChange, children }) {
  const sheetRef = useRef(null)
  const openRef = useRef(open)
  const [height, setHeight] = useState(0)
  const y = useMotionValue(-9999)
  const sheetOpacity = useMotionValue(1)
  const reduceMotion = useReducedMotion()
  const [interactive, setInteractive] = useState(false)

  // Hidden position is "fully tucked under the toolbar".
  const hiddenY = -height

  useLayoutEffect(() => {
    openRef.current = open
  }, [open])

  useLayoutEffect(() => {
    const el = sheetRef.current
    if (!el) return undefined
    const measure = () => {
      const next = el.offsetHeight
      setHeight(next)
      if (!openRef.current) y.set(-next)
    }
    measure()
    const observer = new ResizeObserver(measure)
    observer.observe(el)
    return () => observer.disconnect()
  }, [y])

  const settle = useCallback(
    (target, velocity = 0) => {
      if (reduceMotion) {
        // No travel: the sheet appears in place and cross-fades.
        if (target === 0) {
          y.set(0)
          sheetOpacity.set(0)
          return animate(sheetOpacity, 1, FADE)
        }
        return animate(sheetOpacity, 0, { ...FADE, onComplete: () => y.set(target) })
      }
      const spring = velocity === 0 ? SPRING_DEFAULT : SPRING_MOMENTUM
      return animate(y, target, { ...spring, velocity })
    },
    [reduceMotion, y, sheetOpacity],
  )

  // React to the open flag from any source (toggle button, Escape, route change).
  useEffect(() => {
    if (!height) return
    settle(open ? 0 : hiddenY)
  }, [open, height, hiddenY, settle])

  // The sheet accepts input the moment it starts appearing; it ignores input
  // only when fully hidden.
  useMotionValueEvent(y, 'change', (latest) => {
    setInteractive(height > 0 && latest > hiddenY + 0.5)
  })

  // Scrim dims as the sheet arrives; content de-blurs as the material lands.
  const progress = useTransform(y, [hiddenY, 0], [0, 1])
  const scrimOpacity = progress
  const contentFilter = useTransform(progress, (p) =>
    reduceMotion ? 'none' : `blur(${(1 - Math.min(1, Math.max(0, p))) * 6}px)`,
  )
  const contentOpacity = useTransform(progress, [0, 0.4, 1], [0, 0.6, 1])

  useEffect(() => {
    if (!open) return undefined
    const previous = document.body.style.overflow
    document.body.style.overflow = 'hidden'
    sheetRef.current?.focus({ preventScroll: true })
    return () => {
      document.body.style.overflow = previous
    }
  }, [open])

  const onDragEnd = (_event, info) => {
    const velocity = info.velocity.y
    const current = y.get()

    let shouldOpen
    if (Math.abs(velocity) > DECISIVE_VELOCITY) {
      // A committed flick: direction wins, regardless of position.
      shouldOpen = velocity > 0
    } else {
      // A gentle release: land where the momentum is heading.
      const projected = current + project(velocity)
      shouldOpen = projected > hiddenY / 2
    }

    if (shouldOpen !== open) {
      onOpenChange(shouldOpen)
    }
    // Hand the finger's velocity straight into the spring so there is no seam.
    settle(shouldOpen ? 0 : hiddenY, velocity)
  }

  return (
    <>
      <motion.div
        className="menu-scrim"
        style={{ opacity: scrimOpacity, pointerEvents: interactive ? 'auto' : 'none' }}
        onClick={() => onOpenChange(false)}
        aria-hidden="true"
      />
      <motion.div
        ref={sheetRef}
        className="menu-sheet material-thick"
        role="dialog"
        aria-modal="true"
        aria-label="Menü"
        tabIndex={-1}
        inert={!interactive ? true : undefined}
        style={{
          y,
          opacity: sheetOpacity,
          visibility: height ? 'visible' : 'hidden',
          pointerEvents: interactive ? 'auto' : 'none',
        }}
        drag={reduceMotion ? false : 'y'}
        dragConstraints={{ top: hiddenY, bottom: 0 }}
        // Free travel back toward the toolbar; rubber-band when pulled past rest.
        dragElastic={{ top: 0, bottom: 0.18 }}
        dragMomentum={false}
        onDragEnd={onDragEnd}
      >
        <motion.div
          className="menu-sheet-content"
          style={{ filter: contentFilter, opacity: contentOpacity }}
        >
          {children}
        </motion.div>
        <div className="menu-grabber" aria-hidden="true" />
      </motion.div>
    </>
  )
}
