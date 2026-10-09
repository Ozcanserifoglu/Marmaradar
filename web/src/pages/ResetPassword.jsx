import { useMemo, useState } from 'react'
import { Link, useSearchParams } from 'react-router-dom'
import { AnimatePresence, motion, useReducedMotion } from 'motion/react'
import { CheckCircle2, AlertCircle, Check } from 'lucide-react'
import Navbar from '../components/Navbar'
import { resetPassword } from '../api/client'
import { FADE, SPRING_DEFAULT } from '../motion/springs'
import '../styles/forms.css'

const MIN_PASSWORD_LENGTH = 8

export default function ResetPassword() {
  const [searchParams] = useSearchParams()
  const token = useMemo(() => searchParams.get('token')?.trim() || '', [searchParams])
  const reduceMotion = useReducedMotion()

  const [password, setPassword] = useState('')
  const [confirm, setConfirm] = useState('')
  const [touched, setTouched] = useState({ password: false, confirm: false })
  const [status, setStatus] = useState('idle') // idle | loading | success | error
  const [apiError, setApiError] = useState('')

  const missingToken = !token
  const loading = status === 'loading'

  // Validate as the user types; show the message only once a field has been visited.
  const passwordError =
    password.length > 0 && password.length < MIN_PASSWORD_LENGTH
      ? `En az ${MIN_PASSWORD_LENGTH} karakter olmalı.`
      : ''
  const confirmError = confirm.length > 0 && confirm !== password ? 'Şifreler eşleşmiyor.' : ''
  const passwordValid = password.length >= MIN_PASSWORD_LENGTH
  const confirmValid = passwordValid && confirm === password
  const canSubmit = passwordValid && confirmValid && !loading

  async function handleSubmit(event) {
    event.preventDefault()
    setApiError('')
    setTouched({ password: true, confirm: true })
    if (!passwordValid || !confirmValid) return

    setStatus('loading')
    try {
      await resetPassword({ token, password })
      setStatus('success')
    } catch (err) {
      setStatus('error')
      setApiError(err?.message || 'Bir şeyler ters gitti, lütfen tekrar deneyin.')
    }
  }

  const swap = reduceMotion
    ? { initial: { opacity: 0 }, animate: { opacity: 1 }, exit: { opacity: 0 }, transition: FADE }
    : {
        initial: { opacity: 0, y: 12 },
        animate: { opacity: 1, y: 0 },
        exit: { opacity: 0, y: -8 },
        transition: SPRING_DEFAULT,
      }

  return (
    <div className="form-page">
      <Navbar minimal />
      <div className="form-body">
        <div className="ambient ambient-subtle" aria-hidden="true" />
        <div className="container form-container">
          <motion.div
            className="form-card"
            initial={{ opacity: 0, y: reduceMotion ? 0 : 16 }}
            animate={{ opacity: 1, y: 0 }}
            transition={reduceMotion ? FADE : SPRING_DEFAULT}
          >
            <h1 className="t-title2">Şifreyi Sıfırla</h1>
            <p className="form-lead">
              Hesabın için yeni bir şifre belirle. Bağlantı tek kullanımlıktır.
            </p>

            <AnimatePresence mode="wait" initial={false}>
              {missingToken ? (
                <motion.div key="missing" className="form-alert" role="alert" {...swap}>
                  <AlertCircle size={20} aria-hidden="true" />
                  <div>
                    <strong>Geçersiz veya eksik bağlantı</strong>
                    <p>E-postadaki bağlantıyı tekrar açmayı deneyin.</p>
                  </div>
                </motion.div>
              ) : status === 'success' ? (
                <motion.div key="success" className="form-success" role="status" {...swap}>
                  <span className="form-success-icon">
                    <CheckCircle2 size={30} aria-hidden="true" />
                  </span>
                  <h2 className="t-title3">Şifren güncellendi</h2>
                  <p>Yeni şifrenle uygulamaya giriş yapabilirsin.</p>
                  <Link className="btn btn-primary" to="/">
                    Ana Sayfaya Dön
                  </Link>
                </motion.div>
              ) : (
                <motion.form
                  key="form"
                  className="form"
                  onSubmit={handleSubmit}
                  noValidate
                  aria-busy={loading}
                  {...swap}
                >
                  <label className="field">
                    <span className="field-label">Yeni Şifre</span>
                    <input
                      type="password"
                      name="password"
                      autoComplete="new-password"
                      value={password}
                      onChange={(e) => setPassword(e.target.value)}
                      onBlur={() => setTouched((t) => ({ ...t, password: true }))}
                      disabled={loading}
                      minLength={MIN_PASSWORD_LENGTH}
                      aria-invalid={touched.password && passwordError ? true : undefined}
                      aria-describedby="password-hint"
                      required
                    />
                    {touched.password && passwordError ? (
                      <span className="field-error" id="password-hint" role="alert">
                        <AlertCircle size={14} aria-hidden="true" />
                        {passwordError}
                      </span>
                    ) : (
                      <span className="field-hint" id="password-hint">
                        En az {MIN_PASSWORD_LENGTH} karakter.
                      </span>
                    )}
                  </label>

                  <label className="field">
                    <span className="field-label">Yeni Şifre (Tekrar)</span>
                    <input
                      type="password"
                      name="confirm"
                      autoComplete="new-password"
                      value={confirm}
                      onChange={(e) => setConfirm(e.target.value)}
                      onBlur={() => setTouched((t) => ({ ...t, confirm: true }))}
                      disabled={loading}
                      minLength={MIN_PASSWORD_LENGTH}
                      aria-invalid={touched.confirm && confirmError ? true : undefined}
                      aria-describedby="confirm-hint"
                      required
                    />
                    {touched.confirm && confirmError ? (
                      <span className="field-error" id="confirm-hint" role="alert">
                        <AlertCircle size={14} aria-hidden="true" />
                        {confirmError}
                      </span>
                    ) : confirmValid ? (
                      <span className="field-ok" id="confirm-hint">
                        <Check size={14} aria-hidden="true" />
                        Şifreler eşleşiyor.
                      </span>
                    ) : null}
                  </label>

                  {status === 'error' && apiError ? (
                    <div className="form-alert" role="alert">
                      <AlertCircle size={18} aria-hidden="true" />
                      <p>{apiError}</p>
                    </div>
                  ) : null}

                  <button
                    className="btn btn-primary btn-block form-submit"
                    type="submit"
                    disabled={!canSubmit}
                  >
                    {loading ? 'Gönderiliyor…' : 'Şifreyi Güncelle'}
                  </button>
                </motion.form>
              )}
            </AnimatePresence>
          </motion.div>
        </div>
      </div>
    </div>
  )
}
