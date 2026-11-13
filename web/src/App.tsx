import { Navigate, Route, Routes } from 'react-router-dom'
import type { ReactNode } from 'react'
import { useAuth } from './lib/auth'
import { Layout } from './components/Layout'
import { Spinner } from './components/ui'
import Login from './pages/Login'
import Dashboard from './pages/Dashboard'
import Consejos from './pages/Consejos'
import ConsejoDetalle from './pages/ConsejoDetalle'
import Mapa from './pages/Mapa'
import Usuarios from './pages/Usuarios'

function Protegido({ children, admin }: { children: ReactNode; admin?: boolean }) {
  const { user, loading, esAdmin } = useAuth()
  if (loading) return <div className="grid h-full place-items-center"><Spinner className="size-8" /></div>
  if (!user) return <Navigate to="/login" replace />
  if (admin && !esAdmin) return <Navigate to="/" replace />
  return <>{children}</>
}

export default function App() {
  return (
    <Routes>
      <Route path="/login" element={<Login />} />
      <Route element={<Protegido><Layout /></Protegido>}>
        <Route index element={<Dashboard />} />
        <Route path="consejos" element={<Consejos />} />
        <Route path="consejos/:id" element={<ConsejoDetalle />} />
        <Route path="mapa" element={<Mapa />} />
        <Route path="usuarios" element={<Protegido admin><Usuarios /></Protegido>} />
      </Route>
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  )
}
