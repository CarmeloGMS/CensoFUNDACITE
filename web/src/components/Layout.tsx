import { NavLink, Outlet, useLocation } from 'react-router-dom'
import { ClipboardPlus, LayoutDashboard, ListChecks, LogOut, Map, Menu, Sprout, Users, X } from 'lucide-react'
import { useState } from 'react'
import clsx from 'clsx'
import { useAuth } from '../lib/auth'
import { ROL_LABEL } from '../lib/format'
import { Avatar } from './ui'

export function Logo({ light = false }: { light?: boolean }) {
  return (
    <div className="flex items-center gap-3">
      <div className="grid size-10 place-items-center rounded-xl bg-gradient-to-br from-brand-400 to-brand-700 shadow-lg shadow-brand-900/30">
        <Sprout className="size-5.5 text-white" />
      </div>
      <div className="leading-tight">
        <p className={clsx('text-sm font-semibold', light ? 'text-white' : 'text-stone-900')}>Censo Campesino</p>
        <p className={clsx('text-[11px]', light ? 'text-brand-200/80' : 'text-stone-500')}>Estado La Guaira</p>
      </div>
    </div>
  )
}

export function Layout() {
  const { user, logout, esAdmin } = useAuth()
  const [open, setOpen] = useState(false)
  const loc = useLocation()
  const nav = [
    { to: '/', label: 'Panel general', icon: LayoutDashboard, end: true },
    { to: '/consejos', label: 'Registros', icon: ListChecks, end: true },
    { to: '/mapa', label: 'Mapa', icon: Map },
    ...(esAdmin ? [{ to: '/usuarios', label: 'Usuarios', icon: Users }] : []),
  ]
  const nombre = user ? [user.first_name, user.last_name].filter(Boolean).join(' ') || user.username : ''

  const sidebar = (
    <div className="flex h-full flex-col bg-brand-950 bg-[radial-gradient(ellipse_at_top_left,rgba(16,185,129,0.18),transparent_60%)] px-4 py-6">
      <div className="px-2"><Logo light /></div>
      <nav className="mt-10 flex flex-1 flex-col gap-1">
        <NavLink to="/consejos/nuevo" onClick={() => setOpen(false)}
          className="mb-5 flex items-center justify-center gap-2 rounded-xl bg-gradient-to-r from-brand-400 to-brand-600 px-3 py-2.5 text-sm font-semibold text-white shadow-lg shadow-brand-950/40 ring-1 ring-white/20 transition hover:brightness-110">
          <ClipboardPlus className="size-4.5" />
          Nuevo registro
        </NavLink>
        <p className="px-3 pb-2 text-[10px] font-semibold tracking-widest text-brand-300/50 uppercase">Menú</p>
        {nav.map(({ to, label, icon: Icon, end }) => (
          <NavLink key={to} to={to} end={end} onClick={() => setOpen(false)}
            className={({ isActive }) => clsx(
              'group flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-medium transition-all',
              isActive ? 'bg-white/10 text-white shadow-inner ring-1 ring-white/10' : 'text-brand-100/70 hover:bg-white/5 hover:text-white',
            )}>
            <Icon className="size-4.5" />
            {label}
          </NavLink>
        ))}
      </nav>
      <p className="px-2 pb-3 text-[10px] leading-relaxed text-brand-300/50">
        © 2026 · Censo de Consejos Campesinos por Fundacite La Guaira ·
        Gimnasio Vertical de La Guaira, Piso 1
        <br />
        Desarrollado por Carmelo Marcano · Programador y desarrollador de
        software
      </p>
      <div className="rounded-2xl bg-white/5 p-3 ring-1 ring-white/10">
        <div className="flex items-center gap-3">
          <Avatar name={nombre} />
          <div className="min-w-0 flex-1">
            <p className="truncate text-sm font-medium text-white">{nombre}</p>
            <p className="text-[11px] text-brand-200/70">{ROL_LABEL[user?.rol ?? ''] ?? 'Sin rol'}</p>
          </div>
          <button onClick={logout} title="Cerrar sesión" className="rounded-lg p-1.5 text-brand-200/70 hover:bg-white/10 hover:text-white">
            <LogOut className="size-4" />
          </button>
        </div>
      </div>
    </div>
  )

  return (
    <div className="flex h-full">
      <aside className="hidden w-64 shrink-0 lg:block">{sidebar}</aside>
      {open && (
        <div className="fixed inset-0 z-40 lg:hidden">
          <div className="absolute inset-0 bg-stone-900/50" onClick={() => setOpen(false)} />
          <div className="absolute inset-y-0 left-0 w-64">{sidebar}</div>
          <button className="absolute top-4 left-68 rounded-lg bg-white p-2" onClick={() => setOpen(false)}><X className="size-4" /></button>
        </div>
      )}
      <div className="flex min-w-0 flex-1 flex-col">
        <header className="flex items-center gap-3 border-b border-stone-200 bg-white px-4 py-3 lg:hidden">
          <button onClick={() => setOpen(true)} className="rounded-lg p-1.5 hover:bg-stone-100"><Menu className="size-5" /></button>
          <Logo />
        </header>
        <main key={loc.pathname} className="min-h-0 flex-1 overflow-y-auto">
          <Outlet />
        </main>
      </div>
    </div>
  )
}

export function PageHeader({ title, subtitle, actions }: { title: string; subtitle?: string; actions?: React.ReactNode }) {
  return (
    <div className="flex flex-wrap items-end justify-between gap-4 pb-6">
      <div>
        <h1 className="text-2xl font-semibold tracking-tight text-stone-900">{title}</h1>
        {subtitle && <p className="mt-1 text-sm text-stone-500">{subtitle}</p>}
      </div>
      {actions && <div className="flex flex-wrap items-center gap-2">{actions}</div>}
    </div>
  )
}
