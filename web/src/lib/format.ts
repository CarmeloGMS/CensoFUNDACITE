import type { Estado } from './types'

export const nf = new Intl.NumberFormat('es-VE')
export const fmtNum = (n: number | string | null | undefined, digits = 0) =>
  n === null || n === undefined || n === '' ? '—' : new Intl.NumberFormat('es-VE', { maximumFractionDigits: digits }).format(Number(n))

export const fmtFecha = (s: string | null | undefined, withTime = false) => {
  if (!s) return '—'
  const d = new Date(s.length === 10 ? `${s}T00:00:00` : s)
  return d.toLocaleDateString('es-VE', {
    day: '2-digit', month: 'short', year: 'numeric',
    ...(withTime ? { hour: '2-digit', minute: '2-digit' } : {}),
  })
}

export const fmtMes = (ym: string) => {
  const [y, m] = ym.split('-').map(Number)
  return new Date(y, m - 1, 1).toLocaleDateString('es-VE', { month: 'short', year: '2-digit' })
}

export const ESTADO_META: Record<Estado, { label: string; color: string; badge: string; dot: string }> = {
  validado: { label: 'Validado', color: '#059669', badge: 'bg-emerald-50 text-emerald-700 ring-emerald-600/20', dot: 'bg-emerald-500' },
  enviado: { label: 'Pendiente', color: '#d97706', badge: 'bg-amber-50 text-amber-700 ring-amber-600/20', dot: 'bg-amber-500' },
  rechazado: { label: 'Rechazado', color: '#e11d48', badge: 'bg-rose-50 text-rose-700 ring-rose-600/20', dot: 'bg-rose-500' },
}

export const ROL_LABEL: Record<string, string> = {
  administrador: 'Administrador',
  supervisor: 'Supervisor',
  encuestador: 'Encuestador',
}

export const initials = (name: string) =>
  name.split(/\s+/).filter(Boolean).slice(0, 2).map((p) => p[0]?.toUpperCase()).join('') || '?'
