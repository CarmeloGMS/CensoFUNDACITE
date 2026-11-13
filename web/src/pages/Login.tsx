import { useState, type FormEvent } from 'react'
import { Navigate } from 'react-router-dom'
import { Lock, MapPin, ShieldCheck, User, WifiOff } from 'lucide-react'
import { useAuth } from '../lib/auth'
import { Button, Input, Label } from '../components/ui'
import { Logo } from '../components/Layout'

export default function Login() {
  const { user, login } = useAuth()
  const [username, setUsername] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)

  if (user) return <Navigate to="/" replace />

  const submit = async (e: FormEvent) => {
    e.preventDefault()
    setError('')
    setLoading(true)
    try {
      await login(username, password)
    } catch {
      setError('Usuario o contraseña incorrectos.')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="grid min-h-full lg:grid-cols-2">
      <div className="relative hidden overflow-hidden bg-brand-950 lg:block">
        <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_20%_10%,rgba(52,211,153,0.35),transparent_55%),radial-gradient(ellipse_at_90%_90%,rgba(251,191,36,0.22),transparent_50%)]" />
        <svg className="absolute inset-x-0 bottom-0 w-full text-brand-900/70" viewBox="0 0 800 300" preserveAspectRatio="none">
          <path fill="currentColor" d="M0 220 C120 140 220 200 330 150 C440 100 520 170 620 120 C700 85 760 110 800 95 L800 300 L0 300Z" />
          <path fill="#022c22" opacity=".8" d="M0 260 C140 210 260 250 380 215 C500 180 600 235 800 190 L800 300 L0 300Z" />
        </svg>
        <div className="relative flex h-full flex-col justify-between p-12">
          <Logo light />
          <div className="max-w-md">
            <h1 className="text-4xl leading-tight font-semibold tracking-tight text-white">
              Registro y georreferenciación de los consejos campesinos
            </h1>
            <p className="mt-4 text-brand-100/80">
              Información de campo de cada organización productiva del estado La Guaira, en un solo lugar.
            </p>
            <div className="mt-10 grid gap-4">
              {[
                { icon: MapPin, t: 'Ubicación GPS de cada consejo' },
                { icon: WifiOff, t: 'Captura sin conexión desde la app móvil' },
                { icon: ShieldCheck, t: 'Validación por supervisores' },
              ].map(({ icon: Icon, t }) => (
                <div key={t} className="flex items-center gap-3 text-sm text-brand-50">
                  <div className="grid size-9 place-items-center rounded-xl bg-white/10 ring-1 ring-white/15"><Icon className="size-4" /></div>
                  {t}
                </div>
              ))}
            </div>
          </div>
          <p className="text-xs text-brand-200/50">© {new Date().getFullYear()} · Censo de Consejos Campesinos</p>
        </div>
      </div>

      <div className="flex items-center justify-center p-6 sm:p-12">
        <div className="w-full max-w-sm">
          <div className="mb-10 lg:hidden"><Logo /></div>
          <h2 className="text-2xl font-semibold tracking-tight text-stone-900">Bienvenido</h2>
          <p className="mt-1 text-sm text-stone-500">Ingresa con tu usuario institucional.</p>
          <form onSubmit={submit} className="mt-8 space-y-5">
            <div>
              <Label htmlFor="u">Usuario</Label>
              <div className="relative">
                <User className="pointer-events-none absolute top-1/2 left-3 size-4 -translate-y-1/2 text-stone-400" />
                <Input id="u" className="py-2.5 pl-9" value={username} onChange={(e) => setUsername(e.target.value)} autoComplete="username" required autoFocus />
              </div>
            </div>
            <div>
              <Label htmlFor="p">Contraseña</Label>
              <div className="relative">
                <Lock className="pointer-events-none absolute top-1/2 left-3 size-4 -translate-y-1/2 text-stone-400" />
                <Input id="p" type="password" className="py-2.5 pl-9" value={password} onChange={(e) => setPassword(e.target.value)} autoComplete="current-password" required />
              </div>
            </div>
            {error && <p className="rounded-xl bg-rose-50 px-3 py-2 text-sm text-rose-700 ring-1 ring-rose-200">{error}</p>}
            <Button type="submit" loading={loading} className="w-full py-2.5">Iniciar sesión</Button>
          </form>
        </div>
      </div>
    </div>
  )
}
