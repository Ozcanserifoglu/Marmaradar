import { useState } from 'react'
import { Link } from 'react-router-dom'
import { AlertCircle, CheckCircle2 } from 'lucide-react'
import Navbar from '../components/Navbar'
import GradientBlobs from '../components/GradientBlobs'
import { deleteAccount, login } from '../api/client'
import './DeleteAccount.css'

export default function DeleteAccount() {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [confirmText, setConfirmText] = useState('')
  const [fieldError, setFieldError] = useState('')
  const [status, setStatus] = useState('idle') // idle | loading | success | error
  const [apiError, setApiError] = useState('')

  async function handleSubmit(event) {
    event.preventDefault()
    setApiError('')

    if (!email.trim() || !password) {
      setFieldError('E-posta ve şifre gerekli.')
      return
    }
    if (confirmText.trim().toUpperCase() !== 'SIL') {
      setFieldError('Onaylamak için SIL yaz.')
      return
    }

    setFieldError('')
    setStatus('loading')

    try {
      const session = await login({
        email: email.trim(),
        password,
      })
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

  return (
    <div className="delete-page">
      <Navbar minimal />
      <div className="delete-body">
        <GradientBlobs subtle />
        <div className="container delete-container">
          <div className="delete-card">
            <h1>Hesabı Sil</h1>
            <p className="delete-lead">
              Hesabını ve sunucudaki ilişkili verilerini kalıcı olarak sil. Bu işlem geri
              alınamaz.
            </p>

            {status === 'success' ? (
              <div className="delete-success" role="status">
                <CheckCircle2 size={40} aria-hidden="true" />
                <h2>Hesabın silindi</h2>
                <p>
                  Verilerin kaldırıldı. Google veya Apple ile giriş yaptıysan uygulama içinden
                  de hesabını silebilirsin.
                </p>
                <Link className="btn btn-primary" to="/">
                  Ana Sayfaya Dön
                </Link>
              </div>
            ) : (
              <>
                <p className="delete-note">
                  E-posta ve şifre ile kayıt olduysan aşağıdaki formu kullan. Google veya Apple
                  ile giriş yaptıysan uygulamada Profil → Hesabı sil yolunu kullan.
                </p>

                <form className="delete-form" onSubmit={handleSubmit} noValidate>
                  <label className="field">
                    <span>E-posta</span>
                    <input
                      type="email"
                      name="email"
                      autoComplete="email"
                      value={email}
                      onChange={(e) => setEmail(e.target.value)}
                      disabled={status === 'loading'}
                      required
                    />
                  </label>

                  <label className="field">
                    <span>Şifre</span>
                    <input
                      type="password"
                      name="password"
                      autoComplete="current-password"
                      value={password}
                      onChange={(e) => setPassword(e.target.value)}
                      disabled={status === 'loading'}
                      required
                    />
                  </label>

                  <label className="field">
                    <span>
                      Onay — <strong>SIL</strong> yaz
                    </span>
                    <input
                      type="text"
                      name="confirm"
                      autoComplete="off"
                      value={confirmText}
                      onChange={(e) => setConfirmText(e.target.value)}
                      disabled={status === 'loading'}
                      placeholder="SIL"
                      required
                    />
                  </label>

                  {fieldError && (
                    <p className="field-error" role="alert">
                      {fieldError}
                    </p>
                  )}

                  {status === 'error' && apiError && (
                    <div className="delete-alert error" role="alert">
                      <AlertCircle size={18} aria-hidden="true" />
                      <p>{apiError}</p>
                    </div>
                  )}

                  <button
                    className="btn-danger delete-submit"
                    type="submit"
                    disabled={status === 'loading'}
                  >
                    {status === 'loading' ? 'Siliniyor...' : 'Hesabımı kalıcı olarak sil'}
                  </button>
                </form>
              </>
            )}
          </div>
        </div>
      </div>
    </div>
  )
}
