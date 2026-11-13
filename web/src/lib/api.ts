const BASE = import.meta.env.VITE_API_URL ?? ''

const ACCESS = 'censo.access'
const REFRESH = 'censo.refresh'

export class ApiError extends Error {
  status: number
  data: unknown
  constructor(status: number, data: unknown, message: string) {
    super(message)
    this.status = status
    this.data = data
  }
}

export const tokens = {
  get access() { return localStorage.getItem(ACCESS) },
  get refresh() { return localStorage.getItem(REFRESH) },
  set(access: string, refresh?: string) {
    localStorage.setItem(ACCESS, access)
    if (refresh) localStorage.setItem(REFRESH, refresh)
  },
  clear() {
    localStorage.removeItem(ACCESS)
    localStorage.removeItem(REFRESH)
  },
}

let refreshing: Promise<boolean> | null = null

async function tryRefresh(): Promise<boolean> {
  const refresh = tokens.refresh
  if (!refresh) return false
  refreshing ??= fetch(`${BASE}/api/auth/token/refresh/`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ refresh }),
  })
    .then(async (r) => {
      if (!r.ok) return false
      const data = await r.json()
      tokens.set(data.access, data.refresh)
      return true
    })
    .catch(() => false)
    .finally(() => { refreshing = null })
  return refreshing
}

function errorMessage(data: unknown, fallback: string): string {
  if (!data || typeof data !== 'object') return fallback
  const d = data as Record<string, unknown>
  if (typeof d.detail === 'string') return d.detail
  const first = Object.entries(d)[0]
  if (first) {
    const [k, v] = first
    const msg = Array.isArray(v) ? v.join(' ') : String(v)
    return k === 'non_field_errors' ? msg : `${k}: ${msg}`
  }
  return fallback
}

export async function request(path: string, init: RequestInit = {}, retry = true): Promise<Response> {
  const headers = new Headers(init.headers)
  if (tokens.access) headers.set('Authorization', `Bearer ${tokens.access}`)
  if (init.body && !(init.body instanceof FormData) && !headers.has('Content-Type')) {
    headers.set('Content-Type', 'application/json')
  }
  const res = await fetch(`${BASE}${path}`, { ...init, headers })
  if (res.status === 401 && retry && tokens.refresh) {
    if (await tryRefresh()) return request(path, init, false)
    tokens.clear()
    window.dispatchEvent(new Event('censo:logout'))
  }
  if (!res.ok) {
    let data: unknown = null
    try { data = await res.json() } catch { /* sin cuerpo */ }
    throw new ApiError(res.status, data, errorMessage(data, `Error ${res.status}`))
  }
  return res
}

export async function api<T>(path: string, init: RequestInit = {}): Promise<T> {
  const res = await request(path, init)
  if (res.status === 204) return undefined as T
  return res.json() as Promise<T>
}

export function qs(params: object): string {
  const sp = new URLSearchParams()
  for (const [k, v] of Object.entries(params)) {
    if (v !== undefined && v !== null && v !== '') sp.set(k, String(v))
  }
  const s = sp.toString()
  return s ? `?${s}` : ''
}

export async function downloadFile(path: string, filename: string) {
  const res = await request(path)
  const blob = await res.blob()
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = filename
  a.click()
  URL.revokeObjectURL(url)
}
