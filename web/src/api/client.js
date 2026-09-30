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

async function postJson(path, body) {
  const base = getBaseUrl()
  const url = `${base}${path}`

  const response = await fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Accept: 'application/json',
    },
    body: JSON.stringify(body),
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

/**
 * POST /v1/auth/reset-password
 * Backend contract (confirmed): { token, password }
 */
export async function resetPassword({ token, password }) {
  return postJson('/v1/auth/reset-password', { token, password })
}

/**
 * POST /v1/auth/login
 * Returns { access_token, refresh_token, expires_in, user }
 */
export async function login({ email, password }) {
  return postJson('/v1/auth/login', { email, password })
}

/**
 * DELETE /v1/users/me
 * Requires a valid access token.
 */
export async function deleteAccount({ accessToken }) {
  const base = getBaseUrl()
  const url = `${base}/v1/users/me`

  const response = await fetch(url, {
    method: 'DELETE',
    headers: {
      Accept: 'application/json',
      Authorization: `Bearer ${accessToken}`,
    },
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
