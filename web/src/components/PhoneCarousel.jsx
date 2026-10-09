import { useCallback, useLayoutEffect, useRef, useState } from 'react'
import { animate, motion, useMotionValue, useReducedMotion } from 'motion/react'
import {
  FADE,
  SPRING_DEFAULT,
  SPRING_MOMENTUM,
  clamp,
  createVelocityTracker,
  nearestSnapIndex,
  project,
  rubberband,
} from '../motion/springs'
import './PhoneCarousel.css'

/** Movement needed before we commit to a horizontal drag. */
const HYSTERESIS = 10
/** Below this release speed we treat the gesture as a placement, not a flick. */
const FLICK_VELOCITY = 120

// Capture keeps tracking when the pointer leaves the element. Browsers throw
// for pointers that have already gone away; losing capture is not fatal.
function capturePointer(el, pointerId) {
  try {
    el.setPointerCapture(pointerId)
  } catch {
    /* pointer already released */
  }
}

function releasePointer(el, pointerId) {
  try {
    if (el.hasPointerCapture(pointerId)) el.releasePointerCapture(pointerId)
  } catch {
    /* pointer already released */
  }
}

/**
 * Swipeable screenshots inside a phone frame.
 *
 * The track follows the pointer 1:1 from wherever it was grabbed, resists at
 * both ends, and on release springs to the page the momentum is heading for,
 * carrying the finger's velocity into the spring.
 */
export default function PhoneCarousel({ slides, ariaLabel = 'Uygulama ekran görüntüleri' }) {
  const viewportRef = useRef(null)
  const [width, setWidth] = useState(0)
  const [index, setIndex] = useState(0)
  const x = useMotionValue(0)
  const reduceMotion = useReducedMotion()

  const indexRef = useRef(0)
  const gesture = useRef(null)
  const tracker = useRef(createVelocityTracker())

  const count = slides.length
  const minX = -(count - 1) * width

  useLayoutEffect(() => {
    indexRef.current = index
  }, [index])

  useLayoutEffect(() => {
    const el = viewportRef.current
    if (!el) return undefined
    const measure = () => {
      const next = el.clientWidth
      setWidth(next)
      // Keep the current page in place when the layout changes.
      x.set(-indexRef.current * next)
    }
    measure()
    const observer = new ResizeObserver(measure)
    observer.observe(el)
    return () => observer.disconnect()
  }, [x])

  const settleTo = useCallback(
    (nextIndex, velocity = 0) => {
      const target = -nextIndex * width
      setIndex(nextIndex)
      if (reduceMotion) {
        x.set(target)
        return
      }
      const spring = Math.abs(velocity) > FLICK_VELOCITY ? SPRING_MOMENTUM : SPRING_DEFAULT
      animate(x, target, { ...spring, velocity })
    },
    [reduceMotion, width, x],
  )

  const onPointerDown = (e) => {
    if (reduceMotion || !width) return
    if (e.pointerType === 'mouse' && e.button !== 0) return
    // Grabbing a moving track picks it up where it is.
    x.stop()
    gesture.current = {
      pointerId: e.pointerId,
      startClientX: e.clientX,
      startClientY: e.clientY,
      startX: x.get(),
      committed: false,
    }
    tracker.current.reset(e.clientX)
  }

  const onPointerMove = (e) => {
    const g = gesture.current
    if (!g || g.pointerId !== e.pointerId) return

    const dx = e.clientX - g.startClientX
    const dy = e.clientY - g.startClientY

    if (!g.committed) {
      if (Math.abs(dx) < HYSTERESIS && Math.abs(dy) < HYSTERESIS) return
      if (Math.abs(dy) > Math.abs(dx)) {
        // Vertical intent: hand the gesture back to the page.
        gesture.current = null
        return
      }
      g.committed = true
      capturePointer(e.currentTarget, e.pointerId)
      // Re-anchor so the track does not jump by the hysteresis distance.
      g.startClientX = e.clientX
      g.startX = x.get()
      tracker.current.reset(e.clientX)
    }

    tracker.current.push(e.clientX)
    let next = g.startX + (e.clientX - g.startClientX)
    if (next > 0) next = rubberband(next, width)
    else if (next < minX) next = minX + rubberband(next - minX, width)
    x.set(next)
  }

  const endGesture = (e) => {
    const g = gesture.current
    if (!g || g.pointerId !== e.pointerId) return
    gesture.current = null
    if (!g.committed) return

    releasePointer(e.currentTarget, e.pointerId)

    const velocity = tracker.current.velocity()
    const current = x.get()
    // Land where the throw is heading, one page at a time.
    const projected = current + project(velocity, 0.99)
    const snapPoints = slides.map((_, i) => -i * width)
    const projectedIndex = nearestSnapIndex(projected, snapPoints)
    const nextIndex = clamp(projectedIndex, index - 1, index + 1)
    settleTo(clamp(nextIndex, 0, count - 1), velocity)
  }

  const onKeyDown = (e) => {
    if (e.key === 'ArrowRight') {
      e.preventDefault()
      settleTo(Math.min(count - 1, index + 1))
    } else if (e.key === 'ArrowLeft') {
      e.preventDefault()
      settleTo(Math.max(0, index - 1))
    }
  }

  return (
    <div className="carousel">
      <div className="phone">
        <div
          ref={viewportRef}
          className={`phone-screen${reduceMotion ? ' is-static' : ''}`}
          role="group"
          aria-roledescription="carousel"
          aria-label={ariaLabel}
          tabIndex={0}
          onKeyDown={onKeyDown}
          onPointerDown={onPointerDown}
          onPointerMove={onPointerMove}
          onPointerUp={endGesture}
          onPointerCancel={endGesture}
        >
          {reduceMotion ? (
            slides.map((slide, i) => (
              <motion.img
                key={slide.src}
                className="carousel-slide carousel-slide-stacked"
                src={slide.src}
                alt={slide.alt}
                width={472}
                height={1024}
                draggable={false}
                loading={i === 0 ? 'eager' : 'lazy'}
                decoding="async"
                initial={false}
                animate={{ opacity: i === index ? 1 : 0 }}
                transition={FADE}
                aria-hidden={i !== index}
              />
            ))
          ) : (
            <motion.div className="carousel-track" style={{ x }}>
              {slides.map((slide, i) => (
                <img
                  key={slide.src}
                  className="carousel-slide"
                  src={slide.src}
                  alt={slide.alt}
                  width={472}
                  height={1024}
                  draggable={false}
                  loading={i === 0 ? 'eager' : 'lazy'}
                  decoding="async"
                  aria-hidden={i !== index}
                />
              ))}
            </motion.div>
          )}
        </div>
      </div>

      <div className="carousel-controls">
        <div className="carousel-dots" role="tablist" aria-label="Ekranlar">
          {slides.map((slide, i) => (
            <button
              key={slide.src}
              type="button"
              role="tab"
              className={`carousel-dot${i === index ? ' is-active' : ''}`}
              aria-selected={i === index}
              aria-label={slide.label}
              onClick={() => settleTo(i)}
            >
              <span />
            </button>
          ))}
        </div>
        <p className="carousel-caption t-footnote" aria-live="polite">
          {slides[index]?.label}
        </p>
      </div>
    </div>
  )
}
