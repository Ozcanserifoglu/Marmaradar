/**
 * Spring presets and gesture physics.
 *
 * Apple describes springs with two designer-facing values: damping ratio
 * (overshoot) and response (speed, in seconds). Motion's `bounce` +
 * `duration` API maps onto them closely, so these presets are expressed
 * in Apple's terms and translated here once.
 */

/** Critically damped, response 0.4s. The house default for UI state changes. */
export const SPRING_DEFAULT = { type: 'spring', bounce: 0, duration: 0.4 }

/** Critically damped, response 0.3s. For small, frequent changes (toggles, chevrons). */
export const SPRING_SNAPPY = { type: 'spring', bounce: 0, duration: 0.3 }

/**
 * Slightly under-damped (damping ≈ 0.8), response 0.3s.
 * Only for motion that inherits the user's momentum: a flick, a throw, a
 * released drag. Overshoot on something that merely faded in feels wrong.
 */
export const SPRING_MOMENTUM = { type: 'spring', bounce: 0.2, duration: 0.3 }

/** Reduced-motion stand-in: a short cross-fade with no travel. */
export const FADE = { duration: 0.2, ease: 'easeOut' }

/**
 * Where a flick would come to rest under scroll-style deceleration.
 * `velocity` is px/s. 0.998 matches normal scroll feel; 0.99 is snappier.
 */
export function project(velocity, decelerationRate = 0.998) {
  return ((velocity / 1000) * decelerationRate) / (1 - decelerationRate)
}

/**
 * Progressive resistance past a boundary. The further past the edge the
 * pointer goes, the less the element follows.
 */
export function rubberband(overshoot, dimension, constant = 0.55) {
  return (overshoot * dimension * constant) / (dimension + constant * Math.abs(overshoot))
}

/** Index of the snap point closest to `value`. */
export function nearestSnapIndex(value, snapPoints) {
  let best = 0
  let bestDistance = Infinity
  for (let i = 0; i < snapPoints.length; i += 1) {
    const distance = Math.abs(snapPoints[i] - value)
    if (distance < bestDistance) {
      bestDistance = distance
      best = i
    }
  }
  return best
}

/** Clamp a number to [min, max]. */
export function clamp(value, min, max) {
  return Math.min(max, Math.max(min, value))
}

/**
 * Tracks recent pointer samples so release velocity reflects the last
 * ~100ms of movement rather than the final jittery event.
 */
export function createVelocityTracker(windowMs = 100) {
  let samples = []

  return {
    reset(position, time = performance.now()) {
      samples = [{ position, time }]
    },
    push(position, time = performance.now()) {
      samples.push({ position, time })
      const cutoff = time - windowMs
      while (samples.length > 2 && samples[0].time < cutoff) samples.shift()
    },
    /** px/s over the retained window; 0 if there is not enough data. */
    velocity() {
      if (samples.length < 2) return 0
      const first = samples[0]
      const last = samples[samples.length - 1]
      const dt = last.time - first.time
      if (dt <= 0) return 0
      return ((last.position - first.position) / dt) * 1000
    },
  }
}
