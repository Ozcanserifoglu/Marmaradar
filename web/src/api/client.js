const DEFAULT_BASE = 'http://localhost:8081'

function getBaseUrl() {
  const fromEnv =
    typeof import.meta !== 'undefined' && import.meta.env
      ? import.meta.env.VITE_API_BASE_URL
      : undefined
  return (fromEnv && String(fromEnv).replace(/\/$/, '')) || DEFAULT_BASE
}

async function parseErrorMessage(response) {
  try {
    const data = await response.json()
    if (data && typeof data.error === 'string' && data.error.trim()) {
      return data.error
    }
  } catch {
    // ignore non-JSON error bodies
  }
  return 'Bir şeyler ters gitti, lütfen tekrar deneyin.'
}

/**
 * POST /v1/auth/reset-password
 * Backend contract (confirmed): { token, password }
 */
export async function resetPassword({ token, password }) {
  const base = getBaseUrl()
  // Confirmed against Go handler + KrakenD: POST /v1/auth/reset-password
  const url = `${base}/v1/auth/reset-password`

  const response = await fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Accept: 'application/json',
    },
    // Confirmed field names: token + password (not newPassword)
    body: JSON.stringify({ token, password }),
  })

  if (!response.ok) {
    const message = await parseErrorMessage(response)
    const error = new Error(message)
    error.status = response.status
    throw error
  }

  try {
    return await response.json()
  } catch {
    return { ok: true }
  }
}
