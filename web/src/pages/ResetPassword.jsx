import { useMemo, useState } from 'react'
import { Link, useSearchParams } from 'react-router-dom'
import { CheckCircle2, AlertCircle } from 'lucide-react'
import Navbar from '../components/Navbar'
import GradientBlobs from '../components/GradientBlobs'
import { resetPassword } from '../api/client'
import './ResetPassword.css'

const MIN_PASSWORD_LENGTH = 8

export default function ResetPassword() {
  const [searchParams] = useSearchParams()
  const token = useMemo(() => searchParams.get('token')?.trim() || '', [searchParams])

  const [password, setPassword] = useState('')
  const [confirm, setConfirm] = useState('')
  const [fieldError, setFieldError] = useState('')
  const [status, setStatus] = useState('idle') // idle | loading | success | error
  const [apiError, setApiError] = useState('')

  const missingToken = !token

  function validate() {
    if (password.length < MIN_PASSWORD_LENGTH) {
      return `Şifre en az ${MIN_PASSWORD_LENGTH} karakter olmalı.`
    }
    if (password !== confirm) {
      return 'Şifreler eşleşmiyor.'
    }
    return ''
  }

  async function handleSubmit(event) {
    event.preventDefault()
    setApiError('')

    const validationError = validate()
    if (validationError) {
      setFieldError(validationError)
      return
    }

    setFieldError('')
    setStatus('loading')

    try {
      await resetPassword({ token, password })
      setStatus('success')
    } catch (err) {
      setStatus('error')
      setApiError(err?.message || 'Bir şeyler ters gitti, lütfen tekrar deneyin.')
    }
  }

  return (
    <div className="reset-page">
      <Navbar minimal />
      <div className="reset-body">
        <GradientBlobs subtle />
        <div className="container reset-container">
          <div className="reset-card">
            <h1>Şifreyi Sıfırla</h1>
            <p className="reset-lead">
              Hesabın için yeni bir şifre belirle. Bağlantı tek kullanımlıktır.
            </p>

            {missingToken && (
              <div className="reset-alert error" role="alert">
                <AlertCircle size={20} aria-hidden="true" />
                <div>
                  <strong>Geçersiz veya eksik bağlantı</strong>
                  <p>E-postadaki bağlantıyı tekrar açmayı deneyin.</p>
                </div>
              </div>
            )}

            {!missingToken && status === 'success' && (
              <div className="reset-success" role="status">
                <CheckCircle2 size={40} aria-hidden="true" />
                <h2>Şifren güncellendi</h2>
                <p>Yeni şifrenle uygulamaya giriş yapabilirsin.</p>
                <Link className="btn btn-primary" to="/">
                  Ana Sayfaya Dön
                </Link>
              </div>
            )}

            {!missingToken && status !== 'success' && (
              <form className="reset-form" onSubmit={handleSubmit} noValidate>
                <label className="field">
                  <span>Yeni Şifre</span>
                  <input
                    type="password"
                    name="password"
                    autoComplete="new-password"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    disabled={status === 'loading'}
                    minLength={MIN_PASSWORD_LENGTH}
                    required
                  />
                </label>

                <label className="field">
                  <span>Yeni Şifre (Tekrar)</span>
                  <input
                    type="password"
                    name="confirm"
                    autoComplete="new-password"
                    value={confirm}
                    onChange={(e) => setConfirm(e.target.value)}
                    disabled={status === 'loading'}
                    minLength={MIN_PASSWORD_LENGTH}
                    required
                  />
                </label>

                {fieldError && (
                  <p className="field-error" role="alert">
                    {fieldError}
                  </p>
                )}

                {status === 'error' && apiError && (
                  <div className="reset-alert error" role="alert">
                    <AlertCircle size={18} aria-hidden="true" />
                    <p>{apiError}</p>
                  </div>
                )}

                <button
                  className="btn btn-primary reset-submit"
                  type="submit"
                  disabled={status === 'loading'}
                >
                  {status === 'loading' ? 'Gönderiliyor...' : 'Şifreyi Güncelle'}
                </button>
              </form>
            )}
          </div>
        </div>
      </div>
    </div>
  )
}
