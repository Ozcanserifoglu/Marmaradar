import { useState } from 'react'
import { Link } from 'react-router-dom'
import { AnimatePresence, motion, useReducedMotion } from 'motion/react'
import { AlertCircle, CheckCircle2 } from 'lucide-react'
import Navbar from '../components/Navbar'
import { deleteAccount, login } from '../api/client'
import { FADE, SPRING_DEFAULT } from '../motion/springs'
import '../styles/forms.css'

const CONFIRM_WORD = 'SIL'

export default function DeleteAccount() {
  const reduceMotion = useReducedMotion()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [confirmText, setConfirmText] = useState('')
  const [touched, setTouched] = useState({ email: false, password: false, confirm: false })
  const [status, setStatus] = useState('idle') // idle | loading | success | error
  const [apiError, setApiError] = useState('')

  const loading = status === 'loading'

  const emailError = email.trim() === '' ? 'E-posta gerekli.' : ''
  const passwordError = password === '' ? 'Şifre gerekli.' : ''
  const confirmError =
    confirmText.length > 0 && confirmText.trim().toUpperCase() !== CONFIRM_WORD
      ? `Onaylamak için ${CONFIRM_WORD} yaz.`
      : ''
  const confirmValid = confirmText.trim().toUpperCase() === CONFIRM_WORD
  const canSubmit = !emailError && !passwordError && confirmValid && !loading

  async function handleSubmit(event) {
    event.preventDefault()
    setApiError('')
    setTouched({ email: true, password: true, confirm: true })
    if (!canSubmit) return

    setStatus('loading')
    try {
      const session = await login({ email: email.trim(), password })
      const accessToken = session?.access_token
      if (!accessToken) {
        throw new Error('Giriş başarısız, lütfen tekrar deneyin.')
      }
      await deleteAccount({ accessToken })
      setStatus('success')
      setPassword('')
      setConfirmText('')
    } catch (err) {
      setStatus('error')
      const message = err?.message || 'Bir şeyler ters gitti, lütfen tekrar deneyin.'
      if (err?.status === 401 || /invalid email or password/i.test(message)) {
        setApiError('E-posta veya şifre hatalı.')
      } else {
        setApiError(message)
      }
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
            <h1 className="t-title2">Hesabı Sil</h1>
            <p className="form-lead">
              Hesabını ve sunucudaki ilişkili verilerini kalıcı olarak sil. Bu işlem geri
              alınamaz.
            </p>

            <AnimatePresence mode="wait" initial={false}>
              {status === 'success' ? (
                <motion.div key="success" className="form-success" role="status" {...swap}>
                  <span className="form-success-icon">
                    <CheckCircle2 size={30} aria-hidden="true" />
                  </span>
                  <h2 className="t-title3">Hesabın silindi</h2>
                  <p>
                    Verilerin kaldırıldı. Google veya Apple ile giriş yaptıysan uygulama içinden
                    de hesabını silebilirsin.
                  </p>
                  <Link className="btn btn-primary" to="/">
                    Ana Sayfaya Dön
                  </Link>
                </motion.div>
              ) : (
                <motion.div key="form" {...swap}>
                  <p className="form-note">
                    E-posta ve şifre ile kayıt olduysan aşağıdaki formu kullan. Google veya Apple
                    ile giriş yaptıysan uygulamada Profil → Hesabı sil yolunu kullan.
                  </p>

                  <form className="form" onSubmit={handleSubmit} noValidate aria-busy={loading}>
                    <label className="field">
                      <span className="field-label">E-posta</span>
                      <input
                        type="email"
                        name="email"
                        autoComplete="email"
                        value={email}
                        onChange={(e) => setEmail(e.target.value)}
                        onBlur={() => setTouched((t) => ({ ...t, email: true }))}
                        disabled={loading}
                        aria-invalid={touched.email && emailError ? true : undefined}
                        required
                      />
                      {touched.email && emailError ? (
                        <span className="field-error" role="alert">
                          <AlertCircle size={14} aria-hidden="true" />
                          {emailError}
                        </span>
                      ) : null}
                    </label>

                    <label className="field">
                      <span className="field-label">Şifre</span>
                      <input
                        type="password"
                        name="password"
                        autoComplete="current-password"
                        value={password}
                        onChange={(e) => setPassword(e.target.value)}
                        onBlur={() => setTouched((t) => ({ ...t, password: true }))}
                        disabled={loading}
                        aria-invalid={touched.password && passwordError ? true : undefined}
                        required
                      />
                      {touched.password && passwordError ? (
                        <span className="field-error" role="alert">
                          <AlertCircle size={14} aria-hidden="true" />
                          {passwordError}
                        </span>
                      ) : null}
                    </label>

                    <label className="field">
                      <span className="field-label">
                        Onay — <strong>{CONFIRM_WORD}</strong> yaz
                      </span>
                      <input
                        type="text"
                        name="confirm"
                        autoComplete="off"
                        autoCapitalize="characters"
                        value={confirmText}
                        onChange={(e) => setConfirmText(e.target.value)}
                        onBlur={() => setTouched((t) => ({ ...t, confirm: true }))}
                        disabled={loading}
                        placeholder={CONFIRM_WORD}
                        aria-invalid={touched.confirm && confirmError ? true : undefined}
                        required
                      />
                      {touched.confirm && confirmError ? (
                        <span className="field-error" role="alert">
                          <AlertCircle size={14} aria-hidden="true" />
                          {confirmError}
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
                      className="btn btn-destructive btn-block form-submit"
                      type="submit"
                      disabled={!canSubmit}
                    >
                      {loading ? 'Siliniyor…' : 'Hesabımı kalıcı olarak sil'}
                    </button>
                  </form>
                </motion.div>
              )}
            </AnimatePresence>
          </motion.div>
        </div>
      </div>
    </div>
  )
}
