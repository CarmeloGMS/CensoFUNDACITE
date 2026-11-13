import { createContext, useCallback, useContext, useEffect, useState, type ReactNode } from 'react'
import { useQueryClient } from '@tanstack/react-query'
import { api, tokens } from './api'
import type { Usuario } from './types'

interface AuthCtx {
  user: Usuario | null
  loading: boolean
  login: (username: string, password: string) => Promise<void>
  logout: () => void
  puedeValidar: boolean
  esAdmin: boolean
}

const Ctx = createContext<AuthCtx | null>(null)

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<Usuario | null>(null)
  const [loading, setLoading] = useState(!!tokens.access)
  const qc = useQueryClient()

  const logout = useCallback(() => {
    tokens.clear()
    setUser(null)
    qc.clear()
  }, [qc])

  useEffect(() => {
    if (!tokens.access) return
    api<Usuario>('/api/auth/me/')
      .then(setUser)
      .catch(() => tokens.clear())
      .finally(() => setLoading(false))
  }, [])

  useEffect(() => {
    const h = () => setUser(null)
    window.addEventListener('censo:logout', h)
    return () => window.removeEventListener('censo:logout', h)
  }, [])

  const login = useCallback(async (username: string, password: string) => {
    const t = await api<{ access: string; refresh: string }>('/api/auth/token/', {
      method: 'POST',
      body: JSON.stringify({ username, password }),
    })
    tokens.set(t.access, t.refresh)
    setUser(await api<Usuario>('/api/auth/me/'))
  }, [])

  const rol = user?.rol
  return (
    <Ctx.Provider value={{
      user, loading, login, logout,
      puedeValidar: rol === 'administrador' || rol === 'supervisor',
      esAdmin: rol === 'administrador',
    }}>
      {children}
    </Ctx.Provider>
  )
}

export function useAuth() {
  const c = useContext(Ctx)
  if (!c) throw new Error('useAuth fuera de AuthProvider')
  return c
}
